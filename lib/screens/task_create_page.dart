import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TaskCreatePage extends StatefulWidget {
  const TaskCreatePage({super.key});

  @override
  State<TaskCreatePage> createState() => _TaskCreatePageState();
}

class _TaskCreatePageState extends State<TaskCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _memoController = TextEditingController();
  final _apiService = ApiService();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = false;
  String? _titleError;

  @override
  void dispose() {
    _titleController.dispose();
    _memoController.dispose();
    super.dispose();
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
      setState(() {
        _isLoading = true;
      });

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
      } on ApiException catch (e) {
        // APIエラー時の処理
        if (mounted) {
          // フィールドごとのエラーメッセージを設定
          setState(() {
            _titleError = e.getFieldError('title');
          });

          // フィールドエラーがない場合は、一般的なエラーメッセージを表示
          if (_titleError == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(e.getErrorMessage()),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          } else {
            // フィールドエラーがある場合は、フォームを再検証してエラーを表示
            _formKey.currentState?.validate();
          }
        }
      } catch (e) {
        // その他のエラー時の処理
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('予定の登録に失敗しました: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                              '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
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
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
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
    );
  }
}
