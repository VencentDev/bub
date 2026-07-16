import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/generated/models/todo_create_request.dart';
import '../../api/generated/models/todo_response.dart';
import '../../api/generated/models/todo_status.dart';
import '../../api/generated/models/todo_update_request.dart';
import '../../core/dio_provider.dart';

enum TodoFilter {
  all,
  todo,
  done;

  TodoStatus? get status => switch (this) {
    TodoFilter.all => null,
    TodoFilter.todo => TodoStatus.todo,
    TodoFilter.done => TodoStatus.done,
  };

  String get label => switch (this) {
    TodoFilter.all => 'All',
    TodoFilter.todo => 'Todo',
    TodoFilter.done => 'Done',
  };
}

class TodosState {
  const TodosState({
    required this.todos,
    this.filter = TodoFilter.all,
    this.isSaving = false,
  });

  final List<TodoResponse> todos;
  final TodoFilter filter;
  final bool isSaving;

  int get openCount =>
      todos.where((todo) => todo.status != TodoStatus.done).length;
  int get doneCount =>
      todos.where((todo) => todo.status == TodoStatus.done).length;

  TodosState copyWith({
    List<TodoResponse>? todos,
    TodoFilter? filter,
    bool? isSaving,
  }) => TodosState(
    todos: todos ?? this.todos,
    filter: filter ?? this.filter,
    isSaving: isSaving ?? this.isSaving,
  );
}

class TodosController extends AsyncNotifier<TodosState> {
  @override
  Future<TodosState> build() async => _load(TodoFilter.all);

  Future<TodosState> _load(TodoFilter filter) async {
    final page = await ref
        .read(restClientProvider)
        .fallback
        .listTodos(status: filter.status, sort: const ['createdAt,desc']);
    return TodosState(todos: page.content, filter: filter);
  }

  Future<void> refresh() async {
    final filter = state.asData?.value.filter ?? TodoFilter.all;
    state = const AsyncLoading<TodosState>();
    state = await AsyncValue.guard(() => _load(filter));
  }

  Future<void> setFilter(TodoFilter filter) async {
    if (state.asData?.value.filter == filter) return;
    state = const AsyncLoading<TodosState>();
    state = await AsyncValue.guard(() => _load(filter));
  }

  Future<void> createTodo({required String title, String? description}) async {
    final current = state.asData?.value;
    if (current == null) return;

    state = AsyncData(current.copyWith(isSaving: true));
    state = await AsyncValue.guard(() async {
      await ref
          .read(restClientProvider)
          .fallback
          .createTodo(
            body: TodoCreateRequest(
              title: title,
              description: description,
              status: TodoStatus.todo,
            ),
          );
      return _load(current.filter);
    });
  }

  Future<void> toggleTodo(TodoResponse todo) async {
    final current = state.asData?.value;
    if (current == null) return;

    final nextStatus = todo.status == TodoStatus.done
        ? TodoStatus.todo
        : TodoStatus.done;
    state = AsyncData(current.copyWith(isSaving: true));
    state = await AsyncValue.guard(() async {
      await ref
          .read(restClientProvider)
          .fallback
          .updateTodo(
            id: todo.id,
            body: TodoUpdateRequest(status: nextStatus),
          );
      return _load(current.filter);
    });
  }

  Future<void> deleteTodo(TodoResponse todo) async {
    final current = state.asData?.value;
    if (current == null) return;

    state = AsyncData(current.copyWith(isSaving: true));
    state = await AsyncValue.guard(() async {
      await ref.read(restClientProvider).fallback.deleteTodo(id: todo.id);
      return _load(current.filter);
    });
  }
}

final todosControllerProvider =
    AsyncNotifierProvider<TodosController, TodosState>(TodosController.new);
