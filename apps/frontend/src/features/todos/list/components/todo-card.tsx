'use client';

import { CalendarDays, Pencil, Trash2 } from 'lucide-react';
import { useState } from 'react';

import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { toast } from '@/components/ui/use-toast';
import { useDeleteTodo } from '@/features/todos/list/api/todos.hooks';
import { TodoFormSheet } from '@/features/todos/list/components/todo-form-sheet';

import type { Todo } from '@/features/todos/list/api/todos.hooks';

const statusLabel: Record<Todo['status'], string> = {
  TODO: 'To do',
  IN_PROGRESS: 'In progress',
  DONE: 'Done',
};

export function TodoCard({ todo }: { todo: Todo }) {
  const [editing, setEditing] = useState(false);
  const del = useDeleteTodo();

  async function onDelete() {
    if (!window.confirm('Delete this todo?')) {
      return;
    }

    try {
      await del.mutateAsync(todo.id);
      toast({ title: 'Deleted' });
    } catch (error) {
      toast({
        title: 'Failed',
        description: error instanceof Error ? error.message : String(error),
        variant: 'destructive',
      });
    }
  }

  return (
    <>
      <Card className="rounded-md">
        <CardContent className="flex flex-col gap-4 p-4 sm:flex-row sm:items-start sm:justify-between">
          <div className="min-w-0 space-y-2">
            <div className="flex flex-wrap items-center gap-2">
              <h2 className="break-words text-base font-semibold">{todo.title}</h2>
              <Badge variant={todo.status === 'DONE' ? 'secondary' : 'outline'}>
                {statusLabel[todo.status]}
              </Badge>
            </div>

            {todo.description && (
              <p className="whitespace-pre-wrap break-words text-sm text-muted-foreground">
                {todo.description}
              </p>
            )}

            {todo.dueDate && (
              <div className="flex items-center gap-2 text-xs text-muted-foreground">
                <CalendarDays className="h-4 w-4" />
                <time dateTime={todo.dueDate}>{todo.dueDate}</time>
              </div>
            )}
          </div>

          <div className="flex shrink-0 items-center gap-2">
            <Button
              type="button"
              variant="outline"
              size="icon"
              title="Edit todo"
              onClick={() => setEditing(true)}
            >
              <Pencil className="h-4 w-4" />
              <span className="sr-only">Edit todo</span>
            </Button>
            <Button
              type="button"
              variant="outline"
              size="icon"
              title="Delete todo"
              onClick={onDelete}
              disabled={del.isPending}
            >
              <Trash2 className="h-4 w-4" />
              <span className="sr-only">Delete todo</span>
            </Button>
          </div>
        </CardContent>
      </Card>

      <TodoFormSheet open={editing} onOpenChange={setEditing} todo={todo} />
    </>
  );
}
