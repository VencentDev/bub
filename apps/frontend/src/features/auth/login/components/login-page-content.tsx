'use client';

import Link from 'next/link';
import { useSearchParams } from 'next/navigation';
import { Suspense } from 'react';

import { siteConfig } from '@/config/site';
import { AuroraPanel } from '@/features/auth/shared/components/aurora-panel';
import { OAuthButtons } from '@/features/auth/shared/components/oauth-buttons';

export function LoginPageContent() {
  return (
    <Suspense fallback={<LoginShell />}>
      <LoginContent />
    </Suspense>
  );
}

function LoginContent() {
  const searchParams = useSearchParams();
  const callbackUrl = searchParams.get('callbackUrl') ?? '/todos';

  return <LoginShell callbackUrl={callbackUrl} />;
}

function LoginShell({ callbackUrl }: { callbackUrl?: string }) {
  return (
    <main className="relative -mx-4 -my-6 flex min-h-[calc(100svh-3.5rem)] max-w-[100vw] items-center overflow-x-clip overflow-y-hidden bg-background px-4 py-6 text-foreground selection:bg-accent/30 md:py-8">
      <BackgroundOrbs />
      <section className="relative z-10 mx-auto flex min-h-[520px] w-full max-w-[min(56rem,calc(100vw-2rem))] animate-float-in flex-col overflow-hidden rounded-xl border border-border bg-card shadow-2xl md:flex-row">
        <AuroraPanel
          variant="login"
          title={siteConfig.name}
          subtitle="Signal access through the neural substrate."
        />
        <div className="flex flex-1 items-center p-8 md:p-12">
          <form className="w-full space-y-6" onSubmit={(event) => event.preventDefault()}>
            <div className="space-y-2">
              <p className="font-mono text-[10px] uppercase tracking-[0.3em] text-accent-alt">
                Secure channel
              </p>
              <h1 className="text-3xl font-bold tracking-tight">Sign in</h1>
              <p className="text-sm text-muted-foreground">
                Enter your credentials or continue with a connected provider.
              </p>
            </div>

            <div className="space-y-4">
              <div className="space-y-1.5">
                <label
                  htmlFor="email"
                  className="font-mono text-[11px] uppercase tracking-wider text-muted-foreground"
                >
                  Email Address
                </label>
                <input
                  id="email"
                  name="email"
                  type="email"
                  autoComplete="email"
                  placeholder={siteConfig.emailPlaceholder}
                  className="field-input"
                />
              </div>

              <div className="space-y-1.5">
                <div className="flex items-center justify-between gap-4">
                  <label
                    htmlFor="password"
                    className="font-mono text-[11px] uppercase tracking-wider text-muted-foreground"
                  >
                    Password
                  </label>
                  <Link
                    href="/login"
                    className="font-mono text-[11px] uppercase tracking-wider text-accent transition-colors hover:text-accent-alt"
                  >
                    Forgot?
                  </Link>
                </div>
                <input
                  id="password"
                  name="password"
                  type="password"
                  autoComplete="current-password"
                  placeholder="••••••••"
                  className="field-input"
                />
              </div>
            </div>

            <button
              type="submit"
              className="w-full rounded-lg bg-foreground py-2.5 font-semibold text-background shadow-lg shadow-foreground/5 transition-all duration-300 hover:bg-foreground/90 hover:shadow-foreground/15 active:scale-[0.98]"
            >
              Sign In
            </button>

            <AuthDivider label="Alternative" />
            <OAuthButtons callbackUrl={callbackUrl} />

            <p className="text-center text-sm text-muted-foreground">
              New here?{' '}
              <Link
                href="/signup"
                className="text-accent underline-offset-4 transition-colors hover:text-accent-alt hover:underline decoration-accent/40"
              >
                Create account
              </Link>
            </p>
          </form>
        </div>
      </section>
    </main>
  );
}

function AuthDivider({ label }: { label: string }) {
  return (
    <div className="relative">
      <div className="absolute inset-0 flex items-center">
        <span className="w-full border-t border-border" />
      </div>
      <div className="relative flex justify-center">
        <span className="bg-card px-3 font-mono text-[10px] uppercase tracking-widest text-muted-foreground">
          {label}
        </span>
      </div>
    </div>
  );
}

function BackgroundOrbs() {
  return (
    <>
      <span className="absolute left-1/2 top-20 size-64 -translate-x-1/2 rounded-full bg-accent/20 blur-3xl" />
      <span className="absolute bottom-10 right-10 size-72 rounded-full bg-accent-alt/15 blur-3xl" />
      <span className="absolute bottom-1/3 left-12 size-40 rounded-full bg-cyan-400/10 blur-3xl" />
    </>
  );
}
