import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../navigation/transitions.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../widgets/auth_field.dart';
import '../widgets/auth_layout.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/password_strength.dart';
import '../widgets/primary_button.dart';
import '../widgets/rise_in.dart';
import 'role_screen.dart';
import 'sign_in_screen.dart';

/// Sign Up: "Create Account".
///
/// Built on [AuthLayout] with a photo of volunteers packing food. Full name,
/// email, phone and password (with a live strength meter), plus a Terms &
/// Conditions box that must be ticked. Everything validates on submit and the
/// form shakes when something's wrong. "Sign In" swaps to [SignInScreen].
///
/// A valid submit moves on to account setup ([RoleScreen]). No account is
/// actually created yet: that comes with Firebase.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();

  String? _nameError;
  String? _emailError;
  String? _phoneError;
  String? _passwordError;
  bool _agreed = false;
  bool _termsError = false;
  bool _loading = false;

  /// Plays once after a failed submit to shake the form.
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password]) {
      c.dispose();
    }
    for (final f in [_emailFocus, _phoneFocus, _passwordFocus]) {
      f.dispose();
    }
    _shake.dispose();
    super.dispose();
  }

  static String? _validatePhone(String phone) {
    if (phone.isEmpty) return 'Please enter your phone number';
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7 || digits.length > 15) {
      return "That phone number doesn't look right";
    }
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text;
    setState(() {
      _nameError = name.length < 2 ? 'Please enter your full name' : null;
      _emailError = email.isEmpty
          ? 'Please enter your email'
          : !_emailPattern.hasMatch(email)
          ? "That email doesn't look right"
          : null;
      _phoneError = _validatePhone(_phone.text.trim());
      _passwordError = password.isEmpty
          ? 'Please create a password'
          : password.length < 8
          ? 'Use at least 8 characters'
          : null;
      _termsError = !_agreed;
    });
    final invalid = [
      _nameError,
      _emailError,
      _phoneError,
      _passwordError,
    ].any((e) => e != null);
    if (invalid || _termsError) {
      HapticFeedback.mediumImpact();
      _shake.forward(from: 0);
      return;
    }

    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.of(context).push(softRoute(const RoleScreen(), slide: true));
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      photo: 'assets/images/impact_packing.jpg',
      photoFocus: const Alignment(-0.15, 0.2),
      quote: 'Together, we turn surplus food into support.',
      caption:
          'Join the volunteers and coordinators getting food to every '
          'community before shortages happen.',
      features: const [
        (Icons.volunteer_activism_rounded, 'Volunteer or coordinate'),
        (Icons.place_rounded, 'Every site in one view'),
        (Icons.bolt_rounded, 'Real-time updates'),
      ],
      form: _form,
    );
  }

  Widget _form(BuildContext context, AuthFormArgs f) {
    final s = f.scale;
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
              'Create Account',
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
              "Let's make an impact together",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16.5 * s, color: AppColors.bodyText),
            ),
          ),
          f.space(44),
          Transform.translate(
            offset: Offset(shake, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RiseIn(
                  progress: f.rise(4),
                  distance: 16 * s,
                  child: AuthField(
                    controller: _name,
                    hint: 'Full Name',
                    icon: Icons.person_outline_rounded,
                    scale: s,
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.name],
                    textInputAction: TextInputAction.next,
                    errorText: _nameError,
                    onChanged: (_) {
                      if (_nameError != null) {
                        setState(() => _nameError = null);
                      }
                    },
                    onSubmitted: (_) => _emailFocus.requestFocus(),
                  ),
                ),
                f.space(26),
                RiseIn(
                  progress: f.rise(5),
                  distance: 16 * s,
                  child: AuthField(
                    controller: _email,
                    focusNode: _emailFocus,
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
                    onSubmitted: (_) => _phoneFocus.requestFocus(),
                  ),
                ),
                f.space(26),
                RiseIn(
                  progress: f.rise(6),
                  distance: 16 * s,
                  child: AuthField(
                    controller: _phone,
                    focusNode: _phoneFocus,
                    hint: 'Phone Number',
                    icon: Icons.phone_outlined,
                    scale: s,
                    keyboardType: TextInputType.phone,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[0-9+\-\s()]'),
                      ),
                    ],
                    textInputAction: TextInputAction.next,
                    errorText: _phoneError,
                    onChanged: (_) {
                      if (_phoneError != null) {
                        setState(() => _phoneError = null);
                      }
                    },
                    onSubmitted: (_) => _passwordFocus.requestFocus(),
                  ),
                ),
                f.space(26),
                RiseIn(
                  progress: f.rise(7),
                  distance: 16 * s,
                  child: AuthField(
                    controller: _password,
                    focusNode: _passwordFocus,
                    hint: 'Password',
                    icon: Icons.lock_outline_rounded,
                    scale: s,
                    obscure: true,
                    autofillHints: const [AutofillHints.newPassword],
                    textInputAction: TextInputAction.done,
                    errorText: _passwordError,
                    onChanged: (_) {
                      // Rebuild for the strength meter, and clear any error.
                      setState(() => _passwordError = null);
                    },
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                // Live strength meter while a password is being typed.
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: _password.text.isEmpty
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          padding: EdgeInsets.fromLTRB(4 * s, 12 * s, 4 * s, 0),
                          child: PasswordStrengthMeter(
                            password: _password.text,
                            scale: s,
                          ),
                        ),
                ),
                f.space(30),
                RiseIn(progress: f.rise(8), distance: 12 * s, child: _terms(s)),
              ],
            ),
          ),
          f.space(44),
          RiseIn(
            progress: f.rise(9),
            distance: 16 * s,
            child: PrimaryButton(
              label: 'Create Account',
              scale: s * 0.92,
              time: f.time,
              loading: _loading,
              onPressed: _submit,
            ),
          ),
          f.space(40),
          RiseIn(
            progress: f.rise(10),
            distance: 12 * s,
            child: AuthSwitchPrompt(
              prompt: 'Already have an account?',
              action: 'Sign In',
              scale: s,
              // Swap rather than stack, so Back still leads to onboarding.
              onTap: () =>
                  Navigator.of(context)
                      .pushReplacement(softRoute(const SignInScreen())),
            ),
          ),
        ],
      ),
    );
  }

  /// "I agree to the Terms & Conditions" checkbox, with a message below if
  /// it wasn't ticked on submit.
  Widget _terms(double s) {
    final text = TextStyle(fontSize: 14.5 * s, color: AppColors.bodyText);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthCheckbox(
          value: _agreed,
          scale: s,
          semanticsLabel: 'I agree to the Terms & Conditions',
          error: _termsError,
          onChanged: (v) => setState(() {
            _agreed = v;
            if (v) _termsError = false;
          }),
          label: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('I agree to the ', style: text),
              AuthTextLink(
                label: 'Terms & Conditions',
                scale: s,
                fontSize: 14.5,
                onTap: () => showAuthNotice(
                  context,
                  'The Terms & Conditions page is coming soon.',
                ),
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: !_termsError
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: EdgeInsets.fromLTRB(2 * s, 8 * s, 0, 0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 15 * s,
                        color: AppColors.error,
                      ),
                      SizedBox(width: 6 * s),
                      Expanded(
                        child: Text(
                          'Please accept the Terms & Conditions',
                          style: TextStyle(
                            fontSize: 13 * s,
                            fontWeight: FontWeight.w500,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
