'use client';

import { useQuery } from '@tanstack/react-query';
import { useSession } from 'next-auth/react';

import { clientApi } from '@/lib/api';
import { qk } from '@/lib/queryKeys';

import type { paths } from '@app/api-types';

type Me = paths['/api/v1/users/me']['get']['responses']['200']['content']['application/json'];

export function useMe() {
  const { data: session } = useSession();

  return useQuery({
    queryKey: qk.me(),
    queryFn: () => clientApi<Me>(session?.accessToken, '/api/v1/users/me'),
    enabled: !!session?.accessToken,
  });
}
