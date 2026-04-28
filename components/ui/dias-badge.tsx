interface DiasBadgeProps {
  dias: number;
}

export function DiasBadge({ dias }: DiasBadgeProps) {
  const getColor = () => {
    if (dias < 3) return 'bg-green-100 text-green-700';
    if (dias <= 7) return 'bg-yellow-100 text-yellow-700';
    return 'bg-red-100 text-red-700';
  };

  const getEmoji = () => {
    if (dias < 3) return '⚡';
    if (dias <= 7) return '⏰';
    return '🚨';
  };

  return (
    <span className={`inline-flex items-center gap-1 px-3 py-1 rounded-full text-sm font-medium ${getColor()}`}>
      <span>{getEmoji()}</span>
      {dias === 0 ? 'Hoje' : dias === 1 ? '1 dia' : `${dias} dias`}
    </span>
  );
}
