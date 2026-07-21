import 'package:flutter/material.dart';

Future<bool?> showSafeDeleteConfirmation(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete from Safe?'),
      content: const Text('This removes the item from the shared Safe.'),
      actions: [
        TextButton(
          key: const Key('safe-delete-cancel'),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('safe-delete-confirm'),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}
