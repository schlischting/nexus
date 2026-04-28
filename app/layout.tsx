import type { Metadata } from 'next';
import { Inter } from 'next/font/google';
import './globals.css';
import { Toaster } from 'sonner';

const inter = Inter({ subsets: ['latin'] });

export const metadata: Metadata = {
  title: 'NEXUS - Conciliação de Cartões',
  description:
    'Sistema de conciliação automática de transações GETNET com títulos TOTVS',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="pt-BR">
      <body className={inter.className}>
        <div className="min-h-screen bg-gray-50">{children}</div>
        <Toaster position="top-right" />
      </body>
    </html>
  );
}
