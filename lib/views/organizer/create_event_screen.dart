// lib/views/organizer/create_event_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../services/cloudinary_image_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/malaysia_states.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/event_viewmodel.dart';
import '../shared/widgets.dart';

class CreateEventScreen extends StatefulWidget {
  final EventModel? eventToEdit;
  const CreateEventScreen({super.key, this.eventToEdit});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _maxVolCtrl = TextEditingController(text: '20');
  final _reqCtrl = TextEditingController();
  final _benefitCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  final _picker = ImagePicker();
  final _imageService = CloudinaryImageService();

  EventCategory _category = EventCategory.community;
  String? _selectedState;
  DateTime _startDate = DateTime.now().add(const Duration(days: 7));
  DateTime _endDate = DateTime.now().add(const Duration(days: 7, hours: 4));
  final List<String> _requirements = [];
  final List<String> _benefits = [];
  bool _isUploadingImage = false;

  bool get _isEditing => widget.eventToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final e = widget.eventToEdit!;
      _titleCtrl.text = e.title;
      _descCtrl.text = e.description;
      _locationCtrl.text = e.location;
      _selectedState = e.state;
      _maxVolCtrl.text = e.maxVolunteers.toString();
      _category = e.category;
      _startDate = e.startDate;
      _endDate = e.endDate;
      _imageUrlCtrl.text = e.imageUrl ?? '';
      _requirements.addAll(e.requirements);
      _benefits.addAll(e.benefits);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _maxVolCtrl.dispose();
    _reqCtrl.dispose();
    _benefitCtrl.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(isStart ? _startDate : _endDate),
    );
    if (time == null) return;
    final dt =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _startDate = dt;
      } else {
        _endDate = dt;
      }
    });
  }

  void _addItem(List<String> list, TextEditingController ctrl) {
    if (ctrl.text.trim().isEmpty) return;
    setState(() {
      list.add(ctrl.text.trim());
      ctrl.clear();
    });
  }

  Future<void> _pickAndUploadImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file == null) return;

    setState(() => _isUploadingImage = true);
    try {
      final imageUrl = await _imageService.uploadImage(
        file: file,
        folder: 'jomimpact/events',
      );
      _imageUrlCtrl.text = imageUrl;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event image uploaded successfully.'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
    if (mounted) {
      setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final authVm = context.read<AuthViewModel>();
    final vm = context.read<EventViewModel>();
    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event end time must be after the start time.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }
    bool ok;
    if (_isEditing) {
      final updated = widget.eventToEdit!.copyWith(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        state: _selectedState,
        startDate: _startDate,
        endDate: _endDate,
        category: _category,
        maxVolunteers: int.tryParse(_maxVolCtrl.text) ?? 20,
        imageUrl: _imageUrlCtrl.text.trim().isEmpty
            ? null
            : _imageUrlCtrl.text.trim(),
        clearImageUrl: _imageUrlCtrl.text.trim().isEmpty,
        requirements: List.from(_requirements),
        benefits: List.from(_benefits),
      );
      ok = await vm.updateEvent(updated);
    } else {
      ok = await vm.createEvent(
        organizer: authVm.currentUser!,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        state: _selectedState!,
        startDate: _startDate,
        endDate: _endDate,
        category: _category,
        maxVolunteers: int.tryParse(_maxVolCtrl.text) ?? 20,
        imageUrl: _imageUrlCtrl.text.trim().isEmpty
            ? null
            : _imageUrlCtrl.text.trim(),
        requirements: List.from(_requirements),
        benefits: List.from(_benefits),
      );
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? (_isEditing
                ? 'Event updated successfully.'
                : 'Event published successfully.')
            : (vm.error ?? 'Something went wrong.')),
        backgroundColor: ok ? AppTheme.success : AppTheme.error,
      ));
      if (ok) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EventViewModel>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: Text(_isEditing ? 'Edit Event' : 'Create Event')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel('Basic Info'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                    labelText: 'Event Title *',
                    prefixIcon: Icon(Icons.title, color: AppTheme.textLight)),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                    labelText: 'Description *',
                    prefixIcon:
                        Icon(Icons.description, color: AppTheme.textLight),
                    alignLabelWithHint: true),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationCtrl,
                decoration: const InputDecoration(
                    labelText: 'Location *',
                    prefixIcon: Icon(Icons.location_on_outlined,
                        color: AppTheme.textLight)),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedState,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'State / Federal Territory *',
                  prefixIcon:
                      Icon(Icons.map_outlined, color: AppTheme.textLight),
                ),
                items: malaysiaStates
                    .map((state) =>
                        DropdownMenuItem(value: state, child: Text(state)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedState = value),
                validator: (value) => value == null ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              const _SectionLabel('Category'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: EventCategory.values.map((cat) {
                  final selected = _category == cat;
                  final color = CategoryHelper.getColor(cat);
                  return GestureDetector(
                    onTap: () => setState(() => _category = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected ? color : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: selected ? color : AppTheme.divider),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(CategoryHelper.getIcon(cat),
                            size: 13, color: selected ? Colors.white : color),
                        const SizedBox(width: 4),
                        Text(CategoryHelper.getName(cat),
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? Colors.white
                                    : AppTheme.textMedium)),
                      ]),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              const _SectionLabel('Date & Time'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: _DateTile(
                    label: 'Start',
                    value: DateFormat('d MMM, h:mm a').format(_startDate),
                    onTap: () => _pickDate(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateTile(
                    label: 'End',
                    value: DateFormat('d MMM, h:mm a').format(_endDate),
                    onTap: () => _pickDate(false),
                  ),
                ),
              ]),
              const SizedBox(height: 20),
              const _SectionLabel('Event Image'),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: EventBannerImage(
                    imageUrl: _imageUrlCtrl.text.trim().isEmpty
                        ? null
                        : _imageUrlCtrl.text.trim(),
                    category: _category,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isUploadingImage ? null : _pickAndUploadImage,
                      icon: _isUploadingImage
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload_outlined),
                      label: const Text('Upload from gallery'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (_imageUrlCtrl.text.trim().isNotEmpty)
                    OutlinedButton(
                      onPressed: () => setState(() => _imageUrlCtrl.clear()),
                      child: const Text('Remove'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imageUrlCtrl,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Image URL (optional)',
                  prefixIcon: Icon(Icons.link, color: AppTheme.textLight),
                ),
              ),
              const SizedBox(height: 20),
              const _SectionLabel('Volunteers'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _maxVolCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Maximum Volunteers *',
                  prefixIcon:
                      Icon(Icons.people_outline, color: AppTheme.textLight),
                ),
                validator: (v) {
                  if (v!.isEmpty) return 'Required';
                  if (int.tryParse(v) == null || int.parse(v) < 1) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const _SectionLabel('Requirements'),
              const SizedBox(height: 10),
              ..._requirements.asMap().entries.map((e) => _ListChip(
                    label: e.value,
                    onDelete: () =>
                        setState(() => _requirements.removeAt(e.key)),
                  )),
              if (_requirements.isNotEmpty) const SizedBox(height: 8),
              Row(children: [
                Expanded(
                    child: TextField(
                  controller: _reqCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Add requirement...',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                )),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _addItem(_requirements, _reqCtrl),
                  icon: const Icon(Icons.add_circle, color: AppTheme.primary),
                ),
              ]),
              const SizedBox(height: 20),
              const _SectionLabel('Benefits for Volunteers'),
              const SizedBox(height: 10),
              ..._benefits.asMap().entries.map((e) => _ListChip(
                    label: e.value,
                    color: AppTheme.secondary,
                    onDelete: () => setState(() => _benefits.removeAt(e.key)),
                  )),
              if (_benefits.isNotEmpty) const SizedBox(height: 8),
              Row(children: [
                Expanded(
                    child: TextField(
                  controller: _benefitCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Add benefit...',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                )),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _addItem(_benefits, _benefitCtrl),
                  icon: const Icon(Icons.add_circle, color: AppTheme.secondary),
                ),
              ]),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: vm.isLoading ? null : _submit,
                icon: vm.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Icon(_isEditing ? Icons.save : Icons.publish),
                label: Text(_isEditing ? 'Save Changes' : 'Publish Event'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textDark));
}

class _DateTile extends StatelessWidget {
  final String label, value;
  final VoidCallback onTap;
  const _DateTile(
      {required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.divider, width: 1.5),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textLight,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.calendar_today,
                  size: 14, color: AppTheme.primary),
              const SizedBox(width: 6),
              Expanded(
                  child: Text(value,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark))),
            ]),
          ]),
        ),
      );
}

class _ListChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onDelete;
  const _ListChip(
      {required this.label,
      this.color = AppTheme.primary,
      required this.onDelete});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(children: [
            Icon(Icons.drag_handle, size: 14, color: color.withOpacity(0.5)),
            const SizedBox(width: 8),
            Expanded(
                child:
                    Text(label, style: TextStyle(fontSize: 13, color: color))),
            GestureDetector(
                onTap: onDelete,
                child: Icon(Icons.close, size: 16, color: color)),
          ]),
        ),
      );
}

// Helper used in create_event_screen but defined in app_theme, re-export here for clarity
// class CategoryHelper {
//   static String getName(EventCategory cat) {
//     const map = {
//       EventCategory.environment: 'Environment',
//       EventCategory.education: 'Education',
//       EventCategory.health: 'Health',
//       EventCategory.community: 'Community',
//       EventCategory.animals: 'Animals',
//       EventCategory.elderly: 'Elderly',
//       EventCategory.children: 'Children',
//       EventCategory.disaster: 'Disaster Relief',
//     };
//     return map[cat] ?? cat.name;
//   }

//   static Color getColor(EventCategory cat) {
//     const map = {
//       EventCategory.environment: Color(0xFF2E7D32),
//       EventCategory.education: Color(0xFF1565C0),
//       EventCategory.health: Color(0xFFC62828),
//       EventCategory.community: Color(0xFF6A1B9A),
//       EventCategory.animals: Color(0xFFE65100),
//       EventCategory.elderly: Color(0xFF00695C),
//       EventCategory.children: Color(0xFFAD1457),
//       EventCategory.disaster: Color(0xFF4E342E),
//     };
//     return map[cat] ?? Colors.grey;
//   }

//   static IconData getIcon(EventCategory cat) {
//     const map = {
//       EventCategory.environment: Icons.eco,
//       EventCategory.education: Icons.school,
//       EventCategory.health: Icons.favorite,
//       EventCategory.community: Icons.people,
//       EventCategory.animals: Icons.pets,
//       EventCategory.elderly: Icons.elderly,
//       EventCategory.children: Icons.child_care,
//       EventCategory.disaster: Icons.emergency,
//     };
//     return map[cat] ?? Icons.category;
//   }
// }
