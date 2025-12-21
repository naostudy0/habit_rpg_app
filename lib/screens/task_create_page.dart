import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/error_handler.dart';
import '../services/loading_service.dart';
import '../services/settings_service.dart';
import '../widgets/loading_widget.dart';
import '../utils/time_formatter.dart';

class TaskCreatePage extends StatefulWidget {
  final DateTime? initialDate;

  const TaskCreatePage({super.key, this.initialDate});

  @override
  State<TaskCreatePage> createState() => _TaskCreatePageState();
}

class _TaskCreatePageState extends State<TaskCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _memoController = TextEditingController();
  final _apiService = ApiService();
  final _errorHandler = ErrorHandler();
  final _loadingService = LoadingService();
  final _settingsService = SettingsService();
  late DateTime _selectedDate;
  TimeOfDay _selectedTime = TimeOfDay.now();
  String? _titleError;

  static const String _loadingOperation = 'create_task';

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
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
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: _settingsService.is24HourFormat,
          ),
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

  // フォームをクリア
  void _clearForm() {
    // コントローラーをクリア
    _titleController.clear();
    _memoController.clear();

    // 状態を更新
    setState(() {
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
      _titleError = null;
    });

    // フォームのバリデーション状態をリセット
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _formKey.currentState?.reset();
    });
  }

  Future<void> _submitForm() async {
    // エラーメッセージをクリア
    setState(() {
      _titleError = null;
    });

    if (_formKey.currentState!.validate()) {
      _loadingService.setLoading(_loadingOperation, true);

      try {
        await _apiService.createTask(
          title: _titleController.text.trim(),
          scheduledDate: _selectedDate,
          scheduledTime: _selectedTime,
          memo: _memoController.text.trim().isEmpty ? null : _memoController.text.trim(),
        );

        if (mounted) {
          // フォームをクリア
          _clearForm();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('予定を登録しました'),
              backgroundColor: Colors.green,
            ),
          );
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
            _errorHandler.handleError(
              context,
              e,
              contextMessage: '予定作成',
            );
          } else {
            // フィールドエラーがある場合は、フォームを再検証してエラーを表示
            _formKey.currentState?.validate();
          }
        }
      } finally {
        if (mounted) {
          _loadingService.setLoading(_loadingOperation, false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingWidget(
      operation: _loadingOperation,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('新しい予定'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
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
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
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
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
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
                            const Icon(Icons.calendar_today, color: Colors.grey),
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
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
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

              // 登録ボタン
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _loadingService.isLoading(_loadingOperation) ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _loadingService.isLoading(_loadingOperation)
                      ? const SimpleLoadingIndicator(
                          color: Colors.white,
                          size: 20,
                        )
                      : const Text(
                          '予定を登録',
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
