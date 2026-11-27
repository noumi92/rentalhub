import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/admin_support_data_source.dart';
import '../../domain/admin_permissions.dart';
import 'admin_permission_check.dart';

/// The E3 announcement composer: English + Urdu title and body (the
/// rulebook §5.5 bilingual requirement), audience (role / city /
/// plan), channel (Push / WhatsApp / both), and an optional schedule.
/// WhatsApp delivery waits for the Meta token (plan D2) — the
/// announcement is saved as `pending_whatsapp`, never as sent.
///
/// Phase 3 (3.2): with [existing] set, the sheet edits that draft
/// or scheduled announcement instead of creating one — sent
/// announcements never reach this sheet (the detail view hides
/// Edit for them, and the data source refuses the update).
class AnnouncementFormSheet extends StatefulWidget {
  const AnnouncementFormSheet({super.key, required this.onCreated, this.existing});

  final VoidCallback onCreated;

  /// The announcement to edit, or null to create a new one.
  final AdminAnnouncement? existing;

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
  // F-m18 / AD-m12(a): cities come from
  // `platform_settings/global.live_cities` (trio = load fallback).
  List<String> _liveCities = const ['Lahore', 'Karachi', 'Islamabad'];

  @override
  void initState() {
    super.initState();
    // Phase 3 (3.2): editing pre-fills every field from the
    // existing announcement, including its schedule.
    final existing = widget.existing;
    if (existing != null) {
      _titleEn.text = existing.titleEn;
      _titleUr.text = existing.titleUr;
      _bodyEn.text = existing.bodyEn;
      _bodyUr.text = existing.bodyUr;
      _audienceRole = existing.audienceRole;
      _audienceCity = existing.audienceCity;
      _audiencePlan = existing.audiencePlan;
      _channel = existing.channel;
      _schedule = existing.scheduledAt != null;
      _scheduledAt = existing.scheduledAt;
    }
    _loadCities();
  }

  Future<void> _loadCities() async {
    try {
      final s = await sl<AdminSupportDataSource>().getPlatformSettings();
      final cities = s?.liveCities;
      if (mounted && cities != null && cities.isNotEmpty) {
        setState(() => _liveCities = cities);
      }
    } catch (_) {} // Fallback trio stays; the announcement can still be saved.
  }

  @override
  void dispose() {
    _titleEn.dispose();
    _titleUr.dispose();
    _bodyEn.dispose();
    _bodyUr.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (_titleEn.text.trim().isEmpty || _bodyEn.text.trim().isEmpty) {
      AppFeedback.showError(context, l10n.admin2_anncFormEnRequired);
      return;
    }
    if (_titleUr.text.trim().isEmpty || _bodyUr.text.trim().isEmpty) {
      AppFeedback.showError(context, l10n.admin2_anncFormUrRequired);
      return;
    }
    // AD-m12(b): "Schedule for later" ON with no date used to save
    // `scheduledAt: null` with no error — a schedule for nothing.
    if (_schedule && _scheduledAt == null) {
      AppFeedback.showError(context, AppLocalizations.of(context)!.adminAnncScheduleDateRequired);
      return;
    }
    // F-C1: super admin + operations only (managePlatform). See
    // the shop application sheet for the check's contract.
    final check = await AdminPermissionCheck.check(
        context, AdminPermission.managePlatform);
    if (!check.proceed) return;
    setState(() => _isSaving = true);
    final existing = widget.existing;
    final ds = sl<AdminSupportDataSource>();
    if (existing != null) {
      // Phase 3 (3.2): edit path — the data source refuses sent
      // announcements, so a stale sheet cannot rewrite history.
      final ok = await ds.updateAnnouncement(
        announcementId: existing.id,
        titleEn: _titleEn.text.trim(),
        titleUr: _titleUr.text.trim(),
        bodyEn: _bodyEn.text.trim(),
        bodyUr: _bodyUr.text.trim(),
        audienceRole: _audienceRole,
        audienceCity: _audienceCity,
        audiencePlan: _audiencePlan,
        channel: _channel,
        scheduledAt: _schedule ? _scheduledAt : null,
        adminRole: check.role,
      );
      if (!mounted) return;
      if (ok) {
        AppFeedback.showSuccess(
            context, AppLocalizations.of(context)!.admin2_anncUpdated);
        widget.onCreated();
        Navigator.of(context).pop();
      } else {
        AppFeedback.showError(
            context, AppLocalizations.of(context)!.admin2_serverUnreachable);
        setState(() => _isSaving = false);
      }
      return;
    }
    final id = await ds.createAnnouncement(
      titleEn: _titleEn.text.trim(),
      titleUr: _titleUr.text.trim(),
      bodyEn: _bodyEn.text.trim(),
      bodyUr: _bodyUr.text.trim(),
      audienceRole: _audienceRole,
      audienceCity: _audienceCity,
      audiencePlan: _audiencePlan,
      channel: _channel,
      scheduledAt: _schedule ? _scheduledAt : null,
      adminRole: check.role,
    );
    if (!mounted) return;
    if (id != null) {
      AppFeedback.showSuccess(
          context, AppLocalizations.of(context)!.admin2_anncFormSaved);
      widget.onCreated();
      Navigator.of(context).pop();
    } else {
      AppFeedback.showError(
          context, AppLocalizations.of(context)!.admin2_serverUnreachable);
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
            Text(
                widget.existing != null
                    ? l10n.admin2_anncEdit
                    : l10n.admin2_anncNew,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    )),
            const SizedBox(height: 16),
            _field(l10n.admin2_anncFormTitleEn, _titleEn),
            _field(l10n.admin2_anncFormTitleUr, _titleUr),
            _field(l10n.admin2_anncFormBodyEn, _bodyEn, maxLines: 3),
            _field(l10n.admin2_anncFormBodyUr, _bodyUr, maxLines: 3),
            _dropdown(l10n.admin2_anncFormAudienceRole, _audienceRole, {
              'all': l10n.admin2_anncFormEveryone,
              'owner': l10n.admin2_anncFormOwners,
              'customer': l10n.admin2_anncFormCustomers,
            }, (v) => setState(() => _audienceRole = v)),
            _dropdown(l10n.admin2_anncFormAudienceCity, _audienceCity,
                {'all': l10n.admin2_anncFormAllCities, for (final c in _liveCities) c: c},
                (v) => setState(() => _audienceCity = v)),
            _dropdown(l10n.admin2_anncFormAudiencePlan, _audiencePlan, {
              'all': l10n.admin2_anncFormAllPlans,
              'free': l10n.admin2_anncFormFree,
              'pro': l10n.admin2_anncFormPro,
              'business': l10n.admin2_anncFormBusiness,
            }, (v) => setState(() => _audiencePlan = v)),
            _dropdown(l10n.admin2_anncFormChannel, _channel, {
              'push': l10n.admin2_anncFormPush,
              'whatsapp': l10n.admin2_anncFormWhatsapp,
              'both': l10n.admin2_anncFormBoth,
            }, (v) => setState(() => _channel = v)),
            SwitchListTile(
              title: Text(l10n.admin2_anncFormSchedule),
              value: _schedule,
              onChanged: (v) => setState(() => _schedule = v),
            ),
            if (_schedule)
              OutlinedButton.icon(
                icon: const Icon(Icons.schedule_rounded, size: 18),
                // AD-m12(c): DateFormat + locale, not raw toString().
                label: Text(_scheduledAt == null
                    ? l10n.admin2_anncFormPickDate
                    : l10n.admin2_anncFormScheduled(DateFormat.yMd(Localizations.localeOf(context).languageCode).add_jm().format(_scheduledAt!))),
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
                // Phase 1 (1.5): 48dp minimum touch target
                // (rulebook §4.6).
                style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 48)),
                child: Text(_isSaving
                    ? l10n.admin2_saving
                    : widget.existing != null
                        ? l10n.admin2_anncFormUpdate
                        : l10n.admin2_anncFormSave),
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
            borderSide: BorderSide(color: Theme.of(context).dividerColor),
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
        // isExpanded: the button must fill the field width — at 2.0x
        // text scale the intrinsic-width row of the selected item +
        // arrow overflows the field (the WhatsApp channel label is
        // the longest item).
        isExpanded: true,
        dropdownColor: Theme.of(context).colorScheme.surface,
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).dividerColor),
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
