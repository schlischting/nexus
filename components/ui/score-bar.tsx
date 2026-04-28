'use client';

import { useState } from 'react';

interface ScoreBreakdown {
  valor_diff?: number;
  dias_diff?: number;
  bandeira_match?: boolean;
}

interface ScoreBarProps {
  score: number;
  breakdown?: ScoreBreakdown;
  showDetails?: boolean;
}

export function ScoreBar({ score, breakdown, showDetails = true }: ScoreBarProps) {
  const [showTooltip, setShowTooltip] = useState(false);

  const percentage = Math.round(score * 100);
  const getColor = () => {
    if (percentage >= 95) return 'from-green-400 to-emerald-600';
    if (percentage >= 75) return 'from-yellow-400 to-yellow-600';
    return 'from-red-400 to-red-600';
  };

  const getLabel = () => {
    if (percentage >= 95) return 'Excelente';
    if (percentage >= 75) return 'Bom';
    return 'Baixo';
  };

  return (
    <div className="space-y-2">
      <div className="flex items-center justify-between mb-2">
        <span className="text-sm font-semibold text-gray-700">Score de Correspondência</span>
        <span className={`text-lg font-bold ${
          percentage >= 95 ? 'text-green-600' : percentage >= 75 ? 'text-yellow-600' : 'text-red-600'
        }`}>
          {percentage}%
        </span>
      </div>

      <div className="w-full h-3 bg-gray-200 rounded-full overflow-hidden">
        <div
          className={`h-full bg-gradient-to-r ${getColor()} transition-all`}
          style={{ width: `${percentage}%` }}
        />
      </div>

      {showDetails && breakdown && (
        <div
          className="mt-3 p-3 bg-gray-50 rounded-lg text-xs space-y-1 cursor-help"
          onMouseEnter={() => setShowTooltip(true)}
          onMouseLeave={() => setShowTooltip(false)}
        >
          <div className="flex justify-between">
            <span className="text-gray-600">Diferença de Valor:</span>
            <span className="font-mono text-gray-900">{breakdown.valor_diff?.toFixed(2)}%</span>
          </div>
          <div className="flex justify-between">
            <span className="text-gray-600">Diferença de Dias:</span>
            <span className="font-mono text-gray-900">{breakdown.dias_diff} dias</span>
          </div>
          <div className="flex justify-between">
            <span className="text-gray-600">Bandeira:</span>
            <span className={breakdown.bandeira_match ? 'text-green-600 font-bold' : 'text-red-600 font-bold'}>
              {breakdown.bandeira_match ? '✓ Match' : '✗ Mismatch'}
            </span>
          </div>
        </div>
      )}

      {percentage < 75 && (
        <div className="mt-2 p-2 bg-red-50 border border-red-200 rounded text-xs text-red-700">
          ⚠️ Score baixo. Pode ser rejeitado por supervisor.
        </div>
      )}
    </div>
  );
}
