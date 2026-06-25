import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/theme_constants.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<AuthProvider>();
    final success = await provider.loginWithEmail(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login failed. Please try again.')),
      );
    }
  }

  Future<void> _loginWithGoogle() async {
    final provider = context.read<AuthProvider>();
    bool success = await provider.loginWithGoogle();

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacementNamed(context, '/home');
      return;
    }

    // Check if there's an existing local user
    final hasExisting = await provider.restoreSession();
    if (hasExisting && mounted) {
      final action = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _AccountChoiceDialog(name: provider.user!.name),
      );
      if (action == 'continue' && mounted) {
        Navigator.pushReplacementNamed(context, '/home');
        return;
      }
      if (action == 'new' && mounted) {
        await provider.clearSession();
      } else {
        return;
      }
    }

    // Google sign-in failed — offer offline mode instead
    if (!mounted) return;
    final offline = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Google Sign-In Failed'),
        content: const Text(
          'Could not sign in with Google.\n\n'
          'To use Google sign-in, add your SHA-1 fingerprint to the Firebase Console '
          'and enable Google as a sign-in provider.\n\n'
          'Would you like to continue in offline mode instead?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Continue Offline')),
        ],
      ),
    );
    if (offline != true || !mounted) return;

    final name = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _GoogleNameDialog(),
    );

    if (name == null || !mounted) return;

    success = await provider.createLocalAccount(name);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Running in offline mode — Google sign-in not configured')),
      );
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
                  const SizedBox(height: 40),
                  Icon(
                    Icons.favorite,
                    size: 64,
                    color: ThemeConstants.primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome Back',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to continue with your partner',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 40),
                  GlassCard(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: Validators.email,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          obscureText: _obscurePassword,
                          validator: Validators.password,
                        ),
                        const SizedBox(height: 24),
                        Consumer<AuthProvider>(
                          builder: (_, provider, __) => GradientButton(
                            text: 'Sign In',
                            isLoading: provider.isLoading,
                            onPressed: _loginWithEmail,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: _loginWithGoogle,
                    icon: const Icon(Icons.g_mobiledata, size: 28),
                    label: const Text('Continue with Google'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(ThemeConstants.borderRadius),
                      ),
                      side: BorderSide(
                        color: isDark ? Colors.white24 : Colors.black12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    child: const Text(
                      "Don't have an account? Sign Up",
                      style: TextStyle(color: ThemeConstants.primaryColor),
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

class _GoogleNameDialog extends StatefulWidget {
  const _GoogleNameDialog();

  @override
  State<_GoogleNameDialog> createState() => _GoogleNameDialogState();
}

class _GoogleNameDialogState extends State<_GoogleNameDialog> {
  final _controller = TextEditingController(text: 'Partner');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Welcome!'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Enter your name to get started:'),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Your Name',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}

class _AccountChoiceDialog extends StatelessWidget {
  final String name;
  const _AccountChoiceDialog({required this.name});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Account Found'),
      content: Text('Welcome back, $name!\n\nWould you like to continue with this account or start a new one?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, 'continue'),
          child: const Text('Continue'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, 'new'),
          child: const Text('New Account'),
        ),
      ],
    );
  }
}
