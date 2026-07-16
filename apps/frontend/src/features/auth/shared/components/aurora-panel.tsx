import Image from 'next/image';

import prismImage from '@/assets/prism.png';
import { cn } from '@/lib/utils';

type AuroraPanelProps = {
  title: string;
  subtitle: string;
  variant: 'login' | 'signup';
  className?: string;
};

export function AuroraPanel({ title, subtitle, variant, className }: AuroraPanelProps) {
  if (variant === 'signup') {
    return (
      <aside
        className={cn(
          'relative flex min-h-[280px] w-full items-center justify-center overflow-hidden border-t border-border md:min-h-0 md:w-[45%] md:border-l md:border-t-0',
          className,
        )}
      >
        <Image
          src={prismImage}
          alt=""
          fill
          priority
          sizes="(min-width: 768px) 405px, 100vw"
          className="object-cover opacity-50"
        />
        <div className="absolute inset-0 bg-gradient-to-t from-card via-card/40 to-transparent" />
        <div className="relative z-10 flex flex-col items-center text-center">
          <div className="relative mb-8 flex size-24 items-center justify-center rounded-full border border-accent/30">
            <span className="absolute inset-0 rounded-full border border-accent/30 animate-[ping_4s_linear_infinite]" />
            <span className="size-12 animate-pulse rounded-full bg-accent/30 blur-xl" />
            <span className="absolute size-4 rotate-12 rounded-sm bg-accent-alt transition-transform duration-500 hover:rotate-45" />
          </div>
          <h2 className="text-lg font-medium tracking-wide text-foreground">{title}</h2>
          <p className="mt-2 font-mono text-[10px] uppercase tracking-[0.2em] text-accent-alt">
            {subtitle}
          </p>
        </div>
      </aside>
    );
  }

  return (
    <aside
      className={cn(
        'relative flex min-h-[280px] w-full items-center justify-center overflow-hidden border-b border-border bg-gradient-to-br from-accent/20 via-card to-accent-alt/20 md:min-h-0 md:w-[45%] md:border-b-0 md:border-r',
        className,
      )}
    >
      <span className="absolute -left-20 top-12 size-56 animate-aurora rounded-full bg-accent/30 blur-3xl" />
      <span className="absolute -bottom-16 right-4 size-64 animate-aurora rounded-full bg-accent-alt/25 blur-3xl [animation-delay:-4s]" />
      <span className="absolute left-1/3 top-1/3 size-32 animate-aurora rounded-full bg-cyan-400/15 blur-2xl [animation-delay:-7s]" />
      <div className="relative z-10 flex max-w-xs flex-col items-center px-8 text-center">
        <div className="mb-6 flex size-14 items-center justify-center rounded-lg border border-foreground/10 bg-foreground/5 ring-1 ring-foreground/5 backdrop-blur-sm transition-transform duration-500 hover:scale-110 hover:rotate-3">
          <span className="size-6 rotate-45 rounded-sm bg-gradient-to-tr from-accent to-accent-alt" />
        </div>
        <h2 className="text-xl font-semibold tracking-tight text-foreground">{title}</h2>
        <p className="mt-2 max-w-[22ch] text-sm text-muted-foreground">{subtitle}</p>
      </div>
    </aside>
  );
}
