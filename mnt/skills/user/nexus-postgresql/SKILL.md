# Skill: Nexus PostgreSQL

**Versão:** 1.0  
**Data:** 2026-04-25  
**Escopo:** RLS, Views, Funções, Índices, Convenções Supabase

---

## Padrões RLS Multi-Tenant por filial_cnpj

### Estrutura Base
```sql
-- Operador_filial: acesso apenas filiais autorizadas
CREATE POLICY rls_table_operador
  ON tabela FOR ALL
  USING (
    filial_cnpj IN (
      SELECT filial_cnpj FROM user_filiais_cnpj 
      WHERE user_id = auth.uid() AND perfil = 'operador_filial'
    )
  );

-- Supervisor: leitura em todas filiais, escrita em conciliacao_vinculos
CREATE POLICY rls_table_supervisor_read
  ON tabela FOR SELECT
  USING (auth.jwt() ->> 'role' = 'supervisor');

-- Admin: bypass total
CREATE POLICY rls_table_admin_all
  ON tabela FOR ALL
  USING (auth.jwt() ->> 'role' = 'admin');
```

### Checklist RLS
- [ ] Toda tabela tem `filial_cnpj CHAR(14) FK → filiais`
- [ ] Toda tabela tem `ALTER TABLE tabela ENABLE ROW LEVEL SECURITY`
- [ ] Operador_filial: busca `user_filiais_cnpj WHERE user_id = auth.uid()`
- [ ] Supervisor: `auth.jwt() ->> 'role' = 'supervisor'` retorna TRUE
- [ ] Admin: `auth.jwt() ->> 'role' = 'admin'` retorna TRUE

---

## Views de Alertas

### vw_nsu_sem_titulo
```sql
CREATE OR REPLACE VIEW vw_nsu_sem_titulo AS
SELECT 
  t.transacao_id,
  t.filial_cnpj,
  t.nsu,
  t.data_venda,
  t.valor,
  COUNT(cv.*) as vinculos_count
FROM transacoes_getnet t
LEFT JOIN conciliacao_vinculos cv ON t.transacao_id = cv.transacao_getnet_id
  AND cv.status NOT IN ('nsu_invalido', 'rejeitado')
WHERE t.status = 'pendente'
GROUP BY t.transacao_id, t.filial_cnpj, t.nsu, t.data_venda, t.valor
HAVING COUNT(cv.vinculo_id) = 0
ORDER BY t.data_venda DESC;
```

**Uso:** Dashboard operador alerta 🔴 "NSU sem título"

### vw_titulo_sem_nsu
```sql
CREATE OR REPLACE VIEW vw_titulo_sem_nsu AS
SELECT 
  t.titulo_id,
  t.filial_cnpj,
  t.numero_nf,
  t.tipo_titulo,
  t.data_vencimento,
  t.valor_bruto,
  COUNT(cv.*) as vinculos_count
FROM titulos_totvs t
LEFT JOIN conciliacao_vinculos cv ON t.titulo_id = cv.titulo_totvs_id
  AND cv.status NOT IN ('nsu_invalido', 'rejeitado')
WHERE t.status = 'aberto'
  AND t.tipo_titulo IN ('NF', 'AN')
GROUP BY t.titulo_id, t.filial_cnpj, t.numero_nf, t.tipo_titulo, t.data_vencimento, t.valor_bruto
HAVING COUNT(cv.vinculo_id) = 0
ORDER BY t.data_vencimento ASC;
```

**Uso:** Dashboard operador alerta 🟡 "Título sem NSU"

### vw_sugestoes_supervisor
```sql
CREATE OR REPLACE VIEW vw_sugestoes_supervisor AS
SELECT 
  cv.vinculo_id,
  cv.filial_cnpj,
  tg.nsu,
  tg.valor as valor_getnet,
  tt.numero_nf,
  tt.valor_bruto as valor_totvs,
  cv.score_confianca,
  ABS(tg.valor - tt.valor_bruto) as diferenca_valor,
  ABS(EXTRACT(DAY FROM tg.data_venda - tt.data_vencimento))::INT as dias_diferenca
FROM conciliacao_vinculos cv
JOIN transacoes_getnet tg ON cv.transacao_getnet_id = tg.transacao_id
JOIN titulos_totvs tt ON cv.titulo_totvs_id = tt.titulo_id
WHERE cv.status = 'sugerido'
ORDER BY cv.score_confianca DESC;
```

**Uso:** Dashboard supervisor validação manual (0.75-0.95 score)

---

## Função calcular_score_matching()

```sql
CREATE OR REPLACE FUNCTION calcular_score_matching(
  p_valor_getnet NUMERIC,
  p_valor_totvs NUMERIC,
  p_data_getnet DATE,
  p_data_totvs DATE,
  p_tolerancia_pct NUMERIC DEFAULT 5,
  p_tolerancia_dias INTEGER DEFAULT 3
) RETURNS NUMERIC AS $$
DECLARE
  score_valor NUMERIC := 0.0;
  score_data NUMERIC := 0.0;
  score_final NUMERIC := 0.0;
  diff_valor_pct NUMERIC;
  diff_dias INTEGER;
BEGIN
  -- Score Valor (peso 0.5)
  -- Diferença percentual: (|valor1 - valor2| / valor2) * 100
  IF p_valor_totvs > 0 THEN
    diff_valor_pct := ABS(p_valor_getnet - p_valor_totvs) / p_valor_totvs * 100;
    IF diff_valor_pct <= p_tolerancia_pct THEN
      score_valor := 0.5;  -- match exato
    ELSIF diff_valor_pct <= (p_tolerancia_pct * 2) THEN
      score_valor := 0.25; -- match parcial
    END IF;
  END IF;

  -- Score Data (peso 0.3)
  diff_dias := ABS(EXTRACT(DAY FROM p_data_getnet - p_data_totvs))::INT;
  IF diff_dias = 0 THEN
    score_data := 0.3;     -- mesmo dia
  ELSIF diff_dias <= p_tolerancia_dias THEN
    score_data := 0.15;    -- dentro tolerância
  END IF;

  -- Score NF (peso 0.2)
  -- Nota: requer numero_nf_informado na tabela conciliacao_vinculos
  -- Por simplicidade, 0.2 automático se há vínculo (verificado em lógica de aplicação)

  score_final := score_valor + score_data + 0.2;
  RETURN ROUND(score_final::NUMERIC, 3);
END;
$$ LANGUAGE plpgsql;
```

**Uso em SQL:**
```sql
SELECT calcular_score_matching(
  tg.valor,
  tt.valor_bruto,
  tg.data_venda,
  tt.data_vencimento,
  (SELECT valor::NUMERIC FROM config_parametros WHERE chave = 'tolerancia_valor_pct'),
  (SELECT valor::INT FROM config_parametros WHERE chave = 'tolerancia_dias')
) as score;
```

---

## Índices para Performance

### Críticos (devem existir SEMPRE)
```sql
-- Transações: busca por filial + data
CREATE INDEX idx_tgetnet_cnpj_data ON transacoes_getnet(filial_cnpj, data_venda DESC);

-- Transações: deduplicação por NSU (CNPJ-scoped)
CREATE INDEX idx_tgetnet_cnpj_nsu ON transacoes_getnet(filial_cnpj, nsu);

-- Títulos: busca por filial + vencimento
CREATE INDEX idx_ttotvs_cnpj_data ON titulos_totvs(filial_cnpj, data_vencimento DESC);

-- Vínculos: status operacional
CREATE INDEX idx_vinculos_status ON conciliacao_vinculos(status)
  WHERE status IN ('pendente', 'sugerido', 'erro_baixa');

-- Vínculos: score para ranking de sugestões
CREATE INDEX idx_vinculos_score ON conciliacao_vinculos(score_confianca DESC);
```

### Recomendados (melhoram dashboards)
```sql
-- Busca por tipo de título (AN vs NF)
CREATE INDEX idx_ttotvs_tipo ON titulos_totvs(filial_cnpj, tipo_titulo);

-- Busca de gaps por filial
CREATE INDEX idx_vinculos_getnet ON conciliacao_vinculos(transacao_getnet_id);
CREATE INDEX idx_vinculos_totvs ON conciliacao_vinculos(titulo_totvs_id);

-- Filtro supervisor para pendentes de baixa
CREATE INDEX idx_vinculos_pendente_baixa ON conciliacao_vinculos(filial_cnpj, status)
  WHERE status IN ('pendente', 'erro_baixa');
```

---

## Convenções Supabase Específicas do Nexus

### Nomenclatura
- Tabelas: snake_case, no plural: `transacoes_getnet`, `titulos_totvs`
- Colunas: snake_case, sem sufixo de tipo: `filial_cnpj` (não `filial_cnpj_pk`)
- Foreign keys: `{tabela_referenciada}_{coluna}`: `filial_cnpj`, `transacao_getnet_id`
- Índices: `idx_{tabela}_{colunas}`: `idx_transacoes_getnet_cnpj_data`
- Views: `vw_{propósito}`: `vw_nsu_sem_titulo`, `vw_sugestoes_supervisor`
- Funções: snake_case, verbo primeiro: `calcular_score_matching()`, `update_timestamp()`

### Timestamps
```sql
-- Sempre usar estes dois campos
data_criacao TIMESTAMP WITH TIME ZONE DEFAULT NOW()
data_atualizacao TIMESTAMP WITH TIME ZONE DEFAULT NOW()

-- Trigger automático para update
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.data_atualizacao = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_{tabela}_timestamp
  BEFORE UPDATE ON {tabela}
  FOR EACH ROW
  EXECUTE FUNCTION update_timestamp();
```

### Enums (Type Safety)
```sql
-- Definir uma vez, reutilizar em múltiplas colunas
CREATE TYPE status_vinculo AS ENUM (
  'pendente', 'sugerido', 'confirmado', 'erro_baixa', 'rejeitado'
);

-- Usar direto
status status_vinculo NOT NULL DEFAULT 'pendente'

-- Atualizar: adicionar novo valor
ALTER TYPE status_vinculo ADD VALUE 'novo_status' BEFORE 'rejeitado';
```

### Row Level Security Checklist
- [ ] `ALTER TABLE tabela ENABLE ROW LEVEL SECURITY;`
- [ ] Policies baseadas em `filial_cnpj` (nunca `filial_id`)
- [ ] Auth verificado via `auth.jwt() ->> 'role'`
- [ ] `user_filiais_cnpj` como tabela de mapeamento
- [ ] Supervisor: acesso read ALL filiais (policy com OR)
- [ ] Admin: policy com `auth.jwt() ->> 'role' = 'admin'`

### Comments (Documentação no Schema)
```sql
COMMENT ON TABLE tabela IS 'Descrição clara da tabela, casos de uso, relacionamentos';
COMMENT ON COLUMN tabela.coluna IS 'Descrição da coluna, restrições, valores esperados';
```

---

## Operações Comuns no FlutterFlow

### Query: Gaps por Filial (Operador)
```sql
-- NSU sem título (Dashboard 🔴)
SELECT * FROM vw_nsu_sem_titulo 
WHERE filial_cnpj = $1 
ORDER BY data_venda DESC;

-- Títulos sem NSU (Dashboard 🟡)
SELECT * FROM vw_titulo_sem_nsu 
WHERE filial_cnpj = $1 
ORDER BY data_vencimento ASC;
```

### Query: Sugestões para Supervisor
```sql
SELECT * FROM vw_sugestoes_supervisor 
WHERE status = 'sugerido'
ORDER BY score_confianca DESC
LIMIT 20;
```

### Mutation: Confirmar Vínculo
```sql
UPDATE conciliacao_vinculos
SET status = 'confirmado',
    usuario_validacao = auth.uid()::text,
    data_validacao = NOW()
WHERE vinculo_id = $1
RETURNING *;
```

### Mutation: Rejeitar Vínculo
```sql
UPDATE conciliacao_vinculos
SET status = 'rejeitado',
    motivo_rejeicao = $2,
    usuario_validacao = auth.uid()::text,
    data_validacao = NOW()
WHERE vinculo_id = $1
RETURNING *;
```

---

## Links Úteis

- [Supabase RLS docs](https://supabase.com/docs/guides/auth/row-level-security)
- [PostgreSQL Full Text Search](https://www.postgresql.org/docs/current/textsearch.html)
- [ENUM Type](https://www.postgresql.org/docs/current/datatype-enum.html)
