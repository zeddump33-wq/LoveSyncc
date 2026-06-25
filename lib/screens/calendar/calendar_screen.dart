import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/constants/theme_constants.dart';
import '../../core/utils/date_utils.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/empty_state.dart';
import '../../models/event_model.dart';
import '../../providers/calendar_provider.dart';
import '../../providers/couple_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/utils/encryption_utils.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();
  CalendarFormat _format = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final couple = context.read<CoupleProvider>();
    if (couple.couple != null) {
      await context.read<CalendarProvider>().loadEvents(couple.couple!.id);
    }
  }

  Future<void> _addEvent() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _AddEventDialog(),
    );

    if (result == null || !mounted) return;

    final auth = context.read<AuthProvider>();
    final couple = context.read<CoupleProvider>();
    if (couple.couple == null || auth.user == null) return;

    final event = EventModel(
      id: EncryptionUtils.generateId(),
      coupleId: couple.couple!.id,
      title: result['title'],
      description: result['description'],
      date: DateFormatUtils.formatDate(_selectedDate),
      type: result['type'],
      reminderEnabled: result['reminder'] ? 1 : 0,
      createdAt: DateFormatUtils.formatDateTime(DateTime.now()),
      createdBy: auth.user!.id,
    );

    await context.read<CalendarProvider>().addEvent(event);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addEvent,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                : [const Color(0xFFFDF2F8), const Color(0xFFFFF5F9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            GlassCard(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(8),
              child: TableCalendar(
                firstDay: DateTime(2020),
                lastDay: DateTime(2030),
                focusedDay: _focusedDate,
                selectedDayPredicate: (d) => isSameDay(d, _selectedDate),
                calendarFormat: _format,
                onFormatChanged: (f) => setState(() => _format = f),
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDate = selected;
                    _focusedDate = focused;
                  });
                },
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: ThemeConstants.primaryColor.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: ThemeConstants.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormatUtils.formatDisplay(_selectedDate),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 16),
                  ),
                  TextButton.icon(
                    onPressed: _addEvent,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Event'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Consumer<CalendarProvider>(
                builder: (_, cal, __) {
                  final dayEvents = cal.getEventsForDate(_selectedDate);
                  if (dayEvents.isEmpty) {
                    return const EmptyState(
                      icon: Icons.event_busy,
                      title: 'No events',
                      subtitle: 'Tap + to add an event for this day',
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: dayEvents.length,
                    itemBuilder: (_, i) => _buildEventCard(dayEvents[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(EventModel event) {
    IconData icon;
    switch (event.type) {
      case 'anniversary':
        icon = Icons.favorite;
        break;
      case 'birthday':
        icon = Icons.cake;
        break;
      default:
        icon = Icons.event;
    }

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ThemeConstants.primaryColor.withOpacity(0.1),
            ),
            child: Icon(icon, color: ThemeConstants.primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (event.description != null) Text(event.description!, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          if (event.reminderEnabled == 1)
            const Icon(Icons.notifications_active, size: 18, color: ThemeConstants.primaryColor),
        ],
      ),
    );
  }
}

class _AddEventDialog extends StatefulWidget {
  const _AddEventDialog();

  @override
  State<_AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<_AddEventDialog> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _type = 'custom';
  bool _reminder = true;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add Event', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Event Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(value: 'custom', child: Text('Custom')),
                DropdownMenuItem(value: 'anniversary', child: Text('Anniversary')),
                DropdownMenuItem(value: 'birthday', child: Text('Birthday')),
              ],
              onChanged: (v) => setState(() => _type = v ?? 'custom'),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Enable Reminder'),
              value: _reminder,
              onChanged: (v) => setState(() => _reminder = v),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 20),
            GradientButton(
              text: 'Add Event',
              onPressed: () {
                if (_titleController.text.trim().isEmpty) return;
                Navigator.pop(context, {
                  'title': _titleController.text.trim(),
                  'description': _descController.text.trim().isEmpty ? null : _descController.text.trim(),
                  'type': _type,
                  'reminder': _reminder,
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
