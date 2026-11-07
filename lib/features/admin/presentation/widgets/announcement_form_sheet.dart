import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../data/datasources/admin_support_data_source.dart';

/// The E3 announcement composer: English + Urdu title and body (the
/// rulebook §5.5 bilingual requirement), audience (role / city /
/// plan), channel (Push / WhatsApp / both), and an optional schedule.
/// WhatsApp delivery waits for the Meta token (plan D2) — the
/// announcement is saved as `pending_whatsapp`, never as sent.
class AnnouncementFormSheet extends StatefulWidget {
  const AnnouncementFormSheet({super.key, required this.onCreated});

  final VoidCallback onCreated;

  @override
  State<AnnouncementFormSheet> createState() => _AnnouncementFormSheetState();
}

class _AnnouncementFormSheetState extends State<AnnouncementFormSheet> {
  final _titleEn = TextEditingController();
  final _titleUr = TextEditingController();
  final _bodyEn = TextEditingController();
  final _bodyUr = TextEditingController();
  String _audienceRole = 'all';
  String _audienceCity = 'all';
  String _audiencePlan = 'all';
  String _channel = 'push';
  bool _schedule = false;
  DateTime? _scheduledAt;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleEn.dispose();
    _titleUr.dispose();
    _bodyEn.dispose();
    _bodyUr.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleEn.text.trim().isEmpty || _bodyEn.text.trim().isEmpty) {
      AppFeedback.showError(
          context, 'The English title and body are required.');
      return;
    }
    if (_titleUr.text.trim().isEmpty || _bodyUr.text.trim().isEmpty) {
      AppFeedback.showError(context,
          'The Urdu title and body are required too (rulebook §5.5).');
      return;
    }
    setState(() => _isSaving = true);
    final id = await sl<AdminSupportDataSource>().createAnnouncement(
      titleEn: _titleEn.text.trim(),
      titleUr: _titleUr.text.trim(),
      bodyEn: _bodyEn.text.trim(),
      bodyUr: _bodyUr.text.trim(),
      audienceRole: _audienceRole,
      audienceCity: _audienceCity,
      audiencePlan: _audiencePlan,
      channel: _channel,
      scheduledAt: _schedule ? _scheduledAt : null,
    );
    if (!mounted) return;
    if (id != null) {
      AppFeedback.showSuccess(context, 'Announcement saved.');
      widget.onCreated();
      Navigator.of(context).pop();
    } else {
      AppFeedback.showError(context, 'Could not reach the server.');
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) => SingleChildScrollView(
        controller: controller,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('New announcement',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary)),
            const SizedBox(height: 16),
            _field('Title (English)', _titleEn),
            _field('Title (Urdu)', _titleUr),
            _field('Body (English)', _bodyEn, maxLines: 3),
            _field('Body (Urdu)', _bodyUr, maxLines: 3),
            _dropdown('Audience — role', _audienceRole, const {
              'all': 'Everyone',
              'owner': 'Owners',
              'customer': 'Customers',
            }, (v) => setState(() => _audienceRole = v)),
            _dropdown('Audience — city', _audienceCity, const {
              'all': 'All cities',
              'Lahore': 'Lahore',
              'Karachi': 'Karachi',
              'Islamabad': 'Islamabad',
            }, (v) => setState(() => _audienceCity = v)),
            _dropdown('Audience — plan', _audiencePlan, const {
              'all': 'All plans',
              'free': 'Free',
              'pro': 'Pro',
              'business': 'Business',
            }, (v) => setState(() => _audiencePlan = v)),
            _dropdown('Channel', _channel, const {
              'push': 'Push',
              'whatsapp': 'WhatsApp (waits for the Meta token, D2)',
              'both': 'Push + WhatsApp',
            }, (v) => setState(() => _channel = v)),
            SwitchListTile(
              title: const Text('Schedule for later'),
              value: _schedule,
              onChanged: (v) => setState(() => _schedule = v),
            ),
            if (_schedule)
              OutlinedButton.icon(
                icon: const Icon(Icons.schedule_rounded, size: 18),
                label: Text(_scheduledAt == null
                    ? 'Pick a date and time'
                    : 'Scheduled: $_scheduledAt'),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                  );
                  if (date == null || !context.mounted) return;
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time == null) return;
                  setState(() => _scheduledAt = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    time.hour,
                    time.minute,
                  ));
                },
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                child: Text(_isSaving ? 'Saving…' : 'Save announcement'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.borderSubtle),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _dropdown(String label, String value, Map<String, String> items,
      ValueChanged<String> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.borderSubtle),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        items: items.entries
            .map((e) =>
                DropdownMenuItem(value: e.key, child: Text(e.value)))
            .toList(),
        onChanged: (v) => onChanged(v ?? value),
      ),
    );
  }
}
