# Skill: Nexus Python Backend

**Versão:** 1.0  
**Data:** 2026-04-25  
**Escopo:** import_getnet.py, totvs_client.py, padrões, erros, reprocessamento

---

## Padrões de import_getnet.py v2.1

### Inicialização
```python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

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

# Configurar encoding UTF-8 (crítico no Windows)
sys.stdout.reconfigure(encoding='utf-8')

# Logging com arquivo + console
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('import_getnet.log', encoding='utf-8'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)
```

### Mapeamento de Colunas (Por Índice, NÃO por Nome)
```python
# ⚠️ CRÍTICO: Use índices (0-based), não nomes com acentos
# Razão: Nomes de coluna têm acentos (NÚMERO, AUTORIZAÇÃO) que causam encoding issues

INDICES_COLUNAS = {
    'codigo_ec': 1,                   # ESTABELECIMENTO COMERCIAL
    'filial_cnpj': 2,                 # CPF / CNPJ
    'data_venda': 13,                 # DATA DA VENDA
    'hora_venda': 14,                 # HORA DA VENDA (usar este, não timestamp)
    'valor_venda': 15,                # VALOR DA VENDA
    'numero_autorizacao': 10,         # AUTORIZAÇÃO
    'nsu': 11,                        # NÚMERO COMPROVANTE DE VENDA (NSU)
    'bandeira': 4,                    # BANDEIRA / MODALIDADE
    'tipo_lancamento': 5              # TIPO DE LANÇAMENTO
}

# Acesso: row.iloc[INDICES_COLUNAS['nsu']]  ← seguro
# Não: row['NÚMERO COMPROVANTE DE VENDA (NSU)']  ← pode falhar por encoding
```

### Funções de Validação

```python
def extrair_numeros_cnpj(cnpj_str: str) -> str:
    """Remove formatação (pontos, barras, etc) → '84943067001393'"""
    if not isinstance(cnpj_str, str):
        return ""
    return re.sub(r'\D', '', cnpj_str)

def validar_nsu(nsu: str) -> bool:
    """NSU: não pode ser nulo ou '-'"""
    nsu_limpo = str(nsu).strip()
    return nsu_limpo and nsu_limpo != '-'

def validar_autorizacao(auth: str) -> bool:
    """Autorização: não pode ser nulo ou '-'"""
    auth_limpo = str(auth).strip()
    return auth_limpo and auth_limpo != '-'

def validar_hora(hora_str: str) -> Tuple[bool, Optional[str]]:
    """Validar formato HH:MM:SS"""
    hora_limpo = str(hora_str).strip()
    if not hora_limpo or hora_limpo == '-':
        return False, None
    try:
        datetime.strptime(hora_limpo, '%H:%M:%S')
        return True, hora_limpo
    except ValueError:
        return False, None

def validar_data(data_str: str) -> Tuple[bool, Optional[datetime]]:
    """Suportar múltiplos formatos: YYYY-MM-DD HH:MM:SS, DD/MM/YYYY, etc"""
    formatos = [
        '%Y-%m-%d %H:%M:%S',
        '%Y-%m-%d',
        '%d/%m/%Y %H:%M:%S',
        '%d/%m/%Y'
    ]
    for fmt in formatos:
        try:
            return True, datetime.strptime(str(data_str).strip(), fmt)
        except ValueError:
            continue
    return False, None

def validar_valor(valor_str) -> Tuple[bool, Optional[float]]:
    """Converter string → float, rejeitar <= 0 e '-'"""
    valor_limpo = str(valor_str).strip()
    if not valor_limpo or valor_limpo == '-':
        return False, None
    try:
        valor_float = float(valor_limpo)
        return valor_float > 0, valor_float if valor_float > 0 else None
    except (ValueError, AttributeError):
        return False, None

def validar_bandeira(bandeira_str: str) -> Tuple[bool, Optional[str]]:
    """Extrair bandeira base: 'Visa Crédito' → 'Visa'"""
    bandeira_raw = str(bandeira_str).strip().lower()
    mapeamento = {
        'visa': 'Visa',
        'mastercard': 'Mastercard',
        'elo': 'Elo',
        'amex': 'AMEX'
    }
    for prefixo, nome in mapeamento.items():
        if bandeira_raw.startswith(prefixo):
            return True, nome
    return False, None

def gerar_hash_transacao(cnpj: str, nsu: str, auth: str, valor: str, data_str: str) -> str:
    """
    Hash SHA256 para deduplicação CNPJ-scoped.
    ⚠️ CRÍTICO: Include CNPJ no hash para evitar falsas duplicatas entre filiais
    """
    chave = f"{cnpj}|{nsu}|{auth}|{valor}|{data_str}"
    return hashlib.sha256(chave.encode()).hexdigest()
```

### Classe Principal: ImportadorGETNET

```python
class ImportadorGETNET:
    def __init__(self, arquivo: str, filial_cnpj: Optional[str] = None, dry_run: bool = False):
        self.arquivo = Path(arquivo)
        self.filial_cnpj_filtro = extrair_numeros_cnpj(filial_cnpj) if filial_cnpj else None
        self.dry_run = dry_run
        self.transacoes_validas = []
        self.metricas = {
            'total_linhas': 0,
            'filtradas_tipo_lancamento': 0,
            'descartes_nulos': 0,
            'validas': 0,
            'duplicatas': 0,
            'valor_total': 0.0,
            'distribuicao_tipos': {}
        }

    def ler_arquivo(self) -> bool:
        """Ler Excel ADTO_*.xlsx aba 'Detalhado', skip 7 linhas"""
        try:
            self.df_bruto = pd.read_excel(
                self.arquivo,
                sheet_name='Detalhado',
                skiprows=7,
                dtype=str  # Tudo como string para limpeza
            )
            self.metricas['total_linhas'] = len(self.df_bruto)
            logger.info(f"✓ Lidas {self.metricas['total_linhas']:,} linhas")
            return True
        except Exception as e:
            logger.error(f"✗ Erro ao ler {self.arquivo}: {e}")
            return False

    def limpar_e_validar(self) -> bool:
        """Validar transações conforme regras"""
        hashes_vistos = set()

        for idx, row in self.df_bruto.iterrows():
            linha_numero = idx + 10

            # Extração por índice (seguro)
            tipo = str(row.iloc[INDICES_COLUNAS['tipo_lancamento']]).strip()
            if tipo != 'Vendas':
                self.metricas['distribuicao_tipos'][tipo] = \
                    self.metricas['distribuicao_tipos'].get(tipo, 0) + 1
                self.metricas['filtradas_tipo_lancamento'] += 1
                continue

            # ... validação dos campos
            # Acumular erros em erros_linha
            # Se ok, criar dict e adicionar a transacoes_validas

            transacao = {
                'filial_cnpj': cnpj,
                'nsu': nsu,
                'numero_autorizacao': auth,
                'data_venda': data_str,
                'hora_venda': hora_str,
                'valor': valor,
                'bandeira': bandeira,
                'hash_transacao': hash_tx,
                'status': 'pendente'
            }

            if hash_tx in hashes_vistos:
                self.metricas['duplicatas'] += 1
                logger.warning(f"⚠ Duplicata detectada (linha {linha_numero}): {hash_tx[:16]}...")
                continue

            hashes_vistos.add(hash_tx)
            self.transacoes_validas.append(transacao)
            self.metricas['validas'] += 1
            self.metricas['valor_total'] += valor

        return len(self.transacoes_validas) > 0

    def gerar_relatorio(self) -> dict:
        """Retornar métricas estruturadas"""
        return {
            'timestamp': datetime.now().isoformat(),
            'arquivo': str(self.arquivo),
            'metricas': self.metricas,
            'transacoes_validas': len(self.transacoes_validas),
            'resumo': {
                'total_lido': self.metricas['total_linhas'],
                'filtrado_tipo': self.metricas['filtradas_tipo_lancamento'],
                'importado': self.metricas['validas'],
                'duplicatas': self.metricas['duplicatas'],
                'valor_total': f"R$ {self.metricas['valor_total']:.2f}"
            }
        }

    def salvar_json(self, caminho: Path) -> bool:
        """Salvar transações em JSON para importar em Supabase"""
        try:
            with open(caminho, 'w', encoding='utf-8') as f:
                json.dump(self.transacoes_validas, f, indent=2, ensure_ascii=False)
            logger.info(f"✓ Salvo {len(self.transacoes_validas)} transações em {caminho}")
            return True
        except Exception as e:
            logger.error(f"✗ Erro ao salvar JSON: {e}")
            return False
```

---

## Criar Novos Importers (Padrão totvs_import.py)

### Estrutura
```python
"""
totvs_import.py: Importar títulos do TOTVS para Supabase
Fonte: Arquivo JSON exportado por programa Progress diariamente
"""

class ImportadorTOTVS:
    """Similar a ImportadorGETNET mas para títulos_totvs"""

    def __init__(self, arquivo_json: str, dry_run: bool = False):
        self.arquivo = Path(arquivo_json)
        self.dry_run = dry_run
        self.titulos_validos = []
        self.metricas = {}

    def ler_arquivo(self) -> bool:
        """Ler JSON de títulos"""
        try:
            with open(self.arquivo, 'r', encoding='utf-8') as f:
                dados = json.load(f)
            logger.info(f"✓ Carregados {len(dados)} títulos de {self.arquivo}")
            return True
        except Exception as e:
            logger.error(f"✗ Erro ao ler {self.arquivo}: {e}")
            return False

    def validar(self) -> bool:
        """Validar campos obrigatórios do TOTVS"""
        for titulo_raw in dados:
            # Validar: filial_cnpj, numero_nf, especie, valor_bruto, etc
            # Normalizar valores
            titulo = {
                'filial_cnpj': titulo_raw['filial_cnpj'],  # 14 dígitos
                'numero_nf': titulo_raw['numero_nf'],
                'especie': titulo_raw.get('especie', 'NF'),  # Default 'NF'
                'valor_bruto': float(titulo_raw['valor']),
                'status': 'aberto'
            }
            self.titulos_validos.append(titulo)
        return len(self.titulos_validos) > 0
```

---

## totvs_client.py: Mock → Produção

### Padrão Mock (Hoje)
```python
class TotvsMockClient:
    """Mock para desenvolvimento/teste"""

    def buscar_titulos_por_nf(self, filial_cnpj: str, numero_nf: str) -> List[dict]:
        """Retorna títulos da NF (geralmente 1, exceção: múltiplos cartões)"""
        # Dados mockados por filial
        mock_data = {
            '84943067001393': [
                {'titulo_id': 1, 'numero_nf': 'NF-001', 'valor': 1000.00, ...},
                {'titulo_id': 2, 'numero_nf': 'NF-002', 'valor': 500.00, ...}
            ]
        }
        return mock_data.get(filial_cnpj, [])

    def buscar_titulos_abertos(self, filial_cnpj: str) -> List[dict]:
        """Retorna todos títulos abertos da filial"""
        pass

    def obter_titulo_por_id(self, titulo_id: str) -> Optional[dict]:
        """Retornar 1 título específico"""
        pass
```

### Evolução para Produção (PASOE)
```python
class TotvsPasoeClient:
    """Comunicação com PASOE (Progress Application Server)"""

    def __init__(self, base_url: str, username: str, password: str):
        self.base_url = base_url  # https://totvs-server/api
        self.session = requests.Session()
        self.session.auth = (username, password)

    def buscar_titulos_por_nf(self, filial_cnpj: str, numero_nf: str) -> List[dict]:
        """GET /api/titulos?filial={cnpj}&nf={nf}"""
        try:
            resp = self.session.get(
                f"{self.base_url}/titulos",
                params={'filial': filial_cnpj, 'nf': numero_nf},
                timeout=10
            )
            if resp.status_code == 200:
                return resp.json()
            else:
                logger.error(f"TOTVS: {resp.status_code} - {resp.text}")
                return []
        except Exception as e:
            logger.error(f"Erro conectando PASOE: {e}")
            return []

    def executar_baixa(self, vinculos_json: str) -> dict:
        """POST /api/baixa com JSON de vínculos"""
        try:
            resp = self.session.post(
                f"{self.base_url}/baixa",
                json=vinculos_json,
                timeout=30
            )
            return resp.json()
        except Exception as e:
            logger.error(f"Erro na baixa PASOE: {e}")
            return {'status': 'erro', 'mensagem': str(e)}
```

---

## Exportação JSON Nexus → TOTVS

```python
def exportar_para_totvs(vinculos_confirmados: List[dict]) -> str:
    """Preparar JSON para enviar ao PASOE para baixa"""
    payload = []
    
    for vl in vinculos_confirmados:
        payload.append({
            'nexus_vinculo_id': vl['vinculo_id'],
            'nsu': vl['nsu'],
            'filial_cnpj': vl['filial_cnpj'],
            'especie': vl['especie'],  # 'NF' ou 'AN'
            'serie': vl['serie'],
            'numero': vl['numero'],
            'parcela': vl['parcela'],
            'valor_liquido_parcela': float(vl['valor']),
            'data_vencimento': vl['data_vencimento'].isoformat()
        })
    
    return json.dumps(payload, indent=2, ensure_ascii=False)

def processar_resposta_totvs(resposta_json: str) -> List[dict]:
    """Processar retorno do PASOE e atualizar status dos vínculos"""
    resposta = json.loads(resposta_json)
    
    atualizacoes = []
    for item in resposta:
        atualizacoes.append({
            'vinculo_id': item['nexus_vinculo_id'],
            'status': 'confirmado' if item['status'] == 'baixado' else 'erro_baixa',
            'data_baixa_totvs': item.get('data_baixa'),
            'status_baixa': item['status'],
            'erro_baixa': item.get('erro_descricao')
        })
    
    return atualizacoes
```

---

## Tratamento de Erros e Reprocessamento

### Erros Esperados
```python
ERROS_CONHECIDOS = {
    'E001_TITULO_NAO_ENCONTRADO': {
        'mensagem': 'Título não existe na filial',
        'acao': 'Supervisor valida NF informado'
    },
    'E002_SALDO_INSUFICIENTE': {
        'mensagem': 'Saldo da filial insuficiente',
        'acao': 'Reprocessar quando saldo disponível'
    },
    'E003_TITULO_VENCIDO': {
        'mensagem': 'Título vencido, não pode baixar',
        'acao': 'Supervisor aprova ou rejeita'
    }
}

def registrar_erro(vinculo_id: str, erro_codigo: str, erro_descricao: str):
    """Registrar erro de baixa e permitir retry"""
    logger.error(f"[{erro_codigo}] Vínculo {vinculo_id}: {erro_descricao}")
    
    # Atualizar status_vinculo no DB
    # Notificar supervisor via Slack/Email
    # Permitir reprocessamento manual
```

### Retry Logic
```python
def reprocessar_erros(max_retries: int = 3):
    """Buscar vínculos com erro_baixa e reprocessar"""
    
    vinculos_erro = supabase.table('conciliacao_vinculos').select('*').eq(
        'status', 'erro_baixa'
    ).execute()
    
    for vl in vinculos_erro.data:
        if vl['retry_count'] < max_retries:
            logger.info(f"Reprocessando vínculo {vl['vinculo_id']} (tentativa {vl['retry_count'] + 1})")
            
            resultado = totvs_client.executar_baixa([vl])
            
            if resultado['status'] == 'baixado':
                # Atualizar para confirmado
                pass
            else:
                # Incrementar retry_count
                pass
```

---

## Estrutura de Entrada/Saída

### Input: Excel GETNET
```
arquivo: ADTO_23042026.xlsx
sheet: "Detalhado"
skiprows: 7
estrutura: [ESTABELECIMENTO_COMERCIAL, CPF/CNPJ, AUTORIZAÇÃO, ..., DATA_VENDA, HORA_VENDA, VALOR_VENDA]
```

### Output: JSON para Supabase
```json
[
  {
    "filial_cnpj": "84943067001393",
    "nsu": "000002771",
    "numero_autorizacao": "123456",
    "data_venda": "2026-03-26",
    "hora_venda": "11:07:56",
    "valor": 1500.00,
    "bandeira": "Visa",
    "hash_transacao": "abc123...",
    "status": "pendente"
  }
]
```

### Input: Títulos TOTVS (JSON exportado por Progress)
```json
[
  {
    "filial_cnpj": "84943067001393",
    "numero_nf": "001234",
    "especie": "NF",
    "serie": "001",
    "numero": "001234",
    "parcela": "a1",
    "valor_bruto": 1500.00,
    "data_emissao": "2026-03-20",
    "data_vencimento": "2026-05-28"
  }
]
```

### Output: JSON para TOTVS (Nexus → PASOE)
```json
[
  {
    "nexus_vinculo_id": "uuid-xxx",
    "nsu": "000002771",
    "filial_cnpj": "84943067001393",
    "especie": "NF",
    "numero": "001234",
    "valor_liquido_parcela": 1500.00,
    "data_vencimento": "2026-05-28"
  }
]
```

---

## Command Line Interface

```bash
# Importar todos CNPJs (dry-run)
python backend/import_getnet.py --file ADTO_23042026.xlsx --dry-run

# Importar específico (com Supabase)
python backend/import_getnet.py \
  --file ADTO_23042026.xlsx \
  --filial-cnpj 84943067001393 \
  --upload

# Verbose logging
python backend/import_getnet.py \
  --file ADTO_23042026.xlsx \
  --debug
```

---

## Checklist Implementação

- [ ] Validações implementadas (NSU, data, valor, bandeira)
- [ ] Hash com CNPJ para deduplicação filial-specific
- [ ] UTF-8 encoding forçado (windows-safe)
- [ ] Logging com arquivo + console
- [ ] JSON output estruturado
- [ ] Dry-run mode operacional
- [ ] Suporte multi-CNPJ
- [ ] Relatório de métricas
- [ ] totvs_client.py em mock (pronto para PASOE)
- [ ] Funções de exportação JSON
- [ ] Tratamento de erros com retry
