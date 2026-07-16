import Link from 'next/link';

import { SignOutButton } from '@/components/sign-out-button';
import { ThemeToggle } from '@/components/theme-toggle';
import { Button } from '@/components/ui/button';
import { siteConfig } from '@/config/site';
import { auth } from '@/lib/auth';

export async function Navbar() {
  const session = await auth();

  return (
    <header className="border-b">
      <div className="container mx-auto flex h-14 items-center justify-between gap-4">
        <Link href="/" className="font-mono text-xs font-semibold uppercase tracking-[0.2em]">
          {siteConfig.navName}
        </Link>
        <nav className="flex items-center gap-2">
          {session ? (
            <>
              <Button asChild variant="ghost" size="sm">
                <Link href="/todos">Todos</Link>
              </Button>
              <SignOutButton />
            </>
          ) : (
            <Button asChild variant="outline" size="sm">
              <Link href="/login">Sign in</Link>
            </Button>
          )}
          <ThemeToggle />
        </nav>
      </div>
    </header>
  );
}
