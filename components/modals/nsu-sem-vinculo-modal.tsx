'use client';

import { useState, useEffect } from 'react';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { BandeiraBadge } from '@/components/ui/bandeira-badge';
import { DiasBadge } from '@/components/ui/dias-badge';
import { X, Search, Loader2 } from 'lucide-react';
import { toast } from 'sonner';
import { criarVinculoPendente } from '@/lib/supabase/queries';
import { getClient } from '@/lib/supabase/client';

interface NsuSemVinculoModalProps {
  filialCnpj: string;
  onClose: () => void;
  onSuccess: () => void;
}

export function NsuSemVinculoModal({ filialCnpj, onClose, onSuccess }: NsuSemVinculoModalProps) {
  const [nsuSearch, setNsuSearch] = useState('');
  const [nsuData, setNsuData] = useState<any>(null);
  const [loading, setLoading] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [modalidade, setModalidade] = useState('credito');
  const [parcelas, setParcelas] = useState('1');
  const [observacoes, setObservacoes] = useState('');

  const supabase = getClient();

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
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async () => {
    if (!nsuData) {
      toast.error('Selecione um NSU');
      return;
    }

    setSubmitting(true);
    try {
      await criarVinculoPendente(nsuData.id, filialCnpj, observacoes);
      toast.success('NSU lançada como pendente! Aguardando NF.');
      onSuccess();
      onClose();
    } catch (error) {
      toast.error('Erro ao salvar NSU');
      console.error(error);
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="space-y-6">
      {/* Search */}
      <div className="space-y-3">
        <label className="block text-sm font-medium text-gray-700">Número do NSU</label>
        <div className="flex gap-2">
          <Input
            type="text"
            placeholder="Digite o NSU (busca automática)..."
            value={nsuSearch}
            onChange={(e) => {
              setNsuSearch(e.target.value);
              handleSearchNSU(e.target.value);
            }}
            disabled={loading}
            className="flex-1"
          />
          {loading && <Loader2 className="w-5 h-5 text-blue-600 animate-spin mt-3" />}
        </div>
      </div>

      {/* NSU Data Display */}
      {nsuData && (
        <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 space-y-3">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <p className="text-xs text-gray-600 uppercase tracking-wide">NSU</p>
              <p className="text-lg font-mono font-bold text-gray-900">{nsuData.nsu}</p>
            </div>
            <div>
              <p className="text-xs text-gray-600 uppercase tracking-wide">Valor</p>
              <p className="text-lg font-bold text-gray-900">R$ {nsuData.valor?.toFixed(2)}</p>
            </div>
            <div>
              <p className="text-xs text-gray-600 uppercase tracking-wide">Bandeira</p>
              <div className="mt-1">
                <BandeiraBadge bandeira={nsuData.bandeira} tipo={nsuData.tipo} />
              </div>
            </div>
            <div>
              <p className="text-xs text-gray-600 uppercase tracking-wide">Data</p>
              <p className="text-sm text-gray-900 mt-1">
                {new Date(nsuData.data_venda).toLocaleDateString('pt-BR')}
              </p>
            </div>
          </div>

          <div className="border-t border-blue-200 pt-3 flex gap-4">
            <div>
              <p className="text-xs text-gray-600">Dias Pendente</p>
              <div className="mt-1">
                <DiasBadge dias={nsuData.diasPendente || 0} />
              </div>
            </div>
            <div>
              <p className="text-xs text-gray-600">Hora</p>
              <p className="text-sm text-gray-900 mt-1">{nsuData.hora_venda || '--:--'}</p>
            </div>
          </div>
        </div>
      )}

      {/* Modalidade */}
      <div className="space-y-3">
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

      {/* Parcelas */}
      {(modalidade === 'credito' || modalidade === 'credito_parcelado') && (
        <div className="space-y-3">
          <label className="block text-sm font-medium text-gray-700">Número de Parcelas</label>
          <Input
            type="number"
            min="1"
            max="12"
            value={parcelas}
            onChange={(e) => setParcelas(e.target.value)}
            className="w-full"
          />
        </div>
      )}

      {/* Observações */}
      <div className="space-y-3">
        <label className="block text-sm font-medium text-gray-700">Observações (opcional)</label>
        <textarea
          value={observacoes}
          onChange={(e) => setObservacoes(e.target.value)}
          placeholder="Adicione qualquer nota relevante..."
          rows={3}
          className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-600 focus:border-transparent"
        />
      </div>

      {/* Alert */}
      <div className="p-3 bg-yellow-50 border border-yellow-200 rounded-lg text-sm text-yellow-800">
        ℹ️ Esta NSU será salva como <strong>pendente</strong>. Você poderá vincular uma NF depois.
      </div>

      {/* Actions */}
      <div className="flex gap-3 pt-6 border-t border-gray-200">
        <Button onClick={onClose} variant="outline" className="flex-1">
          Cancelar
        </Button>
        <Button
          onClick={handleSave}
          disabled={!nsuData || submitting}
          className="flex-1 bg-blue-600 hover:bg-blue-700"
        >
          {submitting ? <Loader2 className="w-4 h-4 animate-spin mr-2" /> : null}
          Salvar como Pendente
        </Button>
      </div>
    </div>
  );
}
