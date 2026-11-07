import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../auth/data/datasources/auth_remote_data_source.dart';
import '../../data/datasources/admin_remote_data_source.dart';
import '../../data/services/admin_session.dart';
import '../widgets/admin_login_form.dart';
import '../widgets/admin_totp_step.dart';

/// Phase A (A1) — the admin sign-in screen (web-first, centred card).
///
/// Email/password via the shared AuthRemoteDataSource, then the admin
/// profile is resolved from the users doc: the account must hold an
/// admin_role (super_admin / operations / support) or it is not an
/// admin at all. TOTP follows the old repo's gate: an admin with
/// totp_enabled enters the 6-digit code; an admin without it enrols
/// (QR code + confirm) on first login. Nothing here touches the
/// customer/owner onboarding — admins never go through it.
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

  /// A signed-in admin who reloads the page lands here: resolve their
  /// profile instead of asking for the password again.
  Future<void> _checkAlreadySignedIn() async {
    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (_) {
      return;
    }
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
      if (!profile.totpEnabled) await _startEnrolment();
    }
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Enter your email and password.');
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
      if (!profile.totpEnabled) await _startEnrolment();
    } catch (e) {
      if (mounted) {
        setState(() => _error = _friendlyError(e));
      }
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _startEnrolment() async {
    try {
      final url = await sl<AdminRemoteDataSource>().enrollTotp();
      if (mounted) setState(() => _otpauthUrl = url);
    } catch (e) {
      if (mounted) setState(() => _error = _friendlyError(e));
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Enter the 6-digit code.');
      return;
    }
    setState(() {
      _isWorking = true;
      _error = null;
    });
    try {
      await sl<AdminRemoteDataSource>().verifyTotp(code);
      if (mounted) {
        AppFeedback.showSuccess(context, 'Signed in.');
        context.go(RouteNames.adminDashboard);
      }
    } catch (e) {
      if (mounted) setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _signOutQuietly() async {
    AdminSession.clear();
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    try {
      await sl<AuthRemoteDataSource>().setLoggedIn(false);
    } catch (_) {}
  }

  String _friendlyError(Object e) {
    final text = e.toString();
    // FirebaseFunctionsException carries a readable message after the colon.
    final marker = text.indexOf('] ');
    if (marker >= 0) return text.substring(marker + 2).trim();
    return text.replaceFirst('Exception: ', '');
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
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.borderSubtle),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _notAdmin
                    ? _buildNotAdmin()
                    : _totpStep
                        ? AdminTotpStep(
                            codeController: _codeController,
                            isWorking: _isWorking,
                            error: _error,
                            onVerify: _verifyCode,
                            otpauthUrl: _otpauthUrl,
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
