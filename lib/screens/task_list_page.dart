import 'package:flutter/material.dart';
import 'task_edit_page.dart';
import '../services/api_service.dart';
import '../services/error_handler.dart';
import '../services/loading_service.dart';
import '../widgets/loading_widget.dart';
import '../models/task.dart';

class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  final ApiService _apiService = ApiService();
  final ErrorHandler _errorHandler = ErrorHandler();
  final LoadingService _loadingService = LoadingService();
  List<Task> _tasks = [];
  bool _isInitialLoading = true;
  String? _errorMessage;
  final Set<String> _completingTaskUuids = {}; // 完了状態切り替え中のタスクUUID

  static const String _loadingOperation = 'load_tasks';
  static const String _loadingOperationDelete = 'delete_task';

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  // 予定一覧を取得
  Future<void> _loadTasks() async {
    setState(() {
      _errorMessage = null;
    });
    _loadingService.setLoading(_loadingOperation, true);

    try {
      final tasks = await _apiService.getTasks();
      setState(() {
        _tasks = tasks;
        _isInitialLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = _errorHandler.getErrorMessage(e);
        _isInitialLoading = false;
      });
      _errorHandler.logError(e, context: '予定一覧取得');
    } finally {
      _loadingService.setLoading(_loadingOperation, false);
    }
  }

  // プルリフレッシュ
  Future<void> _handleRefresh() async {
    await _loadTasks();
  }

  // 予定完了状態切り替え
  Future<void> _toggleTaskCompletion(Task task) async {
    final newCompletionState = !task.isCompleted;

    setState(() {
      _completingTaskUuids.add(task.uuid);
    });

    try {
      final updatedTask = await _apiService.toggleTaskCompletion(
        uuid: task.uuid,
        isCompleted: newCompletionState,
      );

      // タスクリストを更新
      setState(() {
        final index = _tasks.indexWhere((t) => t.uuid == task.uuid);
        if (index != -1) {
          _tasks[index] = updatedTask;
        }
        _completingTaskUuids.remove(task.uuid);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newCompletionState ? '予定を完了にしました' : '予定を未完了にしました',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _completingTaskUuids.remove(task.uuid);
      });
      if (mounted) {
        _errorHandler.handleError(
          context,
          e,
          contextMessage: '予定完了状態切り替え',
        );
      }
    }
  }

  // 予定削除
  Future<void> _deleteTask(Task task) async {
    final taskUuid = task.uuid;
    if (taskUuid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('予定のUUIDが見つかりません'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('予定を削除'),
          content: const Text('この予定を削除しますか？\nこの操作は取り消せません。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('削除'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _errorMessage = null;
    });
    _loadingService.setLoading(_loadingOperationDelete, true);

    try {
      await _apiService.deleteTask(taskUuid);
      // 削除成功後、一覧を再読み込み
      await _loadTasks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('予定を削除しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _errorHandler.getErrorMessage(e);
        });
        _errorHandler.handleError(
          context,
          e,
          contextMessage: '予定削除',
        );
      }
    } finally {
      _loadingService.setLoading(_loadingOperationDelete, false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return LoadingWidget(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('予定一覧'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    // 初期ローディング中
    if (_isInitialLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // エラー表示
    if (_errorMessage != null && _tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'エラーが発生しました',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[800],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadTasks,
              icon: const Icon(Icons.refresh),
              label: const Text('再試行'),
            ),
          ],
        ),
      );
    }

    // 空データ状態
    if (_tasks.isEmpty) {
      return RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.task_alt,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '予定がありません',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '新しい予定を追加してみましょう',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // 予定一覧表示
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          final task = _tasks[index];

          final isCompleting = _completingTaskUuids.contains(task.uuid);

          return Card(
            key: Key(task.uuid),
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: GestureDetector(
                onTap: isCompleting ? null : () => _toggleTaskCompletion(task),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: task.isCompleted
                        ? Colors.green.withOpacity(0.2)
                        : Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: isCompleting
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : Icon(
                          task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: task.isCompleted
                              ? Colors.green
                              : Theme.of(context).colorScheme.primary,
                          size: 28,
                        ),
                ),
              ),
              title: Text(
                task.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  decoration: task.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${task.scheduledDate.year}/${task.scheduledDate.month.toString().padLeft(2, '0')}/${task.scheduledDate.day.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${task.scheduledTime.hour.toString().padLeft(2, '0')}:${task.scheduledTime.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  if (task.memo != null && task.memo!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.memo!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    color: Colors.grey[600],
                    onPressed: isCompleting ? null : () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TaskEditPage(task: task),
                        ),
                      );
                      // 編集画面から戻ってきたら、削除された可能性があるので一覧を再読み込み
                      if (result == true) {
                        _loadTasks();
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    color: Colors.red[400],
                    onPressed: isCompleting ? null : () => _deleteTask(task),
                  ),
                ],
              ),
              onTap: isCompleting ? null : () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TaskEditPage(task: task),
                  ),
                );
                // 編集画面から戻ってきたら、削除された可能性があるので一覧を再読み込み
                if (result == true) {
                  _loadTasks();
                }
              },
            ),
          );
        },
      ),
    );
  }
}
