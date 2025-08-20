import 'package:flutter/material.dart';
import 'task_edit_page.dart';

class TaskListPage extends StatelessWidget {
  const TaskListPage({super.key});

  // 仮の予定データ
  List<Map<String, dynamic>> get _dummyTasks => [
    {
      'id': 1,
      'title': '朝のジョギング',
      'date': DateTime.now().add(const Duration(days: 1)),
      'time': const TimeOfDay(hour: 7, minute: 0),
      'memo': '30分程度の軽いジョギング',
      'isCompleted': false,
    },
    {
      'id': 2,
      'title': '読書',
      'date': DateTime.now().add(const Duration(days: 2)),
      'time': const TimeOfDay(hour: 20, minute: 0),
      'memo': '技術書を30分読む',
      'isCompleted': true,
    },
    {
      'id': 3,
      'title': '筋トレ',
      'date': DateTime.now().add(const Duration(days: 3)),
      'time': const TimeOfDay(hour: 19, minute: 30),
      'memo': '腕立て伏せ、腹筋、スクワット',
      'isCompleted': false,
    },
    {
      'id': 4,
      'title': 'プログラミング学習',
      'date': DateTime.now().add(const Duration(days: 0)),
      'time': const TimeOfDay(hour: 21, minute: 0),
      'memo': 'Flutterの学習を1時間',
      'isCompleted': false,
    },
  ];

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
      body: _dummyTasks.isEmpty
          ? const Center(
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
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _dummyTasks.length,
              itemBuilder: (context, index) {
                final task = _dummyTasks[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: task['isCompleted']
                            ? Colors.green.withOpacity(0.2)
                            : Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Icon(
                        task['isCompleted'] ? Icons.check : Icons.schedule,
                        color: task['isCompleted']
                            ? Colors.green
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    title: Text(
                      task['title'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration: task['isCompleted']
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
                              '${task['date'].year}/${task['date'].month.toString().padLeft(2, '0')}/${task['date'].day.toString().padLeft(2, '0')}',
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
                              '${task['time'].hour.toString().padLeft(2, '0')}:${task['time'].minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        if (task['memo'] != null && task['memo'].isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            task['memo'],
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
    );
  }
}
