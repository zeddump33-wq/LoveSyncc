import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/theme_constants.dart';
import '../../core/utils/encryption_utils.dart';
import '../../core/utils/date_utils.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/empty_state.dart';
import '../../models/goal_model.dart';
import '../../providers/goals_provider.dart';
import '../../providers/couple_provider.dart';
import '../../providers/auth_provider.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadGoals());
  }

  Future<void> _loadGoals() async {
    final couple = context.read<CoupleProvider>();
    if (couple.couple != null) {
      _loaded = true;
      await context.read<GoalsProvider>().loadGoals(couple.couple!.id);
    }
  }

  Future<void> _addGoal() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _AddGoalDialog(),
    );

    if (result == null || !mounted) return;

    final auth = context.read<AuthProvider>();
    final couple = context.read<CoupleProvider>();
    if (couple.couple == null || auth.user == null) return;

    final goal = GoalModel(
      id: EncryptionUtils.generateId(),
      coupleId: couple.couple!.id,
      title: result['title'],
      description: result['description'],
      type: result['type'],
      targetValue: result['target'] != null ? double.parse(result['target'].toString()) : null,
      targetDate: result['targetDate'],
      createdAt: DateFormatUtils.formatDateTime(DateTime.now()),
      createdBy: auth.user!.id,
    );

    await context.read<GoalsProvider>().addGoal(goal);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Couple Goals'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addGoal),
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
        child: Consumer2<GoalsProvider, CoupleProvider>(
          builder: (_, goals, couple, __) {
            if (!_loaded && couple.couple != null) {
              _loaded = true;
              WidgetsBinding.instance.addPostFrameCallback((_) => _loadGoals());
            }
            if (goals.goals.isEmpty) {
              return EmptyState(
                icon: Icons.emoji_events_outlined,
                title: 'No goals yet',
                subtitle: 'Set your first couple goal together',
                actionLabel: 'Add Goal',
                onAction: _addGoal,
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: goals.goals.length,
              itemBuilder: (_, i) => _buildGoalCard(goals.goals[i]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGoalCard(GoalModel goal) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                goal.type == 'savings' ? Icons.savings : goal.type == 'travel' ? Icons.flight_takeoff : Icons.flag_outlined,
                color: ThemeConstants.primaryColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (goal.description != null)
                      Text(goal.description!, style: Theme.of(context).textTheme.bodyMedium),
                    Text(goal.type, style: TextStyle(fontSize: 11, color: ThemeConstants.primaryColor.withOpacity(0.7))),
                  ],
                ),
              ),
              if (goal.isCompleted == 1)
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                onPressed: () => _confirmDeleteGoal(goal.id),
              ),
            ],
          ),
          if (goal.targetValue != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: goal.progress,
                backgroundColor: Colors.grey[300],
                color: ThemeConstants.primaryColor,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${goal.currentValue.toStringAsFixed(0)} / ${goal.targetValue!.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
            ),
          ],
          if (goal.targetDate != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('Target: ${goal.targetDate}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDeleteGoal(String goalId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Goal?'),
        content: const Text('This will permanently remove this goal.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<GoalsProvider>().deleteGoal(goalId);
    }
  }
}

class _AddGoalDialog extends StatefulWidget {
  const _AddGoalDialog();

  @override
  State<_AddGoalDialog> createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends State<_AddGoalDialog> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _targetController = TextEditingController();
  final _customTypeController = TextEditingController();
  String _type = 'savings';
  bool _isCustomType = false;
  String? _targetDate;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      setState(() => _targetDate = DateFormatUtils.formatDate(date));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('New Goal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Goal Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _isCustomType ? 'custom' : _type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'savings', child: Text('Savings')),
                  DropdownMenuItem(value: 'travel', child: Text('Travel')),
                  DropdownMenuItem(value: 'custom', child: Text('Custom...')),
                ],
                onChanged: (v) {
                  setState(() {
                    _isCustomType = v == 'custom';
                    if (!_isCustomType) _type = v ?? 'savings';
                  });
                },
              ),
              if (_isCustomType) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _customTypeController,
                  decoration: const InputDecoration(labelText: 'Custom Type'),
                  onChanged: (v) => _type = v.trim().toLowerCase(),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _targetController,
                decoration: const InputDecoration(labelText: 'Target Amount'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              ListTile(
                title: Text(_targetDate ?? 'Set Target Date'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 20),
              GradientButton(
                text: 'Create Goal',
                onPressed: () {
                  if (_titleController.text.trim().isEmpty) return;
                  Navigator.pop(context, {
                    'title': _titleController.text.trim(),
                    'description': _descController.text.trim().isEmpty ? null : _descController.text.trim(),
                    'type': _type,
                    'target': _targetController.text.trim().isEmpty ? null : double.tryParse(_targetController.text.trim()),
                    'targetDate': _targetDate,
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
