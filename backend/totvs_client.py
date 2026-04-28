"""
Mock TOTVS PASOE Client para Nexus Reconciliation Portal
Simula respostas de Títulos do TOTVS para validação de operator flow
Pronto para substituir por chamadas reais ao PASOE API
"""

import logging
from datetime import datetime, timedelta
from typing import List, Optional, Dict, Any
from dataclasses import dataclass, asdict

logger = logging.getLogger(__name__)


@dataclass
class TituloTotvs:
    """Representa um Título do TOTVS"""
    titulo_id: int
    filial_cnpj: str
    numero_titulo: str
    valor_total: float
    valor_liquido: float
    data_vencimento: str
    cliente_codigo: str
    cliente_nome: str
    status: str = 'aberto'  # aberto, pago, cancelado
    data_emissao: str = None

    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)


class TotvsMockClient:
    """
    Mock client para TOTVS PASOE API
    Em produção, substituir por chamadas HTTP reais ao PASOE
    """

    # Mock de títulos por CNPJ + NF
    MOCK_DATABASE = {
        '84943067001393': [
            TituloTotvs(
                titulo_id=1001,
                filial_cnpj='84943067001393',
                numero_titulo='NF-2026-001001',
                valor_total=5500.00,
                valor_liquido=5445.00,
                data_vencimento='2026-05-24',
                cliente_codigo='CLI-0001',
                cliente_nome='CLIENTE A LTDA',
                data_emissao='2026-04-24'
            ),
            TituloTotvs(
                titulo_id=1002,
                filial_cnpj='84943067001393',
                numero_titulo='NF-2026-001234',
                valor_total=7600.00,
                valor_liquido=7550.00,
                data_vencimento='2026-05-30',
                cliente_codigo='CLI-0002',
                cliente_nome='ACME CORP LTDA',
                data_emissao='2026-04-24'
            ),
            TituloTotvs(
                titulo_id=1003,
                filial_cnpj='84943067001393',
                numero_titulo='NF-2026-001567',
                valor_total=3200.50,
                valor_liquido=3165.30,
                data_vencimento='2026-06-15',
                cliente_codigo='CLI-0003',
                cliente_nome='EMPRESA XYZ SA',
                data_emissao='2026-04-24'
            ),
        ],
        '01234567000180': [
            TituloTotvs(
                titulo_id=2001,
                filial_cnpj='01234567000180',
                numero_titulo='NF-2026-002001',
                valor_total=9800.00,
                valor_liquido=9750.00,
                data_vencimento='2026-05-20',
                cliente_codigo='CLI-0010',
                cliente_nome='DISTRIBUIDOR NORTE',
                data_emissao='2026-04-20'
            ),
            TituloTotvs(
                titulo_id=2002,
                filial_cnpj='01234567000180',
                numero_titulo='NF-2026-002345',
                valor_total=15000.00,
                valor_liquido=14850.00,
                data_vencimento='2026-06-01',
                cliente_codigo='CLI-0011',
                cliente_nome='GRANDE CLIENTE NORDESTE',
                data_emissao='2026-04-24'
            ),
        ],
    }

    def __init__(self, pasoe_url: Optional[str] = None):
        """
        Inicializa client TOTVS

        Args:
            pasoe_url: URL do PASOE em produção (ex: https://totvs.empresa.com/api)
                      Se None, usa mock
        """
        self.pasoe_url = pasoe_url
        self.modo_mock = pasoe_url is None
        logger.info(f"TotvsMockClient inicializado (modo={'MOCK' if self.modo_mock else 'PASOE'})")

    def buscar_titulos_por_nf(
        self,
        filial_cnpj: str,
        numero_nf: str,
    ) -> List[TituloTotvs]:
        """
        Busca títulos TOTVS por NF específica

        Args:
            filial_cnpj: CNPJ da filial (ex: '84943067001393')
            numero_nf: Número da NF (ex: 'NF-2026-001234')

        Returns:
            Lista de TituloTotvs encontrados

        Exemplo:
            >>> client = TotvsMockClient()
            >>> titulos = client.buscar_titulos_por_nf(
            ...     '84943067001393',
            ...     'NF-2026-001234'
            ... )
            >>> print(titulos[0].valor_total)
            7600.0
        """
        if self.modo_mock:
            return self._buscar_mock(filial_cnpj, numero_nf)
        else:
            return self._buscar_pasoe(filial_cnpj, numero_nf)

    def buscar_titulos_por_periodo(
        self,
        filial_cnpj: str,
        data_inicio: str,
        data_fim: str,
    ) -> List[TituloTotvs]:
        """
        Busca títulos TOTVS por período (data emissão)

        Args:
            filial_cnpj: CNPJ da filial
            data_inicio: Data início YYYY-MM-DD
            data_fim: Data fim YYYY-MM-DD

        Returns:
            Lista de TituloTotvs no período
        """
        if self.modo_mock:
            return self._buscar_periodo_mock(filial_cnpj, data_inicio, data_fim)
        else:
            return self._buscar_periodo_pasoe(filial_cnpj, data_inicio, data_fim)

    def buscar_titulos_abertos(
        self,
        filial_cnpj: str,
    ) -> List[TituloTotvs]:
        """
        Busca todos os títulos abertos (não pagos) de uma filial

        Args:
            filial_cnpj: CNPJ da filial

        Returns:
            Lista de TituloTotvs com status='aberto'
        """
        if self.modo_mock:
            return self._buscar_abertos_mock(filial_cnpj)
        else:
            return self._buscar_abertos_pasoe(filial_cnpj)

    def obter_titulo_por_id(self, titulo_id: int) -> Optional[TituloTotvs]:
        """
        Busca um título específico pelo ID

        Args:
            titulo_id: ID único do título

        Returns:
            TituloTotvs se encontrado, None caso contrário
        """
        if self.modo_mock:
            return self._obter_por_id_mock(titulo_id)
        else:
            return self._obter_por_id_pasoe(titulo_id)

    # =============================================================================
    # IMPLEMENTAÇÃO MOCK (para testes local + Portal FlutterFlow)
    # =============================================================================

    def _buscar_mock(self, filial_cnpj: str, numero_nf: str) -> List[TituloTotvs]:
        """Mock: busca NF específica"""
        titulos = self.MOCK_DATABASE.get(filial_cnpj, [])
        resultado = [
            t for t in titulos
            if t.numero_titulo.upper() == numero_nf.upper()
        ]
        logger.debug(f"Mock: busca NF '{numero_nf}' em {filial_cnpj} → {len(resultado)} resultado(s)")
        return resultado

    def _buscar_periodo_mock(
        self,
        filial_cnpj: str,
        data_inicio: str,
        data_fim: str,
    ) -> List[TituloTotvs]:
        """Mock: busca por período"""
        titulos = self.MOCK_DATABASE.get(filial_cnpj, [])

        try:
            dt_inicio = datetime.strptime(data_inicio, '%Y-%m-%d').date()
            dt_fim = datetime.strptime(data_fim, '%Y-%m-%d').date()
        except ValueError as e:
            logger.error(f"Erro ao parsear datas: {e}")
            return []

        resultado = [
            t for t in titulos
            if dt_inicio <= datetime.strptime(t.data_emissao, '%Y-%m-%d').date() <= dt_fim
        ]
        logger.debug(f"Mock: busca período {data_inicio}→{data_fim} em {filial_cnpj} → {len(resultado)} resultado(s)")
        return resultado

    def _buscar_abertos_mock(self, filial_cnpj: str) -> List[TituloTotvs]:
        """Mock: retorna todos os títulos abertos da filial"""
        titulos = self.MOCK_DATABASE.get(filial_cnpj, [])
        resultado = [t for t in titulos if t.status == 'aberto']
        logger.debug(f"Mock: títulos abertos em {filial_cnpj} → {len(resultado)} resultado(s)")
        return resultado

    def _obter_por_id_mock(self, titulo_id: int) -> Optional[TituloTotvs]:
        """Mock: busca título por ID"""
        for cnpj_titulos in self.MOCK_DATABASE.values():
            for titulo in cnpj_titulos:
                if titulo.titulo_id == titulo_id:
                    logger.debug(f"Mock: titulo_id {titulo_id} encontrado")
                    return titulo
        logger.debug(f"Mock: titulo_id {titulo_id} NÃO encontrado")
        return None

    # =============================================================================
    # STUBS PARA PASOE REAL (TODO: implementar quando API estiver disponível)
    # =============================================================================

    def _buscar_pasoe(self, filial_cnpj: str, numero_nf: str) -> List[TituloTotvs]:
        """
        STUB: Busca real do PASOE

        TODO: Implementar chamada HTTP ao PASOE API
        GET {self.pasoe_url}/titulos?filial={filial_cnpj}&nf={numero_nf}

        Exemplo esperado de resposta PASOE:
        {
          "titulos": [
            {
              "titulo_id": 1002,
              "numero_titulo": "NF-2026-001234",
              "valor_total": 7600.00,
              "valor_liquido": 7550.00,
              "data_vencimento": "2026-05-30",
              "cliente_codigo": "CLI-0002",
              "cliente_nome": "ACME CORP LTDA",
              "status": "aberto"
            }
          ]
        }
        """
        raise NotImplementedError("PASOE API não implementada ainda. Use modo MOCK.")

    def _buscar_periodo_pasoe(
        self,
        filial_cnpj: str,
        data_inicio: str,
        data_fim: str,
    ) -> List[TituloTotvs]:
        """STUB: Busca período real do PASOE"""
        raise NotImplementedError("PASOE API não implementada ainda. Use modo MOCK.")

    def _buscar_abertos_pasoe(self, filial_cnpj: str) -> List[TituloTotvs]:
        """STUB: Busca títulos abertos real do PASOE"""
        raise NotImplementedError("PASOE API não implementada ainda. Use modo MOCK.")

    def _obter_por_id_pasoe(self, titulo_id: int) -> Optional[TituloTotvs]:
        """STUB: Busca por ID real do PASOE"""
        raise NotImplementedError("PASOE API não implementada ainda. Use modo MOCK.")


# =============================================================================
# EXEMPLO DE USO
# =============================================================================

if __name__ == '__main__':
    logging.basicConfig(level=logging.DEBUG)

    # Usar mock
    client = TotvsMockClient()

    # Teste 1: Buscar NF específica
    print("\n[Teste 1] Buscar NF específica:")
    titulos = client.buscar_titulos_por_nf('84943067001393', 'NF-2026-001234')
    for titulo in titulos:
        print(f"  - {titulo.numero_titulo}: R$ {titulo.valor_total}")

    # Teste 2: Buscar titulos abertos
    print("\n[Teste 2] Titulos abertos:")
    abertos = client.buscar_titulos_abertos('84943067001393')
    print(f"  Total: {len(abertos)} título(s)")
    for titulo in abertos:
        print(f"    - {titulo.numero_titulo} (R$ {titulo.valor_total}) - Venc: {titulo.data_vencimento}")

    # Teste 3: Buscar por período
    print("\n[Teste 3] Buscar por período:")
    periodo = client.buscar_titulos_por_periodo(
        '84943067001393',
        '2026-04-20',
        '2026-04-30'
    )
    print(f"  Total: {len(periodo)} título(s)")

    # Teste 4: Obter título por ID
    print("\n[Teste 4] Obter título por ID:")
    titulo = client.obter_titulo_por_id(1002)
    if titulo:
        print(f"  {titulo.numero_titulo} - {titulo.cliente_nome}")
        print(f"  Valor: R$ {titulo.valor_total} | Líquido: R$ {titulo.valor_liquido}")
        print(f"  Vencimento: {titulo.data_vencimento}")

    print("\n✅ Todos os testes completados (modo MOCK)")
