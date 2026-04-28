'use client';

import { create } from 'zustand';
import type { PerfilUsuario } from '@/lib/types';

interface AuthUser {
  id: string;
  email: string;
  nome?: string;
}

interface AuthStore {
  user: AuthUser | null;
  perfil: PerfilUsuario | null;
  filialCnpj: string | null;
  filiais: string[];
  isLoading: boolean;
  error: string | null;

  setUser: (user: AuthUser | null) => void;
  setPerfil: (perfil: PerfilUsuario | null) => void;
  setFilialCnpj: (cnpj: string) => void;
  setFiliais: (filiais: string[]) => void;
  setIsLoading: (loading: boolean) => void;
  setError: (error: string | null) => void;
  reset: () => void;
}

export const useAuthStore = create<AuthStore>((set) => ({
  user: null,
  perfil: null,
  filialCnpj: null,
  filiais: [],
  isLoading: false,
  error: null,

  setUser: (user) => set({ user }),
  setPerfil: (perfil) => set({ perfil }),
  setFilialCnpj: (cnpj) => set({ filialCnpj: cnpj }),
  setFiliais: (filiais) => set({ filiais }),
  setIsLoading: (isLoading) => set({ isLoading }),
  setError: (error) => set({ error }),
  reset: () =>
    set({
      user: null,
      perfil: null,
      filialCnpj: null,
      filiais: [],
      isLoading: false,
      error: null,
    }),
}));
