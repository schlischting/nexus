import { type ClassValue, clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export function formatCurrency(value: number, locale = 'pt-BR'): string {
  return new Intl.NumberFormat(locale, {
    style: 'currency',
    currency: 'BRL',
  }).format(value);
}

export function formatDate(date: string | Date, locale = 'pt-BR'): string {
  return new Intl.DateTimeFormat(locale).format(
    typeof date === 'string' ? new Date(date) : date
  );
}

export function formatDatetime(date: string | Date, locale = 'pt-BR'): string {
  return new Intl.DateTimeFormat(locale, {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
  }).format(typeof date === 'string' ? new Date(date) : date);
}

export function getScoreColor(score: number): string {
  if (score >= 0.95) return '#10b981'; // green
  if (score >= 0.75) return '#f59e0b'; // yellow
  return '#ef4444'; // red
}

export function getScoreBadgeVariant(score: number): 'success' | 'warning' | 'error' {
  if (score >= 0.95) return 'success';
  if (score >= 0.75) return 'warning';
  return 'error';
}
