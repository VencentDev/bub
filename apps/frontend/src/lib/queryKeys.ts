export const qk = {
  me: () => ['me'] as const,
  todos: {
    all: () => ['todos'] as const,
    lists: () => ['todos', 'list'] as const,
    list: (filters: { status?: string; page?: number }) => ['todos', 'list', filters] as const,
    detail: (id: string) => ['todos', 'detail', id] as const,
  },
};
