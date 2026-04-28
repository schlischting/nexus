'use client';

import { useState } from 'react';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { BandeiraBadge } from '@/components/ui/bandeira-badge';
import { ScoreBar } from '@/components/ui/score-bar';
import { DiasBadge } from '@/components/ui/dias-badge';
import { ArrowLeft, ChevronRight, Loader2, AlertCircle } from 'lucide-react';
import { toast } from 'sonner';
import { criarVinculoComNf } from '@/lib/supabase/queries';
import { getClient } from '@/lib/supabase/client';

interface NsuComVinculoModalProps {
  filialCnpj: string;
  step: 1 | 2 | 3;
  onStepChange: (step: 1 | 2 | 3) => void;
  onClose: () => void;
  onSuccess: () => void;
}

export function NsuComVinculoModal({ filialCnpj, step, onStepChange, onClose, onSuccess }: NsuComVinculoModalProps) {
  const [nsuSearch, setNsuSearch] = useState('');
  const [nsuData, setNsuData] = useState<any>(null);
  const [nfSearch, setNfSearch] = useState('');
  const [nfData, setNfData] = useState<any>(null);
  const [score, setScore] = useState(0);
  const [scoreBreakdown, setScoreBreakdown] = useState<any>(null);
  const [loading, setLoading] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [modalidade, setModalidade] = useState('credito');
  const [parcelas, setParcelas] = useState('1');
  const [observacoes, setObservacoes] = useState('');

  const supabase = getClient();

  // STEP 1: Search NSU
  const handleSearchNSU = async (value: string) => {
    if (!value.trim()) {
      setNsuData(null);
      return;
    }

    setLoading(true);
    try {
      const response = await fetch(`/api/search/nsu?q=${encodeURIComponent(value)}`);
      const data = await response.json();

      if (response.ok && data.transacoes?.length > 0) {
        setNsuData(data.transacoes[0]);
      } else {
        toast.error('NSU não encontrado');
        setNsuData(null);
      }
    } catch (error) {
      toast.error('Erro ao buscar NSU');
    } finally {
      setLoading(false);
    }
  };

  // STEP 2: Search NF and calculate score
  const handleSearchNF = async (value: string) => {
    setNfSearch(value);
    if (!value.trim()) {
      setNfData(null);
      setScore(0);
      return;
    }

    setLoading(true);
    try {
      const response = await fetch(`/api/search/nf?q=${encodeURIComponent(value)}`);
      const data = await response.json();

      if (response.ok && data.titulos?.length > 0) {
        const nf = data.titulos[0];
        setNfData(nf);

        // Calculate score
        if (nsuData) {
          const scoreResponse = await fetch('/api/vinculos/calculate-score', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ nsu_id: nsuData.id, nf_id: nf.id }),
          });

          const scoreData = await scoreResponse.json();
          setScore(scoreData.score);
          setScoreBreakdown(scoreData.breakdown);
        }
      } else {
        toast.error('NF não encontrada');
        setNfData(null);
      }
    } catch (error) {
      toast.error('Erro ao buscar NF');
    } finally {
      setLoading(false);
    }
  };

  // STEP 3: Submit
  const handleConfirm = async () => {
    if (!nsuData || !nfData) {
      toast.error('Selecione NSU e NF');
      return;
    }

    setSubmitting(true);
    try {
      await criarVinculoComNf(
        nsuData.id,
        nfData.id,
        filialCnpj,
        score,
        observacoes,
        modalidade,
        parseInt(parcelas)
      );

      const status = score > 0.95 ? 'confirmado' : score >= 0.75 ? 'sugerido' : 'rejeitado';
      toast.success(`Vínculo criado! Status: ${status}`);
      onSuccess();
      onClose();
    } catch (error) {
      toast.error('Erro ao criar vínculo');
      console.error(error);
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="space-y-6">
      {/* Stepper */}
      <div className="flex items-center justify-between mb-8">
        {[1, 2, 3].map((s) => (
          <div key={s} className="flex items-center">
            <div
              className={`w-10 h-10 rounded-full flex items-center justify-center font-bold transition-all ${
                step >= s
                  ? 'bg-gradient-to-r from-blue-600 to-indigo-600 text-white'
                  : 'bg-gray-200 text-gray-600'
              }`}
            >
              {s}
            </div>
            {s < 3 && (
              <div
                className={`flex-1 h-1 mx-2 transition-all ${
                  step > s ? 'bg-blue-600' : 'bg-gray-200'
                }`}
              />
            )}
          </div>
        ))}
      </div>

      {/* STEP 1: Search NSU */}
      {step === 1 && (
        <div className="space-y-4">
          <h3 className="text-lg font-bold text-gray-900">🔍 Buscar NSU</h3>

          <div className="space-y-2">
            <label className="block text-sm font-medium text-gray-700">Número do NSU</label>
            <Input
              type="text"
              placeholder="Digite o NSU..."
              value={nsuSearch}
              onChange={(e) => {
                setNsuSearch(e.target.value);
                handleSearchNSU(e.target.value);
              }}
              disabled={loading}
            />
          </div>

          {nsuData && (
            <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 space-y-2">
              <div className="flex justify-between items-start">
                <div>
                  <p className="text-xs text-gray-600">NSU</p>
                  <p className="font-mono font-bold text-gray-900">{nsuData.nsu}</p>
                </div>
                <div className="text-right">
                  <p className="text-xs text-gray-600">Valor</p>
                  <p className="font-bold text-gray-900">R$ {nsuData.valor?.toFixed(2)}</p>
                </div>
              </div>

              <div className="border-t border-blue-200 pt-2 grid grid-cols-2 gap-2 text-sm">
                <div>
                  <p className="text-xs text-gray-600">Bandeira</p>
                  <div className="mt-1">
                    <BandeiraBadge bandeira={nsuData.bandeira} tipo={nsuData.tipo} />
                  </div>
                </div>
                <div className="text-right">
                  <p className="text-xs text-gray-600">Data</p>
                  <p className="text-gray-900">{new Date(nsuData.data_venda).toLocaleDateString('pt-BR')}</p>
                </div>
              </div>
            </div>
          )}

          <div className="flex gap-3 pt-4 border-t border-gray-200">
            <Button onClick={onClose} variant="outline" className="flex-1">
              Cancelar
            </Button>
            <Button
              onClick={() => onStepChange(2)}
              disabled={!nsuData}
              className="flex-1 bg-blue-600 hover:bg-blue-700"
            >
              Próximo <ChevronRight className="w-4 h-4 ml-1" />
            </Button>
          </div>
        </div>
      )}

      {/* STEP 2: Vincular NF + Detalhes */}
      {step === 2 && (
        <div className="space-y-4">
          <h3 className="text-lg font-bold text-gray-900">📋 Vincular NF + Detalhes</h3>

          <div className="space-y-2">
            <label className="block text-sm font-medium text-gray-700">Número da NF</label>
            <Input
              type="text"
              placeholder="Digite a NF..."
              value={nfSearch}
              onChange={(e) => handleSearchNF(e.target.value)}
              disabled={loading}
            />
          </div>

          {nfData && (
            <div className="bg-indigo-50 border border-indigo-200 rounded-lg p-4 space-y-2">
              <div className="flex justify-between items-start">
                <div>
                  <p className="text-xs text-gray-600">NF</p>
                  <p className="font-mono font-bold text-gray-900">{nfData.numero_nf}</p>
                </div>
                <div className="text-right">
                  <p className="text-xs text-gray-600">Valor</p>
                  <p className="font-bold text-gray-900">R$ {nfData.valor?.toFixed(2)}</p>
                </div>
              </div>

              <div className="border-t border-indigo-200 pt-2 space-y-1 text-sm">
                <p><span className="text-gray-600">Cliente:</span> {nfData.cliente_nome}</p>
                <p><span className="text-gray-600">Vencimento:</span> {new Date(nfData.data_vencimento).toLocaleDateString('pt-BR')}</p>
              </div>
            </div>
          )}

          {/* Modalidade */}
          <div className="space-y-2">
            <label className="block text-sm font-medium text-gray-700">Modalidade</label>
            <select
              value={modalidade}
              onChange={(e) => setModalidade(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-600 focus:border-transparent"
            >
              <option value="debito">Débito</option>
              <option value="credito">Crédito</option>
              <option value="credito_parcelado">Crédito Parcelado</option>
            </select>
          </div>

          {(modalidade === 'credito' || modalidade === 'credito_parcelado') && (
            <div className="space-y-2">
              <label className="block text-sm font-medium text-gray-700">Parcelas</label>
              <Input
                type="number"
                min="1"
                max="12"
                value={parcelas}
                onChange={(e) => setParcelas(e.target.value)}
              />
            </div>
          )}

          {/* Score Bar */}
          {nfData && (
            <div className="border-t border-gray-200 pt-4">
              <ScoreBar score={score} breakdown={scoreBreakdown} showDetails={true} />
            </div>
          )}

          {/* Observações */}
          <div className="space-y-2">
            <label className="block text-sm font-medium text-gray-700">Observações (opcional)</label>
            <textarea
              value={observacoes}
              onChange={(e) => setObservacoes(e.target.value)}
              placeholder="Adicione qualquer nota..."
              rows={2}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-600 focus:border-transparent"
            />
          </div>

          <div className="flex gap-3 pt-4 border-t border-gray-200">
            <Button onClick={() => onStepChange(1)} variant="outline" className="flex-1">
              <ArrowLeft className="w-4 h-4 mr-2" /> Voltar
            </Button>
            <Button
              onClick={() => onStepChange(3)}
              disabled={!nfData}
              className="flex-1 bg-blue-600 hover:bg-blue-700"
            >
              Próximo <ChevronRight className="w-4 h-4 ml-1" />
            </Button>
          </div>
        </div>
      )}

      {/* STEP 3: Confirmar */}
      {step === 3 && (
        <div className="space-y-4">
          <h3 className="text-lg font-bold text-gray-900">✓ Confirmar Vínculo</h3>

          {/* Review Card */}
          <div className="bg-gradient-to-br from-blue-50 to-indigo-50 border border-blue-200 rounded-lg p-6 space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-xs text-gray-600 uppercase">NSU</p>
                <p className="text-2xl font-bold text-gray-900 mt-1">{nsuData?.nsu}</p>
              </div>
              <div className="text-right">
                <p className="text-xs text-gray-600 uppercase">NF</p>
                <p className="text-2xl font-bold text-gray-900 mt-1">{nfData?.numero_nf}</p>
              </div>
            </div>

            <div className="border-t border-blue-200 pt-4 space-y-2 text-sm">
              <div className="flex justify-between">
                <span>Bandeira:</span>
                <BandeiraBadge bandeira={nsuData?.bandeira || ''} />
              </div>
              <div className="flex justify-between">
                <span>Modalidade:</span>
                <span className="font-semibold capitalize">{modalidade}</span>
              </div>
              <div className="flex justify-between">
                <span>Parcelas:</span>
                <span className="font-semibold">{parcelas}x</span>
              </div>
            </div>

            <div className="border-t border-blue-200 pt-4">
              <ScoreBar score={score} breakdown={scoreBreakdown} showDetails={true} />
            </div>
          </div>

          {/* Alert for low score */}
          {score < 0.75 && (
            <div className="p-4 bg-yellow-50 border border-yellow-200 rounded-lg flex gap-3">
              <AlertCircle className="w-5 h-5 text-yellow-600 flex-shrink-0 mt-0.5" />
              <div className="text-sm text-yellow-800">
                <p className="font-semibold">Score baixo</p>
                <p>Supervisor pode rejeitar este vínculo.</p>
              </div>
            </div>
          )}

          <div className="flex gap-3 pt-4 border-t border-gray-200">
            <Button onClick={() => onStepChange(2)} variant="outline" className="flex-1">
              <ArrowLeft className="w-4 h-4 mr-2" /> Voltar
            </Button>
            <Button onClick={onClose} variant="ghost" className="flex-1">
              Cancelar
            </Button>
            <Button
              onClick={handleConfirm}
              disabled={submitting}
              className="flex-1 bg-emerald-600 hover:bg-emerald-700"
            >
              {submitting ? <Loader2 className="w-4 h-4 animate-spin mr-2" /> : null}
              Confirmar
            </Button>
          </div>
        </div>
      )}
    </div>
  );
}
