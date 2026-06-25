import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/theme_constants.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/common_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../providers/couple_provider.dart';
import '../../providers/theme_provider.dart';
import '../../core/services/biometric_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/partner_service.dart';
import '../../core/services/file_storage_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
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
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Profile header
            Consumer<AuthProvider>(
              builder: (_, auth, __) => GlassCard(
                child: Row(
                  children: [
                    AvatarWidget(
                      name: auth.user?.name ?? 'Me',
                      photoPath: auth.user?.photoPath,
                      size: 64,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(auth.user?.name ?? 'User',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          Text(auth.user?.email ?? 'Local Account',
                              style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showEditProfileDialog(context),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Partner section
            Consumer<CoupleProvider>(
              builder: (_, couple, __) => GlassCard(
                onTap: couple.isLinked
                    ? () => Navigator.pushNamed(context, '/partner-linking')
                    : () => Navigator.pushNamed(context, '/partner-linking'),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ThemeConstants.primaryColor.withOpacity(0.1),
                      ),
                      child: Icon(
                        couple.isLinked ? Icons.favorite : Icons.person_add,
                        color: ThemeConstants.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            couple.isLinked ? (couple.partner?.name ?? 'My Love') : 'Link Partner',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            couple.isLinked
                                ? '${couple.daysTogether} days together'
                                : 'Connect with your partner',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Love Start Date
            Consumer<CoupleProvider>(
              builder: (_, couple, __) => GlassCard(
                onTap: couple.couple != null ? () => _editAnniversaryDate(context) : null,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ThemeConstants.primaryColor.withOpacity(0.1),
                      ),
                      child: const Icon(Icons.date_range, color: ThemeConstants.primaryColor),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Love Since', style: TextStyle(fontWeight: FontWeight.w600)),
                          Text(
                            couple.couple?.anniversaryDate != null
                                ? couple.couple!.anniversaryDate!
                                : 'Not set yet',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    if (couple.couple != null) const Icon(Icons.edit, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Settings
            const Text('Security', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 8),
            _buildSettingsTile(context, Icons.lock_outline, 'Set PIN Lock', () => _showPinDialog(context)),
            _buildSettingsTile(context, Icons.fingerprint, 'Fingerprint / Face Unlock', () => _toggleBiometric(context)),
            const SizedBox(height: 20),

            const Text('Preferences', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 8),
            _buildThemeSwitch(context),
            const SizedBox(height: 20),

            const Text('Data', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 8),
            _buildSettingsTile(context, Icons.storage, 'Statistics', () => Navigator.pushNamed(context, '/statistics')),

            const SizedBox(height: 20),
            // Logout
            GradientButton(
              text: 'Sign Out',
              gradient: [Colors.red, Colors.redAccent],
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                if (!context.mounted) return;
                Navigator.pushReplacementNamed(context, '/auth');
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: ThemeConstants.primaryColor, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w500))),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildThemeSwitch(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (_, theme, __) => GlassCard(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Icon(theme.isDark ? Icons.dark_mode : Icons.light_mode, color: ThemeConstants.primaryColor),
            const SizedBox(width: 12),
            const Expanded(child: Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w500))),
            Switch(
              value: theme.isDark,
              onChanged: (v) => theme.setDarkMode(v),
              activeColor: ThemeConstants.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  void _editAnniversaryDate(BuildContext context) {
    final couple = context.read<CoupleProvider>();
    final initialDate = couple.couple?.anniversaryDate != null
        ? DateTime.parse(couple.couple!.anniversaryDate!)
        : DateTime.now();
    showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    ).then((date) {
      if (date != null && context.mounted) {
        final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        couple.updateAnniversary(dateStr);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Love start date updated!'), backgroundColor: Colors.green),
        );
      }
    });
  }

  void _showEditProfileDialog(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final nameController = TextEditingController(text: auth.user?.name);
    String? newPhotoPath;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: const Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  final path = await FileStorageService.pickAndSaveImage();
                  if (path != null) setDialogState(() => newPhotoPath = path);
                },
                child: Stack(
                  children: [
                    AvatarWidget(
                      name: auth.user?.name ?? 'Me',
                      photoPath: newPhotoPath ?? auth.user?.photoPath,
                      size: 80,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: ThemeConstants.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                auth.updateProfile(nameController.text.trim(), photoPath: newPhotoPath);
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPinDialog(BuildContext context) {
    final controller = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Set PIN Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Enter PIN'),
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(labelText: 'Confirm PIN'),
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (controller.text == confirmController.text && controller.text.length >= 4) {
                context.read<AuthProvider>().setPinCode(controller.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN set successfully')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleBiometric(BuildContext context) async {
    final available = await BiometricService.isAvailable();
    if (!available) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometric authentication not available on this device')),
      );
      return;
    }

    final enabled = !StorageService.isBiometricEnabled();
    await StorageService.setBiometricEnabled(enabled);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(enabled ? 'Biometric enabled' : 'Biometric disabled')),
    );
    setState(() {});
  }
}
