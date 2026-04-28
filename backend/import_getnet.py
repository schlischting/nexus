#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Nexus: Script de Ingestão de Transações GETNET

Propósito:
  - Ler arquivo Excel ADTO_*.xlsx (sheet: 'Detalhado')
  - Validar e limpar dados conforme regras GETNET
  - Aplicar filtros obrigatórios (TIPO DE LANÇAMENTO == 'Vendas')
  - Detectar duplicatas via hash (incluindo CNPJ para unicidade por filial)
  - Preparar estrutura para Supabase API
  - Suportar processamento de 1 ou múltiplos CNPJs (41 filiais)

Uso:
  # Importar apenas 1 CNPJ (com filtro)
  python import_getnet.py --file ADTO_23042026.xlsx --filial-cnpj "12345678000195" --dry-run

  # Importar TODOS os CNPJs do arquivo (sem filtro)
  python import_getnet.py --file ADTO_23042026.xlsx --dry-run
"""

import sys
import os
import argparse
import hashlib
import json
import logging
import re
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Tuple

import pandas as pd
from dotenv import load_dotenv

# Carregar variáveis de ambiente para Supabase (opcional em dry-run)
try:
    from supabase import create_client, Client
except ImportError:
    Client = None

# Configurar encoding UTF-8 para output
sys.stdout.reconfigure(encoding='utf-8')

# ============================================================================
# CONFIGURAÇÃO DE LOGGING
# ============================================================================

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('import_getnet.log', encoding='utf-8'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# ============================================================================
# CONSTANTES - MAPEAMENTO POR ÍNDICE DE COLUNA (MAIS ROBUSTO)
# ============================================================================

# Índices das colunas no Excel ADTO (após skiprows=7)
# Posição 0-based do arquivo "Detalhado"
INDICES_COLUNAS = {
    'codigo_ec': 1,                   # ESTABELECIMENTO COMERCIAL
    'filial_cnpj': 2,                 # CPF / CNPJ
    'data_venda': 13,                 # DATA DA VENDA
    'hora_venda': 14,                 # HORA DA VENDA (NOVO - usar este em vez de timestamp)
    'valor_venda': 15,                # VALOR DA VENDA
    'numero_autorizacao': 10,         # AUTORIZAÇÃO
    'nsu': 11,                        # NÚMERO COMPROVANTE DE VENDA (NSU)
    'bandeira': 4,                    # BANDEIRA / MODALIDADE
    'tipo_lancamento': 5              # TIPO DE LANÇAMENTO
}

# Descrição das colunas (para logging/referência)
NOMES_COLUNAS = {
    'codigo_ec': 'ESTABELECIMENTO COMERCIAL',
    'filial_cnpj': 'CPF / CNPJ',
    'nsu': 'NÚMERO COMPROVANTE DE VENDA (NSU)',
    'numero_autorizacao': 'AUTORIZAÇÃO',
    'data_venda': 'DATA DA VENDA',
    'hora_venda': 'HORA DA VENDA',
    'valor_venda': 'VALOR DA VENDA',
    'bandeira': 'BANDEIRA / MODALIDADE',
    'tipo_lancamento': 'TIPO DE LANÇAMENTO'
}

# Filtro obrigatório
TIPO_LANCAMENTO_VALIDO = 'Vendas'

# Tipos a ignorar (para logging)
TIPOS_IGNORADOS = {
    'Negociações Realizadas',
    'Saldo Anterior',
    'Cancelamento/Chargeback',
    'Pagamento Realizado'
}

# Mapeamento CNPJ → filial_id (será carregado do banco)
CNPJ_FILIAL_MAP = {}  # Será populado dinâmicamente

# ============================================================================
# FUNÇÕES DE VALIDAÇÃO
# ============================================================================

def extrair_numeros_cnpj(cnpj_str: str) -> str:
    """Extrair apenas dígitos do CNPJ/CPF."""
    if not isinstance(cnpj_str, str):
        return ""
    return re.sub(r'\D', '', cnpj_str)


def validar_nsu(nsu: str) -> bool:
    """NSU não pode ser nulo ou '-'."""
    if not isinstance(nsu, str):
        return False
    nsu_limpo = str(nsu).strip()
    return nsu_limpo and nsu_limpo != '-'


def validar_autorizacao(auth: str) -> bool:
    """
    Autorização: deve ter pelo menos 1 caractere (não nulo ou '-').
    Rejeita explicitamente '-' igual ao NSU.
    """
    if not isinstance(auth, str):
        return False
    auth_limpo = str(auth).strip()
    # Rejeitar vazio, nulo ou '-'
    return auth_limpo and auth_limpo != '-'


def validar_hora(hora_str: str) -> Tuple[bool, Optional[str]]:
    """
    Validar hora. Esperado: 'HH:MM:SS'
    Retorna (válido, hora_str_limpo)
    """
    if not isinstance(hora_str, str):
        return False, None

    hora_limpo = str(hora_str).strip()

    # Rejeitar valor vazio ou '-'
    if not hora_limpo or hora_limpo == '-':
        return False, None

    # Tentar validar com strptime
    try:
        datetime.strptime(hora_limpo, '%H:%M:%S')
        return True, hora_limpo
    except ValueError:
        return False, None


def validar_data(data_str: str) -> Tuple[bool, Optional[datetime]]:
    """Validar data. Esperado: '2026-03-26 00:00:00'"""
    if not isinstance(data_str, str):
        return False, None

    # Tentar múltiplos formatos
    formatos = [
        '%Y-%m-%d %H:%M:%S',  # '2026-03-26 00:00:00'
        '%Y-%m-%d',           # '2026-03-26'
        '%d/%m/%Y %H:%M:%S',  # '26/03/2026 00:00:00'
        '%d/%m/%Y'            # '26/03/2026'
    ]

    for fmt in formatos:
        try:
            data_obj = datetime.strptime(str(data_str).strip(), fmt)
            return True, data_obj
        except ValueError:
            continue

    return False, None


def validar_valor(valor_str) -> Tuple[bool, Optional[float]]:
    """
    Validar valor. Pode vir como:
      - String inteira: '255', '7600'
      - String com decimais: '1000.50'
      - Não pode ser '-'
    Retorna (válido, valor_float)
    """
    if not isinstance(valor_str, str):
        return False, None

    valor_limpo = str(valor_str).strip()

    # Rejeitar valor vazio ou '-'
    if not valor_limpo or valor_limpo == '-':
        return False, None

    try:
        # Converter para float (trata '255' como 255.00)
        valor_float = float(valor_limpo)

        # Valor deve ser positivo
        if valor_float <= 0:
            return False, None

        return True, valor_float

    except (ValueError, AttributeError):
        return False, None


def validar_bandeira(bandeira_str: str) -> Tuple[bool, Optional[str]]:
    """
    Extrair bandeira base de strings como:
      'Visa Crédito' → 'Visa'
      'Mastercard Débito' → 'Mastercard'
      'Elo' → 'Elo'
    """
    if not isinstance(bandeira_str, str):
        return False, None

    bandeira_raw = str(bandeira_str).strip().lower()

    # Mapeamento: prefixo conhecido → bandeira padrão
    bandeiras_conhecidas = {
        'visa': 'Visa',
        'mastercard': 'Mastercard',
        'elo': 'Elo',
        'diners': 'Diners',
        'amex': 'AMEX',
        'discover': 'Discover',
        'hipercard': 'Hipercard'
    }

    for prefixo, nome_padrao in bandeiras_conhecidas.items():
        if bandeira_raw.startswith(prefixo):
            return True, nome_padrao

    # Bandeira desconhecida
    return False, None


def gerar_hash_transacao(cnpj: str, nsu: str, auth: str, valor: str, data_str: str) -> str:
    """
    Gerar hash SHA256 único para detectar duplicatas.
    Concatena: CNPJ + NSU + Autorização + Valor + Data (CNPJ incluso para garantir unicidade por filial).
    """
    chave = f"{cnpj}|{nsu}|{auth}|{valor}|{data_str}"
    return hashlib.sha256(chave.encode()).hexdigest()


def verificar_ou_criar_filial(supabase_client: Optional[object], cnpj: str, codigo_ec: str) -> bool:
    """
    Verificar se filial existe na tabela 'filiais' do Supabase.
    Se não existir, inserir automaticamente.

    Args:
        supabase_client: Cliente Supabase (None em dry-run)
        cnpj: CNPJ da filial (14 dígitos, sem formatação)
        codigo_ec: Código de Estabelecimento Comercial do Excel

    Returns:
        True se existe ou foi criada, False se erro
    """
    if not supabase_client:
        # Em dry-run, apenas log
        logger.info(f"[DRY-RUN] Verificaria filial: {cnpj}")
        return True

    try:
        # Tentar buscar filial existente
        response = supabase_client.table('filiais').select('filial_id').eq('codigo_filial', cnpj).execute()

        if response.data and len(response.data) > 0:
            logger.info(f"✓ Filial {cnpj} já existe (filial_id: {response.data[0]['filial_id']})")
            return True

        # Se não existe, inserir automaticamente
        logger.warning(f"⚠ Filial {cnpj} não encontrada. Criando automaticamente...")

        new_filial = {
            'codigo_filial': cnpj,
            'nome_filial': f"Filial {cnpj} (Auto-criada)",
            'uf': 'SP',  # Padrão - pode ser ajustado depois
            'ativo': True
        }

        insert_response = supabase_client.table('filiais').insert(new_filial).execute()

        if insert_response.data:
            logger.info(f"✓ Filial {cnpj} criada com sucesso (filial_id: {insert_response.data[0]['filial_id']})")
            return True
        else:
            logger.error(f"✗ Erro ao criar filial {cnpj}: {insert_response}")
            return False

    except Exception as e:
        logger.error(f"✗ Erro ao verificar/criar filial {cnpj}: {str(e)}")
        return False


# ============================================================================
# CLASSE PRINCIPAL
# ============================================================================

class ImportadorGETNET:
    """Orquestrador de ingestão GETNET a partir de Excel ADTO."""

    def __init__(self, arquivo: str, filial_cnpj: Optional[str] = None, dry_run: bool = False, supabase_client: Optional[object] = None):
        self.arquivo = Path(arquivo)
        self.filial_cnpj_filtro = extrair_numeros_cnpj(filial_cnpj) if filial_cnpj else None
        self.dry_run = dry_run
        self.supabase_client = supabase_client

        self.df_bruto: pd.DataFrame = None
        self.df_limpo: pd.DataFrame = None
        self.transacoes_validas: List[Dict] = []
        self.erros: List[Dict] = []
        self.avisos: List[Dict] = []

        # Métricas agrupadas por CNPJ
        self.metricas_por_cnpj: Dict[str, Dict] = {}
        self.cnpjs_processados: set = set()
        self.cnpjs_verificados: Dict[str, bool] = {}  # Cache de verificação de filiais

        self.metricas = {
            'total_linhas': 0,
            'filtradas_tipo_lancamento': 0,
            'descartes_nulos': 0,
            'validas': 0,
            'com_erro': 0,
            'duplicatas': 0,
            'valor_total': 0.0,
            'distribuicao_tipos': {},
            'filiais_criadas': 0
        }

    def ler_arquivo(self) -> bool:
        """Ler Excel ADTO_*.xlsx da aba 'Detalhado', pulando primeiras 7 linhas."""
        logger.info(f"Lendo arquivo Excel: {self.arquivo}")

        if not self.arquivo.exists():
            logger.error(f"Arquivo não encontrado: {self.arquivo}")
            return False

        try:
            # Ler aba 'Detalhado', pular 7 linhas de header
            self.df_bruto = pd.read_excel(
                self.arquivo,
                sheet_name='Detalhado',
                skiprows=7,
                dtype=str  # Tudo como string inicialmente para limpeza
            )

            self.metricas['total_linhas'] = len(self.df_bruto)
            logger.info(f"Total de linhas lidas: {self.metricas['total_linhas']:,}")
            logger.info(f"Colunas encontradas: {len(self.df_bruto.columns)}")

            # Log dos primeiros 5 nomes de coluna (pode ter encoding issues)
            logger.info(f"Primeiras 5 colunas (índices 0-4):")
            for i in range(min(5, len(self.df_bruto.columns))):
                logger.info(f"  [{i}] {repr(self.df_bruto.columns[i])}")

            return True

        except FileNotFoundError:
            logger.error(f"Arquivo Excel não encontrado: {self.arquivo}")
            return False
        except KeyError as e:
            logger.error(f"Aba 'Detalhado' não encontrada no Excel: {e}")
            return False
        except Exception as e:
            logger.error(f"Erro ao ler arquivo Excel: {e}")
            return False

    def limpar_e_validar(self) -> bool:
        """
        Limpar e validar transações GETNET conforme regras:
        1. Filtrar TIPO_LANÇAMENTO == 'Vendas'
        2. Descartar linhas com NSU nulo ou '-'
        3. Descartar linhas com VALOR nulo ou '-'
        4. Descartar subtotais (ESTABELECIMENTO_COMERCIAL nulo)
        5. Validar demais campos
        6. Detectar duplicatas via hash
        """
        logger.info("Iniciando validação e limpeza...")

        df = self.df_bruto.copy()

        hashes_vistos = set()

        for idx, row in df.iterrows():
            erros_linha = []
            linha_numero = idx + 8 + 2  # +8 (skiprows) +2 (header + 1-based indexing)

            # ========== EXTRAÇÃO DE CAMPOS (por índice) ==========

            # TIPO DE LANÇAMENTO (coluna 5)
            tipo_lancamento = str(row.iloc[INDICES_COLUNAS['tipo_lancamento']]).strip() if INDICES_COLUNAS['tipo_lancamento'] < len(row) else ''

            # ESTABELECIMENTO COMERCIAL (coluna 1)
            estabelecimento = str(row.iloc[INDICES_COLUNAS['codigo_ec']]).strip() if INDICES_COLUNAS['codigo_ec'] < len(row) else ''

            # NSU (coluna 11)
            nsu_raw = str(row.iloc[INDICES_COLUNAS['nsu']]).strip() if INDICES_COLUNAS['nsu'] < len(row) else ''

            # VALOR DA VENDA (coluna 15)
            valor_raw = str(row.iloc[INDICES_COLUNAS['valor_venda']]).strip() if INDICES_COLUNAS['valor_venda'] < len(row) else ''

            # ========== FILTROS CRÍTICOS (descartar silenciosamente) ==========

            # Filtro 1: TIPO_LANÇAMENTO deve ser 'Vendas'
            if tipo_lancamento not in [TIPO_LANCAMENTO_VALIDO]:
                # Contar por tipo para relatório
                if tipo_lancamento:
                    self.metricas['distribuicao_tipos'][tipo_lancamento] = \
                        self.metricas['distribuicao_tipos'].get(tipo_lancamento, 0) + 1
                self.metricas['filtradas_tipo_lancamento'] += 1
                continue

            # Filtro 2: ESTABELECIMENTO_COMERCIAL não pode ser nulo (é subtotal)
            if not estabelecimento:
                self.metricas['descartes_nulos'] += 1
                self.avisos.append({
                    'linha': linha_numero,
                    'motivo': 'ESTABELECIMENTO_COMERCIAL nulo (subtotal?)'
                })
                continue

            # Filtro 3: NSU não pode ser nulo ou '-'
            if not validar_nsu(nsu_raw):
                self.metricas['descartes_nulos'] += 1
                self.avisos.append({
                    'linha': linha_numero,
                    'motivo': f"NSU nulo ou '-': {nsu_raw}"
                })
                continue

            nsu = nsu_raw

            # Filtro 4: VALOR não pode ser nulo ou '-'
            valor_valido, valor = validar_valor(valor_raw)
            if not valor_valido:
                self.metricas['descartes_nulos'] += 1
                self.avisos.append({
                    'linha': linha_numero,
                    'motivo': f"Valor nulo ou '-': {valor_raw}"
                })
                continue

            # ========== VALIDAÇÕES RESTANTES ==========

            # AUTORIZAÇÃO (coluna 10) - AGORA COM VALIDAÇÃO DE '-'
            auth_raw = str(row.iloc[INDICES_COLUNAS['numero_autorizacao']]).strip() if INDICES_COLUNAS['numero_autorizacao'] < len(row) else ''
            if not validar_autorizacao(auth_raw):
                erros_linha.append(f"Autorização vazia, '-' ou inválida: {auth_raw}")
            auth = auth_raw

            # DATA (coluna 13)
            data_raw = str(row.iloc[INDICES_COLUNAS['data_venda']]).strip() if INDICES_COLUNAS['data_venda'] < len(row) else ''
            data_valida, data_obj = validar_data(data_raw)
            if not data_valida:
                erros_linha.append(f"Data inválida: {data_raw}")

            # HORA (coluna 14 - NOVA ABORDAGEM)
            hora_raw = str(row.iloc[INDICES_COLUNAS['hora_venda']]).strip() if INDICES_COLUNAS['hora_venda'] < len(row) else ''
            hora_valida, hora_str = validar_hora(hora_raw)
            if not hora_valida:
                erros_linha.append(f"Hora inválida: {hora_raw}")

            # BANDEIRA (coluna 4)
            bandeira_raw = str(row.iloc[INDICES_COLUNAS['bandeira']]).strip() if INDICES_COLUNAS['bandeira'] < len(row) else ''
            bandeira_valida, bandeira = validar_bandeira(bandeira_raw)
            if not bandeira_valida:
                erros_linha.append(f"Bandeira inválida ou desconhecida: {bandeira_raw}")

            # CNPJ DA FILIAL (coluna 2)
            cnpj_raw = str(row.iloc[INDICES_COLUNAS['filial_cnpj']]).strip() if INDICES_COLUNAS['filial_cnpj'] < len(row) else ''
            cnpj = extrair_numeros_cnpj(cnpj_raw)
            if not cnpj:
                erros_linha.append(f"CNPJ inválido ou vazio")

            # Se filial_cnpj foi especificado, filtrar apenas esse CNPJ
            if self.filial_cnpj_filtro and cnpj != self.filial_cnpj_filtro:
                erros_linha.append(f"CNPJ não bate: {cnpj} vs {self.filial_cnpj_filtro}")

            # Verificar/criar filial no Supabase (apenas uma vez por CNPJ)
            if cnpj and cnpj not in self.cnpjs_verificados:
                filial_ok = verificar_ou_criar_filial(self.supabase_client, cnpj, estabelecimento)
                self.cnpjs_verificados[cnpj] = filial_ok
                if filial_ok:
                    self.metricas['filiais_criadas'] += 1

            # Se filial não pode ser verificada/criada, rejeitar transação
            if cnpj and not self.cnpjs_verificados.get(cnpj, False):
                erros_linha.append(f"Filial {cnpj} não pode ser verificada/criada no Supabase")

            # ========== DETECÇÃO DE DUPLICATA ==========
            # Hash incluindo CNPJ para garantir unicidade por filial
            if cnpj and nsu and auth and valor and data_obj:
                hash_tx = gerar_hash_transacao(
                    cnpj, nsu, auth, f"{valor:.2f}", data_obj.isoformat()
                )
                if hash_tx in hashes_vistos:
                    erros_linha.append("Transação duplicada (hash já visto)")
                    self.metricas['duplicatas'] += 1
                else:
                    hashes_vistos.add(hash_tx)

            # ========== REGISTRAR RESULTADO ==========
            if erros_linha:
                self.metricas['com_erro'] += 1
                self.erros.append({
                    'linha': linha_numero,
                    'nsu': nsu,
                    'cnpj': cnpj,
                    'erros': '; '.join(erros_linha)
                })

                # Contar erros por CNPJ
                if cnpj:
                    if cnpj not in self.metricas_por_cnpj:
                        self.metricas_por_cnpj[cnpj] = {
                            'validas': 0,
                            'com_erro': 0,
                            'valor_total': 0.0
                        }
                    self.metricas_por_cnpj[cnpj]['com_erro'] += 1
                    self.cnpjs_processados.add(cnpj)
            else:
                self.metricas['validas'] += 1
                self.metricas['valor_total'] += valor

                self.transacoes_validas.append({
                    'filial_cnpj': cnpj,
                    'nsu': nsu,
                    'numero_autorizacao': auth,
                    'data_transacao': data_obj.date().isoformat(),
                    'hora_transacao': hora_str,
                    'valor': valor,
                    'bandeira': bandeira,
                    'codigo_ec': estabelecimento,
                    'tipo_lancamento': tipo_lancamento,
                    'hash_transacao': gerar_hash_transacao(
                        cnpj, nsu, auth, f"{valor:.2f}", data_obj.isoformat()
                    ),
                    'status': 'pendente'
                })

                # Agrupar métricas por CNPJ
                if cnpj not in self.metricas_por_cnpj:
                    self.metricas_por_cnpj[cnpj] = {
                        'validas': 0,
                        'com_erro': 0,
                        'valor_total': 0.0
                    }
                self.metricas_por_cnpj[cnpj]['validas'] += 1
                self.metricas_por_cnpj[cnpj]['valor_total'] += valor
                self.cnpjs_processados.add(cnpj)

        logger.info(
            f"Validação completa:\n"
            f"  - Filtradas por tipo (não 'Vendas'): {self.metricas['filtradas_tipo_lancamento']:,}\n"
            f"  - Descartes por nulos: {self.metricas['descartes_nulos']:,}\n"
            f"  - Válidas: {self.metricas['validas']:,}\n"
            f"  - Com erro: {self.metricas['com_erro']:,}\n"
            f"  - Duplicatas: {self.metricas['duplicatas']}"
        )

        return self.metricas['validas'] > 0

    def exibir_relatorio(self):
        """Exibir relatório completo de processamento."""
        total_processado = (
            self.metricas['filtradas_tipo_lancamento'] +
            self.metricas['descartes_nulos'] +
            self.metricas['validas'] +
            self.metricas['com_erro']
        )

        print("\n" + "="*100)
        print("RELATÓRIO DE INGESTÃO GETNET - ADTO")
        print("="*100)
        print(f"Data: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        filtro_label = f"Filial CNPJ: {self.filial_cnpj_filtro}" if self.filial_cnpj_filtro else "Modo: TODOS OS CNPJs"
        print(filtro_label)
        print(f"Arquivo: {self.arquivo.name}")
        print(f"Modo: {'DRY-RUN (sem inserção)' if self.dry_run else 'PRODUÇÃO'}")
        print("-"*100)

        print("\n📊 RESUMO GERAL:")
        print(f"  Total de linhas no Excel:        {self.metricas['total_linhas']:,}")
        print(f"  Processadas:                     {total_processado:,}")
        print(f"    ├─ Filtradas (não 'Vendas'):   {self.metricas['filtradas_tipo_lancamento']:,}")
        print(f"    ├─ Descartes (nulos):          {self.metricas['descartes_nulos']:,}")
        print(f"    ├─ Válidas (inserção):         {self.metricas['validas']:,} OK")
        print(f"    └─ Com erro (validação):       {self.metricas['com_erro']:,} ERRO")
        print(f"  Duplicatas detectadas:           {self.metricas['duplicatas']}")
        print(f"  Valor total importado:           R$ {self.metricas['valor_total']:,.2f}")
        if not self.dry_run and self.metricas['filiais_criadas'] > 0:
            print(f"  Filiais criadas no Supabase:     {self.metricas['filiais_criadas']}")

        if self.metricas['distribuicao_tipos']:
            print("\n📋 DISTRIBUIÇÃO DE TIPOS (DESCARTADOS):")
            for tipo, count in sorted(self.metricas['distribuicao_tipos'].items(), key=lambda x: x[1], reverse=True):
                pct = (count / self.metricas['total_linhas']) * 100
                print(f"  ├─ {tipo}: {count:,} ({pct:.1f}%)")

        if self.metricas['total_linhas'] > 0:
            taxa_sucesso = (self.metricas['validas'] / self.metricas['total_linhas']) * 100
            print(f"\n📈 TAXA DE SUCESSO GERAL: {taxa_sucesso:.1f}%")

        # Mostrar breakdown por CNPJ se processou múltiplos
        if len(self.cnpjs_processados) > 1:
            print(f"\n💾 DETALHES POR CNPJ ({len(self.cnpjs_processados)} filiais):")
            print(f"  {'CNPJ':<15} {'Válidas':>10} {'Erros':>10} {'Valor Total':>20}")
            print(f"  {'-'*15} {'-'*10} {'-'*10} {'-'*20}")

            for cnpj in sorted(self.metricas_por_cnpj.keys()):
                metr = self.metricas_por_cnpj[cnpj]
                print(f"  {cnpj:<15} {metr['validas']:>10,} {metr['com_erro']:>10,} R$ {metr['valor_total']:>18,.2f}")

        if self.erros:
            print(f"\n⚠️  ERROS DE VALIDAÇÃO (mostrando 5 primeiros de {len(self.erros)}):")
            for erro in self.erros[:5]:
                cnpj_info = f" [{erro.get('cnpj', 'N/A')}]" if erro.get('cnpj') else ""
                print(f"  Linha {erro['linha']:,} (NSU {erro['nsu']}{cnpj_info}):")
                print(f"    └─ {erro['erros']}")
            if len(self.erros) > 5:
                print(f"  ... e mais {len(self.erros) - 5} erros (ver import_getnet.log)")

        if self.avisos:
            print(f"\n⏭️  AVISOS ({len(self.avisos)} linhas descartadas):")
            for aviso in self.avisos[:3]:
                print(f"  Linha {aviso['linha']:,}: {aviso['motivo']}")
            if len(self.avisos) > 3:
                print(f"  ... e mais {len(self.avisos) - 3} avisos (ver import_getnet.log)")

        print("="*100 + "\n")

    def gerar_json_saida(self) -> str:
        """Gerar JSON pronto para Supabase API."""
        output = {
            'metadata': {
                'data_ingesta': datetime.now().isoformat(),
                'filtro_cnpj': self.filial_cnpj_filtro if self.filial_cnpj_filtro else 'TODOS',
                'cnpjs_processados': sorted(list(self.cnpjs_processados)),
                'total_registros': len(self.transacoes_validas),
                'valor_total': self.metricas['valor_total'],
                'arquivo_origem': str(self.arquivo),
                'metricas_por_cnpj': self.metricas_por_cnpj
            },
            'transacoes': self.transacoes_validas
        }

        return json.dumps(output, indent=2, ensure_ascii=False)

    def processar(self) -> bool:
        """Pipeline completo de processamento."""
        logger.info("Iniciando pipeline de ingestão GETNET...")

        if not self.ler_arquivo():
            return False

        if not self.limpar_e_validar():
            logger.error("Nenhuma transação válida após validação")
            self.exibir_relatorio()
            return False

        self.exibir_relatorio()

        # Salvar saída
        output_file = self.arquivo.stem + '_processed.json'
        json_saida = self.gerar_json_saida()

        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(json_saida)

        logger.info(f"JSON de saída salvo em: {output_file}")

        if self.dry_run:
            logger.info("Modo seco ativado. Nenhum dado foi enviado ao Supabase.")
        else:
            logger.info("Para enviar ao Supabase, remova a flag --dry-run e configure"
                       " as credenciais SUPABASE_URL e SUPABASE_KEY.")

        return True


# ============================================================================
# PONTO DE ENTRADA
# ============================================================================

def main():
    """Parse de argumentos e execução."""
    parser = argparse.ArgumentParser(
        description='Importador de Transações GETNET (Excel ADTO) para Nexus',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
Exemplos:
  # Modo validação (dry-run)
  python import_getnet.py --file ADTO_23042026.xlsx --dry-run

  # Modo produção (requer SUPABASE_URL e SUPABASE_KEY no .env)
  python import_getnet.py --file ADTO_23042026.xlsx --filial-cnpj "12345678000195"

  # Todos os CNPJs, validação apenas
  python import_getnet.py --file ADTO_23042026.xlsx --dry-run

Notas:
  - O arquivo deve ser Excel (.xlsx) com aba 'Detalhado'
  - CNPJ aceita com ou sem formatação (apenas dígitos são extraídos)
  - Em modo --dry-run, apenas valida, não insere no banco
  - Modo produção: filiais não encontradas são criadas automaticamente
  - Saída: ADTO_23042026_processed.json (pronto para Supabase)
  - Suporta 41 filiais (CNPJs) únicas no arquivo
        '''
    )

    parser.add_argument(
        '--file',
        type=str,
        required=True,
        help='Arquivo Excel ADTO_*.xlsx com aba "Detalhado"'
    )
    parser.add_argument(
        '--filial-cnpj',
        type=str,
        required=False,
        help='CNPJ da filial (aceita com ou sem formatação). Se omitido, processa TODOS os CNPJs do arquivo'
    )
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Validação sem inserção (testa lógica sem enviar ao Supabase)'
    )

    args = parser.parse_args()

    # Executar
    logger.info(f"Iniciando importação:")
    logger.info(f"  Arquivo: {args.file}")
    if args.filial_cnpj:
        logger.info(f"  Filial CNPJ: {args.filial_cnpj} (filtrado)")
    else:
        logger.info(f"  Filial CNPJ: TODOS (processando todos os CNPJs encontrados)")
    logger.info(f"  Modo: {'DRY-RUN (validação)' if args.dry_run else 'PRODUÇÃO (vai criar filiais se não existirem)'}")

    # Carregar Supabase em modo produção
    supabase_client = None
    if not args.dry_run:
        try:
            load_dotenv()
            supabase_url = os.getenv('SUPABASE_URL')
            supabase_key = os.getenv('SUPABASE_KEY')

            if not supabase_url or not supabase_key:
                logger.error("SUPABASE_URL ou SUPABASE_KEY não configuradas no .env")
                logger.error("Execute em modo --dry-run para validação sem banco de dados")
                return 1

            from supabase import create_client
            supabase_client = create_client(supabase_url, supabase_key)
            logger.info("✓ Conectado ao Supabase")

        except ImportError:
            logger.error("Biblioteca 'supabase-py' não instalada")
            logger.error("Execute: pip install supabase")
            return 1
        except Exception as e:
            logger.error(f"Erro ao conectar ao Supabase: {str(e)}")
            return 1

    importador = ImportadorGETNET(
        arquivo=args.file,
        filial_cnpj=args.filial_cnpj,
        dry_run=args.dry_run,
        supabase_client=supabase_client
    )

    sucesso = importador.processar()
    return 0 if sucesso else 1


if __name__ == '__main__':
    exit(main())
