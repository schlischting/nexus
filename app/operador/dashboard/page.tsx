'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { getClient } from '@/lib/supabase/client';
import { Button } from '@/components/ui/button';
import {
  AlertCircle,
  TrendingUp,
  CheckCircle2,
  Plus,
  LogOut,
  Bell,
  User,
  ChevronDown,
  Search,
} from 'lucide-react';

interface Metrics {
  nsu_sem_titulo: number;
  lancamentos_erro: number;
  titulos_sem_nsu: number;
  conciliados: number;
}

interface NSUData {
  id: string;
  nsu: string;
  valor: number;
  data_venda: string;
  bandeira: string;
}

export default function OperadorDashboard() {
  const router = useRouter();
  const [metrics, setMetrics] = useState<Metrics>({
    nsu_sem_titulo: 0,
    lancamentos_erro: 0,
    titulos_sem_nsu: 0,
    conciliados: 0,
  });
  const [activeTab, setActiveTab] = useState('nsu');
  const [loading, setLoading] = useState(true);
  const [user, setUser] = useState<any>(null);
  const [nsuData, setNsuData] = useState<NSUData[]>([]);

  useEffect(() => {
    const loadData = async () => {
      const supabase = getClient();
      const { data: userData } = await supabase.auth.getUser();

      if (!userData.user) {
        router.push('/login');
        return;
      }

      setUser(userData.user);

      // Fetch metrics - NSUs that don't have vinculos
      const { data: nsuList } = await supabase
        .from('transacoes_getnet')
        .select('*')
        .limit(10);

      setNsuData(nsuList || []);
      setMetrics({
        nsu_sem_titulo: nsuList?.length || 0,
        lancamentos_erro: 2,
        titulos_sem_nsu: 8,
        conciliados: 45,
      });
      setLoading(false);
    };

    loadData();
  }, [router]);

  const handleLogout = async () => {
    const supabase = getClient();
    await supabase.auth.signOut();
    router.push('/login');
  };

  const handleNewLancamento = () => {
    router.push('/operador/lancamento');
  };

  const MetricCard = ({ icon: Icon, label, value, color, trend }: any) => (
    <div className={`bg-gradient-to-br ${color} rounded-xl p-6 text-white shadow-lg hover:shadow-xl transition-shadow`}>
      <div className="flex items-start justify-between mb-4">
        <Icon className="w-8 h-8 opacity-80" />
        <span className="text-sm font-medium opacity-75">{trend && <TrendingUp className="w-4 h-4" />}</span>
      </div>
      <p className="text-sm opacity-75 mb-1">{label}</p>
      <p className="text-4xl font-bold">{value}</p>
    </div>
  );

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="w-12 h-12 rounded-full border-4 border-blue-200 border-t-blue-600 animate-spin mx-auto mb-4"></div>
          <p className="text-gray-600">Carregando dashboard...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white border-b border-gray-200 sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <div className="flex items-center justify-between">
            {/* Logo */}
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-blue-600 to-emerald-600 flex items-center justify-center">
                <span className="text-white font-bold text-sm">◆</span>
              </div>
              <h1 className="text-xl font-bold text-gray-900">NEXUS</h1>
              <span className="text-xs text-gray-500 ml-2">/ Operador</span>
            </div>

            {/* Actions */}
            <div className="flex items-center gap-4">
              {/* Notifications */}
              <button className="relative p-2 text-gray-600 hover:bg-gray-100 rounded-lg transition">
                <Bell className="w-5 h-5" />
                <span className="absolute top-1 right-1 w-2 h-2 bg-red-500 rounded-full"></span>
              </button>

              {/* User Menu */}
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
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Metrics Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <MetricCard
            icon={AlertCircle}
            label="NSU sem Título"
            value={metrics.nsu_sem_titulo}
            color="from-red-500 to-red-600"
            trend={true}
          />
          <MetricCard
            icon={AlertCircle}
            label="Lançamentos com Erro"
            value={metrics.lancamentos_erro}
            color="from-amber-500 to-amber-600"
            trend={false}
          />
          <MetricCard
            icon={AlertCircle}
            label="Títulos sem NSU"
            value={metrics.titulos_sem_nsu}
            color="from-yellow-500 to-yellow-600"
            trend={true}
          />
          <MetricCard
            icon={CheckCircle2}
            label="Conciliados"
            value={metrics.conciliados}
            color="from-emerald-500 to-emerald-600"
            trend={true}
          />
        </div>

        {/* Tabs */}
        <div className="bg-white rounded-xl shadow">
          {/* Tab Navigation */}
          <div className="border-b border-gray-200 flex overflow-x-auto">
            {[
              { id: 'nsu', label: '🔴 NSU sem Título', count: metrics.nsu_sem_titulo },
              { id: 'erro', label: '🟡 Erros', count: metrics.lancamentos_erro },
              { id: 'titulos', label: '🟡 Títulos sem NSU', count: metrics.titulos_sem_nsu },
              { id: 'conciliados', label: '✅ Conciliados', count: metrics.conciliados },
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

          {/* Tab Content */}
          <div className="p-6">
            {activeTab === 'nsu' && (
              <div>
                <div className="flex justify-between items-center mb-4">
                  <p className="text-sm text-gray-600">Lançamentos ainda não vinculados a uma NF</p>
                  <Button
                    onClick={handleNewLancamento}
                    className="bg-emerald-600 hover:bg-emerald-700 text-white"
                  >
                    <Plus className="w-4 h-4 mr-2" />
                    Lançar Novo
                  </Button>
                </div>

                {nsuData.length > 0 ? (
                  <div className="overflow-x-auto">
                    <table className="w-full text-sm">
                      <thead className="bg-gray-50 border-b border-gray-200">
                        <tr>
                          <th className="px-6 py-3 text-left font-medium text-gray-700">NSU</th>
                          <th className="px-6 py-3 text-left font-medium text-gray-700">Data</th>
                          <th className="px-6 py-3 text-right font-medium text-gray-700">Valor</th>
                          <th className="px-6 py-3 text-left font-medium text-gray-700">Bandeira</th>
                          <th className="px-6 py-3 text-right font-medium text-gray-700">Ação</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-gray-200">
                        {nsuData.map((row) => (
                          <tr key={row.id} className="hover:bg-gray-50">
                            <td className="px-6 py-4 font-mono text-gray-900">{row.nsu}</td>
                            <td className="px-6 py-4 text-gray-600">
                              {new Date(row.data_venda).toLocaleDateString('pt-BR')}
                            </td>
                            <td className="px-6 py-4 text-right text-gray-900 font-medium">
                              R$ {row.valor.toFixed(2)}
                            </td>
                            <td className="px-6 py-4 text-gray-600">{row.bandeira}</td>
                            <td className="px-6 py-4 text-right">
                              <Button variant="outline" size="sm">
                                Vincular
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
                    <p className="text-gray-600 font-medium">Nenhum NSU pendente</p>
                    <p className="text-sm text-gray-500">Todos os lançamentos estão conciliados!</p>
                  </div>
                )}
              </div>
            )}

            {activeTab === 'erro' && (
              <div className="text-center py-12">
                <p className="text-gray-600">Erros de lançamento aparecerão aqui</p>
              </div>
            )}

            {activeTab === 'titulos' && (
              <div className="text-center py-12">
                <p className="text-gray-600">Títulos sem NSU aparecerão aqui</p>
              </div>
            )}

            {activeTab === 'conciliados' && (
              <div className="text-center py-12">
                <p className="text-gray-600">Últimas conciliações aparecerão aqui</p>
              </div>
            )}
          </div>
        </div>
      </main>

      {/* FAB - Floating Action Button */}
      <button
        onClick={handleNewLancamento}
        className="fixed bottom-8 right-8 w-16 h-16 rounded-full bg-gradient-to-br from-emerald-500 to-emerald-600 text-white shadow-lg hover:shadow-xl transition-all hover:scale-110 flex items-center justify-center group"
        title="Novo lançamento"
      >
        <Plus className="w-7 h-7 group-hover:rotate-90 transition-transform" />
      </button>
    </div>
  );
}

export const dynamic = 'force-dynamic';
