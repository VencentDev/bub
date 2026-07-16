import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/generated/models/todo_response.dart';
import '../../api/generated/models/todo_status.dart';
import '../../api/generated/models/user_response.dart';
import 'todos_controller.dart';

class TodosScreen extends ConsumerWidget {
  const TodosScreen({required this.user, required this.onLogout, super.key});

  final UserResponse user;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(todosControllerProvider);
    final controller = ref.read(todosControllerProvider.notifier);
    final current = todos.asData?.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Todos'),
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: onLogout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: current?.isSaving == true
            ? null
            : () => _showTodoSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New'),
      ),
      body: RefreshIndicator(
        onRefresh: controller.refresh,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _TodoHeader(user: user, state: current),
            ),
            SliverToBoxAdapter(
              child: _TodoFilters(
                selected: current?.filter ?? TodoFilter.all,
                onSelected: controller.setFilter,
              ),
            ),
            switch (todos) {
              AsyncLoading(:final value) when value == null =>
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                ),
              AsyncError(:final error) => SliverFillRemaining(
                hasScrollBody: false,
                child: _TodoError(error: error, onRetry: controller.refresh),
              ),
              AsyncData(value: final state) when state.todos.isEmpty =>
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyTodos(filter: state.filter),
                ),
              _ => SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                sliver: SliverList.separated(
                  itemCount: current?.todos.length ?? 0,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final todo = current!.todos[index];
                    return _TodoCard(
                      todo: todo,
                      isSaving: current.isSaving,
                      onToggle: () => controller.toggleTodo(todo),
                      onDelete: () => controller.deleteTodo(todo),
                    );
                  },
                ),
              ),
            },
          ],
        ),
      ),
    );
  }

  Future<void> _showTodoSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _TodoFormSheet(
        onSubmit: (title, description) => ref
            .read(todosControllerProvider.notifier)
            .createTodo(title: title, description: description),
      ),
    );
  }
}

class _TodoHeader extends StatelessWidget {
  const _TodoHeader({required this.user, required this.state});

  final UserResponse user;
  final TodosState? state;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today',
            style: text.displaySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            user.displayName?.isNotEmpty == true
                ? user.displayName!
                : user.email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.bodyLarge?.copyWith(color: Theme.of(context).hintColor),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _SummaryTile(
                  label: 'Open',
                  value: '${state?.openCount ?? 0}',
                  icon: Icons.radio_button_unchecked,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryTile(
                  label: 'Done',
                  value: '${state?.doneCount ?? 0}',
                  icon: Icons.check_circle_outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: colors.primary),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(label),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TodoFilters extends StatelessWidget {
  const _TodoFilters({required this.selected, required this.onSelected});

  final TodoFilter selected;
  final ValueChanged<TodoFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          for (final filter in TodoFilter.values) ...[
            ChoiceChip(
              label: Text(filter.label),
              selected: filter == selected,
              onSelected: (_) => onSelected(filter),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _TodoCard extends StatelessWidget {
  const _TodoCard({
    required this.todo,
    required this.isSaving,
    required this.onToggle,
    required this.onDelete,
  });

  final TodoResponse todo;
  final bool isSaving;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final done = todo.status == TodoStatus.done;
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        child: ListTile(
          leading: IconButton(
            tooltip: done ? 'Mark todo' : 'Mark done',
            onPressed: isSaving ? null : onToggle,
            icon: Icon(
              done ? Icons.check_circle : Icons.radio_button_unchecked,
              color: done ? colors.primary : colors.outline,
            ),
          ),
          title: Text(
            todo.title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              decoration: done ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: todo.description?.isNotEmpty == true
              ? Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(todo.description!),
                )
              : null,
          trailing: IconButton(
            tooltip: 'Delete',
            onPressed: isSaving ? null : onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ),
      ),
    );
  }
}

class _TodoFormSheet extends StatefulWidget {
  const _TodoFormSheet({required this.onSubmit});

  final Future<void> Function(String title, String? description) onSubmit;

  @override
  State<_TodoFormSheet> createState() => _TodoFormSheetState();
}

class _TodoFormSheetState extends State<_TodoFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'New todo',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _title,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Title is required'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_task),
              label: const Text('Create todo'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final description = _description.text.trim();
    await widget.onSubmit(
      _title.text.trim(),
      description.isEmpty ? null : description,
    );
    if (mounted) Navigator.of(context).pop();
  }
}

class _EmptyTodos extends StatelessWidget {
  const _EmptyTodos({required this.filter});

  final TodoFilter filter;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.task_alt,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              filter == TodoFilter.done ? 'No completed todos' : 'No todos yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Create a todo to test the backend flow from mobile.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _TodoError extends StatelessWidget {
  const _TodoError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              'Could not load todos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              '$error',
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
