import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Sign up screen — same split layout as login, collects username, email and password
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // App colour scheme
  static const _bg = Color(0xFF0D1117);
  static const _surface = Color(0xFF161B22);
  static const _accent = Color(0xFF00E5FF);
  static const _textPrimary = Color(0xFFE6EDF3);
  static const _textSecondary = Color(0xFF8B949E);
  static const _border = Color(0xFF30363D);

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> signUp() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();

    // Basic validation before hitting Firebase
    if (username.isEmpty) {
      setState(() => _errorMessage = 'Please choose a username.');
      return;
    }
    if (username.length < 3) {
      setState(() => _errorMessage = 'Username must be at least 3 characters.');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      // Create the Firebase Auth account first
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: _passwordController.text,
      );

      final uid = cred.user!.uid;

      // Small delay needed — Firebase auth token takes a moment to propagate
      // before Firestore will accept writes from this new account
      await Future.delayed(const Duration(milliseconds: 2000));

      // Check the username is not already taken
      final existing = await FirebaseFirestore.instance
          .collection('usernames')
          .doc(username.toLowerCase())
          .get();

      if (existing.exists) {
        // Username taken — delete the auth account we just created and bail out
        await cred.user!.delete();
        setState(() { _errorMessage = 'That username is already taken.'; _isLoading = false; });
        return;
      }

      // Write the user profile to Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'username': username,
        'usernameLower': username.toLowerCase(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Reserve the username in the lookup collection
      await FirebaseFirestore.instance
          .collection('usernames')
          .doc(username.toLowerCase())
          .set({'uid': uid});

      // Pop back to login — AuthGate will handle the rest
      if (mounted) Navigator.pop(context);

    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 800;

    return Theme(
      data: ThemeData.dark(),
      child: Scaffold(
        backgroundColor: _bg,
        body: Row(
          children: [
            // Decorative left panel — hidden on mobile
            if (isWide)
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [Color(0xFF0A2A3A), Color(0xFF0D1117)],
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
                            const Text('Join PlayPal', style: TextStyle(color: _textPrimary, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2)),
                            const SizedBox(height: 10),
                            const Text('Your gaming journey starts here', style: TextStyle(color: _textSecondary, fontSize: 15)),
                            const SizedBox(height: 48),
                            _infoCard(Icons.collections_bookmark_outlined, 'Track your library', 'Log what you\'re playing, completed or dropped'),
                            const SizedBox(height: 12),
                            _infoCard(Icons.rate_review_outlined, 'Write reviews', 'Keep personal notes on every game'),
                            const SizedBox(height: 12),
                            _infoCard(Icons.people_outline, 'Connect with friends', 'See what your friends are playing'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Sign up form — fixed 420px on desktop, full width on mobile
            SizedBox(
              width: isWide ? 420 : screenWidth,
              child: Container(
                color: _bg,
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Show logo above form on mobile
                        if (!isWide) ...[
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

                        const Text('Create account', style: TextStyle(color: _textPrimary, fontSize: 26, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        const Text('Choose your gamer identity', style: TextStyle(color: _textSecondary, fontSize: 14)),
                        const SizedBox(height: 32),

                        _fieldLabel('Username'),
                        const SizedBox(height: 8),
                        _inputField(
                          controller: _usernameController,
                          hint: 'YourGamerTag',
                          icon: Icons.alternate_email,
                        ),
                        const SizedBox(height: 6),
                        const Text('This is how friends will find you', style: TextStyle(color: _textSecondary, fontSize: 11)),
                        const SizedBox(height: 18),

                        _fieldLabel('Email'),
                        const SizedBox(height: 8),
                        _inputField(
                          controller: _emailController,
                          hint: 'you@example.com',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 18),

                        _fieldLabel('Password'),
                        const SizedBox(height: 8),
                        _inputField(
                          controller: _passwordController,
                          hint: '••••••••',
                          icon: Icons.lock_outline,
                          obscure: _obscurePassword,
                          onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                          onSubmit: signUp,
                        ),
                        const SizedBox(height: 24),

                        // Error message shown on signup failure
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

                        // Create account button — shows spinner while loading
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: _isLoading
                              ? Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(color: _accent, strokeWidth: 2)))
                              : ElevatedButton(
                                  onPressed: signUp,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _accent,
                                    foregroundColor: _bg,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 0,
                                  ),
                                  child: const Text('Create Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                ),
                        ),
                        const SizedBox(height: 24),

                        // Link back to login
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Already have an account? ', style: TextStyle(color: _textSecondary, fontSize: 13)),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: const Text('Sign In', style: TextStyle(color: _accent, fontWeight: FontWeight.bold, fontSize: 13)),
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

  // Feature highlight card shown on the left panel
  Widget _infoCard(IconData icon, String title, String subtitle) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: _accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: _textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(color: _textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Small label above each input field
  Widget _fieldLabel(String label) {
    return Text(label, style: const TextStyle(color: _textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8));
  }

  // Reusable styled text field
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

// Draws the subtle cyan grid pattern on the left decorative panel
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