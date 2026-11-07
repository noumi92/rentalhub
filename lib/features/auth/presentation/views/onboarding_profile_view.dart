import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import 'widgets/auth_stepper_bar.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/pakistan_phone_field.dart';
import 'widgets/profile_avatar_picker.dart';

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
        _phoneController.text = auth.phoneNumber
            .replaceAll('+92 ', '')
            .replaceAll('+92', '')
            .replaceAll(RegExp(r'^0+'), '')
            .trim();
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
    setState(() => _phoneErrorMessage = null);
    final isNameValid = _formKey.currentState?.validate() ?? false;

    // Validate Pakistani mobile number: 10 digits starting with 3
    final rawPhone = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    bool isPhoneValid = true;

    if (rawPhone.isEmpty) {
      setState(() => _phoneErrorMessage = 'WhatsApp number is required');
      isPhoneValid = false;
    } else if (rawPhone.length != 10 || !rawPhone.startsWith('3')) {
      setState(() {
        _phoneErrorMessage = 'Enter a valid 10-digit number starting with 3 (e.g. 300 1234567)';
      });
      isPhoneValid = false;
    }

    return isNameValid && isPhoneValid;
  }

  void _handleContinue() async {
    if (!_validateForm()) {
      AppFeedback.showError(
        context,
        'Please enter a valid full name and Pakistani WhatsApp number (+92 3XX or 03XX).',
      );
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
      AppFeedback.showSuccess(context, 'Profile details verified.');
      if (widget.onProfileCompleted != null) {
        widget.onProfileCompleted!();
      } else {
        context.go(RouteNames.onboardingRole);
      }
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(context, 'Error saving profile: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    CustomCurvedHeader(
                      height: 105,
                      leadingWidget: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go(RouteNames.auth);
                          }
                        },
                      ),
                      titleWidget: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Step 1: Your Profile',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Enter your contact information',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.primaryContainer,
                            ),
                          ),
                        ],
                      ),
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
                          side: const BorderSide(color: AppColors.borderSubtle),
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
                                  label: 'Full Name',
                                  hint: 'Ahmed Khan',
                                  prefixIcon: Icons.person_outline_rounded,
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Full name is required';
                                    }
                                    if (val.trim().length < 3) {
                                      return 'Name must be at least 3 characters';
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
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.borderSubtle)),
                boxShadow: [
                  BoxShadow(color: Color(0x0C000000), blurRadius: 8, offset: Offset(0, -3)),
                ],
              ),
              child: DebouncedButton(
                text: 'Continue to Role Selection',
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

