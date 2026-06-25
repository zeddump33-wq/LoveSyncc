import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/theme_constants.dart';
import '../../core/services/database_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../providers/auth_provider.dart';
import '../../providers/couple_provider.dart';

class PartnerLinkingScreen extends StatefulWidget {
  const PartnerLinkingScreen({super.key});

  @override
  State<PartnerLinkingScreen> createState() => _PartnerLinkingScreenState();
}

class _PartnerLinkingScreenState extends State<PartnerLinkingScreen> {
  final _inviteController = TextEditingController();
  final _dateController = TextEditingController();
  String? _inviteCode;
  bool _isLinking = false;
  bool _isJoining = false;
  bool _pollingActive = false;
  Timer? _pollTimer;

  Future<void> _createCouple() async {
    if (_dateController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your anniversary date'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLinking = true);
    final provider = context.read<CoupleProvider>();
    final code = await provider.createCouple(_dateController.text.trim());

    if (!mounted) return;
    setState(() => _isLinking = false);

    if (code != null) {
      setState(() => _inviteCode = code);
      _startPolling();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create couple. Please try again.'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _joinCouple() async {
    if (_inviteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an invite code'), backgroundColor: Colors.orange),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    if (auth.user?.inviteCode == _inviteController.text.trim().toUpperCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot connect with yourself!'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isJoining = true);
    final provider = context.read<CoupleProvider>();
    final success = await provider.joinCouple(_inviteController.text.trim().toUpperCase());

    if (!mounted) return;
    setState(() => _isJoining = false);

    if (success) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 28),
              const SizedBox(width: 8),
              const Text('Connected!'),
            ],
          ),
          content: const Text('Successfully connected with your partner!'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Start Chatting'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid invite code or code already used'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _unlinkPartner() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Unlink Partner?'),
        content: const Text('This will disconnect you from your partner. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Unlink', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<CoupleProvider>().unlinkPartner();
      setState(() {
        _inviteCode = null;
      });
    }
  }

  void _startPolling() {
    _pollingActive = true;
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted || !_pollingActive) return;
      final auth = context.read<AuthProvider>();
      if (auth.user?.coupleId == null) return;
      try {
        final joined = await FirestoreService.getJoiningPartner(
          auth.user!.coupleId!,
          auth.user!.id,
        );
        if (joined != null && mounted) {
          _pollingActive = false;
          _pollTimer?.cancel();
          // Update local DB and provider with the joined partner data
          final now = DateTime.now().toIso8601String();
          final joinedUserId = joined['id'] as String;
          await DatabaseService.update('couples', {
            'partner2Id': joinedUserId,
            'status': 'active',
            'updatedAt': now,
          }, auth.user!.coupleId!);
          await DatabaseService.update('users', {
            'partnerId': joinedUserId,
            'updatedAt': now,
          }, auth.user!.id);
          await context.read<CoupleProvider>().loadCouple(auth.user!.coupleId!);
          if (!mounted) return;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.favorite, color: Colors.red, size: 28),
                  const SizedBox(width: 8),
                  const Text('Partner Connected!'),
                ],
              ),
              content: const Text('Your partner has joined. You are now connected!'),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text('Start Chatting'),
                ),
              ],
            ),
          );
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _pollingActive = false;
    _pollTimer?.cancel();
    _inviteController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final couple = context.watch<CoupleProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Partner Linking')),
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
              if (couple.isLinked) ...[
                GlassCard(
                  gradient: ThemeConstants.loveGradient,
                  child: Column(
                    children: [
                      const Icon(Icons.favorite, size: 48, color: Colors.white),
                      const SizedBox(height: 12),
                      const Text('Connected!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text('${couple.daysTogether} days together', style: TextStyle(color: Colors.white.withOpacity(0.9))),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: _unlinkPartner,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white38),
                        ),
                        child: const Text('Unlink Partner'),
                      ),
                    ],
                  ),
                ),
              ] else if (_inviteCode != null) ...[
                GlassCard(
                  gradient: ThemeConstants.loveGradient,
                  child: Column(
                    children: [
                      const Icon(Icons.link, size: 48, color: Colors.white),
                      const SizedBox(height: 12),
                      const Text('Share this code with your partner:',
                          style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: _inviteCode!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Code copied to clipboard!'), duration: Duration(seconds: 2)),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _inviteCode!,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 4,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Icon(Icons.copy, color: Colors.white70, size: 24),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Waiting for partner to join...',
                          style: TextStyle(color: Colors.white.withOpacity(0.7))),
                    ],
                  ),
                ),
              ] else ...[
                GlassCard(
                  child: Column(
                    children: [
                      const Text('Create a Couple', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('Start your love journey', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _dateController,
                        decoration: const InputDecoration(
                          labelText: 'Anniversary Date',
                          prefixIcon: Icon(Icons.calendar_today),
                          suffixIcon: Icon(Icons.date_range),
                        ),
                        readOnly: true,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2010),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            _dateController.text =
                                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      GradientButton(text: 'Create Invite Code', isLoading: _isLinking, onPressed: _createCouple),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('OR', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 20),
                GlassCard(
                  child: Column(
                    children: [
                      const Text('Join a Couple', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('Enter your partner\'s invite code', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _inviteController,
                        decoration: const InputDecoration(
                          labelText: 'Invite Code',
                          prefixIcon: Icon(Icons.vpn_key),
                          hintText: 'Enter 8-character code',
                        ),
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 8,
                      ),
                      const SizedBox(height: 16),
                      GradientButton(text: 'Connect', isLoading: _isJoining, onPressed: _joinCouple),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
