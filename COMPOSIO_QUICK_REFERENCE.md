# Composio Claude Skills - Quick Reference

**⚡ Guia Rápido de 2 Minutos**

---

## 🚀 Setup (5 minutos)

```bash
# 1. Get API key from https://dashboard.composio.dev

# 2. Install plugin
claude --plugin-dir ./connect-apps-plugin

# 3. In Claude Code, run:
/connect-apps:setup
# Paste your API key

# 4. Restart and test:
/connect-apps:list
```

---

## 💻 Uso em Python

### Instalação
```bash
pip install composio-core composio-slack composio-gmail composio-github
```

### Enviar Email (Gmail)
```python
from composio_gmail import GmailToolSet

gmail = GmailToolSet(api_key="sua-api-key")
gmail.send_email(
    to="user@example.com",
    subject="Teste",
    body="Olá mundo"
)
```

### Postar em Slack
```python
from composio_slack import SlackToolSet

slack = SlackToolSet(api_key="sua-api-key")
slack.send_message(
    channel="#general",
    message="Olá, Slack!"
)
```

### Criar Issue no GitHub
```python
from composio_github import GitHubToolSet

github = GitHubToolSet(api_key="sua-api-key")
github.create_issue(
    repo="seu-user/seu-repo",
    title="Bug encontrado",
    body="Descrição do bug"
)
```

### Google Sheets
```python
from composio_sheets import GoogleSheetsToolSet

sheets = GoogleSheetsToolSet(api_key="sua-api-key")
sheets.append_rows(
    spreadsheet_id="seu-sheet-id",
    range="Sheet1!A1",
    values=[[1, 2, 3], [4, 5, 6]]
)
```

---

## 🎯 Top 10 Skills para Nexus

```
1. Slack        → Notificações em tempo real
2. Gmail        → Emails automáticos
3. GitHub       → Issues de erros
4. Google Sheets→ Exportar dados
5. Discord      → Chat equipe
6. Notion       → Documentação
7. Google Docs  → Relatórios
8. Zapier       → Integrações
9. Webhooks     → Custom APIs
10. REST API    → Qualquer app
```

---

## 🔒 Segurança

```python
# ✅ Correto: Use variáveis de ambiente
import os
API_KEY = os.getenv("COMPOSIO_API_KEY")

# ❌ Errado: Não hardcode
# API_KEY = "sk-proj-abc123"
```

**Arquivo `.env`:**
```
COMPOSIO_API_KEY=sk-proj-sua-chave-aqui
```

---

## 📋 Integração Nexus

### Notificar quando Vínculo é Confirmado
```python
from composio_slack import SlackToolSet

slack = SlackToolSet(api_key=os.getenv("COMPOSIO_API_KEY"))

def on_vinculo_confirmado(vínculo_id, nf):
    slack.send_message(
        channel="#reconciliacao",
        message=f"✅ Vínculo {vínculo_id} confirmado: {nf}"
    )
```

### Alertar sobre Erro de Baixa TOTVS
```python
from composio_github import GitHubToolSet

github = GitHubToolSet(api_key=os.getenv("COMPOSIO_API_KEY"))

def on_erro_baixa(vínculo_id, erro):
    github.create_issue(
        repo="seu-repo/nexus",
        title=f"Erro Baixa TOTVS - {vínculo_id}",
        body=f"Erro: {erro}"
    )
```

### Exportar Dados para Planilha
```python
from composio_sheets import GoogleSheetsToolSet

sheets = GoogleSheetsToolSet(api_key=os.getenv("COMPOSIO_API_KEY"))

def exportar_vinculos(vinculos):
    values = [[v['id'], v['nf'], v['status']] for v in vinculos]
    sheets.append_rows(
        spreadsheet_id="seu-sheet-id",
        range="Vinculos!A1",
        values=values
    )
```

---

## 📚 Recursos

- **Dashboard:** https://dashboard.composio.dev
- **Docs:** https://docs.composio.dev
- **GitHub:** https://github.com/composioHQ/awesome-claude-skills
- **Guia Completo:** `docs/COMPOSIO_CLAUDE_SKILLS_GUIA_COMPLETO.md`
- **Biblioteca Local:** `backend/composio-skills/` (832 skills)

---

**Status:** ✅ Pronto para usar  
**Data:** 2026-04-25
