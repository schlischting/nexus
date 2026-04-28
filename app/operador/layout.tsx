'use client';

import { ReactNode, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { DashboardHeader } from '@/components/ui/dashboard-header';
import { getClient } from '@/lib/supabase/client';
import { useAuthStore } from '@/lib/store/auth-store';
import { Loader2 } from 'lucide-react';
import { logout } from '@/lib/auth';

export default function OperadorLayout({ children }: { children: ReactNode }) {
  const router = useRouter();
  const { user, filialCnpj, setUser, setFilialCnpj, setIsLoading } =
    useAuthStore();

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

        setUser({
          id: authUser.id,
          email: authUser.email!,
        });

        // Fetch filial
        const { data: filialData } = await supabase
          .from('user_filiais_cnpj')
          .select('filial_cnpj')
          .eq('user_id', authUser.id)
          .single();

        if (filialData) {
          setFilialCnpj(filialData.filial_cnpj);
        }
      } catch (error) {
        console.error('Auth error:', error);
        router.replace('/auth/login');
      } finally {
        setIsLoading(false);
      }
    };

    initAuth();
  }, [router, setUser, setFilialCnpj, setIsLoading]);

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
        filialCnpj={filialCnpj || undefined}
        userName={user.email?.split('@')[0] || 'Operador'}
        userRole="Operador"
        notificationCount={0}
        onLogout={handleLogout}
      />
      <main className="container-main py-6">{children}</main>
    </div>
  );
}
