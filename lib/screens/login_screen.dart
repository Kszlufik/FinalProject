import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sign_up_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _bg = Color(0xFF0D1117);
  static const _surface = Color(0xFF161B22);
  static const _accent = Color(0xFF00E5FF);
  static const _textPrimary = Color(0xFFE6EDF3);
  static const _textSecondary = Color(0xFF8B949E);
  static const _border = Color(0xFF30363D);
  static const _green = Color(0xFF4ADE80);

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    setState(() { _isLoading = true; _errorMessage = null; _successMessage = null; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email address first.');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; _successMessage = null; });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        setState(() => _successMessage = 'Password reset email sent to $email. Check your inbox!');
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark(),
      child: Scaffold(
        backgroundColor: _bg,
        body: Row(
          children: [
            // Left panel — decorative
            if (MediaQuery.of(context).size.width > 800)
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0D1117), Color(0xFF0A2A3A)],
                    ),
                  ),
                  child: Stack(
                    children: [
                      CustomPaint(painter: _GridPainter(), size: Size.infinite),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _accent.withOpacity(0.1),
                                border: Border.all(color: _accent.withOpacity(0.3), width: 2),
                                boxShadow: [BoxShadow(color: _accent.withOpacity(0.2), blurRadius: 40, spreadRadius: 5)],
                              ),
                              child: const Icon(Icons.sports_esports, color: _accent, size: 56),
                            ),
                            const SizedBox(height: 28),
                            const Text(
                              'PlayPal',
                              style: TextStyle(color: _textPrimary, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 2),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Your gaming universe',
                              style: TextStyle(color: _textSecondary, fontSize: 16, letterSpacing: 1),
                            ),
                            const SizedBox(height: 48),
                            _featurePill(Icons.star_rounded, 'Discover top rated games'),
                            const SizedBox(height: 12),
                            _featurePill(Icons.videogame_asset, 'Connect your Steam library'),
                            const SizedBox(height: 12),
                            _featurePill(Icons.people, 'Share with friends'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Right panel — form
            SizedBox(
              width: MediaQuery.of(context).size.width > 800 ? 420 : double.infinity,
              child: Container(
                color: _bg,
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Mobile logo
                        if (MediaQuery.of(context).size.width <= 800) ...[
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _accent.withOpacity(0.1),
                                    border: Border.all(color: _accent.withOpacity(0.3)),
                                  ),
                                  child: const Icon(Icons.sports_esports, color: _accent, size: 36),
                                ),
                                const SizedBox(height: 12),
                                const Text('PlayPal', style: TextStyle(color: _textPrimary, fontSize: 28, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],

                        const Text('Welcome back', style: TextStyle(color: _textPrimary, fontSize: 26, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        const Text('Sign in to continue your journey', style: TextStyle(color: _textSecondary, fontSize: 14)),
                        const SizedBox(height: 36),

                        // Email
                        _fieldLabel('Email'),
                        const SizedBox(height: 8),
                        _inputField(
                          controller: _emailController,
                          hint: 'you@example.com',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 20),

                        // Password
                        _fieldLabel('Password'),
                        const SizedBox(height: 8),
                        _inputField(
                          controller: _passwordController,
                          hint: '••••••••',
                          icon: Icons.lock_outline,
                          obscure: _obscurePassword,
                          onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                          onSubmit: login,
                        ),
                        const SizedBox(height: 10),

                        // Forgot password
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: _resetPassword,
                            child: const Text(
                              'Forgot password?',
                              style: TextStyle(
                                color: _accent,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Error message
                        if (_errorMessage != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 13))),
                              ],
                            ),
                          ),

                        // Success message
                        if (_successMessage != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _green.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _green.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline, color: _green, size: 16),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_successMessage!, style: const TextStyle(color: _green, fontSize: 13))),
                              ],
                            ),
                          ),

                        // Login button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: _isLoading
                              ? Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(color: _accent, strokeWidth: 2)))
                              : ElevatedButton(
                                  onPressed: login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _accent,
                                    foregroundColor: _bg,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 0,
                                  ),
                                  child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                ),
                        ),
                        const SizedBox(height: 24),

                        // Sign up link
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Don't have an account? ", style: TextStyle(color: _textSecondary, fontSize: 13)),
                              GestureDetector(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpScreen())),
                                child: const Text('Sign Up', style: TextStyle(color: _accent, fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _featurePill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _surface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _accent, size: 16),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: _textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(label, style: const TextStyle(color: _textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8));
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onToggleObscure,
    VoidCallback? onSubmit,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: _textPrimary, fontSize: 14),
      onSubmitted: onSubmit != null ? (_) => onSubmit() : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _textSecondary.withOpacity(0.4), fontSize: 13),
        filled: true,
        fillColor: _surface,
        prefixIcon: Icon(icon, color: _textSecondary, size: 18),
        suffixIcon: onToggleObscure != null
            ? IconButton(
                icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: _textSecondary, size: 18),
                onPressed: onToggleObscure,
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _accent, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.04)
      ..strokeWidth = 1;
    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}