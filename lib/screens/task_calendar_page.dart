import 'package:flutter/material.dart';
import 'task_list_page.dart';
import 'task_create_page.dart';
import 'task_edit_page.dart';
import '../services/api_service.dart';
import '../services/error_handler.dart';
import '../services/loading_service.dart';
import '../widgets/loading_widget.dart';
import '../models/task.dart';

class TaskCalendarPage extends StatefulWidget {
  const TaskCalendarPage({super.key});

  @override
  State<TaskCalendarPage> createState() => _TaskCalendarPageState();
}

class _TaskCalendarPageState extends State<TaskCalendarPage> {
  final ApiService _apiService = ApiService();
  final ErrorHandler _errorHandler = ErrorHandler();
  final LoadingService _loadingService = LoadingService();
  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];
  bool _isInitialLoading = true;
  String? _errorMessage;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, List<Task>> _events = {};
  final Set<String> _completingTaskUuids = {}; // 完了状態切り替え中のタスクUUID

  // 完了状態フィルター
  bool? _completionFilter; // null: すべて, true: 完了のみ, false: 未完了のみ

  static const String _loadingOperation = 'load_tasks';

  @override
  void initState() {
    super.initState();
    _completingTaskUuids.clear();
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
      _applyFilters();
    } catch (e) {
      setState(() {
        _errorMessage = _errorHandler.getErrorMessage(e);
        _isInitialLoading = false;
      });
      _errorHandler.logError(e, context: '予定一覧取得（カレンダー）');
    } finally {
      _loadingService.setLoading(_loadingOperation, false);
    }
  }

  // フィルタリングを適用
  void _applyFilters() {
    setState(() {
      // 完了状態でフィルタリング
      _filteredTasks = _tasks.where((task) {
        if (_completionFilter != null) {
          return task.isCompleted == _completionFilter;
        }
        return true;
      }).toList();

      // フィルタリング後のタスクを日付ごとにグループ化
      _events = _groupTasksByDate(_filteredTasks);
    });
  }

  // 予定を日付ごとにグループ化
  Map<DateTime, List<Task>> _groupTasksByDate(List<Task> tasks) {
    final Map<DateTime, List<Task>> grouped = {};

    for (final task in tasks) {
      final dateKey = DateTime(
        task.scheduledDate.year,
        task.scheduledDate.month,
        task.scheduledDate.day,
      );
      grouped.putIfAbsent(dateKey, () => []).add(task);
    }

    return grouped;
  }

  // 選択された日の予定を取得
  List<Task> _getSelectedDayTasks() {
    final dateKey = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    final tasks = _events[dateKey] ?? [];
    // Taskオブジェクトのみを返すようにフィルタリング
    return tasks.whereType<Task>().toList();
  }

  // 予定完了状態切り替え
  Future<void> _toggleTaskCompletion(Task task) async {
    if (task.uuid.isEmpty) {
      return;
    }

    final newCompletionState = !task.isCompleted;

    setState(() {
      _completingTaskUuids.add(task.uuid);
    });

    try {
      final updatedTask = await _apiService.toggleTaskCompletion(
        uuid: task.uuid,
        isCompleted: newCompletionState,
      );

      // タスクリストとイベントマップを更新
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
          contextMessage: '予定完了状態切り替え（カレンダー）',
        );
      }
    }
  }

  // カレンダーの日付ビルダー
  Widget _calendarDayBuilder(
    BuildContext context,
    DateTime day,
    DateTime focusedDay,
  ) {
    final dateKey = DateTime(day.year, day.month, day.day);
    final dayTasks = _events[dateKey] ?? [];
    final isSelected = isSameDay(day, _selectedDay);
    final isToday = isSameDay(day, DateTime.now());

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
            : Colors.transparent,
        shape: BoxShape.circle,
        border: isToday
            ? Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              )
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : isToday
                      ? Theme.of(context).colorScheme.primary
                      : Colors.black87,
              fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (dayTasks.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  // 日付が同じかどうかを判定
  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return LoadingWidget(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('カレンダー'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            // 完了状態フィルターボタン
            PopupMenuButton<String>(
              icon: Icon(
                _completionFilter == null
                    ? Icons.filter_alt_outlined
                    : Icons.filter_alt,
                color: _completionFilter == null ? null : Theme.of(context).colorScheme.primary,
              ),
              tooltip: 'フィルター',
              onSelected: (value) {
                setState(() {
                  if (value == 'all') {
                    _completionFilter = null;
                  } else if (value == 'completed') {
                    _completionFilter = true;
                  } else if (value == 'incomplete') {
                    _completionFilter = false;
                  }
                });
                _applyFilters();
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'all',
                  child: Row(
                    children: [
                      Icon(
                        _completionFilter == null ? Icons.check : Icons.radio_button_unchecked,
                        size: 20,
                        color: _completionFilter == null
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      const Text('すべて'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'incomplete',
                  child: Row(
                    children: [
                      Icon(
                        _completionFilter == false ? Icons.check : Icons.radio_button_unchecked,
                        size: 20,
                        color: _completionFilter == false
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      const Text('未完了'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'completed',
                  child: Row(
                    children: [
                      Icon(
                        _completionFilter == true ? Icons.check : Icons.radio_button_unchecked,
                        size: 20,
                        color: _completionFilter == true
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      const Text('完了'),
                    ],
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TaskCreatePage(
                      initialDate: _selectedDay,
                    ),
                  ),
                );
                if (result == true) {
                  _loadTasks();
                }
              },
            ),
          ],
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

    // フィルタリング後の結果が空の場合
    if (_filteredTasks.isEmpty && _tasks.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_alt_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'フィルター条件に一致する予定がありません',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _completionFilter = null;
                });
                _applyFilters();
              },
              child: const Text('フィルターをリセット'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // カレンダー部分
        Container(
          padding: const EdgeInsets.all(16),
          child: TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              weekendTextStyle: TextStyle(
                color: Colors.red[400],
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              formatButtonShowsNext: false,
            ),
            eventLoader: (day) {
              final dateKey = DateTime(day.year, day.month, day.day);
              return _events[dateKey] ?? [];
            },
          ),
        ),
        const Divider(),
        // 選択された日の予定一覧
        Expanded(
          child: _buildSelectedDayTasks(),
        ),
      ],
    );
  }

  Widget _buildSelectedDayTasks() {
    final selectedTasks = _getSelectedDayTasks();

    if (selectedTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '${_selectedDay.year}/${_selectedDay.month}/${_selectedDay.day}の予定はありません',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TaskCreatePage(
                      initialDate: _selectedDay,
                    ),
                  ),
                );
                if (result == true) {
                  _loadTasks();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('予定を追加'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: selectedTasks.length,
        itemBuilder: (context, index) {
          final task = selectedTasks[index];

          // Taskオブジェクトの型チェック
          if (task is! Task) {
            return const SizedBox.shrink();
          }

          // UUIDが空の場合はスキップ
          if (task.uuid.isEmpty) {
            return const SizedBox.shrink();
          }

          final isCompleting = _completingTaskUuids.contains(task.uuid);

          return Card(
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
              trailing: Icon(
                Icons.edit,
                color: Colors.grey[400],
              ),
              onTap: isCompleting ? null : () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TaskEditPage(task: task),
                  ),
                );
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

// TableCalendarウィジェット（簡易実装）
class TableCalendar extends StatefulWidget {
  final DateTime firstDay;
  final DateTime lastDay;
  final DateTime focusedDay;
  final bool Function(DateTime) selectedDayPredicate;
  final Function(DateTime, DateTime) onDaySelected;
  final Function(DateTime) onPageChanged;
  final CalendarFormat calendarFormat;
  final StartingDayOfWeek startingDayOfWeek;
  final CalendarStyle calendarStyle;
  final HeaderStyle headerStyle;
  final List<Task> Function(DateTime) eventLoader;

  const TableCalendar({
    super.key,
    required this.firstDay,
    required this.lastDay,
    required this.focusedDay,
    required this.selectedDayPredicate,
    required this.onDaySelected,
    required this.onPageChanged,
    this.calendarFormat = CalendarFormat.month,
    this.startingDayOfWeek = StartingDayOfWeek.monday,
    required this.calendarStyle,
    required this.headerStyle,
    required this.eventLoader,
  });

  @override
  State<TableCalendar> createState() => _TableCalendarState();
}

class _TableCalendarState extends State<TableCalendar> {
  late DateTime _focusedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.focusedDay;
  }

  @override
  void didUpdateWidget(TableCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusedDay != oldWidget.focusedDay) {
      _focusedDay = widget.focusedDay;
    }
  }

  List<DateTime> _getDaysInMonth(DateTime month) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);
    final firstDayOfWeek = firstDayOfMonth.weekday;
    final startOffset = widget.startingDayOfWeek == StartingDayOfWeek.monday
        ? (firstDayOfWeek == 7 ? 0 : firstDayOfWeek) - 1
        : firstDayOfWeek % 7;

    final days = <DateTime>[];
    // 前月の日付
    for (int i = startOffset - 1; i >= 0; i--) {
      days.add(firstDayOfMonth.subtract(Duration(days: i + 1)));
    }
    // 今月の日付
    for (int i = 1; i <= lastDayOfMonth.day; i++) {
      days.add(DateTime(month.year, month.month, i));
    }
    // 来月の日付（42日分になるように）
    final remainingDays = 42 - days.length;
    for (int i = 1; i <= remainingDays; i++) {
      days.add(DateTime(month.year, month.month + 1, i));
    }

    return days;
  }

  @override
  Widget build(BuildContext context) {
    final days = _getDaysInMonth(_focusedDay);
    final weekDays = widget.startingDayOfWeek == StartingDayOfWeek.monday
        ? ['月', '火', '水', '木', '金', '土', '日']
        : ['日', '月', '火', '水', '木', '金', '土'];

    return Column(
      children: [
        // ヘッダー
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                final newMonth = DateTime(_focusedDay.year, _focusedDay.month - 1);
                setState(() {
                  _focusedDay = newMonth;
                });
                widget.onPageChanged(newMonth);
              },
            ),
            Text(
              '${_focusedDay.year}年${_focusedDay.month}月',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                final newMonth = DateTime(_focusedDay.year, _focusedDay.month + 1);
                setState(() {
                  _focusedDay = newMonth;
                });
                widget.onPageChanged(newMonth);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        // 曜日ヘッダー
        Row(
          children: weekDays.map((day) {
            final isWeekend = day == '土' || day == '日';
            return Expanded(
              child: Center(
                child: Text(
                  day,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isWeekend ? Colors.red[400] : Colors.black87,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        // カレンダーグリッド
        ...List.generate(6, (weekIndex) {
          return Row(
            children: List.generate(7, (dayIndex) {
              final dayIndexInMonth = weekIndex * 7 + dayIndex;
              if (dayIndexInMonth >= days.length) {
                return const Expanded(child: SizedBox());
              }
              final day = days[dayIndexInMonth];
              final isSelected = widget.selectedDayPredicate(day);
              final isToday = _isToday(day);
              final isCurrentMonth = day.month == _focusedDay.month;
              final events = widget.eventLoader(day);

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    widget.onDaySelected(day, day);
                  },
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? widget.calendarStyle.selectedDecoration?.color
                          : isToday
                              ? widget.calendarStyle.todayDecoration?.color
                              : Colors.transparent,
                      shape: BoxShape.circle,
                      border: isToday && !isSelected
                          ? Border.all(
                              color: widget.calendarStyle.todayDecoration?.color ?? Colors.blue,
                              width: 2,
                            )
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${day.day}',
                          style: TextStyle(
                            color: isCurrentMonth
                                ? (isSelected
                                    ? Colors.white
                                    : isToday
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.black87)
                                : Colors.grey[400],
                            fontWeight: isSelected || isToday
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                        if (events.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: widget.calendarStyle.markerDecoration?.color ??
                                  Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ],
    );
  }

  bool _isToday(DateTime day) {
    final now = DateTime.now();
    return day.year == now.year &&
        day.month == now.month &&
        day.day == now.day;
  }
}

enum CalendarFormat {
  month,
  twoWeeks,
  week,
}

enum StartingDayOfWeek {
  monday,
  sunday,
}

class CalendarStyle {
  final bool outsideDaysVisible;
  final TextStyle? weekendTextStyle;
  final BoxDecoration? selectedDecoration;
  final BoxDecoration? todayDecoration;
  final BoxDecoration? markerDecoration;

  CalendarStyle({
    this.outsideDaysVisible = false,
    this.weekendTextStyle,
    this.selectedDecoration,
    this.todayDecoration,
    this.markerDecoration,
  });
}

class HeaderStyle {
  final bool formatButtonVisible;
  final bool titleCentered;
  final bool formatButtonShowsNext;

  HeaderStyle({
    this.formatButtonVisible = false,
    this.titleCentered = true,
    this.formatButtonShowsNext = false,
  });
}
