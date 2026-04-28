#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script para inspecionar estrutura real do arquivo ADTO_*.xlsx
"""

import pandas as pd
import numpy as np
from pathlib import Path
import re

arquivo = Path(r"d:\Projetos Dev\Nexus\Excel\ADTO 23042026.xlsx")

print(f"\nLendo: {arquivo}")
print("=" * 120)

# Ler Excel com skip rows
try:
    df = pd.read_excel(arquivo, sheet_name='Detalhado', skiprows=7, dtype=str)
    print("[OK] Excel carregado com sucesso\n")
except Exception as e:
    print(f"[ERRO] {e}")
    exit(1)

# ============================================================================
# 1. ESTRUTURA BASICA
# ============================================================================

print("\n[1] ESTRUTURA BASICA")
print("-" * 120)
print(f"Shape: {df.shape[0]:,} linhas x {df.shape[1]} colunas\n")
print("Colunas encontradas:")
for i, col in enumerate(df.columns, 1):
    print(f"  {i:2d}. {col}")

# ============================================================================
# 2. PRIMEIRAS LINHAS
# ============================================================================

print("\n[2] PRIMEIRAS 3 LINHAS")
print("-" * 120)
print(df.head(3).to_string())

# ============================================================================
# 3. DISTRIBUICAO POR TIPO DE LANCAMENTO
# ============================================================================

print("\n[3] DISTRIBUICAO POR TIPO DE LANCAMENTO")
print("-" * 120)

if 'TIPO DE LANCAMENTO' in df.columns:
    distribuicao = df['TIPO DE LANCAMENTO'].value_counts(dropna=False).sort_values(ascending=False)
    for tipo, count in distribuicao.items():
        pct = (count / len(df)) * 100
        print(f"  {str(tipo):30s}: {count:6,d} ({pct:5.1f}%)")
    print(f"\nTotal: {distribuicao.sum():,}")
else:
    print("ERRO: Coluna 'TIPO DE LANCAMENTO' nao encontrada")

# ============================================================================
# 4. ANALISE DE COLUNAS CRITICAS
# ============================================================================

print("\n[4] ANALISE DE COLUNAS CRITICAS")
print("-" * 120)

# NSU
nsu_col = 'NUMERO COMPROVANTE DE VENDA (NSU)'
if nsu_col in df.columns:
    print(f"\nNSU ({nsu_col}):")
    print(f"  Non-null: {df[nsu_col].notna().sum():,}")
    print(f"  Null: {df[nsu_col].isna().sum():,}")
    print(f"  Valores '-': {(df[nsu_col] == '-').sum():,}")
    print(f"  Valores vazios string: {(df[nsu_col].fillna('').str.strip() == '').sum():,}")

    nsu_unicos = df[nsu_col].dropna().unique()
    print(f"  Valores unicos (total): {len(nsu_unicos):,}")
    print(f"  Amostra (primeiros 5): {list(nsu_unicos[:5])}")

    # Duplicatas
    nsu_counts = df[nsu_col].value_counts()
    duplicatas = nsu_counts[nsu_counts > 1]
    print(f"  NSUs que aparecem mais de 1x: {len(duplicatas)}")
    if len(duplicatas) > 0:
        print(f"    Top 5: {duplicatas.head().to_dict()}")
else:
    print(f"ERRO: Coluna '{nsu_col}' nao encontrada")

# VALOR DA VENDA
valor_col = 'VALOR DA VENDA'
if valor_col in df.columns:
    print(f"\nVALOR DA VENDA ({valor_col}):")
    print(f"  Non-null: {df[valor_col].notna().sum():,}")
    print(f"  Null: {df[valor_col].isna().sum():,}")
    print(f"  Valores '-': {(df[valor_col] == '-').sum():,}")

    amostra_valores = df[valor_col].dropna().unique()[:10]
    print(f"  Amostra (primeiros 10): {list(amostra_valores)}")

    # Tentar converter
    try:
        valores_num = pd.to_numeric(df[valor_col].replace('-', np.nan), errors='coerce')
        print(f"  Min: {valores_num.min():,.2f}")
        print(f"  Max: {valores_num.max():,.2f}")
        print(f"  Media: {valores_num.mean():,.2f}")
        print(f"  Total: R$ {valores_num.sum():,.2f}")
    except Exception as e:
        print(f"  ERRO ao converter: {e}")
else:
    print(f"ERRO: Coluna '{valor_col}' nao encontrada")

# DATA DA VENDA
data_col = 'DATA DA VENDA'
if data_col in df.columns:
    print(f"\nDATA DA VENDA ({data_col}):")
    print(f"  Non-null: {df[data_col].notna().sum():,}")
    print(f"  Null: {df[data_col].isna().sum():,}")

    amostra_datas = df[data_col].dropna().unique()[:5]
    print(f"  Amostra (primeiros 5): {list(amostra_datas)}")
    print(f"  Type do primeiro valor: {type(df[data_col].iloc[0])}")
else:
    print(f"ERRO: Coluna '{data_col}' nao encontrada")

# AUTORIZACAO
auth_col = 'AUTORIZACAO'
if auth_col in df.columns:
    print(f"\nAUTORIZACAO ({auth_col}):")
    print(f"  Non-null: {df[auth_col].notna().sum():,}")
    print(f"  Null: {df[auth_col].isna().sum():,}")
    print(f"  Valores '-': {(df[auth_col] == '-').sum():,}")

    amostra_auth = df[auth_col].dropna().unique()[:5]
    print(f"  Amostra (primeiros 5): {list(amostra_auth)}")
else:
    print(f"ERRO: Coluna '{auth_col}' nao encontrada")

# BANDEIRA
bandeira_col = 'BANDEIRA / MODALIDADE'
if bandeira_col in df.columns:
    print(f"\nBANDEIRA ({bandeira_col}):")
    print(f"  Non-null: {df[bandeira_col].notna().sum():,}")
    print(f"  Valores unicos: {df[bandeira_col].nunique()}")

    dist_bandeira = df[bandeira_col].value_counts(dropna=False).sort_values(ascending=False)
    print(f"  Distribuicao:")
    for bandeira, count in dist_bandeira.items():
        print(f"    {str(bandeira):30s}: {count:6,d}")
else:
    print(f"ERRO: Coluna '{bandeira_col}' nao encontrada")

# ESTABELECIMENTO
estab_col = 'ESTABELECIMENTO COMERCIAL'
if estab_col in df.columns:
    print(f"\nESTABELECIMENTO COMERCIAL ({estab_col}):")
    print(f"  Non-null: {df[estab_col].notna().sum():,}")
    print(f"  Null (subtotais?): {df[estab_col].isna().sum():,}")

    amostra_estab = df[estab_col].dropna().unique()[:5]
    print(f"  Amostra (primeiros 5): {list(amostra_estab)}")
else:
    print(f"ERRO: Coluna '{estab_col}' nao encontrada")

# CNPJ
cnpj_col = 'CPF / CNPJ'
if cnpj_col in df.columns:
    print(f"\nCPF / CNPJ ({cnpj_col}):")
    print(f"  Non-null: {df[cnpj_col].notna().sum():,}")
    print(f"  Null: {df[cnpj_col].isna().sum():,}")
    print(f"  Valores unicos: {df[cnpj_col].nunique()}")

    amostra_cnpj = df[cnpj_col].dropna().unique()[:5]
    print(f"  Amostra (primeiros 5): {list(amostra_cnpj)}")

    # Limpar CNPJ
    cnpjs_limpos = df[cnpj_col].apply(lambda x: re.sub(r'\D', '', str(x)) if pd.notna(x) else '')
    print(f"  CNPJs unicos (apenas digitos): {cnpjs_limpos.nunique()}")

    dist_cnpj = cnpjs_limpos.value_counts().sort_values(ascending=False)
    print(f"  Top 10 CNPJs (por frequencia):")
    for cnpj, count in dist_cnpj.head(10).items():
        print(f"    {cnpj}: {count:,}")
else:
    print(f"ERRO: Coluna '{cnpj_col}' nao encontrada")

# ============================================================================
# 5. SAMPLE COMPLETA
# ============================================================================

print("\n[5] AMOSTRA COMPLETA: UMA LINHA COM TIPO='Vendas'")
print("-" * 120)

if 'TIPO DE LANCAMENTO' in df.columns:
    vendas = df[df['TIPO DE LANCAMENTO'].str.strip() == 'Vendas']
    if len(vendas) > 0:
        print(vendas.iloc[0].to_string())
    else:
        print("Nenhuma linha com TIPO='Vendas' encontrada")
else:
    print("Coluna 'TIPO DE LANCAMENTO' nao encontrada")

print("\n" + "=" * 120)
print("[OK] Inspecao concluida")
