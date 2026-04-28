'use client';

import { useState, useEffect } from 'react';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { BandeiraBadge } from '@/components/ui/bandeira-badge';
import { DiasBadge } from '@/components/ui/dias-badge';
import { AlertCircle, Loader2 } from 'lucide-react';
import { toast } from 'sonner';
import {
  criarVinculoPendente,
  getNsuArquivoGetnet,
  searchNsuEmArquivo,
  criarNsuDigitada
} from '@/lib/supabase/queries';
import { getClient } from '@/lib/supabase/client';

interface NsuSemVinculoModalProps {
  filialCnpj: string;
  onClose: () => void;
  onSuccess: () => void;
}

export function NsuSemVinculoModal({ filialCnpj, onClose, onSuccess }: NsuSemVinculoModalProps) {
  // Estado geral
  const [tipoFluxo, setTipoFluxo] = useState<'arquivo' | 'digitado'>('arquivo');
  const [loading, setLoading] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [nsuSelecionada, setNsuSelecionada] = useState<any>(null);
  const [nsuDigitada, setNsuDigitada] = useState('');
  const [modalidade, setModalidade] = useState('credito');
  const [parcelas, setParcelas] = useState('1');
  const [observacoes, setObservacoes] = useState('');

  // Fluxo A: Arquivo GETNET
  const [nsuListaArquivo, setNsuListaArquivo] = useState<any[]>([]);
  const [nsuBuscaArquivo, setNsuBuscaArquivo] = useState('');

  const supabase = getClient();

  // Carregar NSUs do arquivo ao montar
  useEffect(() => {
    const loadNsuArquivo = async () => {
      try {
        const data = await getNsuArquivoGetnet(filialCnpj);
        setNsuListaArquivo(data);
      } catch (error) {
        console.error('Erro ao carregar NSUs arquivo:', error);
      }
    };
    loadNsuArquivo();
  }, [filialCnpj]);

  // Buscar NSU no arquivo GETNET
  const handleBuscaArquivo = async (value: string) => {
    setNsuBuscaArquivo(value);
    if (!value.trim()) {
      return;
    }

    setLoading(true);
    try {
      const data = await searchNsuEmArquivo(filialCnpj, value);
      setNsuListaArquivo(data);
    } catch (error) {
      toast.error('Erro ao buscar NSU no arquivo');
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  // Buscar NSU digitada
  const handleBuscaNsuDigitada = async (value: string) => {
    setNsuDigitada(value);
    if (!value.trim() || value.length < 3) {
      setNsuSelecionada(null);
      return;
    }

    setLoading(true);
    try {
      const response = await fetch(`/api/search/nsu?q=${encodeURIComponent(value)}`);
      const data = await response.json();

      if (response.ok && data.transacoes?.length > 0) {
        setNsuSelecionada(data.transacoes[0]);
      } else {
        setNsuSelecionada(null);
      }
    } catch (error) {
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  // Salvar NSU
  const handleSalvarPendente = async () => {
    if (!nsuSelecionada) {
      toast.error('Selecione uma NSU');
      return;
    }

    setSubmitting(true);
    try {
      await criarVinculoPendente(nsuSelecionada.transacao_id || nsuSelecionada.id, filialCnpj, observacoes);
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

  // Criar NSU digitada
  const handleCriarNsuDigitada = async () => {
    if (!nsuDigitada.trim()) {
      toast.error('Digite uma NSU');
      return;
    }

    setSubmitting(true);
    try {
      const novaNsu = await criarNsuDigitada({
        filial_cnpj: filialCnpj,
        nsu: nsuDigitada,
        autorizacao: 'MANUAL_' + Date.now().toString().slice(-6),
        data_venda: new Date().toISOString().split('T')[0],
        valor_venda: 0,
        bandeira: 'Manual',
        modalidade,
      });

      if (novaNsu) {
        setNsuSelecionada(novaNsu);
        toast.success('NSU criada! Agora selecione uma NF para vincular.');
      }
    } catch (error) {
      toast.error('Erro ao criar NSU');
      console.error(error);
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="space-y-6">
      {/* SEÇÃO A: Arquivo GETNET */}
      <div className="border-b pb-6">
        <div className="flex items-center gap-3 mb-4">
          <input
            type="radio"
            id="arquivo"
            checked={tipoFluxo === 'arquivo'}
            onChange={() => {
              setTipoFluxo('arquivo');
              setNsuSelecionada(null);
              setNsuDigitada('');
            }}
            className="w-4 h-4 cursor-pointer"
          />
          <label htmlFor="arquivo" className="font-semibold cursor-pointer text-gray-900">
            🔵 NSU importada da GETNET
          </label>
        </div>

        {tipoFluxo === 'arquivo' && (
          <div className="space-y-4 ml-7">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Buscar NSU pendente
              </label>
              <Input
                type="text"
                placeholder="Buscar por NSU..."
                value={nsuBuscaArquivo}
                onChange={(e) => handleBuscaArquivo(e.target.value)}
                disabled={loading}
                className="w-full bg-white text-gray-900 border border-gray-300 placeholder-gray-500"
              />
            </div>

            {nsuListaArquivo.length > 0 && (
              <div className="space-y-2 max-h-48 overflow-y-auto border border-gray-200 rounded-lg p-3 bg-gray-50">
                {nsuListaArquivo.map((nsu: any) => (
                  <div
                    key={nsu.transacao_id || nsu.id}
                    onClick={() => setNsuSelecionada(nsu)}
                    className={`p-3 rounded cursor-pointer transition ${
                      nsuSelecionada?.transacao_id === nsu.transacao_id ||
                      nsuSelecionada?.id === nsu.id
                        ? 'bg-blue-200 border border-blue-400'
                        : 'bg-white border border-gray-300 hover:border-blue-300'
                    }`}
                  >
                    <div className="flex justify-between items-start">
                      <div>
                        <p className="font-mono font-bold text-gray-900">{nsu.nsu}</p>
                        <p className="text-sm text-gray-600">
                          R$ {(nsu.valor_venda || nsu.valor)?.toFixed(2)}
                        </p>
                      </div>
                      <BandeiraBadge
                        bandeira={nsu.bandeira}
                        tipo={nsu.modalidade || nsu.tipo}
                      />
                    </div>
                  </div>
                ))}
              </div>
            )}

            {nsuSelecionada && tipoFluxo === 'arquivo' && (
              <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
                <p className="text-sm text-blue-900 font-semibold mb-2">✓ NSU Selecionada:</p>
                <p className="text-lg font-mono font-bold text-gray-900">
                  {nsuSelecionada.nsu}
                </p>
              </div>
            )}
          </div>
        )}
      </div>

      {/* SEÇÃO B: Digitada Operador */}
      <div className="pb-6">
        <div className="flex items-center gap-3 mb-4">
          <input
            type="radio"
            id="digitado"
            checked={tipoFluxo === 'digitado'}
            onChange={() => {
              setTipoFluxo('digitado');
              setNsuSelecionada(null);
              setNsuBuscaArquivo('');
            }}
            className="w-4 h-4 cursor-pointer"
          />
          <label htmlFor="digitado" className="font-semibold cursor-pointer text-gray-900">
            ⭕ Digitar NSU nova
          </label>
        </div>

        {tipoFluxo === 'digitado' && (
          <div className="space-y-4 ml-7">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Número do NSU
              </label>
              <div className="flex gap-2">
                <Input
                  type="text"
                  placeholder="Digite a NSU (ex: 123456789)..."
                  value={nsuDigitada}
                  onChange={(e) => handleBuscaNsuDigitada(e.target.value)}
                  disabled={submitting}
                  className="flex-1 bg-white text-gray-900 border border-gray-300 placeholder-gray-500"
                />
                <Button
                  onClick={handleCriarNsuDigitada}
                  disabled={!nsuDigitada.trim() || submitting}
                  className="bg-green-600 hover:bg-green-700"
                >
                  {submitting ? <Loader2 className="w-4 h-4 animate-spin" /> : 'Criar'}
                </Button>
              </div>
            </div>

            {nsuSelecionada && tipoFluxo === 'digitado' && (
              <div className="bg-orange-50 border border-orange-200 rounded-lg p-4">
                <p className="text-sm text-orange-900 font-semibold mb-2">✓ NSU Criada:</p>
                <p className="text-lg font-mono font-bold text-gray-900">
                  {nsuSelecionada.nsu}
                </p>
              </div>
            )}
          </div>
        )}
      </div>

      {/* SEÇÃO COMUM: Detalhes */}
      {nsuSelecionada && (
        <>
          <div className="border-t pt-6 space-y-4">
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

            {(modalidade === 'credito' || modalidade === 'credito_parcelado') && (
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
                  className="w-full bg-white text-gray-900 border border-gray-300"
                />
              </div>
            )}

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Observações (opcional)
              </label>
              <textarea
                value={observacoes}
                onChange={(e) => setObservacoes(e.target.value)}
                placeholder="Adicione qualquer nota relevante..."
                rows={3}
                className="w-full px-3 py-2 bg-white text-gray-900 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-600 focus:border-transparent"
              />
            </div>

            <div className="p-4 bg-yellow-50 border border-yellow-200 rounded-lg flex gap-3">
              <AlertCircle className="w-5 h-5 text-yellow-600 flex-shrink-0 mt-0.5" />
              <div className="text-sm text-yellow-800">
                <p className="font-semibold">ℹ️ Aviso</p>
                <p>Esta NSU será salva como <strong>pendente</strong>. O supervisor validará depois.</p>
              </div>
            </div>
          </div>

          <div className="flex gap-3 pt-6 border-t border-gray-200">
            <Button onClick={onClose} variant="outline" className="flex-1">
              Cancelar
            </Button>
            <Button
              onClick={handleSalvarPendente}
              disabled={!nsuSelecionada || submitting}
              className="flex-1 bg-blue-600 hover:bg-blue-700"
            >
              {submitting ? <Loader2 className="w-4 h-4 animate-spin mr-2" /> : null}
              Salvar como Pendente
            </Button>
          </div>
        </>
      )}
    </div>
  );
}
