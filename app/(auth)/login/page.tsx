'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { getClient } from '@/lib/supabase/client';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Loader2, Mail, Lock, ArrowRight } from 'lucide-react';
import { toast } from 'sonner';

const loginSchema = z.object({
  email: z.string().email('Email inválido'),
  password: z.string().min(6, 'Senha deve ter pelo menos 6 caracteres'),
});

type LoginFormData = z.infer<typeof loginSchema>;

export default function LoginPage() {
  const router = useRouter();
  const [isLoading, setIsLoading] = useState(false);

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<LoginFormData>({
    resolver: zodResolver(loginSchema),
  });

  const onSubmit = async (data: LoginFormData) => {
    setIsLoading(true);

    try {
      const supabase = getClient();
      const { error: authError } = await supabase.auth.signInWithPassword({
        email: data.email,
        password: data.password,
      });

      if (authError) {
        toast.error(authError.message);
        setIsLoading(false);
        return;
      }

      const { data: userData } = await supabase.auth.getUser();
      if (userData.user) {
        const { data: roleData } = await supabase
          .from('user_filiais')
          .select('perfil')
          .eq('user_id', userData.user.id)
          .single();

        const role = roleData?.perfil || 'operador_filial';
        toast.success('Login realizado com sucesso');

        if (role === 'supervisor' || role === 'admin') {
          router.push('/supervisor/dashboard');
        } else {
          router.push('/operador/dashboard');
        }
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Erro ao fazer login';
      toast.error(message);
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-600 via-blue-500 to-emerald-500 flex items-center justify-center p-4">
      {/* Background decoration */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div className="absolute -top-40 -right-40 w-80 h-80 bg-blue-400 rounded-full mix-blend-multiply filter blur-3xl opacity-20 animate-blob"></div>
        <div className="absolute -bottom-40 -left-40 w-80 h-80 bg-emerald-400 rounded-full mix-blend-multiply filter blur-3xl opacity-20 animate-blob animation-delay-2000"></div>
      </div>

      <div className="relative w-full max-w-md">
        {/* Login Card */}
        <div className="backdrop-blur-xl bg-white/10 border border-white/20 rounded-2xl shadow-2xl p-8 space-y-6">
          {/* Logo & Title */}
          <div className="text-center space-y-2">
            <div className="inline-flex items-center justify-center w-12 h-12 rounded-lg bg-gradient-to-br from-blue-500 to-emerald-500 mb-4">
              <span className="text-xl font-bold text-white">◆</span>
            </div>
            <h1 className="text-3xl font-bold text-white">NEXUS</h1>
            <p className="text-sm text-blue-100">Conciliação de Cartões GETNET + TOTVS</p>
          </div>

          {/* Form */}
          <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
            {/* Email Field */}
            <div className="space-y-2">
              <label htmlFor="email" className="block text-sm font-medium text-blue-50">
                E-mail
              </label>
              <div className="relative">
                <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-blue-200 pointer-events-none" />
                <Input
                  id="email"
                  {...register('email')}
                  type="email"
                  placeholder="seu@email.com"
                  disabled={isLoading}
                  className={`pl-10 bg-white/10 border backdrop-blur-sm text-white placeholder:text-blue-200 focus:bg-white/20 ${
                    errors.email ? 'border-red-400' : 'border-white/20'
                  }`}
                  aria-label="Email"
                  aria-describedby={errors.email ? 'email-error' : undefined}
                />
              </div>
              {errors.email && (
                <p id="email-error" className="text-xs text-red-300">
                  {errors.email.message}
                </p>
              )}
            </div>

            {/* Password Field */}
            <div className="space-y-2">
              <label htmlFor="password" className="block text-sm font-medium text-blue-50">
                Senha
              </label>
              <div className="relative">
                <Lock className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-blue-200 pointer-events-none" />
                <Input
                  id="password"
                  {...register('password')}
                  type="password"
                  placeholder="••••••••"
                  disabled={isLoading}
                  className={`pl-10 bg-white/10 border backdrop-blur-sm text-white placeholder:text-blue-200 focus:bg-white/20 ${
                    errors.password ? 'border-red-400' : 'border-white/20'
                  }`}
                  aria-label="Senha"
                  aria-describedby={errors.password ? 'password-error' : undefined}
                />
              </div>
              {errors.password && (
                <p id="password-error" className="text-xs text-red-300">
                  {errors.password.message}
                </p>
              )}
            </div>

            {/* Submit Button */}
            <Button
              type="submit"
              disabled={isLoading}
              className="w-full bg-gradient-to-r from-blue-500 to-emerald-500 hover:from-blue-600 hover:to-emerald-600 text-white font-semibold py-2.5 rounded-lg transition-all duration-200 disabled:opacity-50 group"
            >
              {isLoading ? (
                <>
                  <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                  Entrando...
                </>
              ) : (
                <>
                  Entrar
                  <ArrowRight className="w-4 h-4 ml-2 group-hover:translate-x-1 transition-transform" />
                </>
              )}
            </Button>
          </form>

          {/* Divider */}
          <div className="relative">
            <div className="absolute inset-0 flex items-center">
              <div className="w-full border-t border-white/20"></div>
            </div>
            <div className="relative flex justify-center text-sm">
              <span className="px-2 bg-gradient-to-br from-blue-600 via-blue-500 to-emerald-500 text-white/60 text-xs">
                Novo por aqui?
              </span>
            </div>
          </div>

          {/* Signup Link */}
          <Link
            href="/signup"
            className="block w-full text-center py-2.5 rounded-lg bg-white/10 hover:bg-white/20 border border-white/20 text-blue-50 font-medium transition-all duration-200"
          >
            Criar conta
          </Link>

          {/* Footer Text */}
          <p className="text-center text-xs text-blue-100/70">
            Sistema seguro com autenticação Supabase
          </p>
        </div>

        {/* Test Credentials */}
        <div className="mt-6 p-4 rounded-lg bg-white/5 border border-white/10 backdrop-blur-sm">
          <p className="text-xs text-blue-100/70 text-center mb-2">
            <span className="font-semibold">Credenciais de teste:</span>
          </p>
          <div className="text-xs text-blue-100/60 space-y-1 text-center">
            <p>operador@test.com / Senha123!</p>
          </div>
        </div>
      </div>

      <style jsx>{`
        @keyframes blob {
          0%, 100% {
            transform: translate(0, 0) scale(1);
          }
          33% {
            transform: translate(30px, -50px) scale(1.1);
          }
          66% {
            transform: translate(-20px, 20px) scale(0.9);
          }
        }
        .animate-blob {
          animation: blob 7s infinite;
        }
        .animation-delay-2000 {
          animation-delay: 2s;
        }
      `}</style>
    </div>
  );
}
