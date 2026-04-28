'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { getClient } from '@/lib/supabase/client';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { BandeiraBadge } from '@/components/ui/bandeira-badge';
import { ScoreBar } from '@/components/ui/score-bar';
import { DiasBadge } from '@/components/ui/dias-badge';
import {
  AlertCircle,
  TrendingUp,
  CheckCircle2,
  Plus,
  LogOut,
  Bell,
  Search,
  ChevronRight,
  X,
  ArrowLeft,
  Loader2,
} from 'lucide-react';
import { toast } from 'sonner';
import { getNsuPendentes, getNsusComSugestao, getTitulosSemNsu, getUltimasConciliacoes } from '@/lib/supabase/queries';
import { NsuSemVinculoModal } from '@/components/modals/nsu-sem-vinculo-modal';
import { NsuComVinculoModal } from '@/components/modals/nsu-com-vinculo-modal';
import { BuscarNsuPendenteModal } from '@/components/modals/buscar-nsu-pendente-modal';

type TabType = 'pendentes' | 'sugestoes' | 'titulos' | 'conciliados';
type ModalType = 'none' | 'nsu-sem-vinculo' | 'nsu-com-vinculo' | 'buscar-pendente';
type WizardStep = 1 | 2 | 3;

interface Metrics {
  nsu_pendentes: number;
  nsu_com_sugestao: number;
  titulos_sem_nsu: number;
  conciliados: number;
  valor_conciliados: number;
}

export default function OperadorDashboardV2() {
  const router = useRouter();
  const [user, setUser] = useState<any>(null);
  const [filialInfo, setFilialInfo] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<TabType>('pendentes');
  const [metrics, setMetrics] = useState<Metrics>({
    nsu_pendentes: 0,
    nsu_com_sugestao: 0,
    titulos_sem_nsu: 0,
    conciliados: 0,
    valor_conciliados: 0,
  });

  // Modal states
  const [activeModal, setActiveModal] = useState<ModalType>('none');
  const [wizardStep, setWizardStep] = useState<WizardStep>(1);

  // Data states
  const [nsuPendentes, setNsuPendentes] = useState<any[]>([]);
  const [nsusComSugestao, setNsusComSugestao] = useState<any[]>([]);
  const [titulosSemNsu, setTitulosSemNsu] = useState<any[]>([]);
  const [ultimasConciliacoes, setUltimasConciliacoes] = useState<any[]>([]);

  const supabase = getClient();

  // Load dashboard data
  useEffect(() => {
    const loadData = async () => {
      try {
        const { data: userData } = await supabase.auth.getUser();

        if (!userData.user) {
          router.push('/login');
          return;
        }

        setUser(userData.user);

        // Get user's filial
        const { data: userFilial } = await supabase
          .from('user_filiais')
          .select('filial_cnpj')
          .eq('user_id', userData.user.id)
          .single();

        if (!userFilial) {
          toast.error('Filial não configurada');
          return;
        }

        const filialCnpj = userFilial.filial_cnpj;

        // Get filial info
        const { data: filialData } = await supabase
          .from('filiais')
          .select('filial_cnpj, nome_filial, codigo_ec, uf')
          .eq('filial_cnpj', filialCnpj)
          .single();

        if (filialData) {
          setFilialInfo(filialData);
        }

        // Load all data in parallel
        const [pendentes, sugestoes, titulos, conciliados] = await Promise.all([
          getNsuPendentes(filialCnpj),
          getNsusComSugestao(filialCnpj),
          getTitulosSemNsu(filialCnpj),
          getUltimasConciliacoes(filialCnpj),
        ]);

        setNsuPendentes(pendentes);
        setNsusComSugestao(sugestoes);
        setTitulosSemNsu(titulos);
        setUltimasConciliacoes(conciliados);

        const valorConciliados = conciliados.reduce((sum: number, vinculo: any) => {
          return sum + (vinculo.transacoes_getnet?.valor_venda || 0);
        }, 0);

        setMetrics({
          nsu_pendentes: pendentes.length,
          nsu_com_sugestao: sugestoes.length,
          titulos_sem_nsu: titulos.length,
          conciliados: conciliados.length,
          valor_conciliados: valorConciliados,
        });
      } catch (error) {
        console.error('Erro ao carregar dados:', error);
        toast.error('Erro ao carregar dashboard');
      } finally {
        setLoading(false);
      }
    };

    loadData();
  }, [router, supabase]);

  const handleLogout = async () => {
    await supabase.auth.signOut();
    router.push('/login');
  };

  // Métrica Card Component
  const MetricCard = ({ icon: Icon, label, value, color, action }: any) => (
    <div className={`bg-gradient-to-br ${color} rounded-xl p-6 text-white shadow-lg hover:shadow-xl transition-all hover:scale-105`}>
      <div className="flex items-start justify-between mb-4">
        <Icon className="w-8 h-8 opacity-80" />
        <TrendingUp className="w-4 h-4 opacity-50" />
      </div>
      <p className="text-sm opacity-75 mb-2">{label}</p>
      <div className="flex items-end justify-between">
        <p className="text-4xl font-bold">{value}</p>
        {action && (
          <Button
            size="sm"
            variant="ghost"
            className="text-white hover:bg-white/20"
            onClick={action}
          >
            Ver <ChevronRight className="w-4 h-4 ml-1" />
          </Button>
        )}
      </div>
    </div>
  );

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <Loader2 className="w-12 h-12 animate-spin text-blue-600 mx-auto mb-4" />
          <p className="text-gray-600">Carregando dashboard...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white border-b border-gray-200 sticky top-0 z-40">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-blue-600 to-emerald-600 flex items-center justify-center">
                <span className="text-white font-bold text-sm">◆</span>
              </div>
              <h1 className="text-xl font-bold text-gray-900">NEXUS</h1>
              <span className="text-xs text-gray-500 ml-2">/ Operador</span>
            </div>

            <div className="flex items-center gap-4">
              <button className="relative p-2 text-gray-600 hover:bg-gray-100 rounded-lg transition">
                <Bell className="w-5 h-5" />
                <span className="absolute top-1 right-1 w-2 h-2 bg-red-500 rounded-full"></span>
              </button>

              <div className="flex items-center gap-3 pl-4 border-l border-gray-200">
                <div className="text-right hidden sm:block">
                  <p className="text-sm font-medium text-gray-900">{user?.email?.split('@')[0]}</p>
                  <p className="text-xs text-gray-500">Operador</p>
                </div>
                <button
                  onClick={handleLogout}
                  className="p-2 text-gray-600 hover:bg-red-50 hover:text-red-600 rounded-lg transition"
                  title="Sair"
                >
                  <LogOut className="w-5 h-5" />
                </button>
              </div>
            </div>
          </div>

          {/* Filial Info Card */}
          {filialInfo && (
            <div className="bg-gradient-to-r from-blue-50 to-indigo-50 border border-blue-200 rounded-lg p-4">
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm">
                <div>
                  <p className="text-xs text-gray-600 uppercase">Loja</p>
                  <p className="font-semibold text-gray-900 mt-1">{filialInfo.nome_filial || 'N/A'}</p>
                </div>
                <div>
                  <p className="text-xs text-gray-600 uppercase">CNPJ</p>
                  <p className="font-mono text-gray-900 mt-1">{filialInfo.filial_cnpj.replace(/^(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})$/, '$1.$2.$3/$4-$5')}</p>
                </div>
                <div>
                  <p className="text-xs text-gray-600 uppercase">EC / UF</p>
                  <p className="font-semibold text-gray-900 mt-1">{filialInfo.codigo_ec || 'N/A'} • {filialInfo.uf || 'N/A'}</p>
                </div>
              </div>
            </div>
          )}
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* SEÇÃO 1: Quick Actions */}
        <div className="mb-8 grid grid-cols-1 md:grid-cols-3 gap-4">
          <Button
            onClick={() => {
              setActiveModal('nsu-sem-vinculo');
              setWizardStep(1);
            }}
            className="h-16 bg-red-600 hover:bg-red-700 text-white text-lg font-semibold"
          >
            <Plus className="w-6 h-6 mr-2" />
            Lançar NSU SEM Vínculo
          </Button>

          <Button
            onClick={() => {
              setActiveModal('nsu-com-vinculo');
              setWizardStep(1);
            }}
            className="h-16 bg-green-600 hover:bg-green-700 text-white text-lg font-semibold"
          >
            <Plus className="w-6 h-6 mr-2" />
            Lançar NSU COM Vínculo
          </Button>

          <Button
            onClick={() => setActiveModal('buscar-pendente')}
            className="h-16 bg-blue-600 hover:bg-blue-700 text-white text-lg font-semibold"
          >
            <Search className="w-6 h-6 mr-2" />
            Buscar NSU Pendente
          </Button>
        </div>

        {/* SEÇÃO 2: Métricas */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <MetricCard
            icon={AlertCircle}
            label="NSUs Pendentes"
            value={metrics.nsu_pendentes}
            color="from-red-500 to-red-600"
            action={() => setActiveTab('pendentes')}
          />
          <MetricCard
            icon={TrendingUp}
            label="NSUs com Sugestão"
            value={metrics.nsu_com_sugestao}
            color="from-yellow-500 to-yellow-600"
            action={() => setActiveTab('sugestoes')}
          />
          <MetricCard
            icon={AlertCircle}
            label="Títulos sem NSU"
            value={metrics.titulos_sem_nsu}
            color="from-orange-500 to-orange-600"
            action={() => setActiveTab('titulos')}
          />
          <div className="bg-gradient-to-br from-emerald-500 to-emerald-600 rounded-xl p-6 text-white shadow-lg hover:shadow-xl transition-all hover:scale-105">
            <div className="flex items-start justify-between mb-4">
              <CheckCircle2 className="w-8 h-8 opacity-80" />
              <TrendingUp className="w-4 h-4 opacity-50" />
            </div>
            <p className="text-sm opacity-75 mb-2">Conciliados (30 dias)</p>
            <div className="flex items-end justify-between">
              <div className="flex-1">
                <p className="text-4xl font-bold">{metrics.conciliados}</p>
                <p className="text-xs opacity-75 mt-1">R$ {metrics.valor_conciliados.toLocaleString('pt-BR', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</p>
              </div>
              <Button
                size="sm"
                variant="ghost"
                className="text-white hover:bg-white/20"
                onClick={() => setActiveTab('conciliados')}
              >
                Ver <ChevronRight className="w-4 h-4 ml-1" />
              </Button>
            </div>
          </div>
        </div>

        {/* SEÇÃO 3: Tabs com DataTables */}
        <div className="bg-white rounded-xl shadow">
          {/* Tab Navigation */}
          <div className="border-b border-gray-200 flex overflow-x-auto">
            {[
              { id: 'pendentes' as TabType, label: '📌 NSUs Pendentes', count: metrics.nsu_pendentes },
              { id: 'sugestoes' as TabType, label: '🟡 Sugestões', count: metrics.nsu_com_sugestao },
              { id: 'titulos' as TabType, label: '📋 Títulos Pendentes', count: metrics.titulos_sem_nsu },
              { id: 'conciliados' as TabType, label: '✅ Últimas Conciliações', count: metrics.conciliados },
            ].map((tab) => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`flex-1 px-6 py-4 text-sm font-medium border-b-2 transition-colors whitespace-nowrap ${
                  activeTab === tab.id
                    ? 'border-blue-600 text-blue-600'
                    : 'border-transparent text-gray-600 hover:text-gray-900'
                }`}
              >
                {tab.label} <span className="ml-2 text-xs bg-gray-100 rounded-full px-2 py-1">{tab.count}</span>
              </button>
            ))}
          </div>

          {/* Tab Content - Pendentes */}
          {activeTab === 'pendentes' && (
            <div className="p-6">
              {nsuPendentes.length > 0 ? (
                <div className="overflow-x-auto">
                  <table className="w-full text-sm">
                    <thead className="bg-gray-50 border-b border-gray-200">
                      <tr>
                        <th className="px-6 py-3 text-left font-medium text-gray-700">NSU</th>
                        <th className="px-6 py-3 text-right font-medium text-gray-700">Valor</th>
                        <th className="px-6 py-3 text-left font-medium text-gray-700">Bandeira</th>
                        <th className="px-6 py-3 text-left font-medium text-gray-700">Tipo</th>
                        <th className="px-6 py-3 text-left font-medium text-gray-700">Origem</th>
                        <th className="px-6 py-3 text-left font-medium text-gray-700">Data</th>
                        <th className="px-6 py-3 text-left font-medium text-gray-700">Dias</th>
                        <th className="px-6 py-3 text-right font-medium text-gray-700">Ação</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-200">
                      {nsuPendentes.map((row) => (
                        <tr key={row.id} className="hover:bg-gray-50">
                          <td className="px-6 py-4 font-mono text-gray-900">{row.nsu}</td>
                          <td className="px-6 py-4 text-right text-gray-900 font-medium">
                            R$ {row.valor_venda?.toFixed(2) || '0.00'}
                          </td>
                          <td className="px-6 py-4">
                            <BandeiraBadge bandeira={row.bandeira} tipo={row.modalidade} />
                          </td>
                          <td className="px-6 py-4 text-gray-600">
                            {row.modalidade === 'debito' ? '🏧 Débito' : '💳 Crédito'}
                          </td>
                          <td className="px-6 py-4">
                            {row.origem === 'arquivo_getnet' ? (
                              <span className="inline-flex items-center gap-1 px-2 py-1 bg-blue-100 text-blue-700 rounded-full text-xs font-semibold">
                                🔵 GETNET
                              </span>
                            ) : (
                              <span className="inline-flex items-center gap-1 px-2 py-1 bg-orange-100 text-orange-700 rounded-full text-xs font-semibold">
                                ⭕ Manual
                              </span>
                            )}
                          </td>
                          <td className="px-6 py-4 text-gray-600">
                            {new Date(row.data_venda).toLocaleDateString('pt-BR')}
                          </td>
                          <td className="px-6 py-4">
                            <DiasBadge dias={Math.floor((new Date().getTime() - new Date(row.data_venda).getTime()) / (1000 * 60 * 60 * 24))} />
                          </td>
                          <td className="px-6 py-4 text-right">
                            <Button variant="outline" size="sm">
                              Vincular NF
                            </Button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              ) : (
                <div className="text-center py-12">
                  <CheckCircle2 className="w-12 h-12 text-emerald-500 mx-auto mb-3 opacity-50" />
                  <p className="text-gray-600 font-medium">Nenhuma NSU pendente</p>
                  <p className="text-sm text-gray-500">Todas foram vinculadas! 🎉</p>
                </div>
              )}
            </div>
          )}

          {/* Tab Content - Sugestões */}
          {activeTab === 'sugestoes' && (
            <div className="p-6">
              {nsusComSugestao.length > 0 ? (
                <div className="overflow-x-auto">
                  <table className="w-full text-sm">
                    <thead className="bg-gray-50 border-b border-gray-200">
                      <tr>
                        <th className="px-6 py-3 text-left font-medium text-gray-700">NSU</th>
                        <th className="px-6 py-3 text-left font-medium text-gray-700">NF Sugerida</th>
                        <th className="px-6 py-3 text-left font-medium text-gray-700">Score</th>
                        <th className="px-6 py-3 text-left font-medium text-gray-700">Diff Valor</th>
                        <th className="px-6 py-3 text-left font-medium text-gray-700">Diff Dias</th>
                        <th className="px-6 py-3 text-right font-medium text-gray-700">Ações</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-200">
                      {nsusComSugestao.map((row: any) => (
                        <tr key={row.id} className="hover:bg-gray-50">
                          <td className="px-6 py-4 font-mono text-gray-900">{row.transacoes_getnet?.nsu}</td>
                          <td className="px-6 py-4 font-mono text-gray-900">{row.titulos_totvs?.numero_nf}</td>
                          <td className="px-6 py-4">
                            <ScoreBar score={row.score_confianca} showDetails={false} />
                          </td>
                          <td className="px-6 py-4 text-gray-600">-</td>
                          <td className="px-6 py-4 text-gray-600">-</td>
                          <td className="px-6 py-4 text-right space-x-2">
                            <Button variant="outline" size="sm">
                              Confirmar
                            </Button>
                            <Button variant="ghost" size="sm">
                              Rejeitar
                            </Button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              ) : (
                <div className="text-center py-12">
                  <TrendingUp className="w-12 h-12 text-yellow-500 mx-auto mb-3 opacity-50" />
                  <p className="text-gray-600 font-medium">Nenhuma sugestão pendente</p>
                  <p className="text-sm text-gray-500">Tudo está confirmado!</p>
                </div>
              )}
            </div>
          )}

          {/* Tab Content - Títulos */}
          {activeTab === 'titulos' && (
            <div className="p-6">
              {titulosSemNsu.length > 0 ? (
                <div className="overflow-x-auto">
                  <table className="w-full text-sm">
                    <thead className="bg-gray-50 border-b border-gray-200">
                      <tr>
                        <th className="px-6 py-3 text-left font-medium text-gray-700">NF</th>
                        <th className="px-6 py-3 text-right font-medium text-gray-700">Valor</th>
                        <th className="px-6 py-3 text-left font-medium text-gray-700">Data Emissão</th>
                        <th className="px-6 py-3 text-left font-medium text-gray-700">Cliente</th>
                        <th className="px-6 py-3 text-left font-medium text-gray-700">Vencimento</th>
                        <th className="px-6 py-3 text-right font-medium text-gray-700">Ação</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-200">
                      {titulosSemNsu.map((row: any) => (
                        <tr key={row.id} className="hover:bg-gray-50">
                          <td className="px-6 py-4 font-mono text-gray-900">{row.numero_nf}</td>
                          <td className="px-6 py-4 text-right text-gray-900 font-medium">
                            R$ {row.valor_liquido?.toFixed(2) || '0.00'}
                          </td>
                          <td className="px-6 py-4 text-gray-600">
                            {new Date(row.data_emissao).toLocaleDateString('pt-BR')}
                          </td>
                          <td className="px-6 py-4 text-gray-600">{row.cliente_nome}</td>
                          <td className="px-6 py-4">
                            <DiasBadge dias={Math.floor((new Date(row.data_vencimento).getTime() - new Date().getTime()) / (1000 * 60 * 60 * 24))} />
                          </td>
                          <td className="px-6 py-4 text-right">
                            <Button variant="outline" size="sm">
                              Vincular NSU
                            </Button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              ) : (
                <div className="text-center py-12">
                  <CheckCircle2 className="w-12 h-12 text-emerald-500 mx-auto mb-3 opacity-50" />
                  <p className="text-gray-600 font-medium">Nenhum título pendente</p>
                  <p className="text-sm text-gray-500">Todos estão vinculados!</p>
                </div>
              )}
            </div>
          )}

          {/* Tab Content - Conciliados */}
          {activeTab === 'conciliados' && (
            <div className="p-6">
              {ultimasConciliacoes.length > 0 ? (
                <div className="overflow-x-auto">
                  <table className="w-full text-sm">
                    <thead className="bg-gray-50 border-b border-gray-200">
                      <tr>
                        <th className="px-6 py-3 text-left font-medium text-gray-700">NSU</th>
                        <th className="px-6 py-3 text-left font-medium text-gray-700">NF</th>
                        <th className="px-6 py-3 text-left font-medium text-gray-700">Bandeira</th>
                        <th className="px-6 py-3 text-right font-medium text-gray-700">Valor</th>
                        <th className="px-6 py-3 text-left font-medium text-gray-700">Data</th>
                        <th className="px-6 py-3 text-left font-medium text-gray-700">Usuário</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-200">
                      {ultimasConciliacoes.map((row: any) => (
                        <tr key={row.id} className="hover:bg-gray-50">
                          <td className="px-6 py-4 font-mono text-gray-900">{row.transacoes_getnet?.nsu}</td>
                          <td className="px-6 py-4 font-mono text-gray-900">{row.titulos_totvs?.numero_nf}</td>
                          <td className="px-6 py-4">
                            <BandeiraBadge bandeira={row.transacoes_getnet?.bandeira || 'Unknown'} />
                          </td>
                          <td className="px-6 py-4 text-right text-gray-900 font-medium">
                            R$ {row.titulos_totvs?.valor_liquido?.toFixed(2) || '0.00'}
                          </td>
                          <td className="px-6 py-4 text-gray-600">
                            {new Date(row.created_at).toLocaleDateString('pt-BR')}
                          </td>
                          <td className="px-6 py-4 text-gray-600 text-sm">
                            {row.users?.email?.split('@')[0] || 'Sistema'}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              ) : (
                <div className="text-center py-12">
                  <CheckCircle2 className="w-12 h-12 text-emerald-500 mx-auto mb-3 opacity-50" />
                  <p className="text-gray-600 font-medium">Nenhuma conciliação recente</p>
                </div>
              )}
            </div>
          )}
        </div>
      </main>

      {/* Modals */}
      {activeModal !== 'none' && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-xl shadow-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between p-6 border-b border-gray-200 sticky top-0 bg-white">
              <h2 className="text-lg font-bold text-gray-900">
                {activeModal === 'nsu-sem-vinculo' && 'Lançar NSU SEM Vínculo'}
                {activeModal === 'nsu-com-vinculo' && `Lançar NSU COM Vínculo - Step ${wizardStep} de 3`}
                {activeModal === 'buscar-pendente' && 'Buscar NSU Pendente'}
              </h2>
              <button
                onClick={() => setActiveModal('none')}
                className="p-1 hover:bg-gray-100 rounded-lg transition"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="p-6">
              {activeModal === 'nsu-sem-vinculo' && (
                <NsuSemVinculoModal
                  filialCnpj={user?.email || ''}
                  onClose={() => setActiveModal('none')}
                  onSuccess={() => {
                    setActiveModal('none');
                    window.location.reload();
                  }}
                />
              )}

              {activeModal === 'nsu-com-vinculo' && (
                <NsuComVinculoModal
                  filialCnpj={user?.email || ''}
                  step={wizardStep}
                  onStepChange={setWizardStep}
                  onClose={() => setActiveModal('none')}
                  onSuccess={() => {
                    setActiveModal('none');
                    window.location.reload();
                  }}
                />
              )}

              {activeModal === 'buscar-pendente' && (
                <BuscarNsuPendenteModal
                  filialCnpj={user?.email || ''}
                  onClose={() => setActiveModal('none')}
                  onSelectNsu={(nsu) => console.log('NSU selecionada:', nsu)}
                  onOpenWizard={() => {
                    setActiveModal('nsu-com-vinculo');
                    setWizardStep(2);
                  }}
                />
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export const dynamic = 'force-dynamic';
