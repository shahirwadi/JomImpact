import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utils/app_theme.dart';
import '../../utils/malaysia_states.dart';
import '../../viewmodels/auth_viewmodel.dart';

class LocationSetupScreen extends StatefulWidget {
  const LocationSetupScreen({super.key});

  @override
  State<LocationSetupScreen> createState() => _LocationSetupScreenState();
}

class _LocationSetupScreenState extends State<LocationSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  String? _state;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthViewModel>().currentUser!;
    _locationController.text = user.location ?? '';
    _state = isMalaysiaState(user.state) ? user.state : null;
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthViewModel>();
    await auth.updateProfile(auth.currentUser!.copyWith(
      location: _locationController.text.trim(),
      state: _state,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Complete Your Location'),
        actions: [
          TextButton(
            onPressed: auth.isLoading ? null : auth.logout,
            child:
                const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 44, color: AppTheme.primary),
                const SizedBox(height: 14),
                const Text('Where are you based?',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark)),
                const SizedBox(height: 6),
                const Text(
                  'This helps JomImpact show relevant volunteer opportunities and understand community reach.',
                  style: TextStyle(
                      fontSize: 13, color: AppTheme.textMedium, height: 1.5),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'City / Area',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter your city or area'
                      : null,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _state,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'State / Federal Territory',
                    prefixIcon: Icon(Icons.map_outlined),
                  ),
                  items: malaysiaStates
                      .map((state) =>
                          DropdownMenuItem(value: state, child: Text(state)))
                      .toList(),
                  onChanged: (value) => setState(() => _state = value),
                  validator: (value) =>
                      value == null ? 'Select your state' : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: auth.isLoading ? null : _save,
                  child: auth.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Save and Continue'),
                ),
                if (auth.error != null) ...[
                  const SizedBox(height: 12),
                  Text(auth.error!,
                      style:
                          const TextStyle(fontSize: 12, color: AppTheme.error)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
