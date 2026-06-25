import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/theme_constants.dart';
import '../../core/utils/encryption_utils.dart';
import '../../core/utils/date_utils.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/empty_state.dart';
import '../../models/wishlist_model.dart';
import '../../providers/wishlist_provider.dart';
import '../../providers/couple_provider.dart';
import '../../providers/auth_provider.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    final couple = context.read<CoupleProvider>();
    if (couple.couple != null) {
      await context.read<WishlistProvider>().loadWishlist(couple.couple!.id);
    }
  }

  Future<void> _addItem() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _AddWishlistItemDialog(),
    );

    if (result == null || !mounted) return;

    final auth = context.read<AuthProvider>();
    final couple = context.read<CoupleProvider>();
    if (couple.couple == null || auth.user == null) return;

    final item = WishlistModel(
      id: EncryptionUtils.generateId(),
      coupleId: couple.couple!.id,
      title: result['title'],
      description: result['description'],
      price: result['price'],
      link: result['link'],
      createdAt: DateFormatUtils.formatDateTime(DateTime.now()),
      createdBy: auth.user!.id,
    );

    await context.read<WishlistProvider>().addItem(item);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addItem),
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
        child: Consumer<WishlistProvider>(
          builder: (_, wishlist, __) {
            if (wishlist.wishlist.isEmpty) {
              return EmptyState(
                icon: Icons.card_giftcard_outlined,
                title: 'No wishlist items',
                subtitle: 'Add gift ideas for your partner',
                actionLabel: 'Add Item',
                onAction: _addItem,
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: wishlist.wishlist.length,
              itemBuilder: (_, i) => _buildItemCard(wishlist.wishlist[i]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildItemCard(WishlistModel item) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: ThemeConstants.primaryColor.withOpacity(0.1),
            ),
            child: const Icon(Icons.card_giftcard, color: ThemeConstants.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (item.description != null)
                  Text(item.description!, style: Theme.of(context).textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (item.price != null)
                  Text('\$${item.price!.toStringAsFixed(2)}', style: const TextStyle(color: ThemeConstants.primaryColor, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Column(
            children: [
              if (item.isPurchased == 1)
                const Icon(Icons.check_circle, color: Colors.green)
              else if (item.isReserved == 1)
                const Icon(Icons.lock, color: Colors.orange)
              else
                const Icon(Icons.favorite_border, color: Colors.grey),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddWishlistItemDialog extends StatefulWidget {
  const _AddWishlistItemDialog();

  @override
  State<_AddWishlistItemDialog> createState() => _AddWishlistItemDialogState();
}

class _AddWishlistItemDialogState extends State<_AddWishlistItemDialog> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _linkController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _linkController.dispose();
    super.dispose();
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
              const Text('Add Gift Idea', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Gift Title')),
              const SizedBox(height: 12),
              TextField(controller: _descController, decoration: const InputDecoration(labelText: 'Description (optional)'), maxLines: 2),
              const SizedBox(height: 12),
              TextField(controller: _priceController, decoration: const InputDecoration(labelText: 'Price (optional)'), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              TextField(controller: _linkController, decoration: const InputDecoration(labelText: 'Link (optional)')),
              const SizedBox(height: 20),
              GradientButton(
                text: 'Add to Wishlist',
                onPressed: () {
                  if (_titleController.text.trim().isEmpty) return;
                  Navigator.pop(context, {
                    'title': _titleController.text.trim(),
                    'description': _descController.text.trim().isEmpty ? null : _descController.text.trim(),
                    'price': _priceController.text.trim().isEmpty ? null : double.tryParse(_priceController.text.trim()),
                    'link': _linkController.text.trim().isEmpty ? null : _linkController.text.trim(),
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
