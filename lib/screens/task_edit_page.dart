import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/error_handler.dart';
import '../services/loading_service.dart';
import '../services/settings_service.dart';
import '../widgets/loading_widget.dart';
import '../models/task.dart';
import '../utils/time_formatter.dart';

class TaskEditPage extends StatefulWidget {
  final Task task;

  const TaskEditPage({super.key, required this.task});

  @override
  State<TaskEditPage> createState() => _TaskEditPageState();
}

class _TaskEditPageState extends State<TaskEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  final _errorHandler = ErrorHandler();
  final _loadingService = LoadingService();
  final _settingsService = SettingsService();
  late TextEditingController _titleController;
  late TextEditingController _memoController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  String? _titleError;
  String? _taskUuid;

  static const String _loadingOperationUpdate = 'update_task';
  static const String _loadingOperationDelete = 'delete_task';

  @override
  void initState() {
    super.initState();
    // UUIDを取得
    _taskUuid = widget.task.uuid;

    // 既存の予定データでフォームを初期化
    _titleController = TextEditingController(text: widget.task.title);
    _memoController = TextEditingController(text: widget.task.memo ?? '');

    // 日付と時刻を設定
    _selectedDate = widget.task.scheduledDate;
    _selectedTime = widget.task.scheduledTime;

    _settingsService.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _settingsService.removeListener(_onSettingsChanged);
    _titleController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(alwaysUse24HourFormat: _settingsService.is24HourFormat),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveTask() async {
    if (_taskUuid == null || _taskUuid!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('予定のUUIDが見つかりません'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // エラーメッセージをクリア
    setState(() {
      _titleError = null;
    });

    if (_formKey.currentState!.validate()) {
      _loadingService.setLoading(_loadingOperationUpdate, true);

      try {
        await _apiService.updateTask(
          uuid: _taskUuid!,
          title: _titleController.text.trim(),
          scheduledDate: _selectedDate,
          scheduledTime: _selectedTime,
          memo: _memoController.text.trim().isEmpty
              ? null
              : _memoController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('予定を更新しました'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // trueを返して、呼び出し元でリフレッシュできるようにする
        }
      } catch (e) {
        // エラー時の処理
        if (mounted) {
          // フィールドごとのエラーメッセージを設定
          setState(() {
            _titleError = _errorHandler.getFieldError(e, 'title');
          });

          // フィールドエラーがない場合は、一般的なエラーメッセージを表示
          if (_titleError == null) {
            _errorHandler.handleError(context, e, contextMessage: '予定更新');
          } else {
            // フィールドエラーがある場合は、フォームを再検証してエラーを表示
            _formKey.currentState?.validate();
          }
        }
      } finally {
        if (mounted) {
          _loadingService.setLoading(_loadingOperationUpdate, false);
        }
      }
    }
  }

  Future<void> _deleteTask() async {
    if (_taskUuid == null || _taskUuid!.isEmpty) {
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
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('削除'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    _loadingService.setLoading(_loadingOperationDelete, true);

    try {
      await _apiService.deleteTask(_taskUuid!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('予定を削除しました'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // trueを返して、呼び出し元でリフレッシュできるようにする
      }
    } catch (e) {
      if (mounted) {
        _errorHandler.handleError(context, e, contextMessage: '予定削除（編集画面）');
      }
    } finally {
      if (mounted) {
        _loadingService.setLoading(_loadingOperationDelete, false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingWidget(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('予定を編集'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _loadingService.isLoading(_loadingOperationDelete)
                  ? null
                  : _deleteTask,
              color: Colors.red,
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // タイトル入力フィールド
                const Text(
                  'タイトル',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: '予定のタイトルを入力してください',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    errorText: _titleError,
                  ),
                  validator: (value) {
                    // サーバーからのエラーメッセージがある場合はそれを優先
                    if (_titleError != null) {
                      return _titleError;
                    }
                    if (value == null || value.isEmpty) {
                      return 'タイトルを入力してください';
                    }
                    if (value.trim().isEmpty) {
                      return 'タイトルを入力してください';
                    }
                    if (value.length > 255) {
                      return 'タイトルは255文字以内で入力してください';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // 日時選択セクション
                const Text(
                  '日時',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey[50],
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_selectedDate.year}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.day.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectTime(context),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey[50],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                TimeFormatter.formatTime(_selectedTime),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // メモ入力フィールド
                const Text(
                  'メモ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _memoController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: '予定に関するメモを入力してください（任意）',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),

                const Spacer(),

                // 保存ボタン
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed:
                        _loadingService.isLoading(_loadingOperationUpdate)
                        ? null
                        : _saveTask,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _loadingService.isLoading(_loadingOperationUpdate)
                        ? const SimpleLoadingIndicator(
                            color: Colors.white,
                            size: 20,
                          )
                        : const Text(
                            '変更を保存',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
