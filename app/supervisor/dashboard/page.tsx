'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { getClient } from '@/lib/supabase/client';
import { Button } from '@/components/ui/button';
import {
  CheckCircle2,
  AlertCircle,
  TrendingUp,
  Download,
  LogOut,
  Bell,
  Building2,
  Zap,
} from 'lucide-react';
import { toast } from 'sonner';

interface Match {
  id: string;
  nsu: string;
  nf_numero: string;
  score_confianca: number;
  valor: number;
}

interface Gap {
  filial_cnpj: string;
  razao_social: string;
  nsu_sem_titulo: number;
  titulo_sem_nsu: number;
}

export default function SupervisorDashboard() {
  const router = useRouter();
  const [activeTab, setActiveTab] = useState('matches');
  const [loading, setLoading] = useState(true);
  const [user, setUser] = useState<any>(null);
  const [matches, setMatches] = useState<Match[]>([]);
  const [suggestions, setSuggestions] = useState<Match[]>([]);
  const [gaps, setGaps] = useState<Gap[]>([]);

  useEffect(() => {
    const loadData = async () => {
      const supabase = getClient();
      const { data: userData } = await supabase.auth.getUser();

      if (!userData.user) {
        router.push('/login');
        return;
      }

      setUser(userData.user);

      // Fetch matches (score > 0.95)
      const { data: matchesData } = await supabase
        .from('vinculos')
        .select('*')
        .gte('score_confianca', 0.95)
        .limit(10);

      // Fetch suggestions (0.75-0.95)
      const { data: suggestionsData } = await supabase
        .from('vinculos')
        .select('*')
        .gte('score_confianca', 0.75)
        .lt('score_confianca', 0.95)
        .limit(10);

      // Fetch gaps
      const { data: filiais } = await supabase
        .from('filiais')
        .select('cnpj, razao_social');

      const gapsData: Gap[] = [];
      for (const f of filiais || []) {
        const { data: nsuCount } = await supabase
          .from('transacoes_getnet')
          .select('id')
          .eq('filial_cnpj', f.cnpj)
          .is('titulo_id', null);

        const { data: nfCount } = await supabase
          .from('titulos_totvs')
          .select('id')
          .eq('filial_cnpj', f.cnpj)
          .is('transacao_id', null);

        gapsData.push({
          filial_cnpj: f.cnpj,
          razao_social: f.razao_social,
          nsu_sem_titulo: nsuCount?.length || 0,
          titulo_sem_nsu: nfCount?.length || 0,
        });
      }

      setMatches(matchesData || []);
      setSuggestions(suggestionsData || []);
      setGaps(gapsData);
      setLoading(false);
    };

    loadData();
  }, [router]);

  const handleLogout = async () => {
    const supabase = getClient();
    await supabase.auth.signOut();
    router.push('/login');
  };

  const handleExport = async () => {
    toast.loading('Exportando para TOTVS...');
    setTimeout(() => {
      toast.success('Exportado com sucesso!');
    }, 2000);
  };

  const MatchCard = ({ match, isSuggestion }: { match: Match; isSuggestion?: boolean }) => (
    <div className={`bg-white rounded-lg shadow p-4 border-l-4 ${
      isSuggestion ? 'border-amber-500' : 'border-emerald-500'
    }`}>
      <div className="flex items-start justify-between mb-3">
        <div>
          <p className="font-mono font-bold text-gray-900">{match.nsu}</p>
          <p className="text-sm text-gray-600">→ {match.nf_numero}</p>
        </div>
        <span className={`text-sm font-bold px-3 py-1 rounded-full ${
          isSuggestion
            ? 'bg-amber-100 text-amber-800'
            : 'bg-emerald-100 text-emerald-800'
        }`}>
          {(match.score_confianca * 100).toFixed(0)}%
        </span>
      </div>

      <div className="mb-3 bg-gray-50 p-2 rounded">
        <div className="h-2 bg-gray-200 rounded-full overflow-hidden">
          <div
            className={`h-full ${isSuggestion ? 'bg-amber-500' : 'bg-emerald-500'}`}
            style={{ width: `${match.score_confianca * 100}%` }}
          />
        </div>
      </div>

      <p className="text-sm text-gray-600 mb-3">
        Valor: <span className="font-semibold text-gray-900">R$ {match.valor.toFixed(2)}</span>
      </p>

      <div className="flex gap-2">
        <Button size="sm" className="flex-1 bg-emerald-600 hover:bg-emerald-700 text-white">
          {isSuggestion ? 'Confirmar' : '✓ Confirmado'}
        </Button>
        {isSuggestion && (
          <Button size="sm" variant="outline" className="flex-1">
            Rejeitar
          </Button>
        )}
      </div>
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
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-blue-600 to-emerald-600 flex items-center justify-center">
                <span className="text-white font-bold text-sm">◆</span>
              </div>
              <h1 className="text-xl font-bold text-gray-900">NEXUS</h1>
              <span className="text-xs text-gray-500 ml-2">/ Supervisor</span>
            </div>

            <div className="flex items-center gap-4">
              <button className="relative p-2 text-gray-600 hover:bg-gray-100 rounded-lg transition">
                <Bell className="w-5 h-5" />
                <span className="absolute top-1 right-1 w-2 h-2 bg-red-500 rounded-full"></span>
              </button>

              <div className="flex items-center gap-3 pl-4 border-l border-gray-200">
                <div className="text-right hidden sm:block">
                  <p className="text-sm font-medium text-gray-900">{user?.email?.split('@')[0]}</p>
                  <p className="text-xs text-gray-500">Supervisor</p>
                </div>
                <button
                  onClick={handleLogout}
                  className="p-2 text-gray-600 hover:bg-red-50 hover:text-red-600 rounded-lg transition"
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
        {/* Summary Cards */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
          <div className="bg-gradient-to-br from-emerald-500 to-emerald-600 rounded-xl p-6 text-white shadow-lg">
            <p className="text-sm opacity-75 mb-2">Matches Automáticos</p>
            <p className="text-4xl font-bold">{matches.length}</p>
            <p className="text-xs opacity-75 mt-2">Score {`>`} 95%</p>
          </div>

          <div className="bg-gradient-to-br from-amber-500 to-amber-600 rounded-xl p-6 text-white shadow-lg">
            <p className="text-sm opacity-75 mb-2">Sugestões Pendentes</p>
            <p className="text-4xl font-bold">{suggestions.length}</p>
            <p className="text-xs opacity-75 mt-2">Score 75-95%</p>
          </div>

          <div className="bg-gradient-to-br from-red-500 to-red-600 rounded-xl p-6 text-white shadow-lg">
            <p className="text-sm opacity-75 mb-2">Gaps Abertos</p>
            <p className="text-4xl font-bold">
              {gaps.reduce((acc, g) => acc + g.nsu_sem_titulo + g.titulo_sem_nsu, 0)}
            </p>
            <p className="text-xs opacity-75 mt-2">Total por resolver</p>
          </div>
        </div>

        {/* Tabs */}
        <div className="bg-white rounded-xl shadow">
          {/* Tab Navigation */}
          <div className="border-b border-gray-200 flex overflow-x-auto">
            {[
              { id: 'matches', label: '✅ Matches Automáticos', icon: CheckCircle2 },
              { id: 'suggestions', label: '🟡 Sugestões Pendentes', icon: AlertCircle },
              { id: 'gaps', label: '🔴 Gaps Abertos', icon: TrendingUp },
              { id: 'errors', label: '⚠️ Erros de Baixa', icon: Zap },
            ].map((tab) => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`flex items-center gap-2 px-6 py-4 text-sm font-medium border-b-2 transition-colors whitespace-nowrap ${
                  activeTab === tab.id
                    ? 'border-blue-600 text-blue-600'
                    : 'border-transparent text-gray-600 hover:text-gray-900'
                }`}
              >
                <tab.icon className="w-4 h-4" />
                {tab.label}
              </button>
            ))}
          </div>

          {/* Tab Content */}
          <div className="p-6">
            {activeTab === 'matches' && (
              <div>
                <div className="flex justify-between items-center mb-6">
                  <p className="text-sm text-gray-600">
                    Matches com confiança {`>`} 95% prontos para confirmação em lote
                  </p>
                  <Button className="bg-emerald-600 hover:bg-emerald-700">
                    Confirmar {matches.length} em Lote
                  </Button>
                </div>

                {matches.length > 0 ? (
                  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                    {matches.map((match) => (
                      <MatchCard key={match.id} match={match} />
                    ))}
                  </div>
                ) : (
                  <div className="text-center py-12">
                    <CheckCircle2 className="w-12 h-12 text-emerald-500 mx-auto mb-3 opacity-50" />
                    <p className="text-gray-600">Nenhum match automático no momento</p>
                  </div>
                )}
              </div>
            )}

            {activeTab === 'suggestions' && (
              <div>
                <p className="text-sm text-gray-600 mb-6">
                  Sugestões com confiança entre 75-95% que precisam de revisão
                </p>

                {suggestions.length > 0 ? (
                  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                    {suggestions.map((match) => (
                      <MatchCard key={match.id} match={match} isSuggestion />
                    ))}
                  </div>
                ) : (
                  <div className="text-center py-12">
                    <AlertCircle className="w-12 h-12 text-amber-500 mx-auto mb-3 opacity-50" />
                    <p className="text-gray-600">Nenhuma sugestão pendente</p>
                  </div>
                )}
              </div>
            )}

            {activeTab === 'gaps' && (
              <div>
                <div className="overflow-x-auto">
                  <table className="w-full text-sm">
                    <thead className="bg-gray-50 border-b border-gray-200">
                      <tr>
                        <th className="px-6 py-3 text-left font-medium text-gray-700">Filial</th>
                        <th className="px-6 py-3 text-center font-medium text-gray-700">
                          NSU sem Título
                        </th>
                        <th className="px-6 py-3 text-center font-medium text-gray-700">
                          Título sem NSU
                        </th>
                        <th className="px-6 py-3 text-center font-medium text-gray-700">Total</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-200">
                      {gaps.map((gap) => (
                        <tr key={gap.filial_cnpj} className="hover:bg-gray-50">
                          <td className="px-6 py-4 text-gray-900 font-medium">{gap.razao_social}</td>
                          <td className="px-6 py-4 text-center">
                            <span className={`inline-block px-3 py-1 rounded-full text-sm font-bold ${
                              gap.nsu_sem_titulo > 0
                                ? 'bg-red-100 text-red-800'
                                : 'bg-emerald-100 text-emerald-800'
                            }`}>
                              {gap.nsu_sem_titulo}
                            </span>
                          </td>
                          <td className="px-6 py-4 text-center">
                            <span className={`inline-block px-3 py-1 rounded-full text-sm font-bold ${
                              gap.titulo_sem_nsu > 0
                                ? 'bg-amber-100 text-amber-800'
                                : 'bg-emerald-100 text-emerald-800'
                            }`}>
                              {gap.titulo_sem_nsu}
                            </span>
                          </td>
                          <td className="px-6 py-4 text-center text-gray-900 font-bold">
                            {gap.nsu_sem_titulo + gap.titulo_sem_nsu}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            )}

            {activeTab === 'errors' && (
              <div className="text-center py-12">
                <Zap className="w-12 h-12 text-orange-500 mx-auto mb-3 opacity-50" />
                <p className="text-gray-600">Nenhum erro de baixa no momento</p>
              </div>
            )}
          </div>
        </div>

        {/* Export Button */}
        <div className="mt-8 flex justify-center">
          <Button
            onClick={handleExport}
            className="bg-blue-600 hover:bg-blue-700 text-white px-8"
          >
            <Download className="w-4 h-4 mr-2" />
            📤 Exportar para TOTVS
          </Button>
        </div>
      </main>
    </div>
  );
}

export const dynamic = 'force-dynamic';
