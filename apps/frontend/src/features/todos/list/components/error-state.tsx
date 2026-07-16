'use client';

import { signIn } from 'next-auth/react';
import { useEffect } from 'react';

import { Button } from '@/components/ui/button';
import { ApiError } from '@/lib/api';

export function ErrorState({ error }: { error: unknown }) {
  useEffect(() => {
    if (error instanceof ApiError && error.status === 401) {
      void signIn();
    }
  }, [error]);

  if (error instanceof ApiError) {
    if (error.status === 401) {
      return (
        <InlineError
          title="Redirecting to sign in"
          message="Your session needs to be refreshed."
          action={
            <Button size="sm" onClick={() => void signIn()}>
              Sign in
            </Button>
          }
        />
      );
    }

    if (error.status === 403) {
      return <InlineError title="Forbidden" message="You do not have access to these todos." />;
    }

    if (error.status === 404) {
      return <InlineError title="Not found" message="That todo does not exist." />;
    }
  }

  return <InlineError title="Something went wrong" message="Please try again." />;
}

function InlineError({
  title,
  message,
  action,
}: {
  title: string;
  message: string;
  action?: React.ReactNode;
}) {
  return (
    <div className="flex items-center justify-between gap-4 rounded-md border border-destructive/30 bg-destructive/5 p-4">
      <div>
        <p className="font-semibold">{title}</p>
        <p className="text-sm text-muted-foreground">{message}</p>
      </div>
      {action}
    </div>
  );
}
