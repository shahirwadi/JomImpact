// lib/views/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../utils/app_theme.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController(text: 'organizer@demo.com');
  final _passwordCtrl = TextEditingController(text: 'demo123');
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final vm = context.read<AuthViewModel>();
    final ok = await vm.login(_emailCtrl.text.trim(), _passwordCtrl.text);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(vm.error ?? 'Login failed'),
          backgroundColor: AppTheme.error));
    }
  }

  void _quickLogin(String email) {
    _emailCtrl.text = email;
    _passwordCtrl.text = 'demo123';
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: AppTheme.primaryLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),
                // Logo area
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryDark.withOpacity(0.16),
                              blurRadius: 28,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.volunteer_activism,
                            color: AppTheme.primary, size: 44),
                      ),
                      const SizedBox(height: 14),
                      const Text('JomImpact',
                          style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                      const SizedBox(height: 4),
                      const Text('Connecting volunteers with meaningful events',
                          style: TextStyle(fontSize: 13, color: Colors.white),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
                const Text('Welcome back',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
                const SizedBox(height: 4),
                const Text('Sign in to your account',
                    style: TextStyle(fontSize: 14, color: Colors.white)),
                const SizedBox(height: 24),

                // Quick login buttons
                // Container(
                //   padding: const EdgeInsets.all(14),
                //   decoration: BoxDecoration(
                //     color: AppTheme.primary.withOpacity(0.05),
                //     borderRadius: BorderRadius.circular(12),
                //     border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                //   ),
                //   child: Column(
                //     crossAxisAlignment: CrossAxisAlignment.start,
                //     children: [
                //       const Text('Quick Demo Login', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                //       const SizedBox(height: 8),
                //       Row(children: [
                //         Expanded(
                //           child: OutlinedButton.icon(
                //             onPressed: () => _quickLogin('organizer@demo.com'),
                //             icon: const Icon(Icons.business, size: 16),
                //             label: const Text('Organizer', style: TextStyle(fontSize: 12)),
                //             style: OutlinedButton.styleFrom(
                //               minimumSize: const Size(0, 36),
                //               padding: const EdgeInsets.symmetric(horizontal: 8),
                //             ),
                //           ),
                //         ),
                //         const SizedBox(width: 8),
                //         Expanded(
                //           child: OutlinedButton.icon(
                //             onPressed: () => _quickLogin('volunteer@demo.com'),
                //             icon: const Icon(Icons.person, size: 16),
                //             label: const Text('Volunteer', style: TextStyle(fontSize: 12)),
                //             style: OutlinedButton.styleFrom(
                //               minimumSize: const Size(0, 36),
                //               padding: const EdgeInsets.symmetric(horizontal: 8),
                //             ),
                //           ),
                //         ),
                //       ]),
                //       const SizedBox(height: 8),
                //       OutlinedButton.icon(
                //         onPressed: () => _quickLogin('admin@demo.com'),
                //         icon: const Icon(Icons.admin_panel_settings_outlined,
                //             size: 16),
                //         label: const Text('Admin Demo',
                //             style: TextStyle(fontSize: 12)),
                //         style: OutlinedButton.styleFrom(
                //           minimumSize: const Size(double.infinity, 36),
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon:
                        Icon(Icons.email_outlined, color: AppTheme.textLight),
                  ),
                  validator: (v) => v!.isEmpty ? 'Enter email' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline,
                        color: AppTheme.textLight),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                          color: AppTheme.textLight),
                    ),
                  ),
                  validator: (v) => v!.isEmpty ? 'Enter password' : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: vm.isLoading ? null : _login,
                  child: vm.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Sign In'),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? ",
                          style: TextStyle(color: Colors.white)),
                      GestureDetector(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RegisterScreen())),
                        child: const Text('Register',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
