import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/theme_constants.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../providers/auth_provider.dart';

class LocalAccountScreen extends StatefulWidget {
  const LocalAccountScreen({super.key});

  @override
  State<LocalAccountScreen> createState() => _LocalAccountScreenState();
}

class _LocalAccountScreenState extends State<LocalAccountScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<AuthProvider>();
    final success = await provider.createLocalAccount(_nameController.text.trim());

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(ThemeConstants.screenPadding),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ThemeConstants.primaryColor.withOpacity(0.1),
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      size: 64,
                      color: ThemeConstants.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Local Account',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create a local profile to get started.\nNo email or internet required.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  GlassCard(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Your Name',
                            prefixIcon: Icon(Icons.person_outline),
                            hintText: 'Enter your name',
                          ),
                          validator: Validators.name,
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 24),
                        Consumer<AuthProvider>(
                          builder: (_, provider, __) => GradientButton(
                            text: 'Get Started',
                            isLoading: provider.isLoading,
                            onPressed: _createAccount,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/auth'),
                    child: Text(
                      'Sign in with email instead',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
