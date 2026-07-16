'use client';

import { Plus } from 'lucide-react';
import { useState } from 'react';

import { Button } from '@/components/ui/button';
import { TodoFormSheet } from '@/features/todos/list/components/todo-form-sheet';

export function TodoCreateButton({ label = 'New todo' }: { label?: string }) {
  const [open, setOpen] = useState(false);

  return (
    <>
      <Button onClick={() => setOpen(true)}>
        <Plus className="mr-2 h-4 w-4" />
        {label}
      </Button>
      <TodoFormSheet open={open} onOpenChange={setOpen} />
    </>
  );
}
