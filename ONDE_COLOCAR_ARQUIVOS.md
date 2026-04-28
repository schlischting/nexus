# Nexus — Onde Colocar Cada Arquivo

## Estrutura Definitiva do Projeto

```
📦 NEXUS/
│
├── 📄 README.md
├── 📄 .gitignore
├── 📄 PROJECT_STRUCTURE.txt
│
├── 📁 docs/                          ← DOCUMENTAÇÃO (colocar aqui)
│   ├── FLUXO_NEGOCIO.md             ← ✅ NOVO — regras de negócio definitivas
│   ├── REQUISITOS_SCHEMA.md         ← ✅ NOVO — spec do schema v3.0
│   ├── INTEGRACAO_TOTVS.md          ← ✅ NOVO — spec Progress ABL
│   ├── QUALIDADE_DADOS_GETNET.md    ← ✅ já existe
│   ├── PORTAL_OPERADOR_INTEGRACAO.md← ✅ já existe
│   └── 2026-04-24-arquitetura-nexus.md ← manter como histórico
│
├── 📁 database/
│   ├── schema_nexus.sql             ← REESCREVER para v3.0
│   ├── CHECKLIST_SUPABASE.md        ← ✅ NOVO — guia de setup
│   ├── AJUSTES_SCHEMA_NECESSARIOS.md← manter como histórico
│   └── 📁 migrations/
│       └── (vazio por enquanto — banco ainda não existe)
│
├── 📁 backend/
│   ├── import_getnet.py             ← ✅ v2.1 — NÃO MEXER
│   ├── totvs_client.py             ← atualizar com spec INTEGRACAO_TOTVS.md
│   ├── totvs_import.py             ← ✅ NOVO — importar JSON títulos do TOTVS
│   ├── nexus_match_engine.py       ← ✅ NOVO — algoritmo de scoring
│   ├── requirements.txt
│   └── .env.example
│
├── 📁 skills/                       ← ✅ NOVO — skills especializadas
│   ├── nexus-postgresql/
│   │   └── SKILL.md
│   ├── nexus-python-backend/
│   │   └── SKILL.md
│   ├── nexus-flutterflow/
│   │   └── SKILL.md
│   └── nexus-ux/
│       └── SKILL.md
│
├── 📁 data/
│   ├── 📁 input/                    ← Excel GETNET entra aqui
│   ├── 📁 output/                   ← JSONs processados saem aqui
│   └── 📁 totvs/
│       ├── 📁 export/               ← JSONs exportados do TOTVS (títulos)
│       └── 📁 baixa/                ← JSONs de baixa Nexus→TOTVS
│
└── 📁 mobile-app/
    └── README.md                    ← manter para fase futura
```

---

## Arquivos a Criar Agora

| Arquivo | Destino | Prioridade |
|---------|---------|------------|
| FLUXO_NEGOCIO.md | docs/ | 🔴 Crítico |
| REQUISITOS_SCHEMA.md | docs/ | 🔴 Crítico |
| INTEGRACAO_TOTVS.md | docs/ | 🔴 Crítico |
| schema_nexus.sql v3.0 | database/ | 🔴 Crítico |
| CHECKLIST_SUPABASE.md | database/ | 🔴 Crítico |
| nexus-postgresql/SKILL.md | skills/ | 🟡 Importante |
| nexus-python-backend/SKILL.md | skills/ | 🟡 Importante |
| nexus-flutterflow/SKILL.md | skills/ | 🟡 Importante |
| nexus-ux/SKILL.md | skills/ | 🟡 Importante |
| totvs_import.py | backend/ | 🟡 Importante |
| nexus_match_engine.py | backend/ | 🟡 Importante |

---

## Arquivos que NÃO devem ser mexidos

| Arquivo | Motivo |
|---------|--------|
| backend/import_getnet.py | v2.1 funcionando e testado |
| docs/QUALIDADE_DADOS_GETNET.md | documentação válida |
| .gitignore | correto |
