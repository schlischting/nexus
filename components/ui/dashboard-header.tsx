'use client';

import { Bell, LogOut, Menu } from 'lucide-react';
import Link from 'next/link';
import { useState } from 'react';
import { cn } from '@/lib/utils';
import { Button } from '@/components/ui/button';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';

interface DashboardHeaderProps {
  filialCnpj?: string;
  filiais?: { cnpj: string; nome: string }[];
  onFilialChange?: (cnpj: string) => void;
  notificationCount?: number;
  userName?: string;
  userRole?: string;
  onLogout?: () => Promise<void>;
}

export function DashboardHeader({
  filialCnpj,
  filiais = [],
  onFilialChange,
  notificationCount = 0,
  userName = 'Usuário',
  userRole,
  onLogout,
}: DashboardHeaderProps) {
  const [isLoggingOut, setIsLoggingOut] = useState(false);

  const handleLogout = async () => {
    if (!onLogout) return;
    setIsLoggingOut(true);
    try {
      await onLogout();
    } catch (error) {
      console.error('Logout failed:', error);
    } finally {
      setIsLoggingOut(false);
    }
  };

  return (
    <header className="bg-white border-b border-gray-200 sticky top-0 z-40">
      <div className="px-4 py-3 flex items-center justify-between">
        <div className="flex items-center gap-4">
          <Link href="/" className="flex items-center gap-2">
            <div className="w-8 h-8 bg-blue-600 rounded-lg flex items-center justify-center">
              <span className="text-white font-bold text-sm">N</span>
            </div>
            <span className="font-bold text-lg text-gray-900 hidden sm:inline">
              NEXUS
            </span>
          </Link>

          {filiais.length > 0 && (
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <Button
                  variant="outline"
                  size="sm"
                  className="hidden sm:flex"
                >
                  {filialCnpj
                    ? filiais.find((f) => f.cnpj === filialCnpj)?.nome ||
                      filialCnpj
                    : 'Selecione filial'}
                </Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="start">
                {filiais.map((filial) => (
                  <DropdownMenuItem
                    key={filial.cnpj}
                    onClick={() => onFilialChange?.(filial.cnpj)}
                    className={cn(
                      filial.cnpj === filialCnpj &&
                      'bg-blue-100 text-blue-900'
                    )}
                  >
                    {filial.nome}
                  </DropdownMenuItem>
                ))}
              </DropdownMenuContent>
            </DropdownMenu>
          )}
        </div>

        <div className="flex items-center gap-3">
          {notificationCount > 0 && (
            <div className="relative">
              <Button variant="ghost" size="icon">
                <Bell className="w-5 h-5 text-gray-600" />
                <span className="absolute -top-1 -right-1 w-5 h-5 bg-red-500 text-white text-xs font-bold rounded-full flex items-center justify-center">
                  {notificationCount > 9 ? '9+' : notificationCount}
                </span>
              </Button>
            </div>
          )}

          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="ghost" size="sm" className="gap-2">
                <div className="w-8 h-8 bg-blue-600 rounded-full flex items-center justify-center text-white text-sm font-semibold">
                  {userName.charAt(0).toUpperCase()}
                </div>
                <span className="text-sm font-medium hidden sm:inline">
                  {userName}
                </span>
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end">
              <div className="px-2 py-1.5">
                <p className="text-xs font-medium text-gray-500">
                  {userRole || 'Operador'}
                </p>
              </div>
              <DropdownMenuItem onClick={handleLogout} disabled={isLoggingOut}>
                <LogOut className="w-4 h-4 mr-2" />
                Sair
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        </div>
      </div>
    </header>
  );
}
