import type { Metadata } from 'next';

import { siteConfig } from '@/config/site';
import { LoginPageContent } from '@/features/auth/login/components/login-page-content';

export const metadata: Metadata = {
  title: `Sign in - ${siteConfig.name}`,
  description: siteConfig.loginDescription,
  openGraph: {
    title: `Sign in - ${siteConfig.name}`,
    description: siteConfig.loginDescription,
  },
};

export default function LoginPage() {
  return <LoginPageContent />;
}
