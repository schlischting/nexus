'use client';

import { ReactNode, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { DashboardHeader } from '@/components/ui/dashboard-header';
import { getClient } from '@/lib/supabase/client';
import { useAuthStore } from '@/lib/store/auth-store';
import { Loader2 } from 'lucide-react';
import { logout } from '@/lib/auth';

export default function SupervisorLayout({ children }: { children: ReactNode }) {
  const router = useRouter();
  const { user, filiais, setUser, setFiliais, setIsLoading } = useAuthStore();

  useEffect(() => {
    const initAuth = async () => {
      setIsLoading(true);
      try {
        const supabase = getClient();
        const {
          data: { user: authUser },
        } = await supabase.auth.getUser();

        if (!authUser) {
          router.replace('/auth/login');
          return;
        }

        // Check if supervisor
        const { data: roleData } = await supabase
          .from('user_filiais')
          .select('perfil')
          .eq('user_id', authUser.id)
          .single();

        if (!roleData || (roleData.perfil !== 'supervisor' && roleData.perfil !== 'admin')) {
          router.replace('/operador/dashboard');
          return;
        }

        setUser({
          id: authUser.id,
          email: authUser.email!,
        });

        // Fetch all filiais for supervisor
        const { data: filiaisData } = await supabase
          .from('user_filiais_cnpj')
          .select('filial_cnpj')
          .eq('user_id', authUser.id);

        if (filiaisData) {
          setFiliais(filiaisData.map((f) => f.filial_cnpj));
        }
      } catch (error) {
        console.error('Auth error:', error);
        router.replace('/auth/login');
      } finally {
        setIsLoading(false);
      }
    };

    initAuth();
  }, [router, setUser, setFiliais, setIsLoading]);

  const handleLogout = async () => {
    try {
      await logout();
      router.replace('/auth/login');
    } catch (error) {
      console.error('Logout failed:', error);
    }
  };

  if (!user) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <Loader2 className="w-8 h-8 animate-spin text-blue-600" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <DashboardHeader
        filiais={filiais.map((cnpj) => ({ cnpj, nome: cnpj }))}
        userName={user.email?.split('@')[0] || 'Supervisor'}
        userRole="Supervisor"
        notificationCount={0}
        onLogout={handleLogout}
      />
      <main className="container-main py-6">{children}</main>
    </div>
  );
}
