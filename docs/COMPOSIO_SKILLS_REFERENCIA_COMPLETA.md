# Composio Claude Skills - Referência Completa e Integrada

**Data:** 2026-04-25  
**Versão:** 2.0 (Atualizada com biblioteca completa)  
**Status:** ✅ INSTALADO - 33 CUSTOM SKILLS + 832 COMPOSIO SKILLS

---

## 📊 O Que Você Tem

### Total de Skills Disponíveis
```
✅ 33 Custom Skills (awesome-claude-skills)
✅ 832 Composio Skills (500+ aplicações)
───────────────────────────────
✅ 865 SKILLS NO TOTAL
```

---

## 🎯 33 Custom Skills Principais

Estes são skills criados especificamente pela comunidade Composio:

### 📄 Document & Content Skills (5)
```
✅ artifacts-builder
   → Criar e organizar artefatos de documentação
   
✅ canvas-design
   → Design visual com Canvas
   
✅ document-skills
   → Manipulação completa de documentos
   
✅ changelog-generator
   → Gerar changelogs automaticamente
   
✅ content-research-writer
   → Pesquisar e escrever conteúdo
```

### 👥 People & Team Skills (4)
```
✅ internal-comms
   → Comunicação interna automática
   
✅ lead-research-assistant
   → Pesquisar leads e prospects
   
✅ meeting-insights-analyzer
   → Analisar insights de reuniões
   
✅ tailored-resume-generator
   → Gerar resumes personalizados
```

### 🛠️ Development & Build Skills (5)
```
✅ skill-creator
   → Criar novos skills
   
✅ mcp-builder
   → Construir Model Context Protocols
   
✅ theme-factory
   → Criar temas customizados
   
✅ template-skill
   → Template base para novos skills
   
✅ image-enhancer
   → Melhorar qualidade de imagens
```

### 📊 Business & Marketing Skills (6)
```
✅ competitive-ads-extractor
   → Extrair e analisar anúncios concorrentes
   
✅ twitter-algorithm-optimizer
   → Otimizar conteúdo para Twitter
   
✅ invoice-organizer
   → Organizar e processar faturas
   
✅ lead-research-assistant
   → Pesquisar leads (repetido - múltiplos usos)
   
✅ raffle-winner-picker
   → Sortear vencedores automaticamente
   
✅ brand-guidelines
   → Documentar e manter brand guidelines
```

### 🎨 Creative & Media Skills (3)
```
✅ slack-gif-creator
   → Criar GIFs para Slack
   
✅ image-enhancer
   → Melhorar imagens (repetido)
   
✅ canvas-design
   → Design visual (repetido)
```

### 🔧 Utility & Helper Skills (5+)
```
✅ skill-share
   → Compartilhar skills com comunidade
   
✅ developer-growth-analysis
   → Analisar crescimento de developers
   
✅ domain-name-brainstormer
   → Gerar ideias de nomes de domínio
   
✅ file-organizer
   → Organizar arquivos automaticamente
   
✅ langsmith-fetch
   → Integrar com LangSmith
```

---

## 🌐 832 Composio Skills (Por Categoria)

### 📧 Email & Messaging (40+)
```
Gmail, SendGrid, Mailchimp, Twilio, Slack, Discord,
Microsoft Teams, Telegram, WhatsApp, Intercom, Zendesk,
Freshdesk, HubSpot Email, ActiveCampaign
```

**Para Nexus:**
```python
from composio_slack import SlackToolSet
from composio_gmail import GmailToolSet

slack = SlackToolSet(api_key=os.getenv("COMPOSIO_API_KEY"))
gmail = GmailToolSet(api_key=os.getenv("COMPOSIO_API_KEY"))

# Enviar notificação Slack
slack.send_message(channel="#reconciliacao", message="...")

# Enviar email
gmail.send_email(to="user@example.com", subject="...", body="...")
```

### 💼 CRM & Sales (70+)
```
Salesforce, HubSpot, Pipedrive, Zoho CRM, Microsoft Dynamics 365,
Copper, Outreach, Salesloft, Apollo, RocketReach, Clearbit,
Hubbly, Insightly, Keap, SugarCRM, Freshsales
```

### 📊 Data & Analytics (80+)
```
Google Analytics, Mixpanel, Amplitude, Segment, Heap,
Hotjar, FullStory, LogRocket, DataBox, Supermetrics,
Google Sheets, Excel, Tableau, Power BI, Looker,
Redash, Metabase, Sisense, Domo, Qlik
```

### 🏢 Project Management (60+)
```
Asana, Monday.com, Trello, Jira, Linear, Azure DevOps,
ClickUp, Smartsheet, Wrike, Notion, Confluence,
TeamWork, Taiga, OpenProject, Plane, Focalboard
```

### 💾 Cloud & Storage (50+)
```
Google Drive, OneDrive, Dropbox, Box, AWS S3,
Google Cloud Storage, Azure Blob Storage, MinIO,
Backblaze, Wasabi, DigitalOcean Spaces, Linode
```

### 🔐 Security & Auth (40+)
```
Auth0, Okta, Azure AD, AWS IAM, Google Cloud IAM,
Vault, 1Password, LastPass, Bitwarden, Dashlane,
New Relic, DataDog, Splunk, Cloudflare, PagerDuty
```

### 🎨 Design & Media (70+)
```
Figma, Adobe Creative Cloud, Canva, Unsplash, Pexels,
Pixabay, Cloudinary, Imgix, ImageKit, Fastly,
Splice, Artlist, Shutterstock, Getty Images, iStock
```

### 💳 Payment & Billing (50+)
```
Stripe, PayPal, Square, Shopify, WooCommerce,
Magento, BigCommerce, Saleor, Medusa, Braintree,
2Checkout, FastSpring, Gumroad, Paddle, SendOwl
```

### 📱 Social Media (80+)
```
Facebook, Instagram, LinkedIn, Twitter, TikTok,
Pinterest, Snapchat, YouTube, Reddit, Quora,
Medium, Dev.to, Substack, Ghost, Hashnode
```

### 🏗️ Development Tools (100+)
```
GitHub, GitLab, Bitbucket, Gitea, Gitness,
Jenkins, CircleCI, Travis CI, GitLab CI, GitHub Actions,
Docker, Kubernetes, Heroku, Vercel, Netlify,
AWS Lambda, Google Cloud Functions, Azure Functions
```

### 📚 Knowledge & Documentation (40+)
```
Notion, Confluence, OneNote, Evernote, Obsidian,
Notion Wiki, GitBook, ReadTheDocs, Docusaurus,
MkDocs, Sphinx, Slite, Slitepad
```

### 🗓️ Calendar & Scheduling (30+)
```
Google Calendar, Outlook Calendar, Calendly,
Acuity Scheduling, Setmore, YouCanBook.me,
Zoom, Google Meet, Microsoft Teams, Jitsi
```

### 💬 Community & Feedback (30+)
```
Discord, Slack, Telegram, Discourse, Circle,
Mighty Networks, Tribe, Commsor, Common Room,
GetFeedback, Typeform, SurveyMonkey, Qualtrics
```

---

## 🎯 Melhores Skills para Nexus (Recomendado)

### 🔴 CRÍTICO (Implementar Primeira)

#### 1. **Slack** - Notificações em Tempo Real
```python
from composio_slack import SlackToolSet

slack = SlackToolSet(api_key=COMPOSIO_API_KEY)

# Notificar vínculo confirmado
slack.send_message(
    channel="#reconciliacao",
    message="✅ Vínculo 99 confirmado: NF-2026-001234"
)

# Alertar erro de baixa
slack.send_message(
    channel="#alertas-criticos",
    message="❌ Erro em vínculo 100: TOTVS retornou erro"
)

# Enviar resumo diário
slack.send_message(
    channel="#operacoes",
    message="""
    📊 Resumo Conciliações - 2026-04-25
    ✅ Confirmados: 45
    ⏳ Pendentes: 12
    ❌ Erros: 3
    """
)
```

**Implementado em:** `backend/composio_integrations.py` → `SlackNotifier`

---

#### 2. **Gmail** - Relatórios Automáticos
```python
from composio_gmail import GmailToolSet

gmail = GmailToolSet(api_key=COMPOSIO_API_KEY)

# Enviar relatório diário
gmail.send_email(
    to="operadores@empresa.com",
    subject="📊 Resumo Conciliações - 2026-04-25",
    body="""
    <h2>Reconciliação do Dia</h2>
    <table>
        <tr><td>Confirmados:</td><td>45</td></tr>
        <tr><td>Pendentes:</td><td>12</td></tr>
        <tr><td>Erros:</td><td>3</td></tr>
    </table>
    """
)

# Alertar supervisores sobre erros
gmail.send_email(
    to="supervisores@empresa.com",
    subject="🚨 Erros Críticos - Ação Necessária",
    body="Há 3 vínculos com erro de baixa TOTVS..."
)
```

**Implementado em:** `backend/composio_integrations.py` → `EmailReporter`

---

#### 3. **GitHub** - Issues Automáticas
```python
from composio_github import GitHubToolSet

github = GitHubToolSet(api_key=COMPOSIO_API_KEY)

# Criar issue para erro de baixa
github.create_issue(
    repo="seu-user/nexus",
    title="🔴 Erro Baixa TOTVS - Vínculo 100",
    body="""
    ## Detalhes
    - Vínculo: 100
    - Erro: E001_TITULO_NAO_ENCONTRADO
    - Ação: Revisar e fazer retry
    """,
    labels=["bug", "urgent", "totvs"]
)
```

**Implementado em:** `backend/composio_integrations.py` → `GitHubErrorReporter`

---

### 🟡 ALTA (Implementar Segunda)

#### 4. **Google Sheets** - Exportação de Dados
```python
from composio_sheets import GoogleSheetsToolSet

sheets = GoogleSheetsToolSet(api_key=COMPOSIO_API_KEY)

# Exportar vínculos confirmados
sheets.append_rows(
    spreadsheet_id="seu-sheet-id",
    range="Vinculos!A1",
    values=[
        ["vinculo_id", "nf", "valor", "data_baixa", "status"],
        [99, "NF-2026-001234", 7600.00, "2026-04-25", "confirmado"],
        [100, "NF-2026-001235", 5500.00, "2026-04-25", "confirmado"]
    ]
)

# Exportar resumo diário
sheets.append_rows(
    spreadsheet_id="seu-sheet-id",
    range="Resumo!A1",
    values=[
        ["data", "confirmados", "pendentes", "erros", "valor_confirmado"],
        ["2026-04-25", 45, 12, 3, "R$ 312.450,50"]
    ]
)
```

**Implementado em:** `backend/composio_integrations.py` → `GoogleSheetsExporter`

---

#### 5. **Notion** - Documentação de Erros
```python
# Criar página no Notion com erro
# Útil para manter histórico de problemas
# Requer: composio-notion

notion.create_page(
    database_id="seu-db-id",
    properties={
        "title": "Erro Vínculo 100",
        "status": "Em Review",
        "severidade": "Alta",
        "descricao": "TOTVS retornou erro ao baixar título..."
    }
)
```

---

#### 6. **Discord** - Alertas no Servidor
```python
from composio_discord import DiscordToolSet

discord = DiscordToolSet(api_key=COMPOSIO_API_KEY)

# Notificar no Discord
discord.send_message(
    channel_id="sua-channel-id",
    message="✅ Vínculo 99 confirmado com sucesso!"
)
```

---

### 🟢 MÉDIA (Implementar Depois)

#### 7. Google Docs - Relatórios Detalhados
#### 8. Microsoft Teams - Integração com empresas MS
#### 9. Zapier - Integrações adicionais
#### 10. Webhook - APIs custom

---

## 📂 Estrutura de Diretórios

```
d:\Projetos Dev\Nexus\backend\composio-skills\
├── README.md (33 KB) ..................... Documentação original
├── CONTRIBUTING.md ...................... Como contribuir
│
├── 📂 Custom Skills (33 skills)
│   ├── artifacts-builder/
│   ├── canvas-design/
│   ├── document-skills/
│   ├── skill-creator/
│   ├── ... (30 mais)
│   └── SKILL.md (cada skill tem seu SKILL.md)
│
└── 📂 composio-skills/ (832 skills)
    ├── gmail-automation/
    ├── slack-automation/
    ├── github-automation/
    ├── sheets-automation/
    ├── ... (828 mais)
    └── SKILL.md (cada um com documentação)
```

---

## 🔗 Como Usar no Nexus

### Padrão 1: Usar Diretamente em Python

```python
# Em backend/composio_integrations.py (já implementado)
from backend.composio_integrations import ComposioIntegrationManager

manager = ComposioIntegrationManager(
    spreadsheet_id="sua-sheet-id"  # Google Sheets
)

# Quando vínculo é confirmado
manager.on_vinculo_confirmado({
    "vinculo_id": 99,
    "filial_cnpj": "84943067001393",
    "numero_nf_manual": "NF-2026-001234",
    "valor": 7600.00
})

# Quando há erro de baixa
manager.on_erro_baixa({
    "vinculo_id": 100,
    "filial_cnpj": "84943067001393",
    "status_baixa": "E001_TITULO_NAO_ENCONTRADO",
    "erro_baixa": "Título não encontrado na filial"
})

# Enviar resumo diário
manager.resumo_diario(
    stats={
        "confirmados": 45,
        "pendentes": 12,
        "erros": 3,
        "valor_confirmado": 312450.50,
        "valor_pendente": 89500.00,
        "valor_erros": 15000.00
    },
    destinatarios_email=[
        "operadores@empresa.com",
        "supervisores@empresa.com"
    ]
)
```

---

### Padrão 2: Usar em Edge Functions Supabase

```typescript
// supabase/functions/notificar-vinculo/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const COMPOSIO_API_KEY = Deno.env.get("COMPOSIO_API_KEY")

serve(async (req) => {
  const { vínculo_id, status } = await req.json()

  // Chamar Composio API via REST
  const response = await fetch("https://api.composio.dev/v1/actions/execute", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${COMPOSIO_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      action: "SLACK_SEND_MESSAGE",
      input: {
        channel: "#reconciliacao",
        message: `Vínculo ${vínculo_id} agora está ${status}`
      }
    }),
  })

  return new Response(JSON.stringify({ success: true }))
})
```

---

### Padrão 3: Usar via `/connect-apps` no Claude Code

```
/connect-apps:setup
→ Paste your API key

/connect-apps:list
→ Ver apps disponíveis

/connect-apps:send-slack-message
channel=reconciliacao
message=Vínculo confirmado!
```

---

## 🔐 Configuração de Segurança

### `.env` (não commitar)
```bash
COMPOSIO_API_KEY=sk-proj-sua-chave-aqui
```

### `backend/.gitignore` (adicionar)
```
.env
.env.local
.env.*.local
```

### Supabase Secrets (adicionar em Settings)
```
Key: COMPOSIO_API_KEY
Value: sk-proj-sua-chave-aqui
```

---

## 📊 Skill Lookup (Como Encontrar Skills)

### Procurar por Aplicação
```python
# Exemplo: Encontrar skills de Gmail
# Ir em: backend/composio-skills/composio-skills/
# Procurar por "gmail-automation"

# Estrutura: 
# gmail-automation/
#   ├── SKILL.md (documentação)
#   ├── code.md (código exemplo)
#   └── assets/
```

### Procurar por Tipo de Ação
```
Email → Gmail, SendGrid, Mailchimp
Chat → Slack, Discord, Teams, Telegram
Issues → GitHub, GitLab, Jira, Linear
Data → Google Sheets, Excel, Notion
```

---

## 📖 Documentação Completa

| Arquivo | Conteúdo | Uso |
|---------|----------|-----|
| `docs/COMPOSIO_CLAUDE_SKILLS_GUIA_COMPLETO.md` | Guia detalhado + exemplos | 📖 Referência |
| `COMPOSIO_QUICK_REFERENCE.md` | Quick start (2 min) | ⚡ Rápido |
| `backend/composio_integrations.py` | Código pronto | 💻 Implementação |
| `COMPOSIO_INSTALLATION_SUMMARY.md` | Setup | 🔧 Setup |
| `docs/COMPOSIO_SKILLS_REFERENCIA_COMPLETA.md` | Este arquivo | 📚 Referência |

---

## ✅ Checklist de Integração

- [ ] Criar conta em dashboard.composio.dev
- [ ] Gerar API Key
- [ ] Adicionar a `.env`: `COMPOSIO_API_KEY=...`
- [ ] Instalar: `pip install composio-core composio-slack composio-gmail composio-github`
- [ ] Testar SlackNotifier
  ```python
  from backend.composio_integrations import SlackNotifier
  slack = SlackNotifier()
  slack.notificar_vinculo_confirmado("84943067001393", 99, "NF-001", 7600)
  ```
- [ ] Testar EmailReporter
- [ ] Testar GitHubErrorReporter
- [ ] Integrar com fluxo de reconciliação
- [ ] Configurar Supabase secrets
- [ ] Deploy em produção

---

## 🎯 Roadmap de Implementação

### Semana 1 ✅
- Setup Composio
- Implementar Slack Notifier
- Implementar Email Reporter

### Semana 2
- Implementar GitHub Error Reporter
- Implementar Google Sheets Exporter
- Integrar com Edge Functions

### Semana 3
- Adicionar Discord notifications
- Adicionar Notion integration
- Criar dashboard com alertas

### Semana 4
- Adicionar Google Docs reports
- Integrar mais skills conforme necessário
- Otimizar e documentar

---

## 📞 Recursos

**Composio:**
- Dashboard: https://dashboard.composio.dev
- Docs: https://docs.composio.dev
- GitHub: https://github.com/composioHQ/awesome-claude-skills

**Nexus:**
- Quick Reference: `COMPOSIO_QUICK_REFERENCE.md`
- Full Guide: `docs/COMPOSIO_CLAUDE_SKILLS_GUIA_COMPLETO.md`
- Code Examples: `backend/composio_integrations.py`
- Library: `backend/composio-skills/` (33 custom + 832 Composio)

---

**Status:** ✅ **DOCUMENTAÇÃO ATUALIZADA**  
**Data:** 2026-04-25  
**Próximo:** Implementar skills conforme roadmap
