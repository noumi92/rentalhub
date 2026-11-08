import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import 'widgets/auth_stepper_bar.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/pakistan_phone_field.dart';
import 'widgets/profile_avatar_picker.dart';
import '../../../../l10n/app_localizations.dart';

class OnboardingProfileView extends StatefulWidget {
  final VoidCallback? onProfileCompleted;

  const OnboardingProfileView({super.key, this.onProfileCompleted});

  @override
  State<OnboardingProfileView> createState() => _OnboardingProfileViewState();
}

class _OnboardingProfileViewState extends State<OnboardingProfileView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Ahmed Khan');
  final _phoneController = TextEditingController(text: '300 4129811');

  File? _profileImageFile;
  String? _phoneErrorMessage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (sl.isRegistered<AuthRemoteDataSource>()) {
      final auth = sl<AuthRemoteDataSource>();
      if (auth.fullName.trim().isNotEmpty) {
        _nameController.text = auth.fullName.trim();
      }
      if (auth.phoneNumber.trim().isNotEmpty) {
        _phoneController.text = auth.phoneNumber.replaceAll('+92 ', '').replaceAll('+92', '').replaceAll(RegExp(r'^0+'), '').trim();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _phoneErrorMessage = null);
    final isNameValid = _formKey.currentState?.validate() ?? false;

    // Validate Pakistani mobile number: 10 digits starting with 3
    final rawPhone = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    bool isPhoneValid = true;

    if (rawPhone.isEmpty) {
      setState(() => _phoneErrorMessage = l10n.onboardingPhoneRequired);
      isPhoneValid = false;
    } else if (rawPhone.length != 10 || !rawPhone.startsWith('3')) {
      setState(() {
        _phoneErrorMessage = l10n.onboardingValidPhone;
      });
      isPhoneValid = false;
    }

    return isNameValid && isPhoneValid;
  }

  void _handleContinue() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_validateForm()) {
      AppFeedback.showError(context, l10n.onboardingValidNamePhone);
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (sl.isRegistered<AuthRemoteDataSource>()) {
        await sl<AuthRemoteDataSource>().saveProfileInfo(
          fullName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          profilePhotoFile: _profileImageFile,
        );
      }

      if (!mounted) return;
      AppFeedback.showSuccess(context, l10n.onboardingProfileVerified);
      if (widget.onProfileCompleted != null) {
        widget.onProfileCompleted!();
      } else {
        context.go(RouteNames.onboardingRole);
      }
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(context, l10n.onboardingSaveError(e.toString()));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header rolls up with scroll
                    MinimalAppBar(
                      title: l10n.onboardingStep1,
                      subtitle: l10n.onboardingEnterContact,
                      onBack: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(RouteNames.auth);
                        }
                      },
                    ),

                    // 2-Step Progress Stepper
                    const AuthStepperBar(currentStep: 1),

                    // Profile Form Body
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Theme.of(context).dividerColor),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: ProfileAvatarPicker(
                                    imageFile: _profileImageFile,
                                    onImagePicked: (file) {
                                      setState(() => _profileImageFile = file);
                                    },
                                  ),
                                ),
                                const SizedBox(height: 18),
                                AuthTextField(
                                  controller: _nameController,
                                  label: l10n.onboardingFullName,
                                  hint: 'Ahmed Khan',
                                  prefixIcon: Icons.person_outline_rounded,
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return l10n.onboardingNameRequired;
                                    }
                                    if (val.trim().length < 3) {
                                      return l10n.onboardingNameLength;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                PakistanPhoneField(
                                  controller: _phoneController,
                                  errorMessage: _phoneErrorMessage,
                                  onChanged: (_) {
                                    if (_phoneErrorMessage != null) {
                                      setState(() => _phoneErrorMessage = null);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Sticky CTA
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
                boxShadow: [
                  BoxShadow(color: Color(0x0C000000), blurRadius: 8, offset: Offset(0, -3)),
                ],
              ),
              child: DebouncedButton(
                text: l10n.onboardingContinueRole,
                icon: Icons.arrow_forward_rounded,
                isLoading: _isSaving,
                onPressed: () async => _handleContinue(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
