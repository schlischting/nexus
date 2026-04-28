# Composio Skills - Integração Completa com Fluxo Nexus

**Data:** 2026-04-25  
**Objetivo:** Mapear exatamente como cada skill será usado no fluxo de reconciliação  
**Status:** ✅ DOCUMENTADO COM EXEMPLOS REAIS

---

## 🔄 Fluxo Nexus Completo com Composio Skills

```
┌──────────────────────────────────────────────────────────────┐
│ 1. GETNET Import (import_getnet.py)                          │
│    NSU + Valor → transacoes_getnet                           │
│    (sem skills necessários nesta etapa)                      │
└────────────────────┬─────────────────────────────────────────┘
                     ↓
┌──────────────────────────────────────────────────────────────┐
│ 2. Portal do Operador (FlutterFlow)                          │
│    Operador digita NSU + NF → Cria vínculo                   │
│    (sem skills necessários nesta etapa)                      │
└────────────────────┬─────────────────────────────────────────┘
                     ↓
┌──────────────────────────────────────────────────────────────┐
│ 3. Notificar Vínculo Criado                                  │
│    📲 SKILL: Slack                                           │
│    🔔 SKILL: Discord (opcional)                             │
│    Channel: #reconciliacao                                  │
└────────────────────┬─────────────────────────────────────────┘
                     ↓
┌──────────────────────────────────────────────────────────────┐
│ 4. Buscar Título TOTVS                                      │
│    System queries TOTVS (sem skills)                        │
│    Atualiza: titulo_totvs_id, tipo_titulo                  │
└────────────────────┬─────────────────────────────────────────┘
                     ↓
┌──────────────────────────────────────────────────────────────┐
│ 5. Chamar PASOE para Baixa                                  │
│    Sistema invoca PASOE (sem skills)                        │
│    Tenta baixar título no ERP                               │
└────────────────────┬──────────────┬────────────────────────────┘
                     │              │
          ✅ SUCESSO │              │ ❌ ERRO
                     ↓              ↓
    ┌────────────────────┐  ┌──────────────────────┐
    │ 6a. Baixa Sucesso  │  │ 6b. Erro de Baixa    │
    │                    │  │                      │
    │ status=confirmado  │  │ status=erro_baixa    │
    └──────┬─────────────┘  └──────┬───────────────┘
           ↓                       ↓
   ┌──────────────────┐  ┌────────────────────────┐
   │ Notificar Slack  │  │ 1. Notificar Slack    │
   │ ✅ Confirmado    │  │ 2. Criar Issue GitHub │
   │                  │  │ 3. Criar Notion Page  │
   │ Skill: Slack     │  │                       │
   └────────┬─────────┘  │ Skills: Slack,        │
            ↓            │ GitHub, Notion        │
     ┌────────────────┐  └────────┬──────────────┘
     │ Exportar Sheets│           ↓
     │ Skill: Sheets  │   ┌──────────────────────┐
     │                │   │ Enviar Email Alerta  │
     │ Adicionar à    │   │ Skills: Gmail        │
     │ planilha de    │   │                      │
     │ reconciliação  │   │ @supervisores review │
     └────────────────┘   │ ou retry             │
                          └──────────────────────┘
                                 ↓
                          (Aguardando ação)
                                 ↓
                          ┌──────────────────────┐
                          │ Supervisor faz retry │
                          │ PASOE retorna sucesso│
                          └──────────┬───────────┘
                                     ↓
                          Status: confirmado
                                     ↓
                          (Volta ao fluxo sucesso)
```

---

## 📍 Mapeamento Exato de Skills por Etapa

### 1️⃣ ETAPA: Vínculo Criado

**Quando:** Operador clica "Vincular" → Edge Function cria vínculo

**Dados Disponíveis:**
```
{
  "vinculo_id": 99,
  "filial_cnpj": "84943067001393",
  "transacao_getnet_id": 12345,
  "numero_nf_manual": "NF-2026-001234",
  "tipo_vinculacao": "manual",
  "status": "pendente"
}
```

**Skills Acionados:**

#### Skill #1: SLACK - Notificar #reconciliacao
```python
# backend/composio_integrations.py → SlackNotifier

slack.send_message(
    channel="#reconciliacao",
    message="""
    📝 Vínculo Criado (Manual)
    ID: 99
    NSU: 145186923 (da transacao_getnet_id 12345)
    NF Digitada: NF-2026-001234
    Filial: 84943067001393
    Status: Aguardando busca de título TOTVS
    """
)
```

#### Skill #2: DISCORD - Notificar no servidor
```python
# Opcional: notificar também no Discord da equipe
discord.send_message(
    channel_id="seu-channel-id",
    message="📝 Novo vínculo criado manualmente. Aguardando validação."
)
```

---

### 2️⃣ ETAPA: Título TOTVS Encontrado

**Quando:** Sistema encontra título correspondente no TOTVS

**Dados Disponíveis:**
```
{
  "vinculo_id": 99,
  "titulo_totvs_id": 1002,  # ← NOVO
  "numero_nf_manual": "NF-2026-001234",
  "tipo_titulo": "NF",
  "valor": 7600.00
}
```

**Skills Acionados:**

#### Skill #1: SLACK - Confirmar encontro do título
```python
slack.send_message(
    channel="#reconciliacao",
    message="""
    🔍 Título TOTVS Encontrado
    Vínculo ID: 99
    Título ID: 1002
    NF: NF-2026-001234
    Tipo: NF
    Valor: R$ 7.600,00
    Próximo: Baixa automática no PASOE
    """
)
```

---

### 3️⃣ ETAPA: Tentando Baixa no PASOE

**Quando:** Sistema chama PASOE para registrar pagamento

**Skills Acionados:** Nenhum (apenas log interno)

---

### 4️⃣ ETAPA: ✅ Baixa TOTVS COM SUCESSO

**Quando:** PASOE retorna sucesso (data_baixa_totvs preenchido)

**Dados Disponíveis:**
```
{
  "vinculo_id": 99,
  "status": "confirmado",  # ← ALTERADO
  "data_baixa_totvs": "2026-04-25T14:30:45Z",
  "status_baixa": "sucesso",
  "erro_baixa": null,
  "numero_nf_manual": "NF-2026-001234",
  "valor": 7600.00
}
```

**Skills Acionados:**

#### Skill #1: SLACK - Sucesso!
```python
slack.send_message(
    channel="#reconciliacao",
    message="""
    ✅ VÍNCULO CONFIRMADO COM SUCESSO
    ID: 99
    NF: NF-2026-001234
    Valor: R$ 7.600,00
    Data Baixa: 2026-04-25 14:30:45
    Status PASOE: sucesso
    
    Transação e Título agora estão reconciliados.
    """
)
```

#### Skill #2: GOOGLE SHEETS - Exportar linha
```python
sheets.append_rows(
    spreadsheet_id="seu-sheet-id",
    range="Vinculos_Confirmados!A1",
    values=[[
        99,                          # vinculo_id
        "NF-2026-001234",           # numero_nf_manual
        7600.00,                     # valor
        "2026-04-25",                # data_baixa_totvs
        "confirmado",                # status
        "manual"                      # tipo_vinculacao
    ]]
)
```

#### Skill #3: NOTION - Registrar no histórico (opcional)
```python
# Criar página em Notion com detalhes da conciliação
notion.create_page(
    database_id="reconciliacao-db",
    properties={
        "title": "Conciliação #99 - NF-2026-001234",
        "status": "Confirmado",
        "valor": 7600.00,
        "data_baixa": "2026-04-25",
        "tipo": "Manual"
    }
)
```

#### Skill #4: EMAIL - Notificar supervisores (opcional)
```python
# Enviar confirmação diária ao final do dia
gmail.send_email(
    to="supervisores@empresa.com",
    subject="✅ Vínculo #99 Confirmado",
    body="""
    <h3>Conciliação Bem-Sucedida</h3>
    <p>Vínculo 99 foi confirmado com sucesso</p>
    <table>
        <tr><td>NF:</td><td>NF-2026-001234</td></tr>
        <tr><td>Valor:</td><td>R$ 7.600,00</td></tr>
        <tr><td>Data:</td><td>2026-04-25</td></tr>
    </table>
    """
)
```

---

### 5️⃣ ETAPA: ❌ Erro de Baixa TOTVS

**Quando:** PASOE retorna erro (status_baixa com código erro)

**Dados Disponíveis:**
```
{
  "vinculo_id": 100,
  "status": "erro_baixa",  # ← ALTERADO
  "data_baixa_totvs": "2026-04-25T14:35:22Z",
  "status_baixa": "E001_TITULO_NAO_ENCONTRADO",
  "erro_baixa": "Título 001234 não encontrado na filial 84943067001393",
  "numero_nf_manual": "NF-2026-001235",
  "valor": 5500.00
}
```

**Skills Acionados:** (em paralelo)

#### Skill #1: SLACK - Alertar #alertas-criticos
```python
slack.send_message(
    channel="#alertas-criticos",
    message="""
    ❌ ERRO DE BAIXA TOTVS
    Vínculo ID: 100
    NF: NF-2026-001235
    Erro: E001_TITULO_NAO_ENCONTRADO
    Mensagem: Título 001234 não encontrado na filial 84943067001393
    
    ⚠️ Ação Necessária: Revisar e fazer retry
    """
)
```

#### Skill #2: GITHUB - Criar issue automática
```python
github.create_issue(
    repo="rodrigominusa/nexus",
    title="🔴 Erro Baixa TOTVS - Vínculo 100",
    body="""
    ## Detalhes do Erro
    - **Vínculo:** 100
    - **Filial:** 84943067001393
    - **NF:** NF-2026-001235
    - **Valor:** R$ 5.500,00
    - **Código Erro:** E001_TITULO_NAO_ENCONTRADO
    - **Mensagem:** Título 001234 não encontrado na filial 84943067001393
    - **Data:** 2026-04-25 14:35:22

    ## Ações Necessárias
    - [ ] Validar que título existe no TOTVS
    - [ ] Verificar número de NF está correto
    - [ ] Verificar permissões na filial
    - [ ] Fazer retry manualmente ou via API

    ## Padrão
    Se erro persistir, escalar para suporte TOTVS/PASOE
    """,
    labels=["bug", "totvs", "erro-baixa", "urgent"]
)
```

#### Skill #3: NOTION - Registrar erro para análise
```python
# Criar página em Notion com erro para que operadores resolvam
notion.create_page(
    database_id="erros-db",
    properties={
        "title": "Erro Vínculo 100 - E001",
        "status": "Em Review",
        "severidade": "Alta",
        "vínculo_id": 100,
        "tipo_erro": "E001_TITULO_NAO_ENCONTRADO"
    }
)
```

#### Skill #4: EMAIL - Alertar supervisores
```python
gmail.send_email(
    to="supervisores@empresa.com",
    subject="🚨 ERRO: Vínculo 100 - Ação Necessária",
    body="""
    <h3 style="color: red;">⚠️ Erro de Baixa TOTVS</h3>
    <p>Vínculo 100 falhou ao tentar baixar título no PASOE</p>
    <table border="1">
        <tr><td>NF:</td><td>NF-2026-001235</td></tr>
        <tr><td>Erro:</td><td>E001_TITULO_NAO_ENCONTRADO</td></tr>
        <tr><td>Mensagem:</td><td>Título não encontrado na filial</td></tr>
    </table>
    <p><strong>Ação:</strong> Revisar título no TOTVS e fazer retry</p>
    <a href="https://seu-portal.nexus.com/erros/100">Acessar Detalhes</a>
    """
)
```

#### Skill #5: DISCORD - Menção urgente
```python
discord.send_message(
    channel_id="alertas-channel",
    message="@supervisores ❌ Erro crítico em vínculo 100 - verificar imediatamente"
)
```

---

### 6️⃣ ETAPA: Resumo Diário (Nightly Job)

**Quando:** 23:59 todos os dias (Cron job)

**Dados Coletados:**
```python
# Query Supabase para resumo do dia
stats = {
    "confirmados": 45,
    "confirmados_valor": 312450.50,
    "pendentes": 12,
    "pendentes_valor": 89500.00,
    "erros": 3,
    "erros_valor": 15000.00,
    "total_processado": 60,
    "taxa_sucesso": "75%"
}
```

**Skills Acionados:** (em sequência)

#### Skill #1: SLACK - Resumo no #operacoes
```python
slack.send_message(
    channel="#operacoes",
    message="""
    📊 RESUMO DIÁRIO - 2026-04-25

    ✅ Confirmados: 45 | R$ 312.450,50
    ⏳ Pendentes: 12 | R$ 89.500,00
    ❌ Erros: 3 | R$ 15.000,00
    
    Taxa de Sucesso: 75%
    Total Processado: 60 vínculos
    Valor Total: R$ 416.950,50

    @supervisores Revisar 3 erros pendentes.
    """
)
```

#### Skill #2: GOOGLE SHEETS - Exportar linha de resumo
```python
sheets.append_rows(
    spreadsheet_id="seu-sheet-id",
    range="Resumo_Diario!A1",
    values=[[
        "2026-04-25",        # data
        45,                  # confirmados
        312450.50,           # confirmados_valor
        12,                  # pendentes
        89500.00,            # pendentes_valor
        3,                   # erros
        15000.00,            # erros_valor
        "75%"                # taxa_sucesso
    ]]
)
```

#### Skill #3: EMAIL - Enviar relatório completo
```python
gmail.send_email(
    to="operadores@empresa.com",
    cc="supervisores@empresa.com",
    subject="📊 Relatório Diário - 2026-04-25",
    body=f"""
    <html>
    <body>
    <h2>Relatório de Conciliações</h2>
    <p>Data: 2026-04-25</p>
    
    <table border="1" cellpadding="10">
        <tr style="background-color: #f0f0f0;">
            <th>Status</th>
            <th>Quantidade</th>
            <th>Valor</th>
        </tr>
        <tr>
            <td>✅ Confirmados</td>
            <td>45</td>
            <td>R$ 312.450,50</td>
        </tr>
        <tr>
            <td>⏳ Pendentes</td>
            <td>12</td>
            <td>R$ 89.500,00</td>
        </tr>
        <tr style="background-color: #ffcccc;">
            <td>❌ Erros</td>
            <td>3</td>
            <td>R$ 15.000,00</td>
        </tr>
        <tr style="background-color: #f0f0f0;">
            <td><strong>TOTAL</strong></td>
            <td><strong>60</strong></td>
            <td><strong>R$ 416.950,50</strong></td>
        </tr>
    </table>
    
    <p><strong>Taxa de Sucesso:</strong> 75%</p>
    
    <p style="background-color: #fff3cd; padding: 10px; border-left: 4px solid #ffc107;">
        <strong>Ação Necessária:</strong> 
        Há 3 vínculos com erro requerendo revisão.
        <a href="https://seu-portal.nexus.com/dashboard?filter=erro">
            Ver Erros
        </a>
    </p>
    
    <hr/>
    <p style="font-size: 12px; color: #666;">
    Relatório gerado automaticamente pelo Nexus em 2026-04-25
    </p>
    </body>
    </html>
    """
)
```

#### Skill #4: NOTION - Arquivar dia no histórico
```python
# Criar página com resumo diário para referência futura
notion.create_page(
    database_id="relatorios-diarios",
    properties={
        "title": "Relatório 2026-04-25",
        "data": "2026-04-25",
        "confirmados": 45,
        "pendentes": 12,
        "erros": 3,
        "taxa_sucesso": "75%"
    }
)
```

---

## 🎯 Skill Activation Rules (Quando Usar Cada Um)

```python
# Em backend/composio_integrations.py

class ComposioIntegrationManager:
    
    # EVENTO 1: Vínculo Criado
    def on_vinculo_criado(self, vínculo):
        self.slack.notificar_vinculo_criado(vínculo)  # ✅ ALWAYS
        if self.discord:
            self.discord.notify(vínculo)               # ✅ ALWAYS
    
    # EVENTO 2: Título Encontrado
    def on_titulo_encontrado(self, vínculo):
        self.slack.notificar_titulo_encontrado(vínculo) # ✅ ALWAYS
    
    # EVENTO 3: Sucesso de Baixa
    def on_sucesso_baixa(self, vínculo):
        self.slack.notificar_sucesso(vínculo)           # ✅ ALWAYS
        if self.sheets:
            self.sheets.exportar_vinculo(vínculo)       # ✅ IF CONFIGURED
        if self.notion:
            self.notion.registrar_sucesso(vínculo)      # ✅ OPTIONAL
        if self.email_supervisores:
            self.email.notificar_supervisor(vínculo)    # 🟡 OPTIONAL
    
    # EVENTO 4: Erro de Baixa
    def on_erro_baixa(self, vínculo):
        self.slack.alertar_erro(vínculo)                # ✅ ALWAYS
        self.github.criar_issue(vínculo)                # ✅ ALWAYS
        if self.notion:
            self.notion.registrar_erro(vínculo)         # ✅ ALWAYS
        if self.email_supervisores:
            self.email.alertar_supervisor(vínculo)      # ✅ ALWAYS
        if self.discord:
            self.discord.mention_supervisores(vínculo)  # ✅ ALWAYS
    
    # EVENTO 5: Resumo Diário
    def resumo_diario(self, stats):
        self.slack.enviar_resumo(stats)                 # ✅ ALWAYS
        if self.sheets:
            self.sheets.exportar_resumo(stats)          # ✅ ALWAYS
        if self.email_operadores:
            self.email.enviar_relatorio(stats)          # ✅ ALWAYS
        if self.notion:
            self.notion.arquivar_dia(stats)             # 🟡 OPTIONAL
```

---

## 📋 Skill Requirements por Ambiente

### 🏢 Produção (TODOS OBRIGATÓRIOS)
```
✅ Slack ..................... Notificações em tempo real
✅ Gmail ..................... Alertas críticos
✅ GitHub .................... Issues automáticas
✅ Google Sheets ............. Exportação dados
✅ Notion (opcional) ......... Histórico de erros
```

### 🧪 Staging (CORES)
```
✅ Slack ..................... Notificações
✅ Gmail ..................... Relatórios
✅ GitHub .................... Issues
❌ Google Sheets (pode omitir para testes)
❌ Notion (pode omitir para testes)
```

### 💻 Desenvolvimento (MINIMAMENTE)
```
✅ Slack (ou Discord) ........ Notificações dev
✅ GitHub .................... Issues
❌ Gmail (logs de console)
❌ Google Sheets
❌ Notion
```

---

## ✅ Checklist de Setup Completo

- [ ] Criar conta Composio
- [ ] Gerar API Key
- [ ] Instalar SDK: `pip install composio-core composio-slack composio-gmail composio-github composio-sheets`
- [ ] Adicionar `.env`: `COMPOSIO_API_KEY=...`
- [ ] Testar SlackNotifier com Slack workspace
- [ ] Testar GmailNotifier com conta pessoal/empresa
- [ ] Testar GitHubErrorReporter com repo Nexus
- [ ] Testar GoogleSheetsExporter com planilha compartilhada
- [ ] Integrar ComposioIntegrationManager em fluxo de reconciliação
- [ ] Configurar Cron job para resumo diário
- [ ] Documentar em Notion como resgatar erros
- [ ] Deploy em produção com todos os secrets configurados

---

**Status:** ✅ **FLUXO COMPLETO DOCUMENTADO**  
**Data:** 2026-04-25  
**Próximo:** Implementar cada skill conforme checklist
