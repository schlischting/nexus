#!/usr/bin/env python3
"""
Nexus: Script de Ingestão de Transações GETNET

Propósito:
  - Ler arquivo CSV 'extrato_getnet.csv'
  - Validar e limpar dados
  - Preparar estrutura para Supabase API
  - Detectar duplicatas via hash
  - Calcular métricas de qualidade

Uso:
  python import_getnet.py --file extrato_getnet.csv --filial_id 1 --dry-run
"""

import argparse
import hashlib
import json
import logging
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Tuple

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

COLUNAS_ESPERADAS = {
    'nsu': 'NSU',
    'numero_autorizacao': 'Autorização',
    'data_transacao': 'Data',
    'hora_transacao': 'Hora',
    'valor': 'Valor',
    'portador_digitos': 'Últimos 4 Dígitos',
    'bandeira': 'Bandeira',
    'estabelecimento_codigo': 'Estabelecimento',
    'descricao_transacao': 'Descrição'
}

BANDEIRAS_VALIDAS = {'Visa', 'Mastercard', 'Elo', 'Diners', 'AMEX', 'Discover'}
TOLERANCIA_VALOR = 0.01  # R$ 0.01


# ============================================================================
# FUNÇÕES DE VALIDAÇÃO
# ============================================================================

def validar_nsu(nsu: str) -> bool:
    """NSU deve ter 6-12 dígitos."""
    if not isinstance(nsu, str):
        return False
    return nsu.isdigit() and 6 <= len(nsu) <= 12


def validar_autorizacao(auth: str) -> bool:
    """Autorização deve ter 4-6 caracteres alphanumericos."""
    if not isinstance(auth, str):
        return False
    return 4 <= len(str(auth).strip()) <= 6 and str(auth).isalnum()


def validar_data(data_str: str) -> Tuple[bool, str]:
    """Validar formato de data (DD/MM/YYYY ou YYYY-MM-DD)."""
    for fmt in ['%d/%m/%Y', '%Y-%m-%d']:
        try:
            datetime.strptime(str(data_str).strip(), fmt)
            return True, fmt
        except ValueError:
            continue
    return False, None


def validar_hora(hora_str: str) -> bool:
    """Validar formato de hora (HH:MM:SS)."""
    try:
        datetime.strptime(str(hora_str).strip(), '%H:%M:%S')
        return True
    except ValueError:
        return False


def validar_valor(valor) -> bool:
    """Valor deve ser numérico positivo."""
    try:
        v = float(str(valor).replace(',', '.'))
        return v > 0
    except (ValueError, AttributeError):
        return False


def validar_bandeira(bandeira: str) -> bool:
    """Bandeira deve ser conhecida."""
    return str(bandeira).strip() in BANDEIRAS_VALIDAS


def gerar_hash_transacao(nsu: str, auth: str, valor: str, data: str) -> str:
    """
    Gerar hash SHA256 único para detectar duplicatas.
    Concatena: NSU + Autorização + Valor + Data
    """
    chave = f"{nsu}|{auth}|{valor}|{data}"
    return hashlib.sha256(chave.encode()).hexdigest()


# ============================================================================
# CLASSE PRINCIPAL
# ============================================================================

class ImportadorGETNET:
    """Orquestrador de ingestão GETNET."""

    def __init__(self, arquivo: str, filial_id: int, dry_run: bool = False):
        self.arquivo = Path(arquivo)
        self.filial_id = filial_id
        self.dry_run = dry_run

        self.df_bruto: pd.DataFrame = None
        self.df_limpo: pd.DataFrame = None
        self.transacoes_validas: List[Dict] = []
        self.erros: List[Dict] = []

        self.metricas = {
            'total_linhas': 0,
            'validas': 0,
            'com_erro': 0,
            'duplicatas': 0,
            'valor_total': 0.0
        }

    def ler_arquivo(self) -> bool:
        """Ler CSV e fazer validação básica."""
        logger.info(f"Lendo arquivo: {self.arquivo}")

        if not self.arquivo.exists():
            logger.error(f"Arquivo não encontrado: {self.arquivo}")
            return False

        try:
            self.df_bruto = pd.read_csv(
                self.arquivo,
                dtype={
                    'NSU': str,
                    'Autorização': str,
                    'Últimos 4 Dígitos': str,
                    'Bandeira': str,
                    'Estabelecimento': str
                },
                encoding='utf-8'
            )

            self.metricas['total_linhas'] = len(self.df_bruto)
            logger.info(f"Total de linhas lidas: {self.metricas['total_linhas']}")
            logger.info(f"Colunas encontradas: {list(self.df_bruto.columns)}")

            return True

        except pd.errors.ParserError as e:
            logger.error(f"Erro ao parsear CSV: {e}")
            return False
        except Exception as e:
            logger.error(f"Erro inesperado ao ler arquivo: {e}")
            return False

    def limpar_e_validar(self) -> bool:
        """Limpar dados e validar regras de negócio."""
        logger.info("Iniciando validação e limpeza...")

        df = self.df_bruto.copy()
        df = df.fillna('')  # Preencher NaN com strings vazias

        hashes_vistos = set()

        for idx, row in df.iterrows():
            erros_linha = []

            # ========== VALIDAÇÕES ==========

            # NSU
            nsu = str(row.get('NSU', '')).strip()
            if not validar_nsu(nsu):
                erros_linha.append(f"NSU inválido: {nsu}")
            else:
                nsu = nsu.zfill(12)  # Padding com zeros

            # Autorização
            auth = str(row.get('Autorização', '')).strip()
            if not validar_autorizacao(auth):
                erros_linha.append(f"Autorização inválida: {auth}")

            # Data
            data_str = str(row.get('Data', '')).strip()
            data_valida, fmt_data = validar_data(data_str)
            if not data_valida:
                erros_linha.append(f"Data inválida: {data_str}")
                data_obj = None
            else:
                data_obj = datetime.strptime(data_str, fmt_data)

            # Hora
            hora_str = str(row.get('Hora', '')).strip()
            if not validar_hora(hora_str):
                erros_linha.append(f"Hora inválida: {hora_str}")
            else:
                hora_obj = datetime.strptime(hora_str, '%H:%M:%S').time()

            # Valor
            valor_str = str(row.get('Valor', '')).replace(',', '.')
            if not validar_valor(valor_str):
                erros_linha.append(f"Valor inválido: {valor_str}")
                valor = None
            else:
                valor = float(valor_str)

            # Portador (últimos 4 dígitos)
            portador = str(row.get('Últimos 4 Dígitos', '')).strip()
            if len(portador) != 4 or not portador.isdigit():
                erros_linha.append(f"Portador inválido: {portador}")

            # Bandeira
            bandeira = str(row.get('Bandeira', '')).strip()
            if not validar_bandeira(bandeira):
                erros_linha.append(f"Bandeira inválida: {bandeira}")

            # Estabelecimento
            estab = str(row.get('Estabelecimento', '')).strip()
            if len(estab) < 3:
                erros_linha.append(f"Estabelecimento inválido: {estab}")

            # Descrição (opcional, limpar)
            descricao = str(row.get('Descrição', '')).strip()[:255]

            # ========== DETECÇÃO DE DUPLICATA ==========
            if nsu and auth and valor and data_obj:
                hash_tx = gerar_hash_transacao(nsu, auth, str(valor), data_obj.isoformat())
                if hash_tx in hashes_vistos:
                    erros_linha.append("Transação duplicada (hash já visto)")
                    self.metricas['duplicatas'] += 1
                else:
                    hashes_vistos.add(hash_tx)

            # ========== REGISTRAR RESULTADO ==========
            if erros_linha:
                self.metricas['com_erro'] += 1
                self.erros.append({
                    'linha': idx + 2,  # +2 para cabeçalho e indexação 1-based
                    'nsu': nsu,
                    'erros': '; '.join(erros_linha)
                })
            else:
                self.metricas['validas'] += 1
                self.metricas['valor_total'] += valor

                self.transacoes_validas.append({
                    'filial_id': self.filial_id,
                    'nsu': nsu,
                    'numero_autorizacao': auth,
                    'data_transacao': data_obj.date().isoformat(),
                    'hora_transacao': hora_obj.isoformat(),
                    'valor': valor,
                    'portador_digitos': portador,
                    'bandeira': bandeira,
                    'estabelecimento_codigo': estab,
                    'descricao_transacao': descricao,
                    'hash_transacao': gerar_hash_transacao(
                        nsu, auth, str(valor), data_obj.isoformat()
                    ),
                    'status': 'pendente',
                    'quantidade_parcelas': 1,
                    'parcela_atual': 1
                })

        logger.info(f"Validação completa. Válidas: {self.metricas['validas']}, "
                    f"Erros: {self.metricas['com_erro']}")

        return self.metricas['validas'] > 0

    def exibir_relatorio(self):
        """Exibir relatório de processamento."""
        print("\n" + "="*70)
        print("RELATÓRIO DE INGESTÃO GETNET")
        print("="*70)
        print(f"Data: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"Filial ID: {self.filial_id}")
        print(f"Arquivo: {self.arquivo}")
        print("-"*70)
        print(f"Total de linhas: {self.metricas['total_linhas']}")
        print(f"Transações válidas: {self.metricas['validas']}")
        print(f"Linhas com erro: {self.metricas['com_erro']}")
        print(f"Duplicatas detectadas: {self.metricas['duplicatas']}")
        print(f"Valor total ingested: R$ {self.metricas['valor_total']:.2f}")
        print(f"Taxa de sucesso: {(self.metricas['validas']/self.metricas['total_linhas']*100):.1f}%")
        print("-"*70)

        if self.erros:
            print("\nPRIMEIROS 5 ERROS:")
            for erro in self.erros[:5]:
                print(f"  Linha {erro['linha']}: {erro['erros']}")
            if len(self.erros) > 5:
                print(f"  ... e mais {len(self.erros) - 5} erros (ver import_getnet.log)")

        print("="*70 + "\n")

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
        description='Importador de Transações GETNET para Nexus',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
Exemplos:
  python import_getnet.py --file extrato_getnet.csv --filial_id 1
  python import_getnet.py --file extrato_getnet.csv --filial_id 1 --dry-run
        '''
    )

    parser.add_argument(
        '--file',
        type=str,
        required=True,
        help='Caminho para arquivo CSV com transações GETNET'
    )
    parser.add_argument(
        '--filial_id',
        type=int,
        required=True,
        help='ID da filial para os registros'
    )
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Executar validação sem enviar para Supabase'
    )

    args = parser.parse_args()

    # Executar
    importador = ImportadorGETNET(
        arquivo=args.file,
        filial_id=args.filial_id,
        dry_run=args.dry_run
    )

    sucesso = importador.processar()
    return 0 if sucesso else 1


if __name__ == '__main__':
    exit(main())
