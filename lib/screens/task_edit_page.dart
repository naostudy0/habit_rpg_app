import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/task.dart';

class TaskEditPage extends StatefulWidget {
  final Task task;

  const TaskEditPage({super.key, required this.task});

  @override
  State<TaskEditPage> createState() => _TaskEditPageState();
}

class _TaskEditPageState extends State<TaskEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  late TextEditingController _titleController;
  late TextEditingController _memoController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  bool _isLoading = false;
  String? _titleError;
  String? _taskUuid;

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
  }

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
      setState(() {
        _isLoading = true;
      });

      try {
        await _apiService.updateTask(
          uuid: _taskUuid!,
          title: _titleController.text.trim(),
          scheduledDate: _selectedDate,
          scheduledTime: _selectedTime,
          memo: _memoController.text.trim().isEmpty ? null : _memoController.text.trim(),
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
              content: Text('予定の更新に失敗しました: $e'),
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
      _isLoading = true;
    });

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
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.getErrorMessage()),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('予定の削除に失敗しました: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            onPressed: _deleteTask,
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

              // 保存ボタン
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveTask,
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
    );
  }
}
