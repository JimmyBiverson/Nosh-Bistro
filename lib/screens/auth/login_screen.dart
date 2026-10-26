import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'signup_screen.dart';
import '../../services/auth_service.dart';
import '../../services/store_settings.dart';
import '../../widgets/google_sign_in_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  static const _card = Color(0xFF291D15);
  static const _amber = Color(0xFFFFD54F);

  Color get _accentColor => Color(StoreSettings.instance.primaryColor);

  @override
  void initState() {
    super.initState();
    StoreSettings.instance.addListener(_refreshBranding);
  }

  void _refreshBranding() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    StoreSettings.instance.removeListener(_refreshBranding);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'missing-user',
          message: 'Firebase did not return a signed-in user.',
        );
      }
      await AuthService.resolveRole(user);
      if (!mounted) return;
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _errorMessage = _mapError(e.code));
    } on FirebaseException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Could not load your account details. Check your connection and try again. (${e.code})';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await AuthService.signInWithGoogle();
    } on GoogleSignInException catch (error) {
      if (mounted && error.code != GoogleSignInExceptionCode.canceled) {
        setState(() {
          _errorMessage = error.description ?? 'Google sign-in failed.';
        });
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _errorMessage = _mapError(error.code));
    } on FirebaseException catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Could not load your account details. Check your connection and try again. (${error.code})';
        });
      }
    } on UnsupportedError catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    final emailController = TextEditingController(
      text: _emailController.text.trim(),
    );
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset password'),
        content: TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email address'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(emailController.text.trim()),
            child: const Text('Send link'),
          ),
        ],
      ),
    );
    emailController.dispose();
    if (email == null || email.isEmpty || !mounted) return;

    try {
      await AuthService.sendPasswordReset(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent.')),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_mapResetError(error.code))));
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not send the reset email. (${error.code})'),
        ),
      );
    }
  }

  String _mapResetError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'user-not-found':
        return 'No account found for this email.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Could not send the reset email. Please try again.';
    }
  }

  String _mapError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found for this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'account-exists-with-different-credential':
        return 'This email uses another sign-in method. Sign in with that method first.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled for this app.';
      case 'missing-google-id-token':
        return 'Google sign-in is not configured for this app yet.';
      default:
        return 'Login failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(StoreSettings.instance.backgroundColor),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Brand header
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    StoreBrandLogo(size: 32, color: _accentColor),
                    const SizedBox(width: 8),
                    StoreBrandName(
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),

                // Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _accentColor.withValues(alpha: 0.15),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _accentColor.withValues(alpha: 0.08),
                        blurRadius: 32,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Welcome Back',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sign in to continue',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Email
                      _buildInput(
                        controller: _emailController,
                        label: 'Email Address',
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => (v == null || !v.contains('@'))
                            ? 'Enter a valid email'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Password
                      _buildInput(
                        controller: _passwordController,
                        label: 'Password',
                        icon: Icons.lock_outline_rounded,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.white38,
                            size: 20,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                        validator: (v) => (v == null || v.length < 6)
                            ? 'Password must be at least 6 characters'
                            : null,
                      ),

                      // Forgot password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _isLoading ? null : _sendPasswordReset,
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: _amber,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      // Error
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Login button
                      _buildPrimaryButton(
                        label: 'Login',
                        onPressed: _isLoading ? null : _login,
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: 14),
                      const Row(
                        children: [
                          Expanded(child: Divider(color: Colors.white24)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.white24)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      GoogleSignInButton(
                        onPressed: _isLoading ? null : _signInWithGoogle,
                        isLoading: _isLoading,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Sign up link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SignupScreen()),
                      ),
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          color: _accentColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF1F140D),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(99),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(99),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(99),
          borderSide: BorderSide(color: _accentColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(99),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(99),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(99),
          ),
          elevation: 0,
          shadowColor: _accentColor.withValues(alpha: 0.4),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
