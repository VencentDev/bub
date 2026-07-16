'use client';

import { toast as sonnerToast } from 'sonner';

import type { ToastActionElement, ToastProps } from '@/components/ui/toast';
import type { ReactNode } from 'react';

export type ToastInput = ToastProps & {
  action?: ToastActionElement;
  title?: ReactNode;
  description?: ReactNode;
  variant?: 'default' | 'destructive';
};

export function toast(input: ToastInput) {
  const { title, description, action, variant, duration, id } = input;
  const message = title ?? description;
  const options = {
    action,
    description: title ? description : undefined,
    duration,
    id,
  };
  const toastId =
    variant === 'destructive' ? sonnerToast.error(message, options) : sonnerToast(message, options);

  return {
    id: toastId,
    dismiss: () => dismissToast(toastId),
  };
}

export function dismissToast(id?: string | number) {
  sonnerToast.dismiss(id);
}

export function removeToast(id?: string | number) {
  sonnerToast.dismiss(id);
}

export function useToast() {
  return {
    toast,
    toasts: [],
  };
}
