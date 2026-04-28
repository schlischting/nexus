import { getClient } from '@/lib/supabase/client';
import { getServiceRoleClient } from '@/lib/supabase/server';
import type { PerfilUsuario } from '@/lib/types';

export const getCurrentUser = async () => {
  const supabase = getClient();
  const {
    data: { user },
    error,
  } = await supabase.auth.getUser();

  if (error || !user) {
    return null;
  }

  return {
    id: user.id,
    email: user.email!,
  };
};

export const getFilialCnpj = async () => {
  const user = await getCurrentUser();
  if (!user) return null;

  const supabase = getClient();
  const { data, error } = await supabase
    .from('user_filiais_cnpj')
    .select('filial_cnpj')
    .eq('user_id', user.id)
    .single();

  if (error) {
    console.error('Failed to fetch filial_cnpj:', error);
    return null;
  }

  return data?.filial_cnpj || null;
};

export const getFilialsCnpj = async () => {
  const user = await getCurrentUser();
  if (!user) return [];

  const supabase = getClient();
  const { data, error } = await supabase
    .from('user_filiais_cnpj')
    .select('filial_cnpj')
    .eq('user_id', user.id);

  if (error) {
    console.error('Failed to fetch filiais:', error);
    return [];
  }

  return (data || []).map((item) => item.filial_cnpj);
};

export const getPerfil = async (): Promise<PerfilUsuario | null> => {
  const user = await getCurrentUser();
  if (!user) return null;

  const supabase = getClient();
  const { data, error } = await supabase
    .from('user_filiais')
    .select('perfil')
    .eq('user_id', user.id)
    .single();

  if (error) {
    console.error('Failed to fetch profile:', error);
    return null;
  }

  return (data?.perfil as PerfilUsuario) || null;
};

export const logout = async () => {
  const supabase = getClient();
  const { error } = await supabase.auth.signOut();

  if (error) {
    throw new Error(`Logout failed: ${error.message}`);
  }
};

export const hasAccess = async (filialCnpj: string): Promise<boolean> => {
  const filiais = await getFilialsCnpj();
  return filiais.includes(filialCnpj);
};

export const isSupervisor = async (): Promise<boolean> => {
  const perfil = await getPerfil();
  return perfil === 'supervisor' || perfil === 'admin';
};

export const isAdmin = async (): Promise<boolean> => {
  const perfil = await getPerfil();
  return perfil === 'admin';
};
