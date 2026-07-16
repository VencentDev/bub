'use client';

import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useSession } from 'next-auth/react';

import { clientApi } from '@/lib/api';
import { qk } from '@/lib/queryKeys';

import type { paths } from '@app/api-types';

type ListParams = paths['/api/v1/todos']['get']['parameters']['query'];
type ListResp = paths['/api/v1/todos']['get']['responses']['200']['content']['application/json'];
type CreateBody = paths['/api/v1/todos']['post']['requestBody']['content']['application/json'];
type UpdateBody =
  paths['/api/v1/todos/{id}']['patch']['requestBody']['content']['application/json'];
export type Todo =
  paths['/api/v1/todos']['post']['responses']['201']['content']['application/json'];
export type TodoStatus = Todo['status'];
type TodoFilters = Pick<NonNullable<ListParams>, 'status' | 'page'>;

function applyTodoPatch(todo: Todo, body: UpdateBody): Todo {
  return {
    ...todo,
    ...(body.title != null ? { title: body.title } : {}),
    ...(body.description !== undefined ? { description: body.description } : {}),
    ...(body.status != null ? { status: body.status } : {}),
    ...(body.dueDate !== undefined ? { dueDate: body.dueDate } : {}),
  };
}

export function useTodos(filters: TodoFilters = {}) {
  const { data: session } = useSession();
  const params = new URLSearchParams();

  if (filters.status) {
    params.set('status', filters.status);
  }

  if (filters.page !== undefined) {
    params.set('page', String(filters.page));
  }

  const query = params.toString();

  return useQuery({
    queryKey: qk.todos.list(filters),
    queryFn: () =>
      clientApi<ListResp>(session?.accessToken, query ? `/api/v1/todos?${query}` : '/api/v1/todos'),
    enabled: !!session?.accessToken,
  });
}

export function useCreateTodo() {
  const { data: session } = useSession();
  const qc = useQueryClient();

  return useMutation({
    mutationFn: (body: CreateBody) =>
      clientApi<Todo>(session?.accessToken, '/api/v1/todos', {
        method: 'POST',
        body: JSON.stringify(body),
      }),
    onMutate: async (body) => {
      await qc.cancelQueries({ queryKey: qk.todos.all() });

      const previousLists = qc.getQueriesData<ListResp>({
        queryKey: qk.todos.lists(),
      });
      const now = new Date().toISOString();
      const optimisticTodo: Todo = {
        id: `optimistic-${crypto.randomUUID()}`,
        title: body.title,
        description: body.description ?? null,
        status: body.status,
        dueDate: body.dueDate ?? null,
        createdAt: now,
        updatedAt: now,
      };

      previousLists.forEach(([key, data]) => {
        if (!data) {
          return;
        }

        const filters = Array.isArray(key) ? (key[2] as TodoFilters | undefined) : undefined;
        if (filters?.status && filters.status !== optimisticTodo.status) {
          return;
        }

        qc.setQueryData<ListResp>(key, {
          ...data,
          content: [optimisticTodo, ...data.content],
          totalElements: data.totalElements + 1,
        });
      });

      return { previousLists };
    },
    onError: (_e, _body, context) => {
      context?.previousLists.forEach(([key, data]) => qc.setQueryData(key, data));
    },
    onSettled: () => qc.invalidateQueries({ queryKey: qk.todos.all() }),
  });
}

export function useUpdateTodo() {
  const { data: session } = useSession();
  const qc = useQueryClient();

  return useMutation({
    mutationFn: ({ id, body }: { id: string; body: UpdateBody }) =>
      clientApi<Todo>(session?.accessToken, `/api/v1/todos/${id}`, {
        method: 'PATCH',
        body: JSON.stringify(body),
      }),
    onMutate: async ({ id, body }) => {
      await qc.cancelQueries({ queryKey: qk.todos.all() });

      const previousLists = qc.getQueriesData<ListResp>({
        queryKey: qk.todos.lists(),
      });
      const previousDetail = qc.getQueryData<Todo>(qk.todos.detail(id));

      qc.setQueriesData<ListResp>({ queryKey: qk.todos.lists() }, (data) => {
        if (!data) {
          return data;
        }

        return {
          ...data,
          content: data.content.map((todo) => (todo.id === id ? applyTodoPatch(todo, body) : todo)),
        };
      });
      qc.setQueryData<Todo>(qk.todos.detail(id), (todo) =>
        todo ? applyTodoPatch(todo, body) : todo,
      );

      return { previousLists, previousDetail };
    },
    onError: (_e, variables, context) => {
      context?.previousLists.forEach(([key, data]) => qc.setQueryData(key, data));

      if (context?.previousDetail) {
        qc.setQueryData(qk.todos.detail(variables.id), context.previousDetail);
      }
    },
    onSettled: (_data, _error, variables) => {
      void qc.invalidateQueries({ queryKey: qk.todos.all() });
      void qc.invalidateQueries({ queryKey: qk.todos.detail(variables.id) });
    },
  });
}

export function useDeleteTodo() {
  const { data: session } = useSession();
  const qc = useQueryClient();

  return useMutation({
    mutationFn: (id: string) =>
      clientApi<void>(session?.accessToken, `/api/v1/todos/${id}`, {
        method: 'DELETE',
      }),
    onMutate: async (id) => {
      await qc.cancelQueries({ queryKey: qk.todos.all() });

      const previousLists = qc.getQueriesData<ListResp>({
        queryKey: qk.todos.lists(),
      });
      const previousDetail = qc.getQueryData<Todo>(qk.todos.detail(id));

      qc.setQueriesData<ListResp>({ queryKey: qk.todos.lists() }, (data) => {
        if (!data) {
          return data;
        }

        const nextContent = data.content.filter((todo) => todo.id !== id);

        return {
          ...data,
          content: nextContent,
          totalElements:
            nextContent.length === data.content.length
              ? data.totalElements
              : Math.max(0, data.totalElements - 1),
        };
      });
      qc.removeQueries({ queryKey: qk.todos.detail(id) });

      return { previousLists, previousDetail };
    },
    onError: (_e, id, context) => {
      context?.previousLists.forEach(([key, data]) => qc.setQueryData(key, data));

      if (context?.previousDetail) {
        qc.setQueryData(qk.todos.detail(id), context.previousDetail);
      }
    },
    onSettled: (_data, _error, id) => {
      void qc.invalidateQueries({ queryKey: qk.todos.all() });
      void qc.invalidateQueries({ queryKey: qk.todos.detail(id) });
    },
  });
}
