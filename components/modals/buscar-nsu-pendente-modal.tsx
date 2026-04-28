'use client';

import { useState, useEffect } from 'react';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { BandeiraBadge } from '@/components/ui/bandeira-badge';
import { DiasBadge } from '@/components/ui/dias-badge';
import { Search, Loader2 } from 'lucide-react';
import { toast } from 'sonner';
import { getNsuPendentes } from '@/lib/supabase/queries';

interface BuscarNsuPendenteModalProps {
  filialCnpj: string;
  onClose: () => void;
  onSelectNsu?: (nsu: any) => void;
  onOpenWizard?: () => void;
}

export function BuscarNsuPendenteModal({
  filialCnpj,
  onClose,
  onSelectNsu,
  onOpenWizard,
}: BuscarNsuPendenteModalProps) {
  const [searchTerm, setSearchTerm] = useState('');
  const [nsuList, setNsuList] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedNsu, setSelectedNsu] = useState<any>(null);

  useEffect(() => {
    const loadPendentes = async () => {
      try {
        const data = await getNsuPendentes(filialCnpj);
        setNsuList(data);
      } catch (error) {
        console.error(error);
        toast.error('Erro ao carregar NSUs pendentes');
      } finally {
        setLoading(false);
      }
    };

    loadPendentes();
  }, [filialCnpj]);

  const filteredNsus = nsuList.filter(
    (nsu) =>
      nsu.nsu?.includes(searchTerm) ||
      nsu.bandeira?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      nsu.valor_venda?.toString().includes(searchTerm)
  );

  const handleSelectNsu = (nsu: any) => {
    setSelectedNsu(nsu);
    if (onSelectNsu) {
      onSelectNsu(nsu);
    }
  };

  const handleVincularNow = () => {
    if (!selectedNsu) {
      toast.error('Selecione um NSU');
      return;
    }
    if (onOpenWizard) {
      onOpenWizard();
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12">
        <Loader2 className="w-6 h-6 animate-spin text-blue-600 mr-2" />
        <p className="text-gray-600">Carregando NSUs pendentes...</p>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      {/* Search */}
      <div className="relative">
        <Search className="absolute left-3 top-3 w-5 h-5 text-gray-400" />
        <Input
          type="text"
          placeholder="Buscar por NSU, bandeira ou valor..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          className="pl-10"
        />
      </div>

      {/* Table */}
      {filteredNsus.length > 0 ? (
        <div className="border border-gray-200 rounded-lg overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-gray-50 border-b border-gray-200">
                <tr>
                  <th className="px-4 py-3 text-left font-medium text-gray-700">NSU</th>
                  <th className="px-4 py-3 text-right font-medium text-gray-700">Valor</th>
                  <th className="px-4 py-3 text-left font-medium text-gray-700">Bandeira</th>
                  <th className="px-4 py-3 text-left font-medium text-gray-700">Dias</th>
                  <th className="px-4 py-3 text-center font-medium text-gray-700">Selecionar</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200">
                {filteredNsus.map((nsu) => (
                  <tr
                    key={nsu.id}
                    className={`hover:bg-gray-50 cursor-pointer transition ${
                      selectedNsu?.id === nsu.id ? 'bg-blue-50' : ''
                    }`}
                  >
                    <td className="px-4 py-3 font-mono text-gray-900">{nsu.nsu}</td>
                    <td className="px-4 py-3 text-right text-gray-900 font-medium">
                      R$ {nsu.valor_venda?.toFixed(2) || '0.00'}
                    </td>
                    <td className="px-4 py-3">
                      <BandeiraBadge bandeira={nsu.bandeira} tipo={nsu.modalidade} />
                    </td>
                    <td className="px-4 py-3">
                      <DiasBadge
                        dias={Math.floor(
                          (new Date().getTime() - new Date(nsu.data_venda).getTime()) /
                            (1000 * 60 * 60 * 24)
                        )}
                      />
                    </td>
                    <td className="px-4 py-3 text-center">
                      <input
                        type="radio"
                        name="nsu-selection"
                        checked={selectedNsu?.id === nsu.id}
                        onChange={() => handleSelectNsu(nsu)}
                        className="w-4 h-4 cursor-pointer"
                      />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      ) : (
        <div className="text-center py-12">
          <p className="text-gray-600 font-medium">Nenhuma NSU pendente encontrada</p>
          <p className="text-sm text-gray-500 mt-1">Todas as NSUs estão vinculadas!</p>
        </div>
      )}

      {/* Info */}
      {selectedNsu && (
        <div className="p-4 bg-blue-50 border border-blue-200 rounded-lg">
          <p className="text-sm text-blue-900">
            <strong>NSU Selecionada:</strong> {selectedNsu.nsu} • R$ {selectedNsu.valor_venda?.toFixed(2)}
          </p>
        </div>
      )}

      {/* Actions */}
      <div className="flex gap-3 pt-6 border-t border-gray-200">
        <Button onClick={onClose} variant="outline" className="flex-1">
          Fechar
        </Button>
        <Button
          onClick={handleVincularNow}
          disabled={!selectedNsu}
          className="flex-1 bg-green-600 hover:bg-green-700"
        >
          Vincular NF Agora
        </Button>
      </div>
    </div>
  );
}
