import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/theme_constants.dart';
import '../../core/utils/encryption_utils.dart';
import '../../core/utils/date_utils.dart';
import '../../core/widgets/glass_card.dart';
import '../../models/love_note_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/couple_provider.dart';
import '../../providers/love_notes_provider.dart';

class NoteEditorScreen extends StatefulWidget {
  const NoteEditorScreen({super.key});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _type = 'note';
  DateTime? _scheduledDate;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) return;

    final auth = context.read<AuthProvider>();
    final couple = context.read<CoupleProvider>();
    if (couple.couple == null || auth.user == null) return;

    final note = LoveNoteModel(
      id: EncryptionUtils.generateId(),
      coupleId: couple.couple!.id,
      senderId: auth.user!.id,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      type: _type,
      scheduledDate: _scheduledDate != null ? DateFormatUtils.formatDate(_scheduledDate!) : null,
      isDelivered: _type == 'future' ? 0 : 1,
      createdAt: DateFormatUtils.formatDateTime(DateTime.now()),
    );

    await context.read<LoveNotesProvider>().addNote(note);

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _pickScheduledDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      setState(() => _scheduledDate = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Write Love Note'),
        actions: [
          TextButton(onPressed: _save, child: const Text('Save', style: TextStyle(color: ThemeConstants.primaryColor, fontWeight: FontWeight.w600))),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              GlassCard(
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'To my love...',
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                    const Divider(),
                    TextField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        hintText: 'Write your love note here...',
                        border: InputBorder.none,
                      ),
                      maxLines: 10,
                      style: const TextStyle(fontSize: 16, height: 1.6),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Schedule for later'),
                      value: _type == 'future',
                      onChanged: (v) {
                        setState(() => _type = v ? 'future' : 'note');
                        if (v && _scheduledDate == null) {
                          _pickScheduledDate();
                        }
                      },
                    ),
                    if (_type == 'future' && _scheduledDate != null)
                      ListTile(
                        title: Text('Delivery date: ${DateFormatUtils.formatDisplay(_scheduledDate!)}'),
                        trailing: const Icon(Icons.edit_calendar),
                        onTap: _pickScheduledDate,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_contentController.text.isNotEmpty)
                Text(
                  '${_contentController.text.length} characters',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
