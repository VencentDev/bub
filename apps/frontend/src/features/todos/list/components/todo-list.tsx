'use client';

import { ClipboardList } from 'lucide-react';

import { TodoCard } from '@/features/todos/list/components/todo-card';
import { TodoCreateButton } from '@/features/todos/list/components/todo-create-button';

import type { Todo } from '@/features/todos/list/api/todos.hooks';

export function TodoList({ todos }: { todos: Todo[] }) {
  if (todos.length === 0) {
    return (
      <div className="flex min-h-72 flex-col items-center justify-center rounded-md border border-dashed bg-card p-8 text-center">
        <ClipboardList className="mb-4 h-12 w-12 text-muted-foreground" />
        <h2 className="text-lg font-semibold">No todos yet</h2>
        <p className="mt-1 max-w-sm text-sm text-muted-foreground">
          Create the first item for this filtered view.
        </p>
        <div className="mt-5">
          <TodoCreateButton label="Create your first todo" />
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-3">
      {todos.map((todo) => (
        <TodoCard key={todo.id} todo={todo} />
      ))}
    </div>
  );
}
