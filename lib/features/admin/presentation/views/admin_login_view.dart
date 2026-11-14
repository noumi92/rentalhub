import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/data/datasources/auth_remote_data_source.dart';
import '../../data/datasources/admin_remote_data_source.dart';
import '../../data/services/admin_session.dart';
import '../widgets/admin_login_error.dart';
import '../widgets/admin_login_form.dart';
import '../widgets/admin_totp_reminder_banner.dart';
import '../widgets/admin_totp_step.dart';

/// Phase A (A1) — the admin sign-in screen (web-first, centred card):
/// email/password, then the admin profile, then the TOTP step.
class AdminLoginView extends StatefulWidget {
  const AdminLoginView({super.key});

  @override
  State<AdminLoginView> createState() => _AdminLoginViewState();
}

class _AdminLoginViewState extends State<AdminLoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();

  bool _isWorking = false;
  bool _totpStep = false;
  String? _otpauthUrl;
  String? _error;
  bool _notAdmin = false;
  // F-m4: a super admin asked this admin to turn on 2FA.
  bool _hasTotpReminder = false;

  @override
  void initState() {
    super.initState();
    _checkAlreadySignedIn();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  // F-m4: is a 2FA-off reminder waiting? Never blocks sign-in.
  Future<void> _checkTotpReminder(String uid) async {
    final reminded = await sl<AdminRemoteDataSource>().hasTotpReminder(uid);
    if (mounted) setState(() => _hasTotpReminder = reminded);
  }

  /// A signed-in admin who reloads the page lands here: resolve
  /// their profile instead of asking for the password again.
  Future<void> _checkAlreadySignedIn() async {
    User? user;
    try { user = FirebaseAuth.instance.currentUser; } catch (_) { return; }
    if (user == null) return;
    final profile =
        await sl<AdminRemoteDataSource>().getAdminProfile(user.uid);
    if (profile == null || profile.adminRole == null) {
      if (mounted) setState(() => _notAdmin = true);
      return;
    }
    if (!mounted) return;
    if (AdminSession.isTotpVerifiedForCurrentUser) {
      context.go(RouteNames.adminDashboard);
    } else {
      setState(() {
        _totpStep = true;
        _otpauthUrl = profile.totpEnabled ? null : _otpauthUrl;
      });
      if (!profile.totpEnabled) _checkTotpReminder(user.uid);
      if (!profile.totpEnabled && !await _startEnrolment() && mounted) {
        context.go(RouteNames.adminDashboard);
      }
    }
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = AppLocalizations.of(context)?.admin2_loginEmailPassword ?? 'Enter your email and password.');
      return;
    }
    // AD-m5: a basic email-format check before Firebase is even
    // called, so a typo surfaces here instead of as a raw error.
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _error = AppLocalizations.of(context)?.admin2_signInInvalidEmail ?? 'Enter a valid email address.');
      return;
    }
    setState(() {
      _isWorking = true;
      _error = null;
    });
    try {
      final user = await sl<AuthRemoteDataSource>()
          .signInWithEmail(email: email, password: password);
      final profile =
          await sl<AdminRemoteDataSource>().getAdminProfile(user.uid);
      if (profile == null || profile.adminRole == null) {
        await _signOutQuietly();
        if (mounted) {
          setState(() {
            _notAdmin = true;
            _isWorking = false;
          });
        }
        return;
      }
      if (!mounted) return;
      if (AdminSession.isTotpVerifiedForCurrentUser) {
        context.go(RouteNames.adminDashboard);
        return;
      }
      setState(() => _totpStep = true);
      if (!profile.totpEnabled) _checkTotpReminder(user.uid);
      if (!profile.totpEnabled && !await _startEnrolment()) {
        if (mounted) context.go(RouteNames.adminDashboard);
        return;
      }
    } catch (e) {
      if (mounted) setState(() => _error = adminLoginFriendlyError(e, AppLocalizations.of(context)));
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  /// Returns false only when the Functions backend is missing, so
  /// the caller can fall back to password-only login (temporary).
  Future<bool> _startEnrolment() async {
    try {
      final url = await sl<AdminRemoteDataSource>().enrollTotp();
      if (mounted) setState(() => _otpauthUrl = url);
      return true;
    } catch (e) {
      if (AdminSession.isFunctionsUnavailable(e)) return false;
      if (mounted) setState(() => _error = adminLoginFriendlyError(e, AppLocalizations.of(context)));
      return true;
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _error = AppLocalizations.of(context)?.admin2_loginEnterCode ?? 'Enter the 6-digit code.');
      return;
    }
    setState(() {
      _isWorking = true;
      _error = null;
    });
    try {
      await sl<AdminRemoteDataSource>().verifyTotp(code);
      if (mounted) {
        AppFeedback.showSuccess(context, AppLocalizations.of(context)?.admin2_loginSignedIn ?? 'Signed in.');
        context.go(RouteNames.adminDashboard);
      }
    } catch (e) {
      // F-M4: the temporary password-only fallback, extended from
      // enrolment to the verify path (see AdminSession).
      if (await AdminSession.tryPasswordOnlyFallback(e)) {
        if (mounted) context.go(RouteNames.adminDashboard);
        return;
      }
      if (mounted) setState(() => _error = adminLoginFriendlyError(e, AppLocalizations.of(context)));
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _signOutQuietly() async {
    AdminSession.clear();
    try { await FirebaseAuth.instance.signOut(); } catch (_) {}
    try { await sl<AuthRemoteDataSource>().setLoggedIn(false); } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Theme.of(context).dividerColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _notAdmin
                    ? _buildNotAdmin()
                    : _totpStep
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_hasTotpReminder)
                                const AdminTotpReminderBanner(),
                              AdminTotpStep(
                                codeController: _codeController,
                                isWorking: _isWorking,
                                error: _error,
                                onVerify: _verifyCode,
                                otpauthUrl: _otpauthUrl,
                              ),
                            ],
                          )
                        : _buildCredentials(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCredentials() {
    return AdminLoginForm(
      emailController: _emailController,
      passwordController: _passwordController,
      isWorking: _isWorking,
      error: _error,
      onSignIn: _signIn,
    );
  }

  Widget _buildNotAdmin() {
    return AdminNotAdminCard(
      onUseDifferentAccount: () async {
        await _signOutQuietly();
        if (mounted) {
          setState(() {
            _notAdmin = false;
            _totpStep = false;
          });
        }
      },
    );
  }
}
