export const qk = {
  me: (accountKey?: string) => ['me', accountKey ?? 'anonymous'] as const,
};
