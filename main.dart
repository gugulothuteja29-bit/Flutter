import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const PlacementTrackerApp());
}

class PlacementTrackerApp extends StatelessWidget {
  const PlacementTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'College Placement Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6254A1)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F7FC),
      ),
      home: const PlacementHomePage(),
    );
  }
}

class PlacementTask {
  PlacementTask({
    required this.id,
    required this.title,
    required this.company,
    required this.date,
    required this.status,
  });

  final String id;
  String title;
  String company;
  String date;
  String status;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'company': company,
        'date': date,
        'status': status,
      };

  factory PlacementTask.fromJson(Map<String, dynamic> json) => PlacementTask(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        company: json['company'] as String? ?? '',
        date: json['date'] as String? ?? '',
        status: json['status'] as String? ?? 'Pending',
      );
}

class PlacementHomePage extends StatefulWidget {
  const PlacementHomePage({super.key});

  @override
  State<PlacementHomePage> createState() => _PlacementHomePageState();
}

class _PlacementHomePageState extends State<PlacementHomePage> {
  static const _storageKey = 'placement_tracker_tasks_v1';
  final List<PlacementTask> _tasks = [];
  bool _loading = true;
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _tasks
          ..clear()
          ..addAll(decoded.map((item) =>
              PlacementTask.fromJson(Map<String, dynamic>.from(item as Map))));
      }
    } catch (_) {
      // Start with an empty list if there is no saved browser data yet.
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_tasks.map((task) => task.toJson()).toList()),
    );
  }

  List<PlacementTask> get _visibleTasks {
    if (_filter == 'All') return _tasks;
    return _tasks.where((task) => task.status == _filter).toList();
  }

  Future<void> _openTaskForm({PlacementTask? existing}) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final companyController =
        TextEditingController(text: existing?.company ?? '');
    final dateController = TextEditingController(text: existing?.date ?? '');
    String status = existing?.status ?? 'Pending';

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Add placement task' : 'Edit task'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Task title *',
                      hintText: 'Example: Prepare resume',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: companyController,
                    decoration: const InputDecoration(
                      labelText: 'Company / activity',
                      hintText: 'Example: ABC Technologies',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dateController,
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      hintText: 'YYYY-MM-DD',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                      DropdownMenuItem(value: 'In Progress', child: Text('In Progress')),
                      DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                    ],
                    onChanged: (value) {
                      if (value != null) setDialogState(() => status = value);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isEmpty) return;
                Navigator.pop(dialogContext, {
                  'title': title,
                  'company': companyController.text.trim(),
                  'date': dateController.text.trim(),
                  'status': status,
                });
              },
              child: const Text('Save task'),
            ),
          ],
        ),
      ),
    );

    titleController.dispose();
    companyController.dispose();
    dateController.dispose();

    if (result == null) return;
    setState(() {
      if (existing == null) {
        _tasks.insert(
          0,
          PlacementTask(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            title: result['title']!,
            company: result['company']!,
            date: result['date']!,
            status: result['status']!,
          ),
        );
      } else {
        existing
          ..title = result['title']!
          ..company = result['company']!
          ..date = result['date']!
          ..status = result['status']!;
      }
    });
    await _saveTasks();
  }

  Future<void> _deleteTask(PlacementTask task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('Delete "${task.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _tasks.removeWhere((item) => item.id == task.id));
    await _saveTasks();
  }

  @override
  Widget build(BuildContext context) {
    final completed = _tasks.where((task) => task.status == 'Completed').length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('College Placement Tracker',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFFF8F7FC),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: () => _openTaskForm(),
              icon: const Icon(Icons.add),
              label: const Text('New Task'),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1050),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _summaryCard('Total tasks', '${_tasks.length}', Icons.task_alt),
                    _summaryCard('Completed', '$completed', Icons.check_circle_outline),
                    _summaryCard('Remaining', '${_tasks.length - completed}', Icons.pending_actions),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(
                      child: Text('Your tasks',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ),
                    SizedBox(
                      width: 170,
                      child: DropdownButtonFormField<String>(
                        value: _filter,
                        decoration: const InputDecoration(
                          labelText: 'Filter',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'All', child: Text('All')),
                          DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                          DropdownMenuItem(value: 'In Progress', child: Text('In Progress')),
                          DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _filter = value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _visibleTasks.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.assignment_outlined, size: 58, color: Colors.grey),
                                  const SizedBox(height: 12),
                                  Text(
                                    _tasks.isEmpty ? 'No tasks yet' : 'No tasks in this filter',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text('Select “New Task” to add your first placement activity.'),
                                  const SizedBox(height: 14),
                                  FilledButton.icon(
                                    onPressed: () => _openTaskForm(),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add your first task'),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              itemCount: _visibleTasks.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final task = _visibleTasks[index];
                                return Card(
                                  elevation: 0,
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      child: Icon(task.status == 'Completed'
                                          ? Icons.check
                                          : task.status == 'In Progress'
                                              ? Icons.timelapse
                                              : Icons.event_note),
                                    ),
                                    title: Text(task.title,
                                        style: const TextStyle(fontWeight: FontWeight.w600)),
                                    subtitle: Text([
                                      if (task.company.isNotEmpty) task.company,
                                      if (task.date.isNotEmpty) task.date,
                                      task.status,
                                    ].join(' • ')),
                                    isThreeLine: false,
                                    trailing: Wrap(
                                      spacing: 0,
                                      children: [
                                        IconButton(
                                          tooltip: 'Edit task',
                                          onPressed: () => _openTaskForm(existing: task),
                                          icon: const Icon(Icons.edit_outlined),
                                        ),
                                        IconButton(
                                          tooltip: 'Delete task',
                                          onPressed: () => _deleteTask(task),
                                          icon: const Icon(Icons.delete_outline),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Data is saved in this browser on this device. It is not shared across devices.',
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(String label, String value, IconData icon) {
    return SizedBox(
      width: 220,
      child: Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.black54)),
                  Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
