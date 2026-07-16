'use client';

import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { useTodoFiltersStore } from '@/features/todos/list/hooks/use-todo-filters-store';

type TodoStatusFilter = 'ALL' | 'TODO' | 'IN_PROGRESS' | 'DONE';

export function TodoFilters() {
  const { status, setStatus } = useTodoFiltersStore();

  return (
    <div className="flex items-center justify-between gap-3 rounded-md border bg-card p-3">
      <p className="text-sm font-medium">Status</p>
      <Select value={status} onValueChange={(value) => setStatus(value as TodoStatusFilter)}>
        <SelectTrigger className="w-44">
          <SelectValue />
        </SelectTrigger>
        <SelectContent>
          <SelectItem value="ALL">All</SelectItem>
          <SelectItem value="TODO">To do</SelectItem>
          <SelectItem value="IN_PROGRESS">In progress</SelectItem>
          <SelectItem value="DONE">Done</SelectItem>
        </SelectContent>
      </Select>
    </div>
  );
}
