"""
Composio Skills Integration for Nexus Project
Exemplos práticos de como integrar Composio com o fluxo de reconciliação
"""

import os
import logging
from datetime import datetime
from typing import Dict, List, Optional
from dotenv import load_dotenv

# Carregar variáveis de ambiente
load_dotenv()

logger = logging.getLogger(__name__)

# ==============================================================================
# CONFIGURAÇÃO
# ==============================================================================

COMPOSIO_API_KEY = os.getenv("COMPOSIO_API_KEY")

if not COMPOSIO_API_KEY:
    logger.warning("⚠️ COMPOSIO_API_KEY não configurada. Skills desabilitadas.")
    COMPOSIO_ENABLED = False
else:
    COMPOSIO_ENABLED = True
    logger.info("✅ Composio Skills habilitado")


# ==============================================================================
# 1. NOTIFICAÇÕES VIA SLACK
# ==============================================================================

class SlackNotifier:
    """
    Envia notificações para Slack sobre eventos de reconciliação
    Requer: pip install composio-slack
    """

    def __init__(self):
        if not COMPOSIO_ENABLED:
            self.enabled = False
            return

        try:
            from composio_slack import SlackToolSet
            self.slack = SlackToolSet(api_key=COMPOSIO_API_KEY)
            self.enabled = True
            logger.info("✅ SlackNotifier inicializado")
        except ImportError:
            logger.warning("⚠️ composio-slack não instalado")
            self.enabled = False

    def notificar_vinculo_confirmado(
        self, filial_cnpj: str, vínculo_id: int, nf: str, valor: float
    ):
        """Notifica quando vínculo é confirmado com sucesso"""
        if not self.enabled:
            return

        mensagem = f"""
        ✅ **Vínculo Confirmado**
        Filial: `{filial_cnpj}`
        Vínculo ID: `{vínculo_id}`
        NF: `{nf}`
        Valor: R$ {valor:,.2f}
        Data: {datetime.now().strftime('%d/%m/%Y %H:%M:%S')}
        """

        try:
            self.slack.send_message(
                channel="#reconciliacao", message=mensagem.strip()
            )
            logger.info(f"✅ Notificação Slack enviada: vínculo {vínculo_id}")
        except Exception as e:
            logger.error(f"❌ Erro ao enviar notificação Slack: {e}")

    def alertar_erro_baixa_totvs(
        self, vínculo_id: int, status_baixa: str, erro: str
    ):
        """Alertar quando PASOE retorna erro de baixa"""
        if not self.enabled:
            return

        mensagem = f"""
        ❌ **Erro de Baixa TOTVS**
        Vínculo ID: `{vínculo_id}`
        Código Erro: `{status_baixa}`
        Mensagem: {erro}
        Ação: Revisar e fazer retry manualmente
        """

        try:
            self.slack.send_message(
                channel="#alertas-operacionais", message=mensagem.strip()
            )
            logger.info(f"🚨 Alerta Slack enviado: erro vínculo {vínculo_id}")
        except Exception as e:
            logger.error(f"❌ Erro ao enviar alerta Slack: {e}")

    def resumo_diario(self, stats: Dict):
        """Enviar resumo diário de conciliações"""
        if not self.enabled:
            return

        mensagem = f"""
        📊 **Resumo Diário de Conciliações**
        Data: {datetime.now().strftime('%d/%m/%Y')}

        ✅ Confirmados: {stats.get('confirmados', 0)}
        ⏳ Pendentes: {stats.get('pendentes', 0)}
        ❌ Erros: {stats.get('erros', 0)}

        Valor Conciliado: R$ {stats.get('valor_confirmado', 0):,.2f}
        Valor em Aberto: R$ {stats.get('valor_pendente', 0):,.2f}

        @supervisors Revisar erros se houver.
        """

        try:
            self.slack.send_message(
                channel="#operacoes-diarias", message=mensagem.strip()
            )
            logger.info("📊 Resumo diário enviado para Slack")
        except Exception as e:
            logger.error(f"❌ Erro ao enviar resumo: {e}")


# ==============================================================================
# 2. REGISTRO DE ERROS VIA GITHUB
# ==============================================================================

class GitHubErrorReporter:
    """
    Cria issues no GitHub para erros de reconciliação
    Requer: pip install composio-github
    """

    def __init__(self, repo: str = "rodrigominusa/nexus"):
        self.repo = repo
        if not COMPOSIO_ENABLED:
            self.enabled = False
            return

        try:
            from composio_github import GitHubToolSet
            self.github = GitHubToolSet(api_key=COMPOSIO_API_KEY)
            self.enabled = True
            logger.info("✅ GitHubErrorReporter inicializado")
        except ImportError:
            logger.warning("⚠️ composio-github não instalado")
            self.enabled = False

    def criar_issue_erro_baixa(
        self, vínculo_id: int, filial_cnpj: str, erro_detalhes: Dict
    ):
        """Cria issue no GitHub quando há erro de baixa TOTVS"""
        if not self.enabled:
            return

        titulo = f"🔴 Erro de Baixa TOTVS - Vínculo {vínculo_id}"
        corpo = f"""
## Detalhes do Erro
- **Vínculo ID:** {vínculo_id}
- **Filial:** {filial_cnpj}
- **Data/Hora:** {datetime.now().isoformat()}
- **Status Baixa:** {erro_detalhes.get('status_baixa', 'N/A')}

## Mensagem de Erro
```
{erro_detalhes.get('erro_baixa', 'Sem detalhes')}
```

## Ações Necessárias
- [ ] Validar título no TOTVS
- [ ] Verificar permissões de acesso
- [ ] Fazer retry manualmente
- [ ] Contatar suporte PASOE se necessário

## Contexto Técnico
- Tipo: `erro_baixa`
- Severidade: `alta`
- Component: `totvs_integration`
"""

        try:
            self.github.create_issue(
                repo=self.repo,
                title=titulo,
                body=corpo,
                labels=["bug", "totvs", "erro-baixa", "urgent"],
            )
            logger.info(f"✅ Issue GitHub criada: vínculo {vínculo_id}")
        except Exception as e:
            logger.error(f"❌ Erro ao criar issue GitHub: {e}")

    def criar_issue_divergencia(
        self, vínculo_id: int, divergencia: Dict
    ):
        """Cria issue para divergências detectadas"""
        if not self.enabled:
            return

        titulo = f"⚠️ Divergência Detectada - Vínculo {vínculo_id}"
        corpo = f"""
## Detalhes da Divergência
- **Vínculo ID:** {vínculo_id}
- **Diferença Valor:** R$ {divergencia.get('diferenca_valor', 0):.2f}
- **Diferença Dias:** {divergencia.get('diferenca_dias', 0)} dias
- **Score Confiança:** {divergencia.get('score_confianca', 0):.2f}

## Ação Necessária
- [ ] Revisar manualmente
- [ ] Aprovar ou rejeitar vínculo
- [ ] Documentar motivo

## Referência
Data: {datetime.now().isoformat()}
"""

        try:
            self.github.create_issue(
                repo=self.repo,
                title=titulo,
                body=corpo,
                labels=["divergencia", "review-needed"],
            )
            logger.info(f"✅ Issue divergência criada: vínculo {vínculo_id}")
        except Exception as e:
            logger.error(f"❌ Erro ao criar issue divergência: {e}")


# ==============================================================================
# 3. EXPORTAÇÃO PARA GOOGLE SHEETS
# ==============================================================================

class GoogleSheetsExporter:
    """
    Exporta dados de reconciliação para Google Sheets
    Requer: pip install composio-sheets
    """

    def __init__(self, spreadsheet_id: str):
        self.spreadsheet_id = spreadsheet_id
        if not COMPOSIO_ENABLED:
            self.enabled = False
            return

        try:
            from composio_sheets import GoogleSheetsToolSet
            self.sheets = GoogleSheetsToolSet(api_key=COMPOSIO_API_KEY)
            self.enabled = True
            logger.info("✅ GoogleSheetsExporter inicializado")
        except ImportError:
            logger.warning("⚠️ composio-sheets não instalado")
            self.enabled = False

    def exportar_vinculos_confirmados(self, vinculos: List[Dict]):
        """Exporta vínculos confirmados para planilha"""
        if not self.enabled or not vinculos:
            return

        # Preparar dados: [ID, NF, Valor, Data, Status]
        headers = [["ID", "NF", "Valor", "Data Baixa", "Status"]]
        rows = []

        for v in vinculos:
            rows.append([
                v.get("vinculo_id", ""),
                v.get("numero_nf_manual", ""),
                v.get("valor", ""),
                v.get("data_baixa_totvs", "").split("T")[0]
                if v.get("data_baixa_totvs")
                else "",
                v.get("status", ""),
            ])

        try:
            self.sheets.append_rows(
                spreadsheet_id=self.spreadsheet_id,
                range="Vinculos!A1",
                values=headers + rows,
            )
            logger.info(
                f"✅ {len(vinculos)} vínculos exportados para Google Sheets"
            )
        except Exception as e:
            logger.error(f"❌ Erro ao exportar para Sheets: {e}")

    def exportar_resumo_diario(self, stats: Dict):
        """Exporta resumo diário em nova linha"""
        if not self.enabled:
            return

        data_hoje = datetime.now().strftime("%d/%m/%Y")
        row = [[
            data_hoje,
            stats.get("confirmados", 0),
            stats.get("pendentes", 0),
            stats.get("erros", 0),
            f"R$ {stats.get('valor_confirmado', 0):,.2f}",
            f"R$ {stats.get('valor_pendente', 0):,.2f}",
        ]]

        try:
            self.sheets.append_rows(
                spreadsheet_id=self.spreadsheet_id,
                range="Resumo!A1",
                values=row,
            )
            logger.info("✅ Resumo diário exportado para Google Sheets")
        except Exception as e:
            logger.error(f"❌ Erro ao exportar resumo: {e}")


# ==============================================================================
# 4. ENVIO DE EMAILS
# ==============================================================================

class EmailReporter:
    """
    Envia relatórios e notificações por email
    Requer: pip install composio-gmail
    """

    def __init__(self):
        if not COMPOSIO_ENABLED:
            self.enabled = False
            return

        try:
            from composio_gmail import GmailToolSet
            self.gmail = GmailToolSet(api_key=COMPOSIO_API_KEY)
            self.enabled = True
            logger.info("✅ EmailReporter inicializado")
        except ImportError:
            logger.warning("⚠️ composio-gmail não instalado")
            self.enabled = False

    def enviar_relatorio_diario(
        self, destinatarios: List[str], stats: Dict
    ):
        """Envia relatório diário de conciliações"""
        if not self.enabled:
            return

        assunto = f"📊 Resumo Conciliações - {datetime.now().strftime('%d/%m/%Y')}"

        html = f"""
        <html>
        <body style="font-family: Arial, sans-serif;">
            <h2>Resumo de Conciliações</h2>
            <p>Data: {datetime.now().strftime('%d/%m/%Y às %H:%M:%S')}</p>

            <table border="1" cellpadding="10" cellspacing="0">
                <tr style="background-color: #f0f0f0;">
                    <th>Métrica</th>
                    <th>Quantidade</th>
                    <th>Valor</th>
                </tr>
                <tr>
                    <td>✅ Confirmados</td>
                    <td>{stats.get('confirmados', 0)}</td>
                    <td>R$ {stats.get('valor_confirmado', 0):,.2f}</td>
                </tr>
                <tr>
                    <td>⏳ Pendentes</td>
                    <td>{stats.get('pendentes', 0)}</td>
                    <td>R$ {stats.get('valor_pendente', 0):,.2f}</td>
                </tr>
                <tr style="background-color: #ffcccc;">
                    <td>❌ Erros</td>
                    <td>{stats.get('erros', 0)}</td>
                    <td>R$ {stats.get('valor_erros', 0):,.2f}</td>
                </tr>
            </table>

            <p style="margin-top: 20px;">
                <strong>Próximas Ações:</strong>
                {stats.get('erros', 0) > 0 and 'Há erros requerendo revisão.' or 'Nenhuma ação necessária.'}
            </p>

            <p><a href="https://seu-portal.nexus.com/dashboard">
                Acessar Dashboard →
            </a></p>
        </body>
        </html>
        """

        for destinatario in destinatarios:
            try:
                self.gmail.send_email(
                    to=destinatario,
                    subject=assunto,
                    body=html,
                    is_html=True,
                )
                logger.info(f"✅ Email enviado para {destinatario}")
            except Exception as e:
                logger.error(f"❌ Erro ao enviar email para {destinatario}: {e}")

    def alertar_erros_criticos(
        self, destinatarios: List[str], erros: List[Dict]
    ):
        """Envia alerta de erros críticos"""
        if not self.enabled or not erros:
            return

        assunto = f"🚨 {len(erros)} Erro(s) Crítico(s) - Ação Necessária"

        html = f"""
        <html>
        <body style="font-family: Arial, sans-serif;">
            <h2 style="color: red;">⚠️ Erros Críticos Detectados</h2>
            <p>Data: {datetime.now().strftime('%d/%m/%Y às %H:%M:%S')}</p>

            <p><strong>{len(erros)} vínculo(s) com erro(s) requerendo ação:</strong></p>

            <ul>
        """

        for erro in erros:
            html += f"""
                <li>
                    <strong>Vínculo {erro.get('vinculo_id')}</strong>
                    <br/>Erro: {erro.get('erro_baixa', 'N/A')}
                    <br/>Status: {erro.get('status_baixa', 'N/A')}
                </li>
            """

        html += """
            </ul>

            <p style="background-color: #fff3cd; padding: 10px; border-left: 4px solid #ffc107;">
                <strong>Ação Necessária:</strong> Revisar erros no Dashboard e fazer retry ou escalação.
            </p>

            <p><a href="https://seu-portal.nexus.com/dashboard?filter=erro">
                Acessar Dashboard de Erros →
            </a></p>
        </body>
        </html>
        """

        for destinatario in destinatarios:
            try:
                self.gmail.send_email(
                    to=destinatario,
                    subject=assunto,
                    body=html,
                    is_html=True,
                )
                logger.info(f"✅ Alerta crítico enviado para {destinatario}")
            except Exception as e:
                logger.error(
                    f"❌ Erro ao enviar alerta para {destinatario}: {e}"
                )


# ==============================================================================
# 5. INTEGRAÇÃO COMPLETA (ORQUESTRADOR)
# ==============================================================================

class ComposioIntegrationManager:
    """
    Gerenciador centralizado de integrações Composio
    Coordena notificações, exportações e alertas
    """

    def __init__(self, spreadsheet_id: Optional[str] = None):
        self.slack = SlackNotifier()
        self.github = GitHubErrorReporter()
        self.sheets = GoogleSheetsExporter(spreadsheet_id) if spreadsheet_id else None
        self.email = EmailReporter()
        logger.info("✅ ComposioIntegrationManager inicializado")

    def on_vinculo_confirmado(self, vínculo: Dict):
        """Handler quando vínculo é confirmado com sucesso"""
        self.slack.notificar_vinculo_confirmado(
            filial_cnpj=vínculo.get("filial_cnpj"),
            vínculo_id=vínculo.get("vinculo_id"),
            nf=vínculo.get("numero_nf_manual"),
            valor=vínculo.get("valor"),
        )

        # Exportar se Sheets estiver configurado
        if self.sheets:
            self.sheets.exportar_vinculos_confirmados([vínculo])

    def on_erro_baixa(self, vínculo: Dict):
        """Handler quando há erro de baixa TOTVS"""
        # 1. Notificar via Slack
        self.slack.alertar_erro_baixa_totvs(
            vínculo_id=vínculo.get("vinculo_id"),
            status_baixa=vínculo.get("status_baixa"),
            erro=vínculo.get("erro_baixa"),
        )

        # 2. Criar issue no GitHub
        self.github.criar_issue_erro_baixa(
            vínculo_id=vínculo.get("vinculo_id"),
            filial_cnpj=vínculo.get("filial_cnpj"),
            erro_detalhes={
                "status_baixa": vínculo.get("status_baixa"),
                "erro_baixa": vínculo.get("erro_baixa"),
            },
        )

    def resumo_diario(self, stats: Dict, destinatarios_email: List[str]):
        """Handler para enviar resumo diário"""
        # 1. Notificar via Slack
        self.slack.resumo_diario(stats)

        # 2. Exportar para Sheets
        if self.sheets:
            self.sheets.exportar_resumo_diario(stats)

        # 3. Enviar via Email
        if destinatarios_email:
            self.email.enviar_relatorio_diario(
                destinatarios=destinatarios_email, stats=stats
            )


# ==============================================================================
# EXEMPLO DE USO
# ==============================================================================

if __name__ == "__main__":
    # Configurar logging
    logging.basicConfig(level=logging.INFO)

    # Inicializar gerenciador
    manager = ComposioIntegrationManager(
        spreadsheet_id="sua-sheet-id-aqui"
    )

    # Exemplo 1: Vínculo confirmado
    vinculo_confirmado = {
        "vinculo_id": 99,
        "filial_cnpj": "84943067001393",
        "numero_nf_manual": "NF-2026-001234",
        "valor": 7600.00,
    }
    manager.on_vinculo_confirmado(vinculo_confirmado)

    # Exemplo 2: Erro de baixa
    vinculo_erro = {
        "vinculo_id": 100,
        "filial_cnpj": "84943067001393",
        "status_baixa": "E001_TITULO_NAO_ENCONTRADO",
        "erro_baixa": "Título 001234 não encontrado na filial 84943067001393",
    }
    manager.on_erro_baixa(vinculo_erro)

    # Exemplo 3: Resumo diário
    stats = {
        "confirmados": 45,
        "pendentes": 12,
        "erros": 3,
        "valor_confirmado": 312450.50,
        "valor_pendente": 89500.00,
        "valor_erros": 15000.00,
    }
    manager.resumo_diario(
        stats=stats,
        destinatarios_email=["operadores@empresa.com", "supervisores@empresa.com"]
    )

    print("✅ Exemplos executados com sucesso")
