# Composio Claude Skills - Guia Completo

**Última Atualização:** 2026-04-25  
**Versão:** 1.0  
**Status:** ✅ Documentação Oficial Integrada

---

## 📌 O que são Claude Skills?

Claude Skills são workflows customizáveis que ensinam Claude como executar tarefas específicas de acordo com suas necessidades únicas. Eles capacitam Claude a executar tarefas de forma repetível e padronizada em todas as plataformas Claude.

**Diferencial:** Claude não apenas gera texto, mas também **executa ações reais**:
- ✅ Enviar emails
- ✅ Criar issues em GitHub
- ✅ Postar em Slack
- ✅ Atualizar CRM
- ✅ Integrar com 1000+ aplicações

---

## 🚀 Quick Start (5 minutos)

### Pré-requisitos
- Claude Code instalado
- Acesso a https://dashboard.composio.dev

### Step 1: Obter API Key do Composio

1. Ir em: https://dashboard.composio.dev/login
2. Criar conta (gratuita)
3. Copiar sua API Key
4. Guardar em local seguro

### Step 2: Instalar Plugin Connect Apps

```bash
# No seu projeto Nexus
cd "d:\Projetos Dev\Nexus"

# Instalar o plugin
claude --plugin-dir ./connect-apps-plugin
```

**Resultado esperado:**
```
✅ Plugin instalado em ~/.claude/plugins/
```

### Step 3: Configurar Conexão

Dentro de Claude Code:
```
/connect-apps:setup
```

Cole sua API Key quando pedido. Exemplo:
```
Paste your Composio API key: sk-proj-abc123def456...
```

### Step 4: Reiniciar e Testar

```bash
exit
claude
```

**Teste a integração:**
```
/connect-apps:list
```

Deve retornar lista de aplicações disponíveis (500+).

---

## 📊 Biblioteca de Skills Disponíveis

### Total de Skills: 832

A biblioteca Composio incluída tem skills para:

#### 🏢 **Aplicações Empresariais (150+)**
```
Gmail, Slack, Microsoft Teams, Discord, Telegram
Notion, Google Drive, OneDrive, Dropbox, Box
Jira, GitHub, GitLab, Linear, Asana
Salesforce, HubSpot, Pipedrive, Monday.com
```

#### 📊 **Data & Analytics (80+)**
```
Google Sheets, Excel, Tableau, Power BI
Google Analytics, Mixpanel, Amplitude
BigQuery, Redshift, Snowflake
```

#### 🎨 **Criatividade & Media (60+)**
```
Canva, Figma, Adobe Creative Cloud
Unsplash, Pexels, Pixabay (imagens)
OpenAI (DALL-E), Midjourney, Replicate
```

#### 🔧 **Desenvolvimento (100+)**
```
GitHub Actions, GitLab CI, Jenkins
Docker, Kubernetes, AWS, GCP, Azure
Vercel, Netlify, Heroku
NPM, PyPI, RubyGems (gerenciadores de pacotes)
```

#### 💼 **Negócios & Marketing (150+)**
```
Mailchimp, SendGrid, HubSpot
Stripe, PayPal, Square
Google Ads, Facebook Ads, LinkedIn Ads
Shopify, WooCommerce, Magento
```

#### 📞 **Comunicação (80+)**
```
Twilio (SMS/Voice), SendGrid (email)
Calendly, Zoom, Google Meet
Intercom, Zendesk, Freshdesk
```

#### 🏢 **CRM & Sales (70+)**
```
Salesforce, HubSpot, Pipedrive
Zoho CRM, Microsoft Dynamics 365
Copper, Outreach, Salesloft
```

#### 📈 **Produtividade (100+)**
```
Todoist, Microsoft To Do, Trello
Evernote, OneNote, Obsidian
Clockify, Toggl, Harvest
```

#### 🔐 **Segurança & DevOps (60+)**
```
HashiCorp Vault, 1Password, LastPass
New Relic, DataDog, Splunk
CloudFlare, Auth0, Okta
```

**[Ver lista completa →](https://composio.dev/toolkits)**

---

## 💻 Como Usar Skills no Projeto Nexus

### Exemplo 1: Notificar via Slack quando Vínculo é Confirmado

```python
# Em backend/totvs_client.py ou novo arquivo backend/notifications.py

from composio import Composio, Action
from composio_slack import SlackToolSet

# Inicializar
composio = Composio(api_key="sua-api-key")
slack = SlackToolSet(api_key="sua-api-key")

def notificar_vinculo_confirmado(filial_cnpj, nsu, titulo_nf):
    """
    Envia notificação ao canal Slack quando vínculo é confirmado
    """
    mensagem = f"""
    ✅ Vínculo Confirmado
    Filial: {filial_cnpj}
    NSU: {nsu}
    Título: {titulo_nf}
    Data: {datetime.now().strftime('%d/%m/%Y %H:%M:%S')}
    """
    
    # Usar skill do Slack
    slack.send_message(
        channel="#reconciliacao",
        message=mensagem
    )

# Chamar quando vínculo é confirmado
# notificar_vinculo_confirmado("84943067001393", "145186923", "NF-2026-001234")
```

### Exemplo 2: Criar Issue no GitHub quando Há Erro de Baixa TOTVS

```python
# Em backend/totvs_client.py

from composio import Composio
from composio_github import GitHubToolSet

def registrar_erro_baixa_totvs(filial_cnpj, vínculo_id, erro):
    """
    Cria issue no GitHub quando PASOE retorna erro
    """
    github = GitHubToolSet(api_key="sua-api-key-composio")
    
    titulo = f"Erro de Baixa TOTVS - Vínculo {vínculo_id}"
    descricao = f"""
    ## Detalhes do Erro
    - **Filial:** {filial_cnpj}
    - **Vínculo ID:** {vínculo_id}
    - **Erro PASOE:** {erro['status_baixa']}
    - **Mensagem:** {erro['erro_baixa']}
    - **Data/Hora:** {datetime.now().isoformat()}
    
    ## Ação Necessária
    - [ ] Validar título no TOTVS
    - [ ] Verificar permissões
    - [ ] Retry manualmente ou via supervisor
    """
    
    github.create_issue(
        repo="rodrigominusa/Nexus",
        title=titulo,
        body=descricao,
        labels=["bug", "totvs", "erro-baixa"]
    )
```

### Exemplo 3: Enviar Email Diário com Resumo de Reconciliações

```python
# Em backend/scheduler.py (novo arquivo)

from composio import Composio
from composio_gmail import GmailToolSet
from datetime import datetime, timedelta

def enviar_resumo_diario():
    """
    Envia email diário com resumo de conciliações para operadores
    """
    gmail = GmailToolSet(api_key="sua-api-key-composio")
    
    # Buscar dados do dia anterior
    data_inicio = (datetime.now() - timedelta(days=1)).date()
    data_fim = datetime.now().date()
    
    # Query Supabase para pegar estatísticas
    stats = supabase.table('conciliacao_vinculos').select('*').execute()
    
    # Preparar email
    corpo_email = f"""
    <h2>📊 Resumo de Conciliações - {data_fim.strftime('%d/%m/%Y')}</h2>
    
    <p><strong>Período:</strong> {data_inicio} a {data_fim}</p>
    
    <table border="1" cellpadding="10">
        <tr>
            <th>Status</th>
            <th>Quantidade</th>
            <th>Valor Total</th>
        </tr>
        <tr>
            <td>✅ Confirmados</td>
            <td>{stats['confirmados_count']}</td>
            <td>R$ {stats['confirmados_valor']:,.2f}</td>
        </tr>
        <tr>
            <td>⏳ Pendentes</td>
            <td>{stats['pendentes_count']}</td>
            <td>R$ {stats['pendentes_valor']:,.2f}</td>
        </tr>
        <tr>
            <td>❌ Erros Baixa</td>
            <td>{stats['erros_count']}</td>
            <td>R$ {stats['erros_valor']:,.2f}</td>
        </tr>
    </table>
    
    <p><strong>Ação Necessária:</strong> {stats['erros_count']} erros requerem revisão.</p>
    <p><a href="https://seu-portal.nexus.com/dashboard">Acessar Dashboard</a></p>
    """
    
    gmail.send_email(
        to="operadores@empresa.com",
        subject=f"📊 Resumo Conciliações - {data_fim.strftime('%d/%m/%Y')}",
        body=corpo_email,
        is_html=True
    )
```

### Exemplo 4: Sincronizar Dados com Google Sheets

```python
# Em backend/export_sheets.py (novo arquivo)

from composio_sheets import GoogleSheetsToolSet
from datetime import datetime

def exportar_vinculos_para_sheets(filial_cnpj):
    """
    Exporta vínculos confirmados para planilha compartilhada
    """
    sheets = GoogleSheetsToolSet(api_key="sua-api-key-composio")
    
    # Buscar dados do Supabase
    vinculos = supabase.table('conciliacao_vinculos') \
        .select('*') \
        .eq('filial_cnpj', filial_cnpj) \
        .eq('status', 'confirmado') \
        .execute()
    
    # Preparar dados para planilha
    rows = []
    for v in vinculos.data:
        rows.append([
            v['vinculo_id'],
            v['transacao_getnet_id'],
            v['numero_nf_manual'],
            v['valor'],
            v['data_criacao'],
            v['data_baixa_totvs'],
            v['status_baixa']
        ])
    
    # Atualizar Google Sheet
    sheets.append_rows(
        spreadsheet_id="seu-sheet-id",
        range="Vinculos!A2",
        values=rows
    )
    
    # Notificar via Slack
    slack.send_message(
        channel="#operacoes",
        message=f"✅ {len(rows)} vínculos exportados para planilha"
    )
```

---

## 🔧 Instalação Avançada

### Opção 1: Integração via Composio SDK (Python)

```bash
# Instalar SDK Composio
pip install composio-core
pip install composio-gmail
pip install composio-slack
pip install composio-github
```

**Código Python:**
```python
from composio import Composio
from composio_gmail import GmailToolSet
from composio_slack import SlackToolSet

# Inicializar
api_key = "sk-proj-sua-chave-aqui"
composio = Composio(api_key=api_key)

# Usar skills
gmail = GmailToolSet(api_key=api_key)
slack = SlackToolSet(api_key=api_key)

# Enviar email
gmail.send_email(to="user@example.com", subject="Test", body="Hello")

# Postar em Slack
slack.send_message(channel="#general", message="Olá mundo")
```

### Opção 2: Integração via REST API

```bash
# Usar curl ou requests para chamar API Composio
curl -X POST "https://api.composio.dev/v1/actions/execute" \
  -H "Authorization: Bearer seu-api-key" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "GMAIL_SEND_EMAIL",
    "input": {
      "to": "user@example.com",
      "subject": "Test",
      "body": "Hello"
    }
  }'
```

### Opção 3: Integração via Edge Functions Supabase

```typescript
// supabase/functions/enviar-notificacao/index.ts

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const COMPOSIO_API_KEY = Deno.env.get("COMPOSIO_API_KEY")

serve(async (req) => {
  const { filial_cnpj, vínculo_id, status } = await req.json()

  // Chamar Composio API
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

  return new Response(JSON.stringify({ success: true }), {
    headers: { "Content-Type": "application/json" },
  })
})
```

---

## 📋 Melhores Skills para Nexus Project

### Top 10 Skills Recomendados para Reconciliação

| # | Skill | Caso de Uso | Prioridade |
|---|-------|-----------|-----------|
| 1 | **Slack** | Notificações de erros, confirmações | 🔴 CRÍTICO |
| 2 | **Gmail** | Relatórios diários, alertas | 🔴 CRÍTICO |
| 3 | **GitHub** | Issues de erros, auditorias | 🟡 ALTA |
| 4 | **Google Sheets** | Exportar dados, análise | 🟡 ALTA |
| 5 | **Discord** | Chat em tempo real para equipe | 🟡 ALTA |
| 6 | **Notion** | Documentação de erros, KB | 🟢 MÉDIA |
| 7 | **Zapier** | Integrações adicionais | 🟢 MÉDIA |
| 8 | **Google Calendar** | Agendar reviews, lembretes | 🟢 MÉDIA |
| 9 | **Webhook** | Custom integrações | 🟡 ALTA |
| 10 | **REST API** | Qualquer aplicação | 🔴 CRÍTICO |

---

## 🔐 Segurança & Boas Práticas

### ✅ Como Armazenar API Keys

```python
# ❌ NÃO faça isso
API_KEY = "sk-proj-abc123def456"  # Hardcoded!

# ✅ Faça isso
import os
from dotenv import load_dotenv

load_dotenv()
API_KEY = os.getenv("COMPOSIO_API_KEY")
```

**Arquivo `.env` (GITIGNORE):**
```
COMPOSIO_API_KEY=sk-proj-abc123def456
GMAIL_REFRESH_TOKEN=...
SLACK_BOT_TOKEN=...
```

### ✅ RLS (Row Level Security) com Skills

Certifique-se que skills respeitam RLS do Supabase:

```python
def notificar_operador_seguro(user_id, vínculo_id):
    """
    Usa JWT token do usuário para garantir RLS
    """
    # 1. Validar que usuário tem acesso ao vínculo
    vinculo = supabase.auth.session()  # Get current user session
    
    # 2. Enviar notificação apenas se autorizado
    slack.send_message(
        channel=f"@user-{user_id}",
        message=f"Seu vínculo {vínculo_id} foi atualizado"
    )
```

### ✅ Limites de Rate

```python
from time import sleep
from datetime import datetime, timedelta

class ComposioRateLimiter:
    def __init__(self, requests_per_minute=60):
        self.rpm = requests_per_minute
        self.requests = []
    
    def wait_if_needed(self):
        now = datetime.now()
        # Remove requests older than 1 minute
        self.requests = [r for r in self.requests 
                        if r > now - timedelta(minutes=1)]
        
        if len(self.requests) >= self.rpm:
            sleep_time = 60 - (now - self.requests[0]).total_seconds()
            sleep(max(0, sleep_time))
        
        self.requests.append(now)

# Usar
limiter = ComposioRateLimiter(requests_per_minute=100)
limiter.wait_if_needed()
# Fazer request...
```

---

## 🎯 Integração com Fluxo Nexus

### Fluxo 1: Portal do Operador com Notificações

```
Operador digita NSU+NF
        ↓
Edge Function cria vínculo
        ↓
Skill SLACK: notifica #reconciliacao
        ↓
Sistema busca título TOTVS
        ↓
Sistema chama PASOE
        ↓
SE sucesso → Skill SLACK: ✅ confirmado
SE erro    → Skill GITHUB: criar issue + Skill SLACK: alertar
```

### Fluxo 2: Dashboard com Exportação

```
Dashboard carrega dados
        ↓
Supervisor clica "Exportar"
        ↓
Skill GOOGLE_SHEETS: append rows
        ↓
Skill SLACK: "@supervisor vínculo exportado"
        ↓
Supervisor acessa planilha compartilhada
```

### Fluxo 3: Relatório Automático Diário

```
Cron job (23:59 daily)
        ↓
Backend query Supabase (resumo do dia)
        ↓
Skill GMAIL: enviar para operadores@empresa.com
        ↓
Email com tabela de estatísticas
        ↓
Link para dashboard se há erros
```

---

## 📚 Documentação Adicional

### Links Úteis
- **Dashboard Composio:** https://dashboard.composio.dev
- **Documentação Oficial:** https://docs.composio.dev
- **Lista de Skills:** https://composio.dev/toolkits
- **GitHub:** https://github.com/composioHQ/awesome-claude-skills
- **Discord Community:** https://discord.com/invite/composio

### Recursos Nexus
- Schema v2.1 com integração: `database/schema_nexus_v2.1.sql`
- Backend ready: `backend/totvs_client.py`
- Supabase setup: `SUPABASE_DEPLOYMENT_ROTEIRO.md`

---

## ✅ Checklist de Implementação

Para integrar Composio Skills no Nexus:

- [ ] Criar conta em dashboard.composio.dev
- [ ] Gerar API Key
- [ ] Instalar plugin: `claude --plugin-dir ./connect-apps-plugin`
- [ ] Configurar: `/connect-apps:setup`
- [ ] Testar: `/connect-apps:list`
- [ ] Instalar SDK: `pip install composio-core composio-slack composio-gmail`
- [ ] Criar arquivo `.env` com API keys
- [ ] Implementar notificação Slack (Exemplo 1)
- [ ] Implementar GitHub issues (Exemplo 2)
- [ ] Implementar email diário (Exemplo 3)
- [ ] Implementar Google Sheets export (Exemplo 4)
- [ ] Testar fluxo completo end-to-end
- [ ] Documentar secrets em Supabase settings
- [ ] Deploy em produção

---

**Status:** ✅ **DOCUMENTAÇÃO COMPLETA**  
**Próximo Passo:** Implementar skills conforme prioridade  
**Data:** 2026-04-25
