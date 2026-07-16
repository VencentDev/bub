import type { Metadata } from 'next';

import { siteConfig } from '@/config/site';
import { HomePageContent } from '@/features/home/landing/components/home-page-content';

export const metadata: Metadata = {
  title: siteConfig.metadataTitle,
  description: siteConfig.metadataDescription,
  openGraph: {
    title: siteConfig.metadataTitle,
    description: siteConfig.metadataDescription,
  },
};

export default function HomePage() {
  return <HomePageContent />;
}
