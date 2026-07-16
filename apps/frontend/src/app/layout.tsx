import type { Metadata } from 'next';
import { Inter, JetBrains_Mono } from 'next/font/google';
import type { ReactNode } from 'react';

import { Navbar } from '@/components/navbar';
import { Providers } from '@/components/providers';
import { ThemeProvider } from '@/components/theme-provider';
import { siteConfig } from '@/config/site';

import '@/styles/globals.css';

const inter = Inter({ subsets: ['latin'], variable: '--font-inter' });
const jetBrainsMono = JetBrains_Mono({
  subsets: ['latin'],
  variable: '--font-jetbrains-mono',
});

export const metadata: Metadata = {
  title: siteConfig.metadataTitle,
  description: siteConfig.metadataDescription,
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className={`${inter.variable} ${jetBrainsMono.variable} font-display`}>
        <ThemeProvider attribute="class" defaultTheme="system" enableSystem>
          <Providers>
            <Navbar />
            <div className="container mx-auto py-6">{children}</div>
          </Providers>
        </ThemeProvider>
      </body>
    </html>
  );
}
