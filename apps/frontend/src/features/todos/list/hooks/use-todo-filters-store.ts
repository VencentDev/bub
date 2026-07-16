import { create } from 'zustand';

import type { paths } from '@app/api-types';

type TodoStatus = NonNullable<paths['/api/v1/todos']['get']['parameters']['query']>['status'];
type TodoStatusFilter = TodoStatus | 'ALL';

export type TodoFiltersState = {
  status: TodoStatusFilter;
  page: number;
  setStatus: (status: TodoStatusFilter) => void;
  setPage: (page: number) => void;
  reset: () => void;
};

const initialState = {
  status: 'ALL' as const,
  page: 0,
};

export const useTodoFiltersStore = create<TodoFiltersState>((set) => ({
  ...initialState,
  setStatus: (status) => set({ status, page: 0 }),
  setPage: (page) => set({ page }),
  reset: () => set(initialState),
}));
