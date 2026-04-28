import { AlertCircle, AlertTriangle, CheckCircle, InfoIcon } from 'lucide-react';
import { cn } from '@/lib/utils';

type GapCardStatus = 'critical' | 'warning' | 'success' | 'info';

interface GapCardProps {
  status: GapCardStatus;
  count: number;
  description: string;
  icon?: React.ReactNode;
  className?: string;
  onClick?: () => void;
}

const statusConfig: Record<GapCardStatus, {
  bgColor: string;
  textColor: string;
  borderColor: string;
  icon: React.ReactNode;
}> = {
  critical: {
    bgColor: 'bg-red-50',
    textColor: 'text-red-700',
    borderColor: 'border-red-200',
    icon: <AlertCircle className="w-5 h-5" />,
  },
  warning: {
    bgColor: 'bg-yellow-50',
    textColor: 'text-yellow-700',
    borderColor: 'border-yellow-200',
    icon: <AlertTriangle className="w-5 h-5" />,
  },
  success: {
    bgColor: 'bg-green-50',
    textColor: 'text-green-700',
    borderColor: 'border-green-200',
    icon: <CheckCircle className="w-5 h-5" />,
  },
  info: {
    bgColor: 'bg-blue-50',
    textColor: 'text-blue-700',
    borderColor: 'border-blue-200',
    icon: <InfoIcon className="w-5 h-5" />,
  },
};

export function GapCard({
  status,
  count,
  description,
  icon,
  className,
  onClick,
}: GapCardProps) {
  const config = statusConfig[status];

  return (
    <div
      onClick={onClick}
      className={cn(
        'p-4 rounded-lg border',
        config.bgColor,
        config.borderColor,
        onClick && 'cursor-pointer hover:shadow-md transition-shadow',
        className
      )}
    >
      <div className="flex items-start gap-3">
        <div className={config.textColor}>
          {icon || config.icon}
        </div>
        <div className="flex-1 min-w-0">
          <div className={cn('text-2xl font-bold', config.textColor)}>
            {count}
          </div>
          <p className={cn('text-sm', config.textColor)}>
            {description}
          </p>
        </div>
      </div>
    </div>
  );
}
