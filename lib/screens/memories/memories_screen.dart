import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/encryption_utils.dart';
import '../../core/utils/platform_image_loader.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/services/file_storage_service.dart' as file_storage;
import '../../models/memory_model.dart';
import '../../providers/memories_provider.dart';
import '../../providers/couple_provider.dart';

class MemoriesScreen extends StatefulWidget {
  const MemoriesScreen({super.key});

  @override
  State<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMemories());
  }

  Future<void> _loadMemories() async {
    final couple = context.read<CoupleProvider>();
    if (couple.couple != null) {
      _loaded = true;
      await context.read<MemoriesProvider>().loadMemories(couple.couple!.id);
    }
  }

  Future<void> _addMemory() async {
    final path = await file_storage.FileStorageService.pickAndSaveImage();
    if (path == null || !mounted) return;

    final couple = context.read<CoupleProvider>();
    if (couple.couple == null) return;

    final caption = await showDialog<String>(
      context: context,
      builder: (_) => const _CaptionDialog(),
    );

    if (caption == null || !mounted) return;

    final memory = MemoryModel(
      id: EncryptionUtils.generateId(),
      coupleId: couple.couple!.id,
      imagePath: path,
      caption: caption.isEmpty ? null : caption,
      date: DateFormatUtils.formatDate(DateTime.now()),
      createdAt: DateFormatUtils.formatDateTime(DateTime.now()),
    );

    await context.read<MemoriesProvider>().addMemory(memory);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo),
            onPressed: _addMemory,
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
        child: Consumer2<MemoriesProvider, CoupleProvider>(
          builder: (_, mem, couple, __) {
            if (!_loaded && couple.couple != null) {
              _loaded = true;
              WidgetsBinding.instance.addPostFrameCallback((_) => _loadMemories());
            }
            if (mem.memories.isEmpty) {
              return EmptyState(
                icon: Icons.photo_album_outlined,
                title: 'No memories yet',
                subtitle: 'Capture your special moments together',
                actionLabel: 'Add Memory',
                onAction: _addMemory,
              );
            }
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: mem.memories.length,
              itemBuilder: (_, i) => _buildMemoryTile(mem.memories[i]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMemoryTile(MemoryModel memory) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/memory-detail', arguments: memory),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (memory.imagePath != null)
            kIsWeb
                ? Image.network(
                    memory.imagePath!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: Colors.grey[300]),
                  )
                : platformImageWidget(
                    memory.imagePath!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: Colors.grey[300]),
                  )
          else
            Container(color: Colors.grey[300]),
          if (memory.isFavorite == 1)
            const Positioned(
              top: 4,
              right: 4,
              child: Icon(Icons.favorite, color: Colors.red, size: 16),
            ),
        ],
      ),
    );
  }
}

class _CaptionDialog extends StatefulWidget {
  const _CaptionDialog();

  @override
  State<_CaptionDialog> createState() => _CaptionDialogState();
}

class _CaptionDialogState extends State<_CaptionDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
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
            const Text('Add a caption', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Write something special...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              autofocus: true,
            ),
            const SizedBox(height: 20),
            GradientButton(
              text: 'Save',
              onPressed: () => Navigator.pop(context, _controller.text),
            ),
          ],
        ),
      ),
    );
  }
}
