import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/theme_constants.dart';
import '../../core/utils/date_utils.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../models/love_note_model.dart';
import '../../providers/love_notes_provider.dart';
import '../../providers/couple_provider.dart';

class LoveNotesScreen extends StatefulWidget {
  const LoveNotesScreen({super.key});

  @override
  State<LoveNotesScreen> createState() => _LoveNotesScreenState();
}

class _LoveNotesScreenState extends State<LoveNotesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadNotes());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    final couple = context.read<CoupleProvider>();
    if (couple.couple != null) {
      _loaded = true;
      await context.read<LoveNotesProvider>().loadNotes(couple.couple!.id);
    }
  }

  Future<void> _addNote() async {
    final result = await Navigator.pushNamed(context, '/note-editor');
    if (result == null || !mounted) return;

    _loadNotes();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Love Notes'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addNote),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: ThemeConstants.primaryColor,
          unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
          indicatorColor: ThemeConstants.primaryColor,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Favorites'),
            Tab(text: 'Future'),
          ],
        ),
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
        child: Consumer2<LoveNotesProvider, CoupleProvider>(
          builder: (_, notes, couple, __) {
            if (!_loaded && couple.couple != null) {
              _loaded = true;
              WidgetsBinding.instance.addPostFrameCallback((_) => _loadNotes());
            }
            return TabBarView(
              controller: _tabController,
              children: [
                _buildNotesList(notes.notes),
                _buildNotesList(notes.favorites),
                _buildNotesList(notes.futureMessages),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotesList(List<LoveNoteModel> notes) {
    if (notes.isEmpty) {
      return const EmptyState(
        icon: Icons.notes_outlined,
        title: 'No love notes',
        subtitle: 'Write your first love note',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notes.length,
      itemBuilder: (_, i) => _buildNoteCard(notes[i]),
    );
  }

  Widget _buildNoteCard(LoveNoteModel note) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                note.type == 'future' ? Icons.schedule : Icons.favorite,
                color: ThemeConstants.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(note.title, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              IconButton(
                icon: Icon(
                  note.isFavorite == 1 ? Icons.favorite : Icons.favorite_border,
                  color: note.isFavorite == 1 ? Colors.red : Colors.grey,
                  size: 20,
                ),
                onPressed: () => context.read<LoveNotesProvider>().toggleFavorite(note.id),
              ),
            ],
          ),
          if (note.content.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              note.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Text(DateFormatUtils.timeAgo(DateFormatUtils.parseDateTime(note.createdAt)),
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const Spacer(),
              if (note.scheduledDate != null)
                Text('Scheduled: ${note.scheduledDate}',
                    style: const TextStyle(fontSize: 12, color: Colors.orange)),
            ],
          ),
        ],
      ),
    );
  }
}
