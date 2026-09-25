import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../auth/demo_account.dart';
import '../navigation/transitions.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../widgets/auth_field.dart';
import '../widgets/auth_layout.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/google_logo.dart';
import '../widgets/primary_button.dart';
import '../widgets/rise_in.dart';
import 'role_screen.dart';
import 'sign_up_screen.dart';

/// Sign In: "Welcome Back".
///
/// Built on [AuthLayout] (giving-hands photo background, frosted-glass form
/// card). Fields glow when focused, validate on submit and shake when
/// something's wrong. "Sign Up" swaps to [SignUpScreen].
///
/// Real authentication isn't connected yet (Firebase comes later). Until
/// then the [DemoAccount] login (one tap fills it in) leads on to account
/// setup ([RoleScreen]); any other valid-looking login is refused.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with SingleTickerProviderStateMixin {
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  String? _emailError;
  String? _passwordError;
  bool _loading = false;
  bool _remember = true;

  /// Plays once after a failed submit to shake the fields.
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    _shake.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final email = _email.text.trim();
    final password = _password.text;
    setState(() {
      _emailError = email.isEmpty
          ? 'Please enter your email'
          : !_emailPattern.hasMatch(email)
          ? "That email doesn't look right"
          : null;
      _passwordError = password.isEmpty
          ? 'Please enter your password'
          : password.length < 6
          ? 'Password must be at least 6 characters'
          : null;
    });
    if (_emailError != null || _passwordError != null) {
      HapticFeedback.mediumImpact();
      _shake.forward(from: 0);
      return;
    }

    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _loading = false);
    if (!DemoAccount.matches(email, password)) {
      setState(() => _passwordError = 'Incorrect email or password');
      HapticFeedback.mediumImpact();
      _shake.forward(from: 0);
      return;
    }
    Navigator.of(context).push(softRoute(const RoleScreen(), slide: true));
  }

  /// Fills in the demo login.
  void _useDemo() {
    HapticFeedback.selectionClick();
    setState(() {
      _email.text = DemoAccount.email;
      _password.text = DemoAccount.password;
      _emailError = null;
      _passwordError = null;
    });
  }

  void _notice(String message) => showAuthNotice(context, message);

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      photo: 'assets/images/splash_giving.jpg',
      photoFocus: const Alignment(-0.05, 0.1),
      quote: 'Every meal shared is a step toward a hunger-free tomorrow.',
      caption:
          'Coordinate volunteers, track distribution and reach every '
          'community in time.',
      features: const [
        (Icons.insights_rounded, 'Live distribution counts'),
        (Icons.assignment_ind_rounded, 'Volunteer assignments'),
        (Icons.notifications_active_rounded, 'Shortage alerts'),
      ],
      form: _form,
    );
  }

  Widget _form(BuildContext context, AuthFormArgs f) {
    final s = f.scale;
    // A short, fading side-to-side shake after a failed submit.
    final t = _shake.value;
    final shake = math.sin(t * math.pi * 6) * (1 - t) * 10 * s;

    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RiseIn(
            progress: f.rise(3),
            distance: 16 * s,
            child: Text(
              'Welcome Back',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 30 * s,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3 * s,
                color: AppColors.ink,
              ),
            ),
          ),
          SizedBox(height: 6 * s),
          RiseIn(
            progress: f.rise(3),
            distance: 14 * s,
            child: Text(
              'Good to see you again!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16.5 * s, color: AppColors.bodyText),
            ),
          ),
          f.space(22),
          RiseIn(
            progress: f.rise(4),
            distance: 12 * s,
            child: Center(
              child: _DemoAccountPill(scale: s, onTap: _useDemo),
            ),
          ),
          f.space(28),
          Transform.translate(
            offset: Offset(shake, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RiseIn(
                  progress: f.rise(4),
                  distance: 16 * s,
                  child: AuthField(
                    controller: _email,
                    hint: 'Email',
                    icon: Icons.mail_outline_rounded,
                    scale: s,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    errorText: _emailError,
                    onChanged: (_) {
                      if (_emailError != null) {
                        setState(() => _emailError = null);
                      }
                    },
                    onSubmitted: (_) => _passwordFocus.requestFocus(),
                  ),
                ),
                f.space(28),
                RiseIn(
                  progress: f.rise(5),
                  distance: 16 * s,
                  child: AuthField(
                    controller: _password,
                    focusNode: _passwordFocus,
                    hint: 'Password',
                    icon: Icons.lock_outline_rounded,
                    scale: s,
                    obscure: true,
                    autofillHints: const [AutofillHints.password],
                    textInputAction: TextInputAction.done,
                    errorText: _passwordError,
                    onChanged: (_) {
                      if (_passwordError != null) {
                        setState(() => _passwordError = null);
                      }
                    },
                    onSubmitted: (_) => _submit(),
                  ),
                ),
              ],
            ),
          ),
          f.space(26),
          RiseIn(
            progress: f.rise(6),
            distance: 12 * s,
            // Side by side when there's room, stacked on narrow cards.
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 10 * s,
              children: [
                AuthCheckbox(
                  value: _remember,
                  scale: s * 0.92,
                  semanticsLabel: 'Remember me',
                  onChanged: (v) => setState(() => _remember = v),
                  label: Text(
                    'Remember me',
                    style: TextStyle(
                      fontSize: 14.5 * s,
                      fontWeight: FontWeight.w500,
                      color: AppColors.bodyText,
                    ),
                  ),
                ),
                AuthTextLink(
                  label: 'Forgot Password?',
                  scale: s,
                  fontSize: 14.5,
                  onTap: () => _notice(
                    "Password reset isn't connected yet. It will work once Firebase is set up.",
                  ),
                ),
              ],
            ),
          ),
          f.space(44),
          RiseIn(
            progress: f.rise(7),
            distance: 16 * s,
            child: PrimaryButton(
              label: 'Sign In',
              scale: s * 0.92,
              time: f.time,
              loading: _loading,
              onPressed: _submit,
            ),
          ),
          f.space(38),
          RiseIn(
            progress: f.rise(8),
            distance: 12 * s,
            child: AuthDivider(label: 'or continue with', scale: s),
          ),
          f.space(28),
          RiseIn(
            progress: f.rise(9),
            distance: 14 * s,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 18 * s,
              runSpacing: 12 * s,
              children: [
                SocialButton(
                  label: 'Continue with Google',
                  scale: s,
                  onTap: () => _notice(
                    "Google sign-in isn't connected yet. It will work once Firebase is set up.",
                  ),
                  child: GoogleLogo(size: 24 * s),
                ),
                SocialButton(
                  label: 'Continue with Apple',
                  scale: s,
                  onTap: () => _notice(
                    "Apple sign-in isn't connected yet. It will work once Firebase is set up.",
                  ),
                  child: Icon(Icons.apple, size: 28 * s, color: Colors.black),
                ),
              ],
            ),
          ),
          f.space(40),
          RiseIn(
            progress: f.rise(10),
            distance: 12 * s,
            child: AuthSwitchPrompt(
              prompt: "Don't have an account?",
              action: 'Sign Up',
              scale: s,
              // Swap rather than stack, so Back still leads to onboarding.
              onTap: () =>
                  Navigator.of(context)
                      .pushReplacement(softRoute(const SignUpScreen())),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Demo account" pill: shows the demo login and fills it in when tapped.
class _DemoAccountPill extends StatefulWidget {
  const _DemoAccountPill({required this.scale, required this.onTap});

  final double scale;
  final VoidCallback onTap;

  @override
  State<_DemoAccountPill> createState() => _DemoAccountPillState();
}

class _DemoAccountPillState extends State<_DemoAccountPill> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    return Semantics(
      button: true,
      label: 'Use demo account',
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.fromLTRB(8 * s, 7 * s, 14 * s, 7 * s),
            decoration: BoxDecoration(
              color: _hovered
                  ? AppColors.roleChosenCircle
                  : AppColors.roleChosenFill,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.roleChosenBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 26 * s,
                  height: 26 * s,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.brand,
                  ),
                  child: Icon(
                    Icons.key_rounded,
                    size: 15 * s,
                    color: AppColors.white,
                  ),
                ),
                SizedBox(width: 9 * s),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Use demo account',
                        style: TextStyle(
                          fontSize: 13.5 * s,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brand,
                        ),
                      ),
                      Text(
                        '${DemoAccount.email} · ${DemoAccount.password}',
                        style: TextStyle(
                          fontSize: 12 * s,
                          color: AppColors.bodyText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
