'use client';

import { Loader2 } from 'lucide-react';
import { useEffect, useState } from 'react';

import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Sheet, SheetContent, SheetHeader, SheetTitle } from '@/components/ui/sheet';
import { Textarea } from '@/components/ui/textarea';
import { toast } from '@/components/ui/use-toast';
import { useCreateTodo, useUpdateTodo } from '@/features/todos/list/api/todos.hooks';

import type { Todo, TodoStatus } from '@/features/todos/list/api/todos.hooks';

export function TodoFormSheet({
  open,
  onOpenChange,
  todo,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  todo?: Todo;
}) {
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [status, setStatus] = useState<TodoStatus>('TODO');
  const [dueDate, setDueDate] = useState('');
  const create = useCreateTodo();
  const update = useUpdateTodo();
  const pending = create.isPending || update.isPending;

  useEffect(() => {
    if (!open) {
      return;
    }

    setTitle(todo?.title ?? '');
    setDescription(todo?.description ?? '');
    setStatus(todo?.status ?? 'TODO');
    setDueDate(todo?.dueDate ?? '');
  }, [open, todo]);

  async function onSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();

    const normalizedTitle = title.trim();
    if (!normalizedTitle) {
      toast({
        title: 'Title is required',
        description: 'Add a short title before saving.',
        variant: 'destructive',
      });
      return;
    }

    try {
      if (todo) {
        await update.mutateAsync({
          id: todo.id,
          body: {
            title: normalizedTitle === todo.title ? undefined : normalizedTitle,
            description: description === (todo.description ?? '') ? undefined : description,
            status: status === todo.status ? undefined : status,
            dueDate: dueDate === (todo.dueDate ?? '') ? undefined : dueDate || null,
          },
        });
      } else {
        await create.mutateAsync({
          title: normalizedTitle,
          description: description || undefined,
          status,
          dueDate: dueDate || undefined,
        });
      }

      toast({ title: todo ? 'Updated' : 'Created' });
      onOpenChange(false);
    } catch (error) {
      toast({
        title: 'Failed',
        description: error instanceof Error ? error.message : String(error),
        variant: 'destructive',
      });
    }
  }

  return (
    <Sheet open={open} onOpenChange={onOpenChange}>
      <SheetContent className="w-full overflow-y-auto sm:max-w-md">
        <SheetHeader>
          <SheetTitle>{todo ? 'Edit todo' : 'New todo'}</SheetTitle>
        </SheetHeader>

        <form className="mt-6 space-y-4" onSubmit={onSubmit}>
          <div className="space-y-2">
            <Label htmlFor="todo-title">Title</Label>
            <Input
              id="todo-title"
              value={title}
              onChange={(event) => setTitle(event.target.value)}
              placeholder="Follow up with client"
              disabled={pending}
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="todo-description">Description</Label>
            <Textarea
              id="todo-description"
              value={description}
              onChange={(event) => setDescription(event.target.value)}
              placeholder="Notes, context, or next steps"
              disabled={pending}
            />
          </div>

          <div className="grid gap-4 sm:grid-cols-2">
            <div className="space-y-2">
              <Label>Status</Label>
              <Select
                value={status}
                onValueChange={(value) => setStatus(value as TodoStatus)}
                disabled={pending}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="TODO">To do</SelectItem>
                  <SelectItem value="IN_PROGRESS">In progress</SelectItem>
                  <SelectItem value="DONE">Done</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <Label htmlFor="todo-due-date">Due date</Label>
              <Input
                id="todo-due-date"
                type="date"
                value={dueDate}
                onChange={(event) => setDueDate(event.target.value)}
                disabled={pending}
              />
            </div>
          </div>

          <Button type="submit" className="w-full" disabled={pending}>
            {pending && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
            Save
          </Button>
        </form>
      </SheetContent>
    </Sheet>
  );
}
