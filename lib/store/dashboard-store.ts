'use client';

import { create } from 'zustand';
import type {
  DashboardMetrics,
  NsuGap,
  TituloGap,
  SuggestaoSupervisor,
} from '@/lib/types';

interface DashboardStore {
  metrics: DashboardMetrics | null;
  nsuGaps: NsuGap[];
  tituloGaps: TituloGap[];
  sugestoes: SuggestaoSupervisor[];
  isLoading: boolean;
  error: string | null;
  lastUpdated: number | null;

  setMetrics: (metrics: DashboardMetrics) => void;
  setNsuGaps: (gaps: NsuGap[]) => void;
  setTituloGaps: (gaps: TituloGap[]) => void;
  setSugestoes: (sugestoes: SuggestaoSupervisor[]) => void;
  setIsLoading: (loading: boolean) => void;
  setError: (error: string | null) => void;
  updateLastUpdated: () => void;
  reset: () => void;
}

export const useDashboardStore = create<DashboardStore>((set) => ({
  metrics: null,
  nsuGaps: [],
  tituloGaps: [],
  sugestoes: [],
  isLoading: false,
  error: null,
  lastUpdated: null,

  setMetrics: (metrics) => set({ metrics }),
  setNsuGaps: (nsuGaps) => set({ nsuGaps }),
  setTituloGaps: (tituloGaps) => set({ tituloGaps }),
  setSugestoes: (sugestoes) => set({ sugestoes }),
  setIsLoading: (isLoading) => set({ isLoading }),
  setError: (error) => set({ error }),
  updateLastUpdated: () => set({ lastUpdated: Date.now() }),
  reset: () =>
    set({
      metrics: null,
      nsuGaps: [],
      tituloGaps: [],
      sugestoes: [],
      isLoading: false,
      error: null,
      lastUpdated: null,
    }),
}));
