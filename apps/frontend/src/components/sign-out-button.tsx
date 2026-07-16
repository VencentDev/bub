'use client';

import { LogOut } from 'lucide-react';
import { signOut } from 'next-auth/react';

import { Button } from '@/components/ui/button';

export function SignOutButton() {
  return (
    <Button
      type="button"
      variant="outline"
      size="sm"
      className="gap-2"
      onClick={() => void signOut({ redirectTo: '/login' })}
    >
      <LogOut className="size-4" aria-hidden="true" />
      <span>Sign out</span>
    </Button>
  );
}
