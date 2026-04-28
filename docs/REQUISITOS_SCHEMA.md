# Nexus — Requisitos do Schema PostgreSQL (Supabase)
**Versão:** 3.0 definitiva

---

## Regras Gerais

- Banco: PostgreSQL 15+ via Supabase
- Chave de isolamento multi-tenant: `filial_cnpj CHAR(14)` (só dígitos)
- RLS em TODAS as tabelas
- Snake_case em tudo
- Timestamps automáticos via trigger

---

## Tabelas Necessárias

### 1. `filiais`
```
filial_cnpj    CHAR(14) PK — CHECK (^\d{14}$)
codigo_ec      VARCHAR(20) — código EC na GETNET
razao_social   VARCHAR(200)
ativo          BOOLEAN DEFAULT true
criado_em      TIMESTAMP
atualizado_em  TIMESTAMP
```

### 2. `user_filiais` (RLS mapping)
```
id             SERIAL PK
user_id        UUID FK → auth.users
filial_cnpj    CHAR(14) FK → filiais
perfil         VARCHAR(20) — 'operador_filial'|'supervisor'|'admin'
UNIQUE(user_id, filial_cnpj)
```

### 3. `transacoes_getnet`
```
transacao_id        BIGSERIAL PK
filial_cnpj         CHAR(14) FK → filiais
nsu                 VARCHAR(30)
autorizacao         VARCHAR(30)
data_venda          DATE
hora_venda          TIME
valor_venda         NUMERIC(15,2) — valor BRUTO
valor_liquido       NUMERIC(15,2)
valor_liquido_parcela NUMERIC(15,2)
parcelas            SMALLINT DEFAULT 1
valor_parcela       NUMERIC(15,2)
bandeira            VARCHAR(50)
modalidade          VARCHAR(20) — 'credito'|'debito'
data_vencimento     DATE
codigo_ec           VARCHAR(20)
status              ENUM(pendente|conciliada|divergencia|cancelada)
hash_transacao      VARCHAR(64) UNIQUE — SHA256(cnpj|nsu|auth|data|valor)
data_ingesta        TIMESTAMP
UNIQUE(filial_cnpj, nsu)
```

### 4. `titulos_totvs`
```
titulo_id           BIGSERIAL PK
filial_cnpj         CHAR(14) FK → filiais
numero_nf           VARCHAR(30)
especie             VARCHAR(10) — 'NF'|'AN'|'NFS'|etc
serie               VARCHAR(5)
numero              VARCHAR(20)
parcela             VARCHAR(10) — sem padrão: 'a1','01','b2'...
valor_bruto         NUMERIC(15,2)
data_emissao        DATE
data_vencimento     DATE
cliente_codigo      VARCHAR(20)
cliente_nome        VARCHAR(200)
status              ENUM(aberto|baixado|baixado_parcial|cancelado)
nsu_getnet          VARCHAR(30) — preenchido após baixa
nexus_vinculo_id    UUID — preenchido após baixa
data_ingesta        TIMESTAMP
atualizado_em       TIMESTAMP
UNIQUE(filial_cnpj, especie, serie, numero, parcela)
```

### 5. `conciliacao_vinculos`
```
vinculo_id          UUID PK DEFAULT gen_random_uuid()
filial_cnpj         CHAR(14) FK → filiais
transacao_getnet_id BIGINT FK → transacoes_getnet
titulo_totvs_id     BIGINT FK → titulos_totvs (nullable — nsu_invalido)
numero_nf_informado VARCHAR(30) — o que operador digitou
score_confianca     NUMERIC(4,3) — 0.000 a 1.000
origem              VARCHAR(20) — 'auto'|'sugestao'|'manual'
status              ENUM abaixo
confirmado_por      VARCHAR(200) — email supervisor
data_confirmacao    TIMESTAMP
data_exportacao     TIMESTAMP
data_baixa_totvs    TIMESTAMP
valor_baixado       NUMERIC(15,2)
erro_descricao      TEXT
observacao          TEXT
criado_por          VARCHAR(200) — email operador
criado_em           TIMESTAMP
atualizado_em       TIMESTAMP
```

### Status `conciliacao_vinculos` (ENUM)
```
nsu_invalido      — NSU digitado não existe na GETNET
pendente          — aguardando match
sugerido          — match automático gerado (0.75-0.95)
confirmado        — supervisor aprovou (ou auto >0.95)
exportado         — JSON enviado ao TOTVS
baixado           — Progress executou com sucesso
baixado_parcial   — baixa parcial executada
erro_baixa        — Progress retornou erro
rejeitado         — supervisor cancelou
```

### 6. `config_parametros`
```
chave       VARCHAR(50) PK
valor       VARCHAR(200)
descricao   TEXT
atualizado_em TIMESTAMP

Registros iniciais:
tolerancia_valor_pct = '5'
tolerancia_dias      = '3'
score_auto           = '0.95'
score_sugestao       = '0.75'
```

---

## Views Obrigatórias

```sql
-- Alerta A: NSUs sem título vinculado
vw_nsu_sem_titulo:
  SELECT transacoes_getnet WHERE status = 'pendente'
  AND transacao_id NOT IN (
    SELECT transacao_getnet_id FROM conciliacao_vinculos
    WHERE status NOT IN ('nsu_invalido','rejeitado')
  )

-- Alerta B: Títulos sem NSU
vw_titulo_sem_nsu:
  SELECT titulos_totvs WHERE status = 'aberto'
  AND titulo_id NOT IN (
    SELECT titulo_totvs_id FROM conciliacao_vinculos
    WHERE status NOT IN ('nsu_invalido','rejeitado')
    AND titulo_totvs_id IS NOT NULL
  )

-- Sugestões para supervisor
vw_sugestoes_supervisor:
  SELECT conciliacao_vinculos
  WHERE status = 'sugerido'
  ORDER BY score_confianca DESC
```

---

## RLS Policies

```
operador_filial:
  filial_cnpj IN (
    SELECT filial_cnpj FROM user_filiais
    WHERE user_id = auth.uid()
    AND perfil = 'operador_filial'
  )

supervisor:
  acesso total de leitura em todas as filiais
  UPDATE apenas em conciliacao_vinculos

admin:
  acesso total sem restrição
```

---

## Índices Obrigatórios

```sql
idx_tgetnet_cnpj_data    (filial_cnpj, data_venda DESC)
idx_tgetnet_nsu          (filial_cnpj, nsu)
idx_tgetnet_status       (status) WHERE status = 'pendente'
idx_ttotvs_cnpj_nf       (filial_cnpj, numero_nf)
idx_ttotvs_status        (status) WHERE status = 'aberto'
idx_vinculos_status      (status)
idx_vinculos_score       (score_confianca DESC)
idx_vinculos_getnet      (transacao_getnet_id)
idx_vinculos_totvs       (titulo_totvs_id)
```

---

## Função de Scoring

```sql
calcular_score_matching(
  p_valor_getnet    NUMERIC,  -- valor_venda (bruto)
  p_valor_totvs     NUMERIC,  -- valor_bruto título
  p_data_getnet     DATE,     -- data_venda
  p_data_totvs      DATE,     -- data_vencimento título
  p_tolerancia_pct  NUMERIC,  -- da config_parametros
  p_tolerancia_dias INTEGER   -- da config_parametros
) RETURNS NUMERIC

Score = peso_valor(0.5) + peso_data(0.3) + peso_nf(0.2)
```
