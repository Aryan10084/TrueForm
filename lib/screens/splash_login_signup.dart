import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dashboard.dart';

class SplashLoginSignupScreen extends StatefulWidget {
  static const String routeName = '/';
  const SplashLoginSignupScreen({Key? key}) : super(key: key);

  @override
  State<SplashLoginSignupScreen> createState() => _SplashLoginSignupScreenState();
}

class _SplashLoginSignupScreenState extends State<SplashLoginSignupScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _obscurePassword = true;
  int _tabIndex = 0; // 0 = Sign In, 1 = Sign Up
  bool _agreedToTerms = false;

  void _switchTab(int index) {
    setState(() {
      _tabIndex = index;
      _error = null;
    });
  }

  void _showSnackBar(String message, {bool success = false}) {
    final snackBar = SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.white)),
      backgroundColor: success ? Colors.green : Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      duration: const Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _login() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        _showSnackBar('Login successful!', success: true);
        await Future.delayed(const Duration(seconds: 2));
        Navigator.pushReplacementNamed(context, DashboardScreen.routeName);
      }
    } catch (e) {
      setState(() { _error = e.toString(); });
      _showSnackBar('Login failed: ${e.toString()}', success: false);
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _signup() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        _showSnackBar('Account created successfully!', success: true);
        await Future.delayed(const Duration(seconds: 2));
        Navigator.pushReplacementNamed(context, DashboardScreen.routeName);
      }
    } catch (e) {
      setState(() { _error = e.toString(); });
      _showSnackBar('Account creation failed: ${e.toString()}', success: false);
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() { _isLoading = false; });
        return; // User cancelled
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (mounted) {
        Navigator.pushReplacementNamed(context, DashboardScreen.routeName);
      }
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Widget _buildTabBar() {
    // Redesigned tab bar as per Figma
    return Container(
      margin: const EdgeInsets.only(top: 32),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _switchTab(0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _tabIndex == 0 ? const Color(0xFF6C63FF) : Colors.transparent,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Center(
                  child: Text(
                    'Login',
                    style: TextStyle(
                      color: _tabIndex == 0 ? Colors.white : const Color(0xFF6C63FF),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _switchTab(1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _tabIndex == 1 ? const Color(0xFF6C63FF) : Colors.transparent,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Center(
                  child: Text(
                    'Register',
                    style: TextStyle(
                      color: _tabIndex == 1 ? Colors.white : const Color(0xFF6C63FF),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return TextField(
      controller: _emailController,
      decoration: InputDecoration(
        labelText: 'Email',
        hintText: 'Enter your email',
        prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF6C63FF)),
        filled: true,
        fillColor: const Color(0xFFF5F6FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      keyboardType: TextInputType.emailAddress,
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: 'Enter your password',
        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF6C63FF)),
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF6C63FF)),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        filled: true,
        fillColor: const Color(0xFFF5F6FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      obscureText: _obscurePassword,
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {},
        child: const Text('Forgot password?', style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildSignInButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6C63FF),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          minimumSize: const Size.fromHeight(56),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Login'),
      ),
    );
  }

  Widget _buildSignUpButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _signup,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6C63FF),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          minimumSize: const Size.fromHeight(56),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Register'),
      ),
    );
  }

  Widget _buildSocialButtons() {
    return Column(
      children: [
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF232531),
              side: const BorderSide(color: Color(0xFF6C63FF), width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              minimumSize: const Size.fromHeight(56),
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            icon: Image.asset('assets/google.png', width: 24, height: 24),
            label: const Text('Continue with Google'),
            onPressed: _isLoading ? null : _signInWithGoogle,
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Don't have an account? ", style: TextStyle(color: Color(0xFF232531))),
        GestureDetector(
          onTap: () => _switchTab(1),
          child: const Text('Register', style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildSignInLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Already have an account? ', style: TextStyle(color: Color(0xFF232531))),
        GestureDetector(
          onTap: () => _switchTab(0),
          child: const Text('Login', style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFF6C63FF), thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text('or', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600)),
        ),
        const Expanded(child: Divider(color: Color(0xFF6C63FF), thickness: 1)),
      ],
    );
  }

  Widget _buildSignInForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 48),
        const Text('Welcome Back!', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF232531))),
        const SizedBox(height: 8),
        const Text('Login to your account', style: TextStyle(color: Color(0xFF6C63FF), fontSize: 16)),
        const SizedBox(height: 32),
        _buildInputField(icon: Icons.email_outlined, hint: 'Email', controller: _emailController, keyboardType: TextInputType.emailAddress),
        _buildInputField(
          icon: Icons.lock_outline,
          hint: 'Password',
          obscure: _obscurePassword,
          controller: _passwordController,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: const Color(0xFFBDBDBD),
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 8),
        if (_error != null) ...[
          Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 8),
        ],
        _buildSignInButton(),
        const SizedBox(height: 24),
        _buildDivider(),
        _buildSocialButtons(),
        const SizedBox(height: 32),
        _buildSignUpLink(),
      ],
    );
  }

  Widget _buildSignUpForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 48),
        const Text('Create Account', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF232531))),
        const SizedBox(height: 8),
        const Text('Sign up to get started', style: TextStyle(color: Color(0xFF6C63FF), fontSize: 16)),
        const SizedBox(height: 32),
        _buildInputField(icon: Icons.email_outlined, hint: 'Email', controller: _emailController, keyboardType: TextInputType.emailAddress),
        _buildInputField(
          icon: Icons.lock_outline,
          hint: 'Password',
          obscure: _obscurePassword,
          controller: _passwordController,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: const Color(0xFFBDBDBD),
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Checkbox(
              value: _agreedToTerms,
              onChanged: (val) {
                setState(() { _agreedToTerms = val ?? false; });
              },
              activeColor: const Color(0xFF6C63FF),
            ),
            const Text('I agree to the '),
            GestureDetector(
              onTap: () {},
              child: const Text('Terms & Conditions', style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        if (_error != null) ...[
          Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 8),
        ],
        _buildSignUpButton(),
        const SizedBox(height: 24),
        _buildDivider(),
        _buildSocialButtons(),
        const SizedBox(height: 32),
        _buildSignInLink(),
      ],
    );
  }

  Widget _buildInputField({required IconData icon, required String hint, bool obscure = false, TextEditingController? controller, Widget? suffixIcon, TextInputType? keyboardType}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Color(0xFFE0E0E0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: Color(0xFFBDBDBD)),
          hintText: hint,
          hintStyle: TextStyle(color: Color(0xFFBDBDBD)),
          suffixIcon: suffixIcon,
          contentPadding: EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Full background image that covers the entire screen
          Positioned.fill(
            child: Image.asset(
              'assets/bg 1.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 40),
                      // Logo
                      Center(
                        child: Image.asset(
                          'assets/Group 1.png',
                          height: 70,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Heading
                      Text(
                        _tabIndex == 0 ? 'Sign In' : 'Sign Up',
                        style: const TextStyle(
                          color: Color(0xFF2196F3),
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _tabIndex == 0
                            ? 'Enter valid username and password to continue'
                            : 'User proper information to continue',
                        style: const TextStyle(
                          color: Color(0xFF8D8D8D),
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      // Form fields
                      if (_tabIndex == 0) ...[
                        // Email
                        _buildInputField(icon: Icons.email_outlined, hint: 'Email', controller: _emailController, keyboardType: TextInputType.emailAddress),
                        // Password
                        _buildInputField(icon: Icons.lock_outline, hint: 'Password', obscure: _obscurePassword, controller: _passwordController, suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: const Color(0xFFBDBDBD),
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        )),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2196F3),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              minimumSize: const Size.fromHeight(52),
                              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('Login'),
                          ),
                        ),
                      ] else ...[
                        // Email
                        _buildInputField(icon: Icons.email_outlined, hint: 'Email', controller: _emailController, keyboardType: TextInputType.emailAddress),
                        // Password
                        _buildInputField(icon: Icons.lock_outline, hint: 'Password', obscure: _obscurePassword, controller: _passwordController, suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: const Color(0xFFBDBDBD),
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        )),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _signup,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2196F3),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              minimumSize: const Size.fromHeight(52),
                              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('Create Account'),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Expanded(child: Divider(color: Color(0xFF6C63FF), thickness: 1)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text('or', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600)),
                          ),
                          const Expanded(child: Divider(color: Color(0xFF6C63FF), thickness: 1)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Color(0xFF232531),
                            side: BorderSide(color: Color(0xFF6C63FF), width: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            minimumSize: Size.fromHeight(56),
                            textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          icon: Image.asset('assets/google.png', width: 24, height: 24),
                          label: Text('Continue with Google'),
                          onPressed: _isLoading ? null : _signInWithGoogle,
                        ),
                      ),
                      const SizedBox(height: 32),
                      if (_tabIndex == 0)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Don't have an Account? ",
                              style: TextStyle(color: Color(0xFF8D8D8D), fontSize: 15),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _tabIndex = 1),
                              child: const Text(
                                'Sign Up',
                                style: TextStyle(
                                  color: Color(0xFF2196F3),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Already have an Account? ',
                              style: TextStyle(color: Color(0xFF8D8D8D), fontSize: 15),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _tabIndex = 0),
                              child: const Text(
                                'Sign In',
                                style: TextStyle(
                                  color: Color(0xFF2196F3),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 