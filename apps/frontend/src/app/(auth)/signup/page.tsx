import type { Metadata } from 'next';

import { siteConfig } from '@/config/site';
import { SignupPageContent } from '@/features/auth/signup/components/signup-page-content';

export const metadata: Metadata = {
  title: `Create account - ${siteConfig.name}`,
  description: siteConfig.signupDescription,
  openGraph: {
    title: `Create account - ${siteConfig.name}`,
    description: siteConfig.signupDescription,
  },
};

export default function SignupPage() {
  return <SignupPageContent />;
}
