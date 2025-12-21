import 'package:flutter/material.dart';
import 'task_edit_page.dart';
import '../services/api_service.dart';
import '../services/error_handler.dart';
import '../services/loading_service.dart';
import '../services/settings_service.dart';
import '../widgets/loading_widget.dart';
import '../models/task.dart';
import '../utils/time_formatter.dart';

// 並び替えタイプの列挙型
enum TaskSortType {
  dateAscending,        // 日付順
  createdAtAscending,   // 作成日順
  titleAscending,       // タイトル順
  completionStatus,     // 完了状態
}

class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  final ApiService _apiService = ApiService();
  final ErrorHandler _errorHandler = ErrorHandler();
  final LoadingService _loadingService = LoadingService();
  final SettingsService _settingsService = SettingsService();
  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];
  bool _isInitialLoading = true;
  String? _errorMessage;
  final Set<String> _completingTaskUuids = {}; // 完了状態切り替え中のタスクUUID

  // 検索・フィルタリング用の状態
  final TextEditingController _searchController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool? _completionFilter; // null: すべて, true: 完了のみ, false: 未完了のみ
  bool _showFilters = false;

  // 並び替え用の状態
  TaskSortType _sortType = TaskSortType.dateAscending;
  bool _sortAscending = true;

  static const String _loadingOperation = 'load_tasks';
  static const String _loadingOperationDelete = 'delete_task';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applyFilters);
    _settingsService.addListener(_onSettingsChanged);
    _loadTasks();
  }

  @override
  void dispose() {
    _settingsService.removeListener(_onSettingsChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) {
      setState(() {});
    }
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
      // フィルタリングを適用（初期状態ではすべて表示）
      _applyFilters();
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
      _applyFilters();

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
      // _loadTasks内で_applyFiltersが呼ばれるので、ここでは不要
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

  // 検索・フィルタリングを適用
  void _applyFilters() {
    setState(() {
      List<Task> filtered = _tasks.where((task) {
        // 検索キーワードでフィルタリング（タイトル・メモ）
        final searchQuery = _searchController.text.toLowerCase().trim();
        if (searchQuery.isNotEmpty) {
          final titleMatch = task.title.toLowerCase().contains(searchQuery);
          final memoMatch = task.memo?.toLowerCase().contains(searchQuery) ?? false;
          if (!titleMatch && !memoMatch) {
            return false;
          }
        }

        // 完了状態でフィルタリング
        if (_completionFilter != null) {
          if (task.isCompleted != _completionFilter) {
            return false;
          }
        }

        // 日付範囲でフィルタリング
        if (_startDate != null) {
          final taskDate = DateTime(
            task.scheduledDate.year,
            task.scheduledDate.month,
            task.scheduledDate.day,
          );
          final startDate = DateTime(
            _startDate!.year,
            _startDate!.month,
            _startDate!.day,
          );
          if (taskDate.isBefore(startDate)) {
            return false;
          }
        }

        if (_endDate != null) {
          final taskDate = DateTime(
            task.scheduledDate.year,
            task.scheduledDate.month,
            task.scheduledDate.day,
          );
          final endDate = DateTime(
            _endDate!.year,
            _endDate!.month,
            _endDate!.day,
          );
          if (taskDate.isAfter(endDate)) {
            return false;
          }
        }

        return true;
      }).toList();

      // 並び替えを適用
      _filteredTasks = _sortTasks(filtered);
    });
  }

  // タスクを並び替え
  List<Task> _sortTasks(List<Task> tasks) {
    final sorted = List<Task>.from(tasks);

    switch (_sortType) {
      case TaskSortType.dateAscending:
        sorted.sort((a, b) {
          final dateA = DateTime(
            a.scheduledDate.year,
            a.scheduledDate.month,
            a.scheduledDate.day,
            a.scheduledTime.hour,
            a.scheduledTime.minute,
          );
          final dateB = DateTime(
            b.scheduledDate.year,
            b.scheduledDate.month,
            b.scheduledDate.day,
            b.scheduledTime.hour,
            b.scheduledTime.minute,
          );
          return _sortAscending
              ? dateA.compareTo(dateB)
              : dateB.compareTo(dateA);
        });
        break;
      case TaskSortType.createdAtAscending:
        sorted.sort((a, b) {
          return _sortAscending
              ? a.createdAt.compareTo(b.createdAt)
              : b.createdAt.compareTo(a.createdAt);
        });
        break;
      case TaskSortType.titleAscending:
        sorted.sort((a, b) {
          final comparison = a.title.compareTo(b.title);
          return _sortAscending ? comparison : -comparison;
        });
        break;
      case TaskSortType.completionStatus:
        sorted.sort((a, b) {
          // 未完了を先に、完了を後に
          if (a.isCompleted == b.isCompleted) {
            // 同じ状態の場合は日付順
            final dateA = DateTime(
              a.scheduledDate.year,
              a.scheduledDate.month,
              a.scheduledDate.day,
              a.scheduledTime.hour,
              a.scheduledTime.minute,
            );
            final dateB = DateTime(
              b.scheduledDate.year,
              b.scheduledDate.month,
              b.scheduledDate.day,
              b.scheduledTime.hour,
              b.scheduledTime.minute,
            );
            return dateA.compareTo(dateB);
          }
          return a.isCompleted ? 1 : -1;
        });
        break;
    }

    return sorted;
  }

  // フィルターをリセット
  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _startDate = null;
      _endDate = null;
      _completionFilter = null;
      _showFilters = false;
    });
    _applyFilters();
  }

  // 開始日を選択
  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
      _applyFilters();
    }
  }

  // 終了日を選択
  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
      _applyFilters();
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
          actions: [
            // 並び替えボタン
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort),
              tooltip: '並び替え',
              onSelected: (value) {
                setState(() {
                  switch (value) {
                    case 'date_asc':
                      _sortType = TaskSortType.dateAscending;
                      _sortAscending = true;
                      break;
                    case 'date_desc':
                      _sortType = TaskSortType.dateAscending;
                      _sortAscending = false;
                      break;
                    case 'created_asc':
                      _sortType = TaskSortType.createdAtAscending;
                      _sortAscending = true;
                      break;
                    case 'created_desc':
                      _sortType = TaskSortType.createdAtAscending;
                      _sortAscending = false;
                      break;
                    case 'title_asc':
                      _sortType = TaskSortType.titleAscending;
                      _sortAscending = true;
                      break;
                    case 'title_desc':
                      _sortType = TaskSortType.titleAscending;
                      _sortAscending = false;
                      break;
                    case 'completion':
                      _sortType = TaskSortType.completionStatus;
                      break;
                  }
                });
                _applyFilters();
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'date_asc',
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 20),
                      SizedBox(width: 8),
                      Text('日付順（昇順）'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'date_desc',
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 20),
                      SizedBox(width: 8),
                      Text('日付順（降順）'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'created_asc',
                  child: Row(
                    children: [
                      Icon(Icons.access_time, size: 20),
                      SizedBox(width: 8),
                      Text('作成日順（昇順）'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'created_desc',
                  child: Row(
                    children: [
                      Icon(Icons.access_time, size: 20),
                      SizedBox(width: 8),
                      Text('作成日順（降順）'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'title_asc',
                  child: Row(
                    children: [
                      Icon(Icons.sort_by_alpha, size: 20),
                      SizedBox(width: 8),
                      Text('タイトル順（あいうえお）'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'title_desc',
                  child: Row(
                    children: [
                      Icon(Icons.sort_by_alpha, size: 20),
                      SizedBox(width: 8),
                      Text('タイトル順（逆順）'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'completion',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, size: 20),
                      SizedBox(width: 8),
                      Text('完了状態'),
                    ],
                  ),
                ),
              ],
            ),
            IconButton(
              icon: Icon(_showFilters ? Icons.filter_alt : Icons.filter_alt_outlined),
              onPressed: () {
                setState(() {
                  _showFilters = !_showFilters;
                });
              },
              tooltip: 'フィルター',
            ),
          ],
        ),
        body: Column(
          children: [
            // 検索バー
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'タイトル・メモで検索',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _applyFilters();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ),
            // フィルターUI
            if (_showFilters)
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'フィルター',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _resetFilters,
                          child: const Text('リセット'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 完了状態フィルター
                    Row(
                      children: [
                        const Text('状態: '),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('すべて'),
                          selected: _completionFilter == null,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _completionFilter = null;
                              });
                              _applyFilters();
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('未完了'),
                          selected: _completionFilter == false,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _completionFilter = false;
                              });
                              _applyFilters();
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('完了'),
                          selected: _completionFilter == true,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _completionFilter = true;
                              });
                              _applyFilters();
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 日付範囲フィルター
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectStartDate(context),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _startDate == null
                                          ? '開始日'
                                          : '${_startDate!.year}/${_startDate!.month}/${_startDate!.day}',
                                      style: TextStyle(
                                        color: _startDate == null ? Colors.grey[600] : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  if (_startDate != null)
                                    IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        setState(() {
                                          _startDate = null;
                                        });
                                        _applyFilters();
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('〜'),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectEndDate(context),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _endDate == null
                                          ? '終了日'
                                          : '${_endDate!.year}/${_endDate!.month}/${_endDate!.day}',
                                      style: TextStyle(
                                        color: _endDate == null ? Colors.grey[600] : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  if (_endDate != null)
                                    IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        setState(() {
                                          _endDate = null;
                                        });
                                        _applyFilters();
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            // メインコンテンツ
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
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

    // フィルタリング後の結果が空の場合
    if (_filteredTasks.isEmpty && _tasks.isNotEmpty) {
      return RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 300,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '検索条件に一致する予定がありません',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _resetFilters,
                    child: const Text('フィルターをリセット'),
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
        itemCount: _filteredTasks.length,
        itemBuilder: (context, index) {
          final task = _filteredTasks[index];

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
                        TimeFormatter.formatTime(task.scheduledTime),
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
