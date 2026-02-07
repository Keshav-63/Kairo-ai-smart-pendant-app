import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/local_storage_service.dart';
import '../constants/app_theme.dart';
import 'package:intl/intl.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;
  List<Task> _pendingTasks = [];
  List<Task> _completedTasks = [];
  String _currentView = 'list'; // 'list' or 'calendar'
  DateTime _currentMonth = DateTime.now();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fetchTasks();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchTasks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final storage = LocalStorageService.instance;
      final userId = storage.getUserId();

      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Fetch pending and completed tasks in parallel
      final results = await Future.wait([
        _fetchTasksByStatus(userId, 'pending'),
        _fetchTasksByStatus(userId, 'complete'),
      ]);

      setState(() {
        _pendingTasks = results[0];
        _completedTasks = results[1];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load your tasks. Please try again.';
        _isLoading = false;
      });
      debugPrint('[TasksPage] Error fetching tasks: $e');
    }
  }

  Future<List<Task>> _fetchTasksByStatus(String userId, String status) async {
    const baseUrl = 'https://keshavsuthar-kairo-api.hf.space';
    final url = Uri.parse('$baseUrl/tasks/user/$userId?status=$status');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Task.fromJson(json)).toList();
      } else {
        debugPrint('[TasksPage] Failed to fetch $status tasks: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('[TasksPage] Error fetching $status tasks: $e');
      return [];
    }
  }

  Future<void> _completeTask(String taskId) async {
    const baseUrl = 'https://keshavsuthar-kairo-api.hf.space';
    final url = Uri.parse('$baseUrl/tasks/$taskId/complete');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Task marked as complete!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        // Refresh tasks
        _fetchTasks();
      } else {
        throw Exception('Failed to complete task');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update task. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint('[TasksPage] Error completing task: $e');
    }
  }

  Map<String, List<Task>> _getTasksByDate() {
    final Map<String, List<Task>> tasksByDate = {};
    final allTasks = [..._pendingTasks, ..._completedTasks];

    for (var task in allTasks) {
      if (task.dueDateTime != null) {
        final dateKey = DateFormat('yyyy-MM-dd').format(task.dueDateTime!);
        tasksByDate.putIfAbsent(dateKey, () => []);
        tasksByDate[dateKey]!.add(task);
      }
    }

    return tasksByDate;
  }

  void _changeMonth(int offset) {
    setState(() {
      _currentMonth = DateTime(
        _currentMonth.year,
        _currentMonth.month + offset,
        1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        title: Text('Tasks & Reminders', style: AppTheme.headingMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchTasks,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _error != null
                    ? _buildErrorState()
                    : _currentView == 'list'
                        ? _buildListView()
                        : _buildCalendarView(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Automatically detected action items',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildViewButton(
                  icon: Icons.list,
                  label: 'List View',
                  isSelected: _currentView == 'list',
                  onTap: () => setState(() => _currentView = 'list'),
                ),
                const SizedBox(width: 4),
                _buildViewButton(
                  icon: Icons.calendar_today,
                  label: 'Calendar View',
                  isSelected: _currentView == 'calendar',
                  onTap: () => setState(() => _currentView = 'calendar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.indigoAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Colors.indigoAccent,
          ),
          SizedBox(height: 16),
          Text(
            'Loading your tasks...',
            style: TextStyle(color: Colors.white60),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 64,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Something went wrong',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchTasks,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigoAccent,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView() {
    return RefreshIndicator(
      onRefresh: _fetchTasks,
      color: Colors.indigoAccent,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPendingTasksSection(),
            const SizedBox(height: 32),
            _buildCompletedTasksSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingTasksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pending Tasks (${_pendingTasks.length})',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _pendingTasks.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text(
                    'No pending tasks. Great job! 🎉',
                    style: TextStyle(color: Colors.white60, fontSize: 16),
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _pendingTasks.length,
                itemBuilder: (context, index) {
                  return _buildTaskCard(_pendingTasks[index], isPending: true);
                },
              ),
      ],
    );
  }

  Widget _buildCompletedTasksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Completed Tasks (${_completedTasks.length})',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _completedTasks.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text(
                    'No tasks completed yet.',
                    style: TextStyle(color: Colors.white60, fontSize: 16),
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _completedTasks.take(5).length,
                itemBuilder: (context, index) {
                  return _buildCompletedTaskCard(_completedTasks[index]);
                },
              ),
      ],
    );
  }

  Widget _buildTaskCard(Task task, {required bool isPending}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    task.description,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (task.googleCalendarEventId != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Calendar',
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            if (task.context.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '"${task.context}"',
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.white60),
                    const SizedBox(width: 4),
                    Text(
                      task.dueDateTime != null
                          ? DateFormat('MMM dd, yyyy hh:mm a').format(task.dueDateTime!)
                          : 'No due date',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                if (isPending)
                  IconButton(
                    onPressed: () => _completeTask(task.id),
                    icon: const Icon(Icons.check_circle_outline),
                    color: Colors.green,
                    tooltip: 'Mark as complete',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedTaskCard(Task task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900]?.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              task.description,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 14,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ),
          if (task.completedAt != null)
            Text(
              DateFormat('MMM dd').format(task.completedAt!),
              style: const TextStyle(
                color: Colors.green,
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCalendarView() {
    final tasksByDate = _getTasksByDate();
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday;
    final monthName = DateFormat('MMMM yyyy').format(_currentMonth);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Month navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => _changeMonth(-1),
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                ),
                Text(
                  monthName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => _changeMonth(1),
                  icon: const Icon(Icons.chevron_right, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Day headers
            Row(
              children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                  .map((day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            // Calendar grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 0.8,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: firstDayOfMonth % 7 + daysInMonth,
              itemBuilder: (context, index) {
                if (index < firstDayOfMonth % 7) {
                  return Container();
                }

                final day = index - firstDayOfMonth % 7 + 1;
                final dateStr = DateFormat('yyyy-MM-dd').format(
                  DateTime(_currentMonth.year, _currentMonth.month, day),
                );
                final tasksForDay = tasksByDate[dateStr] ?? [];
                final isToday = DateTime.now().day == day &&
                    DateTime.now().month == _currentMonth.month &&
                    DateTime.now().year == _currentMonth.year;

                return _buildCalendarDay(day, tasksForDay, isToday);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarDay(int day, List<Task> tasks, bool isToday) {
    return Container(
      decoration: BoxDecoration(
        color: isToday ? Colors.indigoAccent.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isToday
              ? Colors.indigoAccent
              : Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$day',
            style: TextStyle(
              color: isToday ? Colors.indigoAccent : Colors.white,
              fontSize: 12,
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: ListView.builder(
              itemCount: tasks.length > 3 ? 3 : tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 2),
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: task.status == 'complete'
                        ? Colors.green.withOpacity(0.2)
                        : task.googleCalendarEventId != null
                            ? Colors.blue.withOpacity(0.2)
                            : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    task.description,
                    style: TextStyle(
                      color: task.status == 'complete'
                          ? Colors.greenAccent
                          : task.googleCalendarEventId != null
                              ? Colors.blueAccent
                              : Colors.redAccent,
                      fontSize: 8,
                      decoration: task.status == 'complete'
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),
          if (tasks.length > 3)
            Text(
              '+${tasks.length - 3}',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 8,
              ),
            ),
        ],
      ),
    );
  }
}

// Task model
class Task {
  final String id;
  final String description;
  final String context;
  final DateTime? dueDateTime;
  final String status;
  final String? googleCalendarEventId;
  final DateTime? completedAt;

  Task({
    required this.id,
    required this.description,
    required this.context,
    this.dueDateTime,
    required this.status,
    this.googleCalendarEventId,
    this.completedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['_id']?['\$oid'] ?? json['_id'] ?? '',
      description: json['task_description'] ?? '',
      context: json['context'] ?? '',
      dueDateTime: json['due_date_time'] != null
          ? DateTime.tryParse(json['due_date_time'])
          : null,
      status: json['status'] ?? 'pending',
      googleCalendarEventId: json['googleCalendarEventId'],
      completedAt: json['completed_at']?['\$date'] != null
          ? DateTime.tryParse(json['completed_at']['\$date'])
          : null,
    );
  }
}

