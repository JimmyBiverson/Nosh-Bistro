import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../services/auth_service.dart';
import '../../services/store_settings.dart';
import '../../widgets/google_sign_in_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  static const _card = Color(0xFF291D15);

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
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Create Firebase Auth account
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
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

      _returnToAuthGate();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        switch (e.code) {
          case 'email-already-in-use':
            _errorMessage = 'An account already exists for this email.';
            break;
          case 'weak-password':
            _errorMessage = 'Password is too weak. Use at least 6 characters.';
            break;
          default:
            _errorMessage = 'Sign up failed. ${e.message ?? e.code}';
        }
      });
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Your account was created, but its profile could not be saved. Please sign in again. (${e.code})';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUpWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await AuthService.signInWithGoogle();
      if (mounted) _returnToAuthGate();
    } on GoogleSignInException catch (error) {
      if (mounted && error.code != GoogleSignInExceptionCode.canceled) {
        setState(() {
          _errorMessage = error.description ?? 'Google sign-in failed.';
        });
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = switch (error.code) {
            'account-exists-with-different-credential' =>
              'This email uses another sign-in method. Sign in with that method first.',
            'operation-not-allowed' =>
              'Google sign-in is not enabled for this app.',
            'missing-google-id-token' =>
              'Google sign-in is not configured for this app yet.',
            _ => 'Google sign-in failed. ${error.message ?? error.code}',
          };
        });
      }
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

  void _returnToAuthGate() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(StoreSettings.instance.backgroundColor),
      appBar: AppBar(
        backgroundColor: Color(StoreSettings.instance.backgroundColor),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Brand
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    StoreBrandLogo(size: 28, color: _accentColor),
                    const SizedBox(width: 8),
                    StoreBrandName(
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

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
                        'Create Account',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      StoreBrandName(
                        prefix: 'Join ',
                        suffix: ' today',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),

                      _buildInput(
                        controller: _emailController,
                        label: 'Email Address',
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => (v == null || !v.contains('@'))
                            ? 'Enter a valid email'
                            : null,
                      ),
                      const SizedBox(height: 14),

                      _buildInput(
                        controller: _passwordController,
                        label: 'Password',
                        icon: Icons.lock_outline_rounded,
                        obscureText: _obscurePassword,
                        suffixIcon: _eyeButton(
                          _obscurePassword,
                          () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                        validator: (v) => (v == null || v.length < 6)
                            ? 'Minimum 6 characters'
                            : null,
                      ),
                      const SizedBox(height: 14),

                      _buildInput(
                        controller: _confirmPasswordController,
                        label: 'Confirm Password',
                        icon: Icons.lock_outline_rounded,
                        obscureText: _obscureConfirm,
                        suffixIcon: _eyeButton(
                          _obscureConfirm,
                          () => setState(
                            () => _obscureConfirm = !_obscureConfirm,
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Please confirm your password'
                            : null,
                      ),
                      const SizedBox(height: 20),

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

                      _buildPrimaryButton(
                        label: 'Create Account',
                        onPressed: _isLoading ? null : _signUp,
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
                        onPressed: _isLoading ? null : _signUpWithGoogle,
                        isLoading: _isLoading,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Text(
                        'Log In',
                        style: TextStyle(
                          color: _accentColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _eyeButton(bool obscure, VoidCallback onTap) {
    return IconButton(
      icon: Icon(
        obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: Colors.white38,
        size: 20,
      ),
      onPressed: onTap,
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
