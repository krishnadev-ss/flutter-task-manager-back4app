import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/routes.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/task_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  bool _searchVisible = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(_onTabChanged);

    // Load tasks after first frame so providers are ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadTasks();
    });
  }

  void _onTabChanged() {
    if (_tabCtrl.indexIsChanging) return;
    final filters = [TaskFilter.all, TaskFilter.active, TaskFilter.completed];
    context.read<TaskProvider>().setFilter(filters[_tabCtrl.index]);
  }

  @override
  void dispose() {
    _tabCtrl
      ..removeListener(_onTabChanged)
      ..dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Confirm delete dialog ──────────────────────────────────────────────────

  Future<void> _confirmDelete(BuildContext ctx, String objectId, String title) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('Are you sure you want to delete "$title"? '
            'This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && ctx.mounted) {
      final ok = await ctx.read<TaskProvider>().deleteTask(objectId);
      if (!ok && ctx.mounted) {
        _showError(ctx, ctx.read<TaskProvider>().errorMessage ?? 'Delete failed');
      }
    }
  }

  // ── Logout dialog ─────────────────────────────────────────────────────────

  Future<void> _confirmLogout(BuildContext ctx) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (d) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again to access your tasks.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed == true && ctx.mounted) {
      await ctx.read<AuthProvider>().logout();
      if (ctx.mounted) {
        Navigator.of(ctx).pushReplacementNamed(AppRoutes.login);
      }
    }
  }

  void _showError(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Theme.of(ctx).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: _searchVisible
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search tasks…',
                  border: InputBorder.none,
                ),
                onChanged: (q) =>
                    context.read<TaskProvider>().setSearchQuery(q),
              )
            : const Text(
                'My Tasks',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
        actions: [
          // Search toggle
          IconButton(
            icon: Icon(_searchVisible ? Icons.close : Icons.search_rounded),
            tooltip: _searchVisible ? 'Close search' : 'Search',
            onPressed: () {
              setState(() => _searchVisible = !_searchVisible);
              if (!_searchVisible) {
                _searchCtrl.clear();
                context.read<TaskProvider>().setSearchQuery('');
              }
            },
          ),
          // Profile / logout menu
          if (user != null)
            PopupMenuButton<String>(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(
                    user.initial,
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              itemBuilder: (_) => [
                PopupMenuItem(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded),
                      SizedBox(width: 10),
                      Text('Sign out'),
                    ],
                  ),
                ),
              ],
              onSelected: (v) {
                if (v == 'logout') _confirmLogout(context);
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: [
            _CountTab(label: 'All', count: context.watch<TaskProvider>().totalCount),
            _CountTab(label: 'Active', count: context.watch<TaskProvider>().activeCount),
            _CountTab(
                label: 'Done', count: context.watch<TaskProvider>().completedCount),
          ],
        ),
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, _) {
          // Error banner
          if (taskProvider.errorMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _showError(context, taskProvider.errorMessage!);
                taskProvider.clearError();
              }
            });
          }

          // Full-screen loader (only on first load)
          if (taskProvider.status == TaskStatus.loading &&
              taskProvider.totalCount == 0) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error state (first load failed)
          if (taskProvider.status == TaskStatus.error &&
              taskProvider.totalCount == 0) {
            return _ErrorState(
              onRetry: () => taskProvider.loadTasks(),
            );
          }

          return TabBarView(
            controller: _tabCtrl,
            children: [
              _TaskList(
                filter: TaskFilter.all,
                onDelete: _confirmDelete,
              ),
              _TaskList(
                filter: TaskFilter.active,
                onDelete: _confirmDelete,
              ),
              _TaskList(
                filter: TaskFilter.completed,
                onDelete: _confirmDelete,
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.addTask),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Task'),
      ),
    );
  }
}

// ── Private sub-widgets ────────────────────────────────────────────────────

class _CountTab extends StatelessWidget {
  const _CountTab({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TaskList extends StatelessWidget {
  const _TaskList({
    required this.filter,
    required this.onDelete,
  });

  final TaskFilter filter;
  final Future<void> Function(BuildContext, String, String) onDelete;

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final tasks = taskProvider.tasks;

    if (taskProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (tasks.isEmpty) {
      return _emptyState(context, filter, taskProvider.searchQuery);
    }

    return RefreshIndicator(
      onRefresh: () => taskProvider.loadTasks(),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        itemCount: tasks.length,
        itemBuilder: (ctx, i) {
          final task = tasks[i];
          return TaskCard(
            key: ValueKey(task.objectId),
            task: task,
            onTap: () => Navigator.of(ctx).pushNamed(
              AppRoutes.editTask,
              arguments: task,
            ),
            onToggle: () => taskProvider.toggleCompletion(task),
            onDelete: () => onDelete(ctx, task.objectId!, task.title),
          );
        },
      ),
    );
  }

  Widget _emptyState(BuildContext ctx, TaskFilter f, String query) {
    if (query.isNotEmpty) {
      return EmptyStateWidget(
        icon: Icons.search_off_rounded,
        title: 'No results found',
        subtitle: 'No tasks match "$query". Try a different search term.',
      );
    }
    switch (f) {
      case TaskFilter.all:
        return EmptyStateWidget(
          icon: Icons.inbox_outlined,
          title: 'No tasks yet',
          subtitle: 'Tap the button below to create your first task.',
          actionLabel: 'Add Task',
          onAction: () => Navigator.of(ctx).pushNamed(AppRoutes.addTask),
        );
      case TaskFilter.active:
        return const EmptyStateWidget(
          icon: Icons.check_circle_outline_rounded,
          title: 'All caught up!',
          subtitle: 'You have no active tasks. Great work!',
        );
      case TaskFilter.completed:
        return const EmptyStateWidget(
          icon: Icons.playlist_add_check_rounded,
          title: 'Nothing completed yet',
          subtitle: 'Complete a task and it will appear here.',
        );
    }
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load tasks',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Check your internet connection and try again.',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
