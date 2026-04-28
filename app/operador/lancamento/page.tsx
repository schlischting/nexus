'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { getClient } from '@/lib/supabase/client';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import {
  Search,
  FileText,
  CheckCircle,
  ChevronRight,
  ArrowLeft,
  Loader2,
} from 'lucide-react';
import { toast } from 'sonner';

type Step = 1 | 2 | 3;

interface NSUData {
  id: string;
  nsu: string;
  valor: number;
  data_venda: string;
  bandeira: string;
}

export default function LancamentoPage() {
  const router = useRouter();
  const [step, setStep] = useState<Step>(1);
  const [loading, setLoading] = useState(false);
  const [nsuSearch, setNsuSearch] = useState('');
  const [nsuData, setNsuData] = useState<NSUData | null>(null);
  const [nfNumber, setNfNumber] = useState('');
  const [modalidade, setModalidade] = useState('credito');
  const [parcelas, setParcelas] = useState('1');
  const [score, setScore] = useState(85);

  const supabase = getClient();

  const handleSearchNSU = async (searchValue?: string) => {
    const value = searchValue !== undefined ? searchValue : nsuSearch;

    if (!value.trim()) {
      setNsuData(null);
      return;
    }

    setLoading(true);
    try {
      const response = await fetch(`/api/search/nsu?q=${encodeURIComponent(value)}`);
      const json = await response.json();

      if (!response.ok) {
        toast.error('Erro ao buscar NSU');
        setNsuData(null);
      } else if (json.transacoes && json.transacoes.length > 0) {
        setNsuData(json.transacoes[0]);
        toast.success('NSU encontrado!');
      } else {
        toast.error('NSU não encontrado');
        setNsuData(null);
      }
    } catch (error) {
      toast.error('Erro ao buscar NSU');
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  const debounceSearch = (value: string) => {
    setNsuSearch(value);
    const timer = setTimeout(() => {
      handleSearchNSU(value);
    }, 300);
    return () => clearTimeout(timer);
  };

  const handleNext = () => {
    if (step === 1 && !nsuData) {
      toast.error('Selecione um NSU para continuar');
      return;
    }
    if (step === 2 && !nfNumber.trim()) {
      toast.error('Digite o número da NF');
      return;
    }
    if (step < 3) setStep((step + 1) as Step);
  };

  const handleConfirm = async () => {
    setLoading(true);
    try {
      const { error } = await supabase.from('vinculos').insert({
        transacao_id: nsuData?.id,
        nsu: nsuData?.nsu,
        nf_numero: nfNumber,
        modalidade,
        parcelas: parseInt(parcelas),
        score_confianca: score / 100,
        status: 'confirmado',
      });

      if (error) throw error;

      toast.success('Lançamento confirmado com sucesso!');
      setTimeout(() => router.push('/operador/dashboard'), 1500);
    } catch (error) {
      toast.error('Erro ao confirmar lançamento');
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 py-8 px-4">
      <div className="max-w-2xl mx-auto">
        {/* Header */}
        <div className="mb-8">
          <Button
            variant="ghost"
            onClick={() => router.back()}
            className="mb-4"
          >
            <ArrowLeft className="w-4 h-4 mr-2" />
            Voltar
          </Button>
          <h1 className="text-3xl font-bold text-gray-900 mb-2">Novo Lançamento</h1>
          <p className="text-gray-600">Vincule um NSU a uma Nota Fiscal em 3 passos</p>
        </div>

        {/* Stepper */}
        <div className="bg-white rounded-xl shadow p-8 mb-8">
          {/* Step Indicator */}
          <div className="flex items-center justify-between mb-12">
            {[
              { num: 1, label: 'Buscar NSU', icon: Search },
              { num: 2, label: 'Vincular NF', icon: FileText },
              { num: 3, label: 'Confirmar', icon: CheckCircle },
            ].map((s, i) => (
              <div key={s.num} className="flex items-center">
                <div
                  className={`w-12 h-12 rounded-full flex items-center justify-center font-bold transition-all ${
                    step >= s.num
                      ? 'bg-gradient-to-r from-blue-600 to-indigo-600 text-white'
                      : 'bg-gray-200 text-gray-600'
                  }`}
                >
                  {step > s.num ? (
                    <CheckCircle className="w-6 h-6" />
                  ) : (
                    <s.icon className="w-6 h-6" />
                  )}
                </div>
                <span
                  className={`text-sm font-medium ml-2 ${
                    step >= s.num ? 'text-gray-900' : 'text-gray-500'
                  }`}
                >
                  {s.label}
                </span>
                {i < 2 && (
                  <ChevronRight
                    className={`w-5 h-5 mx-4 ${
                      step > s.num ? 'text-blue-600' : 'text-gray-300'
                    }`}
                  />
                )}
              </div>
            ))}
          </div>

          {/* Step Content */}
          <div className="min-h-64">
            {/* Step 1: Buscar NSU */}
            {step === 1 && (
              <div className="space-y-6">
                <h2 className="text-xl font-bold text-gray-900">🔍 Buscar NSU</h2>
                <div className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Número do NSU
                    </label>
                    <Input
                      type="text"
                      placeholder="Digite o NSU (busca automática)..."
                      value={nsuSearch}
                      onChange={(e) => debounceSearch(e.target.value)}
                      disabled={loading}
                      className="flex-1 bg-white text-gray-900 placeholder-gray-500"
                    />
                  </div>

                  {nsuData && (
                    <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 space-y-2">
                      <p className="text-sm text-gray-600">
                        <span className="font-semibold">NSU:</span> {nsuData.nsu}
                      </p>
                      <p className="text-sm text-gray-600">
                        <span className="font-semibold">Valor:</span> R$ {nsuData.valor.toFixed(2)}
                      </p>
                      <p className="text-sm text-gray-600">
                        <span className="font-semibold">Data:</span>{' '}
                        {new Date(nsuData.data_venda).toLocaleDateString('pt-BR')}
                      </p>
                      <p className="text-sm text-gray-600">
                        <span className="font-semibold">Bandeira:</span> {nsuData.bandeira}
                      </p>
                    </div>
                  )}
                </div>
              </div>
            )}

            {/* Step 2: Vincular NF */}
            {step === 2 && (
              <div className="space-y-6">
                <h2 className="text-xl font-bold text-gray-900">📋 Vincular Nota Fiscal</h2>
                <div className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Número da NF
                    </label>
                    <Input
                      type="text"
                      placeholder="NF-001234"
                      value={nfNumber}
                      onChange={(e) => setNfNumber(e.target.value)}
                      className="w-full bg-white text-gray-900 placeholder-gray-500 border border-gray-300"
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Modalidade
                    </label>
                    <select
                      value={modalidade}
                      onChange={(e) => setModalidade(e.target.value)}
                      className="w-full px-3 py-2 bg-white text-gray-900 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-600 focus:border-transparent"
                    >
                      <option value="debito">Débito</option>
                      <option value="credito">Crédito</option>
                      <option value="credito_parcelado">Crédito Parcelado</option>
                    </select>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Número de Parcelas
                    </label>
                    <Input
                      type="number"
                      min="1"
                      max="12"
                      value={parcelas}
                      onChange={(e) => setParcelas(e.target.value)}
                      className="w-full bg-white text-gray-900 placeholder-gray-500 border border-gray-300"
                    />
                  </div>

                  <div className="bg-indigo-50 border border-indigo-200 rounded-lg p-4">
                    <p className="text-sm text-gray-700">
                      <span className="font-semibold text-indigo-900">Score de Correspondência:</span>
                    </p>
                    <div className="mt-2 flex items-center gap-3">
                      <div className="flex-1 h-2 bg-gray-200 rounded-full overflow-hidden">
                        <div
                          className="h-full bg-gradient-to-r from-green-500 to-emerald-600"
                          style={{ width: `${score}%` }}
                        ></div>
                      </div>
                      <span className="text-lg font-bold text-indigo-900">{score}%</span>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* Step 3: Confirmar */}
            {step === 3 && (
              <div className="space-y-6">
                <h2 className="text-xl font-bold text-gray-900">✓ Confirmar Lançamento</h2>
                <div className="space-y-4">
                  <div className="bg-gradient-to-br from-blue-50 to-indigo-50 border border-blue-200 rounded-lg p-6 space-y-4">
                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <p className="text-xs font-medium text-gray-600 uppercase tracking-wide">NSU</p>
                        <p className="text-2xl font-bold text-gray-900 mt-1">{nsuData?.nsu}</p>
                      </div>
                      <div className="text-right">
                        <p className="text-xs font-medium text-gray-600 uppercase tracking-wide">NF</p>
                        <p className="text-2xl font-bold text-gray-900 mt-1">{nfNumber}</p>
                      </div>
                    </div>

                    <div className="border-t border-blue-200 pt-4">
                      <div className="flex justify-between items-center mb-3">
                        <p className="text-sm text-gray-700">Modalidade:</p>
                        <p className="font-semibold text-gray-900 capitalize">{modalidade}</p>
                      </div>
                      <div className="flex justify-between items-center mb-3">
                        <p className="text-sm text-gray-700">Parcelas:</p>
                        <p className="font-semibold text-gray-900">{parcelas}x</p>
                      </div>
                      <div className="flex justify-between items-center">
                        <p className="text-sm text-gray-700">Score:</p>
                        <span className="inline-block bg-gradient-to-r from-green-400 to-emerald-600 text-white px-3 py-1 rounded-full text-sm font-bold">
                          {score}%
                        </span>
                      </div>
                    </div>

                    <div className="border-t border-blue-200 pt-4">
                      <p className="text-sm text-gray-700 font-medium mb-1">Valor:</p>
                      <p className="text-3xl font-bold text-emerald-600">
                        R$ {nsuData?.valor.toFixed(2)}
                      </p>
                    </div>
                  </div>

                  <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
                    <p className="text-sm text-yellow-800">
                      <span className="font-semibold">⚠️ Aviso:</span> Ao confirmar, este lançamento será marcado como conciliado.
                    </p>
                  </div>
                </div>
              </div>
            )}
          </div>

          {/* Action Buttons */}
          <div className="flex gap-4 mt-12 pt-8 border-t border-gray-200">
            <Button
              onClick={() => {
                if (step > 1) setStep((step - 1) as Step);
                else router.back();
              }}
              disabled={loading}
              className="bg-gray-500 hover:bg-gray-600 text-white"
            >
              {step === 1 ? 'Cancelar' : 'Voltar'}
            </Button>

            {step < 3 ? (
              <Button
                onClick={handleNext}
                disabled={loading || (step === 1 && !nsuData)}
                className="flex-1 bg-blue-600 hover:bg-blue-700"
              >
                Próximo <ChevronRight className="w-4 h-4 ml-2" />
              </Button>
            ) : (
              <Button
                onClick={handleConfirm}
                disabled={loading}
                className="flex-1 bg-emerald-600 hover:bg-emerald-700"
              >
                {loading ? (
                  <>
                    <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                    Confirmando...
                  </>
                ) : (
                  <>
                    <CheckCircle className="w-4 h-4 mr-2" />
                    Confirmar Lançamento
                  </>
                )}
              </Button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

export const dynamic = 'force-dynamic';
