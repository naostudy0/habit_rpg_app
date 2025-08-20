import 'package:flutter/material.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  int _selectedPeriod = 0; // 0: 週間, 1: 月間, 2: 年間

  // 仮の統計データ
  final Map<String, dynamic> _statsData = {
    'totalTasks': 45,
    'completedTasks': 32,
    'completionRate': 71.1,
    'currentStreak': 8,
    'longestStreak': 15,
    'totalDays': 30,
    'weeklyData': [
      {'day': '月', 'completed': 5, 'total': 7},
      {'day': '火', 'completed': 6, 'total': 7},
      {'day': '水', 'completed': 4, 'total': 6},
      {'day': '木', 'completed': 7, 'total': 7},
      {'day': '金', 'completed': 3, 'total': 5},
      {'day': '土', 'completed': 4, 'total': 4},
      {'day': '日', 'completed': 3, 'total': 5},
    ],
    'monthlyData': [
      {'month': '1月', 'completed': 28, 'total': 35},
      {'month': '2月', 'completed': 25, 'total': 32},
      {'month': '3月', 'completed': 30, 'total': 38},
      {'month': '4月', 'completed': 32, 'total': 40},
      {'month': '5月', 'completed': 29, 'total': 36},
      {'month': '6月', 'completed': 35, 'total': 42},
    ],
    'categoryData': [
      {'category': '運動', 'completed': 12, 'total': 15, 'color': Colors.blue},
      {'category': '学習', 'completed': 8, 'total': 10, 'color': Colors.green},
      {'category': '読書', 'completed': 6, 'total': 8, 'color': Colors.orange},
      {'category': '家事', 'completed': 4, 'total': 6, 'color': Colors.purple},
      {'category': 'その他', 'completed': 2, 'total': 6, 'color': Colors.red},
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('統計・進捗'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('統計を共有しました（仮実装）')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 期間選択
          _buildPeriodSelector(),

          const SizedBox(height: 24),

          // サマリーカード
          _buildSummaryCards(),

          const SizedBox(height: 24),

          // 週間進捗グラフ
          _buildWeeklyProgressChart(),

          const SizedBox(height: 24),

          // カテゴリ別進捗
          _buildCategoryProgress(),

          const SizedBox(height: 24),

          // 達成記録
          _buildAchievements(),

          const SizedBox(height: 24),

          // 詳細統計
          _buildDetailedStats(),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '期間',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildPeriodButton('週間', 0),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPeriodButton('月間', 1),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPeriodButton('年間', 2),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String label, int index) {
    final isSelected = _selectedPeriod == index;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedPeriod = index;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? Theme.of(context).colorScheme.primary
            : Colors.grey[200],
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        elevation: isSelected ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildSummaryCard('完了率', '${_statsData['completionRate']}%', Icons.check_circle, Colors.green)),
            const SizedBox(width: 12),
            Expanded(child: _buildSummaryCard('継続日数', '${_statsData['currentStreak']}日', Icons.local_fire_department, Colors.orange)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildSummaryCard('総タスク', '${_statsData['totalTasks']}', Icons.task_alt, Colors.blue)),
            const SizedBox(width: 12),
            Expanded(child: _buildSummaryCard('完了タスク', '${_statsData['completedTasks']}', Icons.done_all, Colors.purple)),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyProgressChart() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '週間進捗',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: _statsData['weeklyData'].map<Widget>((dayData) {
                  final completionRate = dayData['total'] > 0
                      ? dayData['completed'] / dayData['total']
                      : 0.0;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${(completionRate * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 30,
                        height: (120 * completionRate).toDouble(),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dayData['day'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryProgress() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'カテゴリ別進捗',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...(_statsData['categoryData'] as List).map<Widget>((category) {
              final completionRate = category['total'] > 0
                  ? category['completed'] / category['total']
                  : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          category['category'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${category['completed']}/${category['total']}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: completionRate,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(category['color']),
                      minHeight: 8,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(completionRate * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: category['color'],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievements() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '達成記録',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAchievementCard(
                    '最長継続',
                    '${_statsData['longestStreak']}日',
                    Icons.emoji_events,
                    Colors.amber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAchievementCard(
                    '総利用日数',
                    '${_statsData['totalDays']}日',
                    Icons.calendar_today,
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStats() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '詳細統計',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatRow('平均完了率', '${_statsData['completionRate']}%'),
            const Divider(),
            _buildStatRow('週間平均タスク数', '6.4個'),
            const Divider(),
            _buildStatRow('最も活発な曜日', '木曜日'),
            const Divider(),
            _buildStatRow('最も生産的な時間帯', '20:00-22:00'),
            const Divider(),
            _buildStatRow('今月の目標達成率', '85%'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
