'use client';

import { Moon, Sun } from 'lucide-react';
import { useTheme } from 'next-themes';
import { useEffect, useState } from 'react';

import { Button } from '@/components/ui/button';

export function ThemeToggle() {
  const { resolvedTheme, setTheme } = useTheme();
  const [mounted, setMounted] = useState(false);
  const nextTheme = resolvedTheme === 'dark' ? 'light' : 'dark';

  useEffect(() => {
    setMounted(true);
  }, []);

  return (
    <Button
      aria-label="Toggle theme"
      title="Toggle theme"
      size="icon"
      variant="ghost"
      disabled={!mounted}
      onClick={() => setTheme(nextTheme)}
    >
      <Sun className="h-4 w-4 rotate-0 scale-100 transition-all dark:-rotate-90 dark:scale-0" />
      <Moon className="absolute h-4 w-4 rotate-90 scale-0 transition-all dark:rotate-0 dark:scale-100" />
    </Button>
  );
}
