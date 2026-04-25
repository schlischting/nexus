#!/usr/bin/env python3
"""
Nexus: Script de Ingestão de Transações GETNET

Propósito:
  - Ler arquivo Excel ADTO_*.xlsx (sheet: 'Detalhado')
  - Validar e limpar dados conforme regras GETNET
  - Aplicar filtros obrigatórios (TIPO DE LANÇAMENTO == 'Vendas')
  - Detectar duplicatas via hash
  - Preparar estrutura para Supabase API

Uso:
  python import_getnet.py --file ADTO_23042026.xlsx --filial_cnpj "12345678000195" --dry-run
"""

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

# ============================================================================
# CONFIGURAÇÃO DE LOGGING
# ============================================================================

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('import_getnet.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# ============================================================================
# CONSTANTES
# ============================================================================

# Mapeamento de colunas do Excel ADTO para atributos internos
COLUNAS_MAPEAMENTO = {
    'codigo_ec': 'ESTABELECIMENTO COMERCIAL',
    'filial_cnpj': 'CPF / CNPJ',
    'nsu': 'NÚMERO COMPROVANTE DE VENDA (NSU)',
    'numero_autorizacao': 'AUTORIZAÇÃO',
    'data_venda': 'DATA DA VENDA',
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
    """Autorização: deve ter pelo menos 1 caractere (não nulo)."""
    if not isinstance(auth, str):
        return False
    return bool(str(auth).strip())


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
    Retorna em centavos (multiplicado por 100).
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
        'mastercard (transacoes)': 'Mastercard',
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


def gerar_hash_transacao(nsu: str, auth: str, valor: str, data_str: str) -> str:
    """
    Gerar hash SHA256 único para detectar duplicatas.
    Concatena: NSU + Autorização + Valor + Data
    """
    chave = f"{nsu}|{auth}|{valor}|{data_str}"
    return hashlib.sha256(chave.encode()).hexdigest()


# ============================================================================
# CLASSE PRINCIPAL
# ============================================================================

class ImportadorGETNET:
    """Orquestrador de ingestão GETNET a partir de Excel ADTO."""

    def __init__(self, arquivo: str, filial_cnpj: str, dry_run: bool = False):
        self.arquivo = Path(arquivo)
        self.filial_cnpj = extrair_numeros_cnpj(filial_cnpj)
        self.dry_run = dry_run

        self.df_bruto: pd.DataFrame = None
        self.df_limpo: pd.DataFrame = None
        self.transacoes_validas: List[Dict] = []
        self.erros: List[Dict] = []
        self.avisos: List[Dict] = []

        self.metricas = {
            'total_linhas': 0,
            'filtradas_tipo_lancamento': 0,
            'descartes_nulos': 0,
            'validas': 0,
            'com_erro': 0,
            'duplicatas': 0,
            'valor_total': 0.0,
            'distribuicao_tipos': {}
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
            logger.info(f"Total de linhas lidas: {self.metricas['total_linhas']}")
            logger.info(f"Colunas encontradas ({len(self.df_bruto.columns)}): {list(self.df_bruto.columns)}")

            # Verificar se todas as colunas esperadas existem
            colunas_esperadas = set(COLUNAS_MAPEAMENTO.values())
            colunas_presentes = set(self.df_bruto.columns)
            colunas_faltantes = colunas_esperadas - colunas_presentes

            if colunas_faltantes:
                logger.error(f"Colunas faltantes no Excel: {colunas_faltantes}")
                return False

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
        df = df.fillna('')  # Preencher NaN com strings vazias

        hashes_vistos = set()

        for idx, row in df.iterrows():
            erros_linha = []
            linha_numero = idx + 8 + 2  # +8 (skiprows) +2 (header + 1-based indexing)

            # ========== FILTROS CRÍTICOS (descartar silenciosamente) ==========

            # Filtro 1: TIPO_LANÇAMENTO deve ser 'Vendas'
            tipo_lancamento = str(row.get(COLUNAS_MAPEAMENTO['tipo_lancamento'], '')).strip()

            if tipo_lancamento not in [TIPO_LANCAMENTO_VALIDO]:
                # Contar por tipo para relatório
                if tipo_lancamento:
                    self.metricas['distribuicao_tipos'][tipo_lancamento] = \
                        self.metricas['distribuicao_tipos'].get(tipo_lancamento, 0) + 1
                self.metricas['filtradas_tipo_lancamento'] += 1
                continue

            # Filtro 2: ESTABELECIMENTO_COMERCIAL não pode ser nulo (é subtotal)
            estabelecimento = str(row.get(COLUNAS_MAPEAMENTO['codigo_ec'], '')).strip()
            if not estabelecimento:
                self.metricas['descartes_nulos'] += 1
                self.avisos.append({
                    'linha': linha_numero,
                    'motivo': 'ESTABELECIMENTO_COMERCIAL nulo (subtotal?)'
                })
                continue

            # Filtro 3: NSU não pode ser nulo ou '-'
            nsu_raw = str(row.get(COLUNAS_MAPEAMENTO['nsu'], '')).strip()
            if not validar_nsu(nsu_raw):
                self.metricas['descartes_nulos'] += 1
                self.avisos.append({
                    'linha': linha_numero,
                    'motivo': f"NSU nulo ou '-': {nsu_raw}"
                })
                continue

            nsu = nsu_raw

            # Filtro 4: VALOR não pode ser nulo ou '-'
            valor_raw = str(row.get(COLUNAS_MAPEAMENTO['valor_venda'], '')).strip()
            valor_valido, valor = validar_valor(valor_raw)
            if not valor_valido:
                self.metricas['descartes_nulos'] += 1
                self.avisos.append({
                    'linha': linha_numero,
                    'motivo': f"Valor nulo ou '-': {valor_raw}"
                })
                continue

            # ========== VALIDAÇÕES RESTANTES ==========

            # Autorização
            auth = str(row.get(COLUNAS_MAPEAMENTO['numero_autorizacao'], '')).strip()
            if not validar_autorizacao(auth):
                erros_linha.append(f"Autorização vazia ou inválida")

            # Data
            data_raw = str(row.get(COLUNAS_MAPEAMENTO['data_venda'], '')).strip()
            data_valida, data_obj = validar_data(data_raw)
            if not data_valida:
                erros_linha.append(f"Data inválida: {data_raw}")

            # Bandeira
            bandeira_raw = str(row.get(COLUNAS_MAPEAMENTO['bandeira'], '')).strip()
            bandeira_valida, bandeira = validar_bandeira(bandeira_raw)
            if not bandeira_valida:
                erros_linha.append(f"Bandeira inválida ou desconhecida: {bandeira_raw}")

            # CNPJ da filial
            cnpj_raw = str(row.get(COLUNAS_MAPEAMENTO['filial_cnpj'], '')).strip()
            cnpj = extrair_numeros_cnpj(cnpj_raw)
            if not cnpj or cnpj != self.filial_cnpj:
                erros_linha.append(f"CNPJ não bate: {cnpj} vs {self.filial_cnpj}")

            # ========== DETECÇÃO DE DUPLICATA ==========
            if nsu and auth and valor and data_obj:
                hash_tx = gerar_hash_transacao(
                    nsu, auth, f"{valor:.2f}", data_obj.isoformat()
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
                    'erros': '; '.join(erros_linha)
                })
            else:
                self.metricas['validas'] += 1
                self.metricas['valor_total'] += valor

                self.transacoes_validas.append({
                    'filial_cnpj': cnpj,
                    'nsu': nsu,
                    'numero_autorizacao': auth,
                    'data_transacao': data_obj.date().isoformat(),
                    'hora_transacao': f"{data_obj.hour:02d}:{data_obj.minute:02d}:{data_obj.second:02d}",
                    'valor': valor,
                    'bandeira': bandeira,
                    'codigo_ec': estabelecimento,
                    'tipo_lancamento': tipo_lancamento,
                    'hash_transacao': gerar_hash_transacao(
                        nsu, auth, f"{valor:.2f}", data_obj.isoformat()
                    ),
                    'status': 'pendente'
                })

        logger.info(
            f"Validação completa:\n"
            f"  - Filtradas por tipo (não 'Vendas'): {self.metricas['filtradas_tipo_lancamento']}\n"
            f"  - Descartes por nulos: {self.metricas['descartes_nulos']}\n"
            f"  - Válidas: {self.metricas['validas']}\n"
            f"  - Com erro: {self.metricas['com_erro']}\n"
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

        print("\n" + "="*80)
        print("RELATÓRIO DE INGESTÃO GETNET - ADTO")
        print("="*80)
        print(f"Data: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"Filial CNPJ: {self.filial_cnpj}")
        print(f"Arquivo: {self.arquivo.name}")
        print(f"Modo: {'DRY-RUN (sem inserção)' if self.dry_run else 'PRODUÇÃO'}")
        print("-"*80)

        print("\n📊 RESUMO DE PROCESSAMENTO:")
        print(f"  Total de linhas no Excel:        {self.metricas['total_linhas']:,}")
        print(f"  Processadas:                     {total_processado:,}")
        print(f"    ├─ Filtradas (não 'Vendas'):   {self.metricas['filtradas_tipo_lancamento']:,}")
        print(f"    ├─ Descartes (nulos):          {self.metricas['descartes_nulos']:,}")
        print(f"    ├─ Válidas (inserção):         {self.metricas['validas']:,} ✅")
        print(f"    └─ Com erro (validação):       {self.metricas['com_erro']:,} ❌")
        print(f"  Duplicatas detectadas:           {self.metricas['duplicatas']}")
        print(f"  Valor total importado:           R$ {self.metricas['valor_total']:,.2f}")

        if self.metricas['distribuicao_tipos']:
            print("\n📋 DISTRIBUIÇÃO DE TIPOS (DESCARTADOS):")
            for tipo, count in sorted(self.metricas['distribuicao_tipos'].items(), key=lambda x: x[1], reverse=True):
                print(f"  ├─ {tipo}: {count:,}")

        if self.metricas['total_linhas'] > 0:
            taxa_sucesso = (self.metricas['validas'] / self.metricas['total_linhas']) * 100
            print(f"\n📈 TAXA DE SUCESSO: {taxa_sucesso:.1f}%")

        if self.erros:
            print(f"\n⚠️  ERROS DE VALIDAÇÃO (mostrando 5 primeiros de {len(self.erros)}):")
            for erro in self.erros[:5]:
                print(f"  Linha {erro['linha']:,} (NSU {erro['nsu']}):")
                print(f"    └─ {erro['erros']}")
            if len(self.erros) > 5:
                print(f"  ... e mais {len(self.erros) - 5} erros (ver import_getnet.log)")

        if self.avisos:
            print(f"\n⏭️  AVISOS ({len(self.avisos)} linhas descartadas):")
            for aviso in self.avisos[:3]:
                print(f"  Linha {aviso['linha']:,}: {aviso['motivo']}")
            if len(self.avisos) > 3:
                print(f"  ... e mais {len(self.avisos) - 3} avisos (ver import_getnet.log)")

        print("="*80 + "\n")

    def gerar_json_saida(self) -> str:
        """Gerar JSON pronto para Supabase API."""
        output = {
            'metadata': {
                'data_ingesta': datetime.now().isoformat(),
                'filial_id': self.filial_id,
                'total_registros': len(self.transacoes_validas),
                'valor_total': self.metricas['valor_total'],
                'arquivo_origem': str(self.arquivo)
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

        if not self.dry_run:
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
  python import_getnet.py --file ADTO_23042026.xlsx --filial-cnpj "12345678000195"
  python import_getnet.py --file ADTO_23042026.xlsx --filial-cnpj "12.345.678/0001-95" --dry-run

Notas:
  - O arquivo deve ser Excel (.xlsx) com aba 'Detalhado'
  - CNPJ aceita com ou sem formatação (apenas dígitos são extraídos)
  - Em modo --dry-run, apenas valida, não insere no banco
  - Saída: ADTO_23042026_processed.json (pronto para Supabase)
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
        required=True,
        help='CNPJ da filial (aceita com ou sem formatação)'
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
    logger.info(f"  Filial CNPJ: {args.filial_cnpj}")
    logger.info(f"  Modo: {'DRY-RUN' if args.dry_run else 'PRODUÇÃO'}")

    importador = ImportadorGETNET(
        arquivo=args.file,
        filial_cnpj=args.filial_cnpj,
        dry_run=args.dry_run
    )

    sucesso = importador.processar()
    return 0 if sucesso else 1


if __name__ == '__main__':
    exit(main())
