// lib/views/auth/register_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../utils/app_theme.dart';
import '../../utils/malaysia_states.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _orgCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  String? _selectedState;
  UserRole _role = UserRole.volunteer;
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _orgCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final vm = context.read<AuthViewModel>();
    final ok = await vm.register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      role: _role,
      location: _locationCtrl.text.trim(),
      state: _selectedState!,
      organization: _role == UserRole.organizer ? _orgCtrl.text.trim() : null,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(vm.error ?? 'Registration failed'),
          backgroundColor: AppTheme.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Join JomImpact 🌱',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark)),
              const SizedBox(height: 4),
              const Text('Create your account to get started',
                  style: TextStyle(fontSize: 14, color: AppTheme.textMedium)),
              const SizedBox(height: 24),

              // Role selector
              const Text('I am a...',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark)),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                    child: _RoleTile(
                  role: UserRole.volunteer,
                  selected: _role == UserRole.volunteer,
                  icon: Icons.person_outline,
                  label: 'Volunteer',
                  desc: 'Browse & join events',
                  onTap: () => setState(() => _role = UserRole.volunteer),
                )),
                const SizedBox(width: 12),
                Expanded(
                    child: _RoleTile(
                  role: UserRole.organizer,
                  selected: _role == UserRole.organizer,
                  icon: Icons.business_outlined,
                  label: 'Organizer',
                  desc: 'Create & manage events',
                  onTap: () => setState(() => _role = UserRole.organizer),
                )),
              ]),
              const SizedBox(height: 20),
              if (_role == UserRole.organizer)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.2)),
                  ),
                  child: const Text(
                    'Organizer accounts need admin approval before they can publish events.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMedium,
                    ),
                  ),
                ),
              if (_role == UserRole.organizer) const SizedBox(height: 20),

              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: _role == UserRole.organizer
                      ? 'Organization / Full Name'
                      : 'Full Name',
                  prefixIcon: const Icon(Icons.person_outline,
                      color: AppTheme.textLight),
                ),
                validator: (v) => v!.isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 14),

              if (_role == UserRole.organizer) ...[
                TextFormField(
                  controller: _orgCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Organization Name',
                    prefixIcon: Icon(Icons.business, color: AppTheme.textLight),
                  ),
                ),
                const SizedBox(height: 14),
              ],

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
                controller: _locationCtrl,
                decoration: const InputDecoration(
                  labelText: 'City / Area',
                  prefixIcon: Icon(Icons.location_on_outlined,
                      color: AppTheme.textLight),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Enter your city or area'
                    : null,
              ),
              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                value: _selectedState,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'State / Federal Territory',
                  prefixIcon:
                      Icon(Icons.map_outlined, color: AppTheme.textLight),
                ),
                items: malaysiaStates
                    .map((state) =>
                        DropdownMenuItem(value: state, child: Text(state)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedState = value),
                validator: (value) =>
                    value == null ? 'Select your state' : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _passwordCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon:
                      const Icon(Icons.lock_outline, color: AppTheme.textLight),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        color: AppTheme.textLight),
                  ),
                ),
                validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
              ),
              const SizedBox(height: 28),

              ElevatedButton(
                onPressed: vm.isLoading ? null : _register,
                child: vm.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Create Account'),
              ),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text.rich(TextSpan(children: [
                    TextSpan(
                        text: 'Already have an account? ',
                        style: TextStyle(color: AppTheme.textMedium)),
                    TextSpan(
                        text: 'Sign In',
                        style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w700)),
                  ])),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  final UserRole role;
  final bool selected;
  final IconData icon;
  final String label;
  final String desc;
  final VoidCallback onTap;

  const _RoleTile({
    required this.role,
    required this.selected,
    required this.icon,
    required this.label,
    required this.desc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon,
                color: selected ? AppTheme.primary : AppTheme.textLight,
                size: 26),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: selected ? AppTheme.primary : AppTheme.textDark)),
            Text(desc,
                style:
                    const TextStyle(fontSize: 11, color: AppTheme.textMedium)),
          ],
        ),
      ),
    );
  }
}
