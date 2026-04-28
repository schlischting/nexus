# Ajustes Necessários no Schema PostgreSQL

**Data:** 2026-04-24  
**Baseado em:** Análise real do arquivo ADTO_23042026.xlsx  
**Status:** ⏳ PENDENTE IMPLEMENTAÇÃO

---

## 🔴 Problemas Encontrados

### Problema 1: Isolamento por Filial (RLS)

**Situação Atual:**
```sql
-- schema_nexus.sql linha 20
CREATE TABLE filiais (
  filial_id SERIAL PRIMARY KEY,
  codigo_filial VARCHAR(20) NOT NULL UNIQUE,
  ...
);

-- schema_nexus.sql linha 79
CREATE POLICY rls_filiais_own
  ON filiais FOR ALL
  USING (filial_id IN (
    SELECT filial_id FROM user_filiais WHERE user_id = auth.uid()
  ));
```

**Problema:**
- RLS usa `filial_id` (gerado automaticamente, não confiável)
- Arquivo traz `filial_cnpj` (14 dígitos, imutável)
- Não há referência direta entre RLS e dados do arquivo
- Mais fácil de comprometer se IDs for explorado

**Solução:**
- Usar `filial_cnpj` como coluna ÚNICA e CHAVE de isolamento
- Remover dependência de `filial_id` gerado internamente
- RLS fica mais seguro (baseado em identificador fiscal)

---

### Problema 2: Tipo de Dado para CNPJ

**Situação Atual:**
```sql
-- schema_nexus.sql linha 32
filial_cnpj VARCHAR(14) NOT NULL,
```

**Problema:**
- Não há validação de formato (poderia ter 15, 20, ou 100 caracteres)
- Sem CHECK constraint para garantir 14 dígitos

**Solução:**
```sql
filial_cnpj CHAR(14) NOT NULL CHECK (filial_cnpj ~ '^\d{14}$'),
```

---

### Problema 3: Hash Não Reflete Estrutura Real

**Situação Atual:**
```sql
-- schema_nexus.sql linha 42
hash_transacao VARCHAR(64) UNIQUE,
```

**Problema:**
- Hash agora inclui CNPJ (CNPJ|NSU|Auth|Valor|Data)
- Mas schema não documenta que é CNPJ-scoped
- Pode confundir futuras manutenções

**Solução:**
```sql
-- Adicionar comentário
COMMENT ON COLUMN transacoes_getnet.hash_transacao IS
  'SHA256(filial_cnpj|nsu|numero_autorizacao|valor|data_transacao)
   Garante unicidade por filial (CNPJ-scoped deduplication)';
```

---

### Problema 4: Relação entre filial_id e filial_cnpj

**Situação Atual:**
```sql
-- schema_nexus.sql linha 31
filial_id INTEGER REFERENCES filiais(filial_id),
filial_cnpj VARCHAR(14) NOT NULL,
```

**Problema:**
- `filial_id` é NULL-able (pode não estar mapeado)
- `filial_cnpj` é NOT NULL (sempre vem do arquivo)
- Redunda: ambos representam a mesma filial
- Quebra normalização (2 identificadores para 1 entidade)

**Solução:**
- Usar APENAS `filial_cnpj` em transacoes_getnet
- Ter `filial_cnpj CHAR(14) PRIMARY KEY` em filiais (em vez de filial_id)
- Ou manter ambos mas com restrição UNIQUE(filial_id, filial_cnpj)

---

## ✅ Recomendações Prioritárias

### Prioridade 1: CRÍTICA (Segurança de RLS)

**Ajuste:** Refazer RLS para usar `filial_cnpj`

```sql
-- Antes
CREATE POLICY rls_filiais_own ON filiais FOR ALL
  USING (filial_id IN (
    SELECT filial_id FROM user_filiais WHERE user_id = auth.uid()
  ));

-- Depois
CREATE POLICY rls_filiais_own ON filiais FOR ALL
  USING (filial_cnpj IN (
    SELECT filial_cnpj FROM user_filiais_cnpj WHERE user_id = auth.uid()
  ));
```

**Impacto:** Torna RLS mais seguro e direto

---

### Prioridade 2: ALTA (Integridade de Dados)

**Ajuste:** Adicionar CHECK constraint para CNPJ

```sql
-- Atual
codigo_filial VARCHAR(20) NOT NULL UNIQUE,

-- Novo
filial_cnpj CHAR(14) NOT NULL UNIQUE 
  CHECK (filial_cnpj ~ '^\d{14}$'),  -- Apenas dígitos, exatamente 14
```

**Impacto:** Garante que sempre temos CNPJ válido (14 dígitos)

---

### Prioridade 3: MÉDIA (Clareza)

**Ajuste:** Renomear/comentar hash e seu escopo

```sql
-- Adicionar documentação
ALTER TABLE transacoes_getnet
  ALTER COLUMN hash_transacao
    SET DEFAULT NULL;

COMMENT ON COLUMN transacoes_getnet.hash_transacao IS
  'SHA256(filial_cnpj || "|" || nsu || "|" || numero_autorizacao || "|" || valor || "|" || data_transacao).
   Escopo: por filial (CNPJ). Rejeita duplicatas genuínas da mesma transação.
   Exemplo: NSU 000001493 aparecendo 6x no arquivo = apenas 1ª aceita, resto rejeitado.';
```

**Impacto:** Documenta padrão de deduplicação para futuras manutenções

---

### Prioridade 4: BAIXA (Refatoração Futura)

**Ajuste:** Opcionalmente refazer estrutura de filiais

```sql
-- Opção A: Filial_id como PK (atual, com ajustes)
CREATE TABLE filiais (
  filial_id SERIAL PRIMARY KEY,
  filial_cnpj CHAR(14) UNIQUE NOT NULL,
  codigo_ec VARCHAR(20),
  nome_filial VARCHAR(255) NOT NULL,
  uf CHAR(2),
  ativo BOOLEAN DEFAULT true,
  data_criacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  data_atualizacao TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Opção B: filial_cnpj como PK (mais direto, recomendado)
CREATE TABLE filiais (
  filial_cnpj CHAR(14) PRIMARY KEY CHECK (filial_cnpj ~ '^\d{14}$'),
  codigo_ec VARCHAR(20),
  nome_filial VARCHAR(255) NOT NULL,
  uf CHAR(2),
  ativo BOOLEAN DEFAULT true,
  data_criacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  data_atualizacao TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Impacto:** Opção B elimina redundância, mas requer migração de dados

---

## 📋 Plano de Migração Recomendado

### Fase 1: Ajustes Imediatos (sem quebra)

1. ✅ Adicionar CHECK constraint em `codigo_filial` (CHAR(14), 14 dígitos)
2. ✅ Adicionar comentário em `hash_transacao` explicando escopo CNPJ
3. ✅ Atualizar política RLS para usar `filial_cnpj` quando possível

**Script:**
```sql
-- Constraint
ALTER TABLE filiais
  ALTER COLUMN codigo_filial TYPE CHAR(14),
  ADD CONSTRAINT check_cnpj_14_digitos CHECK (codigo_filial ~ '^\d{14}$');

-- Comentário
COMMENT ON COLUMN transacoes_getnet.hash_transacao IS
  'SHA256(filial_cnpj|nsu|numero_autorizacao|valor|data_transacao).
   Deduplicação por filial (CNPJ-scoped).';
```

---

### Fase 2: Refatoração de RLS (com transição)

1. Criar tabela auxiliar `user_filiais_cnpj`
2. Popular baseado em `user_filiais` + `filiais`
3. Atualizar políticas gradualmente
4. Remover antiga após validação

---

### Fase 3: Refatoração de PK (OPCIONAL - futuro)

Se decidir mudar `filial_id` → `filial_cnpj` como PK:
1. Criar nova tabela `filiais_v2`
2. Copiar dados com migração
3. Atualizar FKs em cascata
4. Remover antiga

---

## 🎯 Recomendação Final

### Status Atual: ✅ FUNCIONAL COM RESSALVAS

O schema atual **funciona**, mas tem:
- RLS baseado em ID gerado (menos seguro)
- Sem validação de formato CNPJ (pode aceitar dados ruins)
- Redundância entre filial_id e filial_cnpj (confuso para manutenção)

### Recomendação: IMPLEMENTAR PRIORIDADE 1 E 2

Fazer imediatamente:
1. ✅ Adicionar CHECK constraint para CNPJ (14 dígitos)
2. ✅ Atualizar RLS para usar filial_cnpj (mais seguro)

Opcional (futuro):
3. ⏳ Refazer PK de filiais (filial_id → filial_cnpj)

---

## 📊 Checklist de Validação

Após ajustes, validar:

- [ ] CNPJ sempre 14 dígitos numéricos
- [ ] RLS baseado em filial_cnpj (não filial_id)
- [ ] Hash deduplication funciona por filial
- [ ] Migrations executadas sem erro
- [ ] Dados históricos (se houver) mantêm integridade
- [ ] Testes de inserção de 41 CNPJs diferentes passam
- [ ] Testes de deduplicação (mesmo hash) passam

---

**Próximo Passo:** Aguardando aprovação para implementar Prioridade 1 e 2.
