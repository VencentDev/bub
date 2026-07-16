import Link from 'next/link';

import { siteConfig } from '@/config/site';

export function HomePageContent() {
  return (
    <main className="relative -mx-4 -my-6 flex min-h-[calc(100svh-3.5rem)] max-w-[100vw] flex-col overflow-x-clip overflow-y-hidden bg-background px-4 py-10 text-foreground md:py-12">
      <span className="absolute left-1/2 top-20 size-72 -translate-x-1/2 animate-aurora rounded-full bg-accent/20 blur-3xl" />
      <span className="absolute bottom-20 right-1/4 size-80 animate-aurora rounded-full bg-accent-alt/15 blur-3xl [animation-delay:-5s]" />
      <span className="absolute bottom-28 left-1/4 size-48 animate-aurora rounded-full bg-cyan-400/10 blur-3xl [animation-delay:-8s]" />

      <section className="relative z-10 mx-auto flex flex-1 flex-col items-center justify-center gap-7 text-center">
        <p className="font-mono text-[10px] uppercase tracking-[0.3em] text-accent-alt">
          {siteConfig.name}
        </p>
        <div className="space-y-4">
          <h1 className="text-balance text-4xl font-bold tracking-tight md:text-5xl">
            Build and Deploy
          </h1>
          <p className="mx-auto max-w-md text-sm leading-6 text-muted-foreground">
            A ready template for provider-backed authentication and focused application access.
          </p>
        </div>
        <div className="flex flex-col gap-3 sm:flex-row">
          <Link
            href="/login"
            className="rounded-lg bg-foreground px-5 py-2.5 text-sm font-semibold text-background shadow-lg shadow-foreground/5 transition-all duration-300 hover:bg-foreground/90 hover:shadow-foreground/15 active:scale-[0.98]"
          >
            Sign in
          </Link>
          <Link
            href="/signup"
            className="rounded-lg border border-border bg-foreground/5 px-5 py-2.5 text-sm font-medium transition-all duration-300 hover:border-accent/40 hover:bg-foreground/10 active:scale-[0.98]"
          >
            Create account
          </Link>
        </div>
      </section>
    </main>
  );
}
