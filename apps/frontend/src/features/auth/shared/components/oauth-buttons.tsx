'use client';

import { Github } from 'lucide-react';
import { signIn } from 'next-auth/react';

import { authProviders } from '@/lib/auth-providers';

type OAuthButtonsProps = {
  callbackUrl?: string;
};

export function OAuthButtons({ callbackUrl = '/todos' }: OAuthButtonsProps) {
  return (
    <div className="grid grid-cols-2 gap-3">
      <button
        type="button"
        className="group flex items-center justify-center gap-2 rounded-lg border border-border bg-foreground/5 py-2 transition-all duration-300 hover:border-accent/40 hover:bg-foreground/10 disabled:cursor-not-allowed disabled:opacity-50"
        disabled={!callbackUrl}
        onClick={() => void signIn(authProviders.google, { redirectTo: callbackUrl })}
      >
        <GoogleIcon className="size-4 text-foreground transition-transform duration-300 group-hover:scale-110" />
        <span className="text-xs font-medium">Google</span>
      </button>
      <button
        type="button"
        className="group flex items-center justify-center gap-2 rounded-lg border border-border bg-foreground/5 py-2 transition-all duration-300 hover:border-accent/40 hover:bg-foreground/10 disabled:cursor-not-allowed disabled:opacity-50"
        disabled={!callbackUrl}
        onClick={() => void signIn(authProviders.github, { redirectTo: callbackUrl })}
      >
        <Github className="size-4 text-foreground transition-transform duration-300 group-hover:scale-110" />
        <span className="text-xs font-medium">GitHub</span>
      </button>
    </div>
  );
}

function GoogleIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" className={className}>
      <path
        fill="currentColor"
        d="M21.8 12.23c0-.76-.07-1.49-.2-2.18H12v4.13h5.49a4.7 4.7 0 0 1-2.03 3.08v2.67h3.29c1.93-1.79 3.05-4.42 3.05-7.7Z"
      />
      <path
        fill="currentColor"
        opacity="0.75"
        d="M12 22c2.76 0 5.08-.93 6.77-2.53l-3.29-2.67c-.91.62-2.08.98-3.48.98-2.67 0-4.93-1.88-5.74-4.39H2.87v2.76A10.07 10.07 0 0 0 12 22Z"
      />
      <path
        fill="currentColor"
        opacity="0.55"
        d="M6.26 13.39a6.34 6.34 0 0 1 0-4.05V6.58H2.87a10.18 10.18 0 0 0 0 9.57l3.39-2.76Z"
      />
      <path
        fill="currentColor"
        opacity="0.9"
        d="M12 5.56c1.5 0 2.85.54 3.91 1.6l2.93-2.93A9.79 9.79 0 0 0 12 1.34a10.07 10.07 0 0 0-9.13 5.24l3.39 2.76C7.07 6.83 9.33 5.56 12 5.56Z"
      />
    </svg>
  );
}
