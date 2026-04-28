'use client';

import { AlertCircle, CheckCircle, XCircle } from 'lucide-react';
import { cn } from '@/lib/utils';
import { Button } from '@/components/ui/button';
import type { SuggestaoSupervisor } from '@/lib/types';

interface MatchSuggestionProps {
  suggestion: SuggestaoSupervisor;
  onConfirm: () => void;
  onReject: () => void;
  isLoading?: boolean;
}

export function MatchSuggestion({
  suggestion,
  onConfirm,
  onReject,
  isLoading = false,
}: MatchSuggestionProps) {
  const { score_confianca: score } = suggestion;

  const getScoreColor = () => {
    if (score >= 0.95) return 'bg-green-500';
    if (score >= 0.75) return 'bg-yellow-500';
    return 'bg-red-500';
  };

  const getScoreBgColor = () => {
    if (score >= 0.95) return 'bg-green-100';
    if (score >= 0.75) return 'bg-yellow-100';
    return 'bg-red-100';
  };

  const getScoreLabel = () => {
    if (score >= 0.95) return { label: 'Automático', icon: <CheckCircle className="w-4 h-4" /> };
    if (score >= 0.75) return { label: 'Sugestão', icon: <AlertCircle className="w-4 h-4" /> };
    return { label: 'Baixa confiança', icon: <XCircle className="w-4 h-4" /> };
  };

  const { label: scoreLabel, icon: scoreIcon } = getScoreLabel();
  const daysDiff = Math.abs(suggestion.dias_diferenca);

  return (
    <div className="border rounded-lg p-4 bg-white hover:shadow-md transition-shadow">
      <div className="flex items-start justify-between mb-3">
        <div className="flex-1">
          <div className="flex items-center gap-2 mb-1">
            <span className="font-mono text-sm font-semibold text-blue-600">
              NSU: {suggestion.nsu}
            </span>
            <span className="text-gray-400">→</span>
            <span className="font-mono text-sm font-semibold text-purple-600">
              NF: {suggestion.numero_nf}
            </span>
          </div>
          <p className="text-xs text-gray-500">
            {new Date(suggestion.data_venda).toLocaleDateString('pt-BR')} → {new Date(suggestion.data_vencimento).toLocaleDateString('pt-BR')}
            {daysDiff > 0 && ` (${daysDiff} dias de diferença)`}
          </p>
        </div>
        <div className={cn(
          'flex items-center gap-2 px-3 py-1 rounded-full text-sm font-medium',
          getScoreBgColor()
        )}>
          {scoreIcon}
          <span>{scoreLabel}</span>
        </div>
      </div>

      <div className="mb-3">
        <div className="flex items-center justify-between mb-1">
          <span className="text-xs font-medium text-gray-600">
            Confiança: {(score * 100).toFixed(1)}%
          </span>
        </div>
        <div className="w-full h-2 bg-gray-200 rounded-full overflow-hidden">
          <div
            className={cn('h-full transition-all', getScoreColor())}
            style={{ width: `${score * 100}%` }}
          />
        </div>
      </div>

      <div className="grid grid-cols-2 gap-2 mb-3 text-xs">
        <div>
          <p className="text-gray-500">GETNET</p>
          <p className="font-semibold text-gray-900">
            R$ {suggestion.valor_getnet.toFixed(2)}
          </p>
        </div>
        <div>
          <p className="text-gray-500">TOTVS</p>
          <p className="font-semibold text-gray-900">
            R$ {suggestion.valor_totvs.toFixed(2)}
          </p>
        </div>
      </div>

      <div className="text-xs text-gray-600 mb-3 pb-3 border-t">
        <p className="mt-2">
          <span className="font-medium">Modalidade:</span> {suggestion.modalidade_pagamento}
        </p>
        {suggestion.quantidade_parcelas > 1 && (
          <p>
            <span className="font-medium">Parcelas:</span> {suggestion.quantidade_parcelas}x
          </p>
        )}
      </div>

      <div className="flex gap-2">
        <Button
          variant="outline"
          size="sm"
          onClick={onReject}
          disabled={isLoading}
          className="flex-1"
        >
          Rejeitar
        </Button>
        <Button
          size="sm"
          onClick={onConfirm}
          disabled={isLoading}
          className="flex-1"
        >
          Confirmar
        </Button>
      </div>
    </div>
  );
}
