import 'package:flutter/material.dart';
import 'task_edit_page.dart';
import '../services/api_service.dart';

class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = false;
  bool _isInitialLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  // 予定一覧を取得
  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tasks = await _apiService.getTasks();
      setState(() {
        _tasks = tasks;
        _isLoading = false;
        _isInitialLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e is ApiException ? e.getErrorMessage() : e.toString();
        _isLoading = false;
        _isInitialLoading = false;
      });
    }
  }

  // プルリフレッシュ
  Future<void> _handleRefresh() async {
    await _loadTasks();
  }

  // 日付文字列をDateTimeに変換
  DateTime? _parseDate(dynamic dateValue) {
    if (dateValue == null) return null;
    if (dateValue is DateTime) return dateValue;
    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // 時刻文字列をTimeOfDayに変換
  TimeOfDay? _parseTime(dynamic timeValue) {
    if (timeValue == null) return null;
    if (timeValue is TimeOfDay) return timeValue;
    if (timeValue is String) {
      try {
        final parts = timeValue.split(':');
        if (parts.length >= 2) {
          return TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('予定一覧'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(),
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
      child: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _tasks.length,
            itemBuilder: (context, index) {
              final task = _tasks[index];
              final taskDate = _parseDate(task['date'] ?? task['scheduled_date'] ?? task['scheduled_at']);
              final taskTime = _parseTime(task['time'] ?? task['scheduled_time']);
              final isCompleted = task['is_completed'] ?? task['isCompleted'] ?? false;
              final title = task['title'] ?? task['name'] ?? 'タイトルなし';
              final memo = task['memo'] ?? task['description'] ?? '';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.green.withOpacity(0.2)
                          : Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Icon(
                      isCompleted ? Icons.check : Icons.schedule,
                      color: isCompleted
                          ? Colors.green
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      if (taskDate != null || taskTime != null)
                        Row(
                          children: [
                            if (taskDate != null) ...[
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${taskDate.year}/${taskDate.month.toString().padLeft(2, '0')}/${taskDate.day.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                            if (taskDate != null && taskTime != null)
                              const SizedBox(width: 16),
                            if (taskTime != null) ...[
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${taskTime.hour.toString().padLeft(2, '0')}:${taskTime.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      if (memo.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          memo,
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
                  trailing: Icon(
                    Icons.edit,
                    color: Colors.grey[400],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TaskEditPage(task: task),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          // リフレッシュ中のオーバーレイ
          if (_isLoading && !_isInitialLoading)
            Container(
              color: Colors.black.withOpacity(0.1),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
