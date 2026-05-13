import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const bool kDefaultScreenshotMode = bool.fromEnvironment('SCREENSHOT_MODE');

const Color _brandNavy = Color(0xFF21354A);
const Color _brandBlue = Color(0xFF2E5D7E);
const Color _brandTeal = Color(0xFF2E8C88);
const Color _brandGold = Color(0xFFE1B55B);
const Color _brandPaper = Color(0xFFF6F2EC);

void main() {
  runApp(const OperationsApp());
}

class OperationsApp extends StatelessWidget {
  const OperationsApp({
    super.key,
    this.store,
    this.screenshotMode = kDefaultScreenshotMode,
  });

  final RecordsStore? store;
  final bool screenshotMode;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DUPUY FRANCOISE',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: OperationsShell(
        store: store ?? SharedPreferencesRecordsStore(),
        screenshotMode: screenshotMode,
      ),
    );
  }
}

ThemeData _buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final base = ColorScheme.fromSeed(
    seedColor: _brandBlue,
    brightness: brightness,
  );
  final scheme = base.copyWith(
    primary: isDark ? const Color(0xFF9FC7E7) : _brandNavy,
    onPrimary: isDark ? const Color(0xFF132331) : Colors.white,
    secondary: isDark ? const Color(0xFF86D1CB) : _brandTeal,
    tertiary: isDark ? const Color(0xFFEFD28F) : _brandGold,
    surface: isDark ? const Color(0xFF111820) : Colors.white,
    surfaceContainerHighest: isDark
        ? const Color(0xFF1D2934)
        : const Color(0xFFE9EEF1),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: isDark ? const Color(0xFF0C1117) : _brandPaper,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: scheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      filled: true,
      fillColor: scheme.surface,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: scheme.primaryContainer,
      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
    ),
  );
}

enum WorkType { shift, procurement, patrol, facility }

extension WorkTypeCopy on WorkType {
  String get label {
    switch (this) {
      case WorkType.shift:
        return 'Shift schedule';
      case WorkType.procurement:
        return 'Procurement';
      case WorkType.patrol:
        return 'Patrol log';
      case WorkType.facility:
        return 'Facility booking';
    }
  }

  String get shortLabel {
    switch (this) {
      case WorkType.shift:
        return 'Shifts';
      case WorkType.procurement:
        return 'Supplies';
      case WorkType.patrol:
        return 'Patrols';
      case WorkType.facility:
        return 'Facilities';
    }
  }

  IconData get icon {
    switch (this) {
      case WorkType.shift:
        return Icons.event_available_outlined;
      case WorkType.procurement:
        return Icons.inventory_2_outlined;
      case WorkType.patrol:
        return Icons.route_outlined;
      case WorkType.facility:
        return Icons.meeting_room_outlined;
    }
  }
}

enum WorkStatus { scheduled, inReview, active, completed }

extension WorkStatusCopy on WorkStatus {
  String get label {
    switch (this) {
      case WorkStatus.scheduled:
        return 'Scheduled';
      case WorkStatus.inReview:
        return 'In review';
      case WorkStatus.active:
        return 'Active';
      case WorkStatus.completed:
        return 'Completed';
    }
  }

  Color color(ColorScheme scheme) {
    switch (this) {
      case WorkStatus.scheduled:
        return scheme.primary;
      case WorkStatus.inReview:
        return scheme.tertiary;
      case WorkStatus.active:
        return scheme.secondary;
      case WorkStatus.completed:
        return const Color(0xFF527A4C);
    }
  }
}

class OperationRecord {
  const OperationRecord({
    required this.id,
    required this.type,
    required this.title,
    required this.owner,
    required this.location,
    required this.status,
    required this.priority,
    required this.dueLabel,
    required this.notes,
    required this.createdAt,
  });

  final String id;
  final WorkType type;
  final String title;
  final String owner;
  final String location;
  final WorkStatus status;
  final String priority;
  final String dueLabel;
  final String notes;
  final DateTime createdAt;

  OperationRecord copyWith({WorkStatus? status, String? notes}) {
    return OperationRecord(
      id: id,
      type: type,
      title: title,
      owner: owner,
      location: location,
      status: status ?? this.status,
      priority: priority,
      dueLabel: dueLabel,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'owner': owner,
      'location': location,
      'status': status.name,
      'priority': priority,
      'dueLabel': dueLabel,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory OperationRecord.fromJson(Map<String, Object?> json) {
    return OperationRecord(
      id: json['id'] as String,
      type: WorkType.values.byName(json['type'] as String),
      title: json['title'] as String,
      owner: json['owner'] as String,
      location: json['location'] as String,
      status: WorkStatus.values.byName(json['status'] as String),
      priority: json['priority'] as String,
      dueLabel: json['dueLabel'] as String,
      notes: json['notes'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

abstract class RecordsStore {
  Future<List<OperationRecord>> loadRecords();

  Future<void> saveRecords(List<OperationRecord> records);

  Future<void> clearRecords();
}

class SharedPreferencesRecordsStore implements RecordsStore {
  static const _recordsKey = 'dupuy_francoise_operations_records_v1';

  @override
  Future<List<OperationRecord>> loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_recordsKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map(
            (item) => OperationRecord.fromJson(
              Map<String, Object?>.from(item as Map),
            ),
          )
          .toList();
    } on Object {
      return [];
    }
  }

  @override
  Future<void> saveRecords(List<OperationRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _recordsKey,
      jsonEncode(records.map((record) => record.toJson()).toList()),
    );
  }

  @override
  Future<void> clearRecords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recordsKey);
  }
}

class MemoryRecordsStore implements RecordsStore {
  MemoryRecordsStore([List<OperationRecord>? records])
    : _records = List<OperationRecord>.from(records ?? const []);

  List<OperationRecord> _records;

  @override
  Future<List<OperationRecord>> loadRecords() async {
    return List<OperationRecord>.from(_records);
  }

  @override
  Future<void> saveRecords(List<OperationRecord> records) async {
    _records = List<OperationRecord>.from(records);
  }

  @override
  Future<void> clearRecords() async {
    _records = [];
  }
}

class OperationsShell extends StatefulWidget {
  const OperationsShell({
    super.key,
    required this.store,
    required this.screenshotMode,
  });

  final RecordsStore store;
  final bool screenshotMode;

  @override
  State<OperationsShell> createState() => _OperationsShellState();
}

class _OperationsShellState extends State<OperationsShell> {
  int _selectedIndex = 0;
  bool _loading = true;
  List<OperationRecord> _records = const [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    if (widget.screenshotMode) {
      setState(() {
        _records = _sampleRecords();
        _loading = false;
      });
      return;
    }

    final records = await widget.store.loadRecords();
    if (!mounted) {
      return;
    }
    setState(() {
      _records = records;
      _loading = false;
    });
  }

  Future<void> _saveRecords(List<OperationRecord> records) async {
    setState(() {
      _records = records;
    });
    if (!widget.screenshotMode) {
      await widget.store.saveRecords(records);
    }
  }

  Future<void> _addRecord(OperationRecord record) async {
    await _saveRecords([record, ..._records]);
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedIndex = 1;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${record.type.shortLabel} record saved')),
    );
  }

  Future<void> _updateRecord(OperationRecord updated) async {
    await _saveRecords([
      for (final record in _records)
        if (record.id == updated.id) updated else record,
    ]);
  }

  Future<void> _clearRecords() async {
    setState(() {
      _records = const [];
    });
    if (!widget.screenshotMode) {
      await widget.store.clearRecords();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(
        records: _records,
        onAddPressed: () => setState(() => _selectedIndex = 2),
        onQueuePressed: () => setState(() => _selectedIndex = 1),
      ),
      WorkQueueScreen(records: _records, onRecordUpdated: _updateRecord),
      NewRecordScreen(
        onCreate: _addRecord,
        screenshotMode: widget.screenshotMode,
      ),
      InsightsScreen(records: _records),
      SettingsScreen(
        recordCount: _records.length,
        onClearRecords: _clearRecords,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : IndexedStack(index: _selectedIndex, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.view_list_outlined),
            selectedIcon: Icon(Icons.view_list),
            label: 'Queue',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'New',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.privacy_tip_outlined),
            selectedIcon: Icon(Icons.privacy_tip),
            label: 'Privacy',
          ),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.records,
    required this.onAddPressed,
    required this.onQueuePressed,
  });

  final List<OperationRecord> records;
  final VoidCallback onAddPressed;
  final VoidCallback onQueuePressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final openCount = records
        .where((record) => record.status != WorkStatus.completed)
        .length;
    final completedCount = records.length - openCount;
    final urgentCount = records
        .where((record) => record.priority == 'High')
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _BrandHeader(
          title: 'DUPUY FRANCOISE',
          subtitle: 'Daily operations workspace',
          trailing: FilledButton.icon(
            onPressed: onAddPressed,
            icon: const Icon(Icons.add),
            label: const Text('New'),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _brandNavy,
            borderRadius: BorderRadius.circular(8),
            image: const DecorationImage(
              image: AssetImage('docs/featured.png'),
              fit: BoxFit.cover,
              opacity: 0.18,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Operations control',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Track shifts, supply requests, patrol coverage, and room bookings from one local device workspace.',
                style: TextStyle(color: Colors.white, height: 1.35),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _MetricPill(label: 'Open', value: '$openCount'),
                  _MetricPill(label: 'Complete', value: '$completedCount'),
                  _MetricPill(label: 'High priority', value: '$urgentCount'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Work modules',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth > 640 ? 4 : 2;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: columns,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: columns == 4 ? 1.25 : 1.05,
              children: [
                for (final type in WorkType.values)
                  _ModuleTile(
                    type: type,
                    count: records
                        .where((record) => record.type == type)
                        .length,
                    onTap: onQueuePressed,
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: Text(
                'Next attention',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(
              onPressed: onQueuePressed,
              child: const Text('View all'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (records.isEmpty)
          _EmptyState(
            icon: Icons.assignment_add,
            title: 'No records yet',
            message: 'Create the first shift, request, patrol, or booking.',
            actionLabel: 'Create record',
            onAction: onAddPressed,
          )
        else
          ...records
              .take(3)
              .map(
                (record) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RecordTile(
                    record: record,
                    color: record.status.color(scheme),
                    onTap: onQueuePressed,
                  ),
                ),
              ),
      ],
    );
  }
}

class WorkQueueScreen extends StatefulWidget {
  const WorkQueueScreen({
    super.key,
    required this.records,
    required this.onRecordUpdated,
  });

  final List<OperationRecord> records;
  final ValueChanged<OperationRecord> onRecordUpdated;

  @override
  State<WorkQueueScreen> createState() => _WorkQueueScreenState();
}

class _WorkQueueScreenState extends State<WorkQueueScreen> {
  WorkType? _filter;

  @override
  Widget build(BuildContext context) {
    final filtered = _filter == null
        ? widget.records
        : widget.records
              .where((record) => record.type == _filter)
              .toList(growable: false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        const _BrandHeader(
          title: 'Work queue',
          subtitle: 'Prioritize open operational records',
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: const Text('All'),
                  selected: _filter == null,
                  onSelected: (_) => setState(() => _filter = null),
                ),
              ),
              for (final type in WorkType.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    avatar: Icon(type.icon, size: 18),
                    label: Text(type.shortLabel),
                    selected: _filter == type,
                    onSelected: (_) => setState(() => _filter = type),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (filtered.isEmpty)
          const _EmptyState(
            icon: Icons.playlist_add_check,
            title: 'Queue is clear',
            message: 'New records will appear here as they are saved.',
          )
        else
          ...filtered.map(
            (record) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RecordTile(
                record: record,
                color: record.status.color(Theme.of(context).colorScheme),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => DetailScreen(
                      record: record,
                      onRecordUpdated: widget.onRecordUpdated,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class NewRecordScreen extends StatefulWidget {
  const NewRecordScreen({
    super.key,
    required this.onCreate,
    required this.screenshotMode,
  });

  final ValueChanged<OperationRecord> onCreate;
  final bool screenshotMode;

  @override
  State<NewRecordScreen> createState() => _NewRecordScreenState();
}

class _NewRecordScreenState extends State<NewRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _ownerController;
  late final TextEditingController _locationController;
  late final TextEditingController _dueController;
  late final TextEditingController _notesController;
  WorkType _type = WorkType.shift;
  WorkStatus _status = WorkStatus.scheduled;
  String _priority = 'Normal';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.screenshotMode ? 'Cover reception evening shift' : '',
    );
    _ownerController = TextEditingController(
      text: widget.screenshotMode ? 'M. Laurent' : '',
    );
    _locationController = TextEditingController(
      text: widget.screenshotMode ? 'Main lobby' : '',
    );
    _dueController = TextEditingController(
      text: widget.screenshotMode ? 'Today 18:00' : '',
    );
    _notesController = TextEditingController(
      text: widget.screenshotMode
          ? 'Confirm badge handover and supplier arrival window.'
          : '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _ownerController.dispose();
    _locationController.dispose();
    _dueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final now = DateTime.now();
    widget.onCreate(
      OperationRecord(
        id: now.microsecondsSinceEpoch.toString(),
        type: _type,
        title: _titleController.text.trim(),
        owner: _ownerController.text.trim(),
        location: _locationController.text.trim(),
        status: _status,
        priority: _priority,
        dueLabel: _dueController.text.trim(),
        notes: _notesController.text.trim(),
        createdAt: now,
      ),
    );

    if (!widget.screenshotMode) {
      _formKey.currentState!.reset();
      _titleController.clear();
      _ownerController.clear();
      _locationController.clear();
      _dueController.clear();
      _notesController.clear();
      setState(() {
        _type = WorkType.shift;
        _status = WorkStatus.scheduled;
        _priority = 'Normal';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        const _BrandHeader(
          title: 'Create record',
          subtitle: 'Add an operational item for local tracking',
        ),
        const SizedBox(height: 16),
        Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<WorkType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Workflow'),
                items: [
                  for (final type in WorkType.values)
                    DropdownMenuItem(value: type, child: Text(type.label)),
                ],
                onChanged: (value) => setState(() => _type = value ?? _type),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('record-title-field'),
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  prefixIcon: Icon(Icons.subject),
                ),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('record-owner-field'),
                controller: _ownerController,
                decoration: const InputDecoration(
                  labelText: 'Owner or team',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('record-location-field'),
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
                validator: _required,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<WorkStatus>(
                      initialValue: _status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: [
                        for (final status in WorkStatus.values)
                          DropdownMenuItem(
                            value: status,
                            child: Text(status.label),
                          ),
                      ],
                      onChanged: (value) =>
                          setState(() => _status = value ?? _status),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _priority,
                      decoration: const InputDecoration(labelText: 'Priority'),
                      items: const [
                        DropdownMenuItem(
                          value: 'Normal',
                          child: Text('Normal'),
                        ),
                        DropdownMenuItem(value: 'High', child: Text('High')),
                        DropdownMenuItem(value: 'Low', child: Text('Low')),
                      ],
                      onChanged: (value) =>
                          setState(() => _priority = value ?? _priority),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('record-due-field'),
                controller: _dueController,
                decoration: const InputDecoration(
                  labelText: 'Due time or booking window',
                  prefixIcon: Icon(Icons.schedule_outlined),
                ),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                minLines: 4,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const ValueKey('save-record-button'),
                  onPressed: _submit,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save record'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String? _required(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Required';
  }
  return null;
}

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key, required this.records});

  final List<OperationRecord> records;

  @override
  Widget build(BuildContext context) {
    final completed = records
        .where((record) => record.status == WorkStatus.completed)
        .length;
    final completionRate = records.isEmpty
        ? 0.0
        : (completed / records.length).clamp(0.0, 1.0).toDouble();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        const _BrandHeader(
          title: 'Status reports',
          subtitle: 'Operational outcomes by workflow',
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Completion health',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text('${(completionRate * 100).round()}% of records closed'),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: completionRate),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (final status in WorkStatus.values)
          _StatusLine(
            label: status.label,
            count: records.where((record) => record.status == status).length,
            color: status.color(Theme.of(context).colorScheme),
          ),
        const SizedBox(height: 18),
        Text(
          'Workflow coverage',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        for (final type in WorkType.values)
          _WorkflowCountLine(
            type: type,
            count: records.where((record) => record.type == type).length,
          ),
      ],
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.recordCount,
    required this.onClearRecords,
  });

  final int recordCount;
  final VoidCallback onClearRecords;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _compactQueue = false;
  bool _handoverFocus = true;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        const _BrandHeader(
          title: 'Privacy and settings',
          subtitle: 'Local-only workspace controls',
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                value: _handoverFocus,
                onChanged: (value) => setState(() => _handoverFocus = value),
                title: const Text('Handover focus'),
                subtitle: const Text('Keep high-priority work visible first.'),
                secondary: const Icon(Icons.priority_high_outlined),
              ),
              const Divider(height: 1),
              SwitchListTile(
                value: _compactQueue,
                onChanged: (value) => setState(() => _compactQueue = value),
                title: const Text('Compact queue'),
                subtitle: const Text(
                  'Reduce spacing for denser shift reviews.',
                ),
                secondary: const Icon(Icons.density_medium_outlined),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _InfoCard(
          icon: Icons.phone_android_outlined,
          title: 'Stored on this device',
          message:
              '${widget.recordCount} operation records are saved in local app storage. No account or cloud sync is used.',
        ),
        const SizedBox(height: 12),
        const _InfoCard(
          icon: Icons.lock_outline,
          title: 'No data collection',
          message:
              'The app does not collect analytics, location, contacts, photos, microphone input, advertising identifiers, or payment data.',
        ),
        const SizedBox(height: 12),
        const _InfoCard(
          icon: Icons.support_agent_outlined,
          title: 'Support',
          message: 'DUPUY FRANCOISE\nsupport@dupuyfrancoise.com',
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: widget.recordCount == 0
              ? null
              : () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Clear local records?'),
                      content: const Text(
                        'This removes saved operations records from this device.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed ?? false) {
                    widget.onClearRecords();
                  }
                },
          icon: const Icon(Icons.delete_outline),
          label: const Text('Clear local records'),
        ),
      ],
    );
  }
}

class DetailScreen extends StatefulWidget {
  const DetailScreen({
    super.key,
    required this.record,
    required this.onRecordUpdated,
  });

  final OperationRecord record;
  final ValueChanged<OperationRecord> onRecordUpdated;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late OperationRecord _record = widget.record;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusColor = _record.status.color(scheme);

    return Scaffold(
      appBar: AppBar(title: Text(_record.type.label)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_record.type.icon, color: scheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _record.title,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StatusChip(
                        label: _record.status.label,
                        color: statusColor,
                      ),
                      _StatusChip(
                        label: _record.priority,
                        color: scheme.tertiary,
                      ),
                      _StatusChip(
                        label: _record.dueLabel,
                        color: scheme.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _InfoCard(
            icon: Icons.person_outline,
            title: 'Owner',
            message: _record.owner,
          ),
          const SizedBox(height: 12),
          _InfoCard(
            icon: Icons.place_outlined,
            title: 'Location',
            message: _record.location,
          ),
          const SizedBox(height: 12),
          _InfoCard(
            icon: Icons.notes_outlined,
            title: 'Notes',
            message: _record.notes.isEmpty ? 'No notes added.' : _record.notes,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _record.status == WorkStatus.completed
                ? null
                : () {
                    final updated = _record.copyWith(
                      status: WorkStatus.completed,
                      notes:
                          '${_record.notes}\nClosed locally after manager review.'
                              .trim(),
                    );
                    widget.onRecordUpdated(updated);
                    setState(() {
                      _record = updated;
                    });
                  },
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Mark completed'),
          ),
        ],
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'docs/icon.png',
            width: 48,
            height: 48,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
    required this.type,
    required this.count,
    required this.onTap,
  });

  final WorkType type;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(type.icon, color: scheme.primary),
              const Spacer(),
              Text(
                type.shortLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                '$count active',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({
    required this.record,
    required this.color,
    required this.onTap,
  });

  final OperationRecord record;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(record.type.icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${record.owner} - ${record.location}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _StatusChip(label: record.status.label, color: color),
                        _StatusChip(
                          label: record.dueLabel,
                          color: scheme.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
          Text('$count', style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _WorkflowCountLine extends StatelessWidget {
  const _WorkflowCountLine({required this.type, required this.count});

  final WorkType type;
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(type.icon, color: scheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                type.label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Text('$count'),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: scheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(message),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(icon, size: 42, color: scheme.primary),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 14),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

List<OperationRecord> _sampleRecords() {
  final created = DateTime(2026, 5, 12, 8);
  return [
    OperationRecord(
      id: 'sample-001',
      type: WorkType.shift,
      title: 'Confirm late shift coverage',
      owner: 'S. Martin',
      location: 'Front desk',
      status: WorkStatus.active,
      priority: 'High',
      dueLabel: 'Today 17:30',
      notes:
          'Two guards assigned. Reception handover must include badge audit.',
      createdAt: created,
    ),
    OperationRecord(
      id: 'sample-002',
      type: WorkType.procurement,
      title: 'Approve cleaning supply request',
      owner: 'Facilities team',
      location: 'Stock room B',
      status: WorkStatus.inReview,
      priority: 'Normal',
      dueLabel: 'Today 15:00',
      notes: 'Review quantity against weekly stock threshold before approval.',
      createdAt: created.subtract(const Duration(hours: 1)),
    ),
    OperationRecord(
      id: 'sample-003',
      type: WorkType.patrol,
      title: 'North wing patrol round',
      owner: 'Security post 2',
      location: 'North wing',
      status: WorkStatus.scheduled,
      priority: 'High',
      dueLabel: 'Tonight 21:00',
      notes: 'Check loading bay, archive corridor, and emergency exits.',
      createdAt: created.subtract(const Duration(hours: 2)),
    ),
    OperationRecord(
      id: 'sample-004',
      type: WorkType.facility,
      title: 'Reserve boardroom for supplier review',
      owner: 'Operations office',
      location: 'Boardroom A',
      status: WorkStatus.completed,
      priority: 'Normal',
      dueLabel: 'Closed',
      notes: 'Room confirmed with projector and access list.',
      createdAt: created.subtract(const Duration(hours: 3)),
    ),
    OperationRecord(
      id: 'sample-005',
      type: WorkType.procurement,
      title: 'Quote replacement access cards',
      owner: 'Admin team',
      location: 'Procurement desk',
      status: WorkStatus.scheduled,
      priority: 'Low',
      dueLabel: 'Friday',
      notes: 'Collect two quotes and attach vendor response in local notes.',
      createdAt: created.subtract(const Duration(hours: 4)),
    ),
  ];
}
