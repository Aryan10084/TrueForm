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

  Future<void> _login() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacementNamed(context, DashboardScreen.routeName);
      }
    } catch (e) {
      setState(() { _error = e.toString(); });
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
        Navigator.pushReplacementNamed(context, DashboardScreen.routeName);
      }
    } catch (e) {
      setState(() { _error = e.toString(); });
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
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _switchTab(0),
            child: Container(
              height: 4,
              color: _tabIndex == 0 ? Theme.of(context).colorScheme.primary : Colors.grey[800],
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => _switchTab(1),
            child: Container(
              height: 4,
              color: _tabIndex == 1 ? Theme.of(context).colorScheme.primary : Colors.grey[800],
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 4,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextField(
      controller: _emailController,
      decoration: const InputDecoration(
        labelText: 'Email',
        hintText: 'Type yours email',
        prefixIcon: Icon(Icons.email_outlined, color: Colors.white54),
      ),
      keyboardType: TextInputType.emailAddress,
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: 'Type yours password',
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.white54),
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white54),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
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
        child: const Text('Forgot password ?', style: TextStyle(color: Color(0xFF00E0FF))),
      ),
    );
  }

  Widget _buildSignInButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _login,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        minimumSize: const Size.fromHeight(48),
        textStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
      ),
      child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Sign In'),
    );
  }

  Widget _buildSignUpButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _signup,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        minimumSize: const Size.fromHeight(48),
        textStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
      ),
      child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Sign up'),
    );
  }

  Widget _buildSocialButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            minimumSize: const Size(160, 48),
          ),
          icon: Image.asset('assets/google.png', width: 24, height: 24),
          label: const Text('Sign in with Google'),
          onPressed: _isLoading ? null : _signInWithGoogle,
        ),
      ],
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Don't have an account? ", style: TextStyle(color: Colors.white54)),
        GestureDetector(
          onTap: () => _switchTab(1),
          child: const Text('Sign up here', style: TextStyle(color: Color(0xFF00E0FF))),
        ),
      ],
    );
  }

  Widget _buildSignInLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Already have an account? ', style: TextStyle(color: Colors.white54)),
        GestureDetector(
          onTap: () => _switchTab(0),
          child: const Text('Sign in here', style: TextStyle(color: Color(0xFF00E0FF))),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: Colors.white24)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text('Or', style: TextStyle(color: Colors.white.withOpacity(0.5))),
        ),
        const Expanded(child: Divider(color: Colors.white24)),
      ],
    );
  }

  Widget _buildSignInForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        const Text('Sign in with Email', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Input your registered account!', style: TextStyle(color: Colors.white54)),
        const SizedBox(height: 32),
        const Text('Email'),
        const SizedBox(height: 8),
        _buildEmailField(),
        const SizedBox(height: 16),
        const Text('Password'),
        const SizedBox(height: 8),
        _buildPasswordField(),
        _buildForgotPassword(),
        const SizedBox(height: 16),
        if (_error != null) ...[
          Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 8),
        ],
        _buildSignInButton(),
        const SizedBox(height: 24),
        _buildDivider(),
        const SizedBox(height: 24),
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
        const SizedBox(height: 32),
        const Text('Sign up with Email', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Create account !', style: TextStyle(color: Colors.white54)),
        const SizedBox(height: 32),
        const Text('Email'),
        const SizedBox(height: 8),
        _buildEmailField(),
        const SizedBox(height: 16),
        const Text('Password'),
        const SizedBox(height: 8),
        _buildPasswordField(),
        const SizedBox(height: 16),
        const Text('Phone number'),
        const SizedBox(height: 8),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Phone number',
            hintText: 'Type yours phone number',
            prefixIcon: Icon(Icons.phone, color: Colors.white54),
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Checkbox(
              value: _agreedToTerms,
              onChanged: (val) {
                setState(() { _agreedToTerms = val ?? false; });
              },
            ),
            const Text('Have to agree with our '),
            GestureDetector(
              onTap: () {},
              child: const Text('Terms & conditions', style: TextStyle(color: Color(0xFF00E0FF))),
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
        const SizedBox(height: 24),
        _buildSocialButtons(),
        const SizedBox(height: 32),
        _buildSignInLink(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 24),
                _buildTabBar(),
                _tabIndex == 0 ? _buildSignInForm() : _buildSignUpForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 