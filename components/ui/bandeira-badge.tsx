import { CreditCard } from 'lucide-react';

interface BandeiraBadgeProps {
  bandeira: string;
  tipo?: 'credito' | 'debito';
}

const BANDEIRA_COLORS: Record<string, { bg: string; text: string; icon: string }> = {
  visa: { bg: 'bg-blue-100', text: 'text-blue-700', icon: '🔵' },
  mastercard: { bg: 'bg-orange-100', text: 'text-orange-700', icon: '🟠' },
  elo: { bg: 'bg-purple-100', text: 'text-purple-700', icon: '🟣' },
  amex: { bg: 'bg-green-100', text: 'text-green-700', icon: '🟢' },
};

export function BandeiraBadge({ bandeira, tipo }: BandeiraBadgeProps) {
  const normalized = bandeira?.toLowerCase() || 'unknown';
  const config = BANDEIRA_COLORS[normalized] || {
    bg: 'bg-gray-100',
    text: 'text-gray-700',
    icon: '⚪',
  };

  return (
    <span className={`inline-flex items-center gap-2 px-3 py-1 rounded-full text-sm font-medium ${config.bg} ${config.text}`}>
      <span>{config.icon}</span>
      {bandeira}
      {tipo && (
        <>
          <span>•</span>
          <span className="text-xs opacity-75">{tipo === 'credito' ? '💳' : '🏧'}</span>
        </>
      )}
    </span>
  );
}
