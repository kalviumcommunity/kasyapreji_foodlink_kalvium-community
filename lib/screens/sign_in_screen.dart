import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../widgets/asset_photo.dart';
import '../widgets/auth_field.dart';
import '../widgets/foodlink_logo.dart';
import '../widgets/google_logo.dart';
import '../widgets/leaf.dart';
import '../widgets/light_particles.dart';
import '../widgets/onboarding_layout.dart';
import '../widgets/primary_button.dart';
import '../widgets/rise_in.dart';

/// Sign In: "Welcome Back".
///
/// The giving-hands photo fills the background. Phones show it whole in a
/// rounded card over a soft blurred fill, with the form below in a frosted-glass
/// card; laptops show it full-bleed with the brand story on the left and the
/// glass form card on the right. Everything rises in on arrival; fields glow
/// when focused, validate on submit and shake when something's wrong.
///
/// Authentication isn't connected yet (Firebase comes later), so actions that
/// need it show a clear notice instead of pretending to work.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, this.onSignUp});

  /// Called when "Sign Up" is tapped.
  final VoidCallback? onSignUp;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with TickerProviderStateMixin {
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  String? _emailError;
  String? _passwordError;
  bool _loading = false;
  bool _remember = true;

  final _photo = AssetPhoto('assets/images/splash_giving.jpg');

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..forward();

  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  /// Plays once after a failed submit to shake the fields.
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  /// Entrance for the n-th element from the top, staggered.
  double _rise(int n) {
    final start = (n * 0.06).clamp(0.0, 0.6);
    return Curves.easeOutCubic.transform(
      ((_intro.value - start) / 0.4).clamp(0.0, 1.0),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _photo.resolve(context, () {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    _intro.dispose();
    _ambient.dispose();
    _shake.dispose();
    _photo.dispose();
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
    _notice(
      "Sign-in isn't connected yet. It will work once Firebase is set up.",
    );
  }

  void _notice(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.brandDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: AppColors.logoOnDark,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontFamily: AppFonts.body,
                    color: AppColors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Light icons over the dark photo background.
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: AppColors.splashGradient.last,
        body: Builder(
          builder: (context) {
            // Scale from the full screen, not the space left above an open
            // keyboard, so text doesn't shrink while typing.
            final size = MediaQuery.sizeOf(context);
            final wide =
                size.width >= OnboardingLayout.wideBreakpoint &&
                size.width > size.height;
            return AnimatedBuilder(
              animation: Listenable.merge([_intro, _ambient, _shake]),
              builder: (context, _) => Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _BackgroundPainter(
                        photo: _photo.image,
                        time: _ambient.value,
                        reveal: _rise(0),
                        // Phones show a soft, blurred fill behind the full
                        // photo card; laptops show the photo itself.
                        blur: wide ? 0 : 22,
                        wide: wide,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: wide ? _buildWide(size) : _buildCompact(size),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Phone layout
  // ---------------------------------------------------------------------------

  Widget _buildCompact(Size size) {
    final s = math.min(
      size.width / OnboardingLayout.designWidth,
      size.height / OnboardingLayout.designHeight,
    );
    // On tablets held upright, keep things a comfortable width.
    final contentWidth = math.min(size.width, 520 * s);

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(0, 8 * s, 0, 20 * s),
        child: Center(
          child: SizedBox(
            width: contentWidth,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16 * s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RiseIn(
                    progress: _rise(0),
                    distance: -10 * s,
                    child: _headerRow(s, onDark: true, brand: true),
                  ),
                  SizedBox(height: 14 * s),
                  // The whole photo, uncropped.
                  RiseIn(
                    progress: _rise(1),
                    distance: 18 * s,
                    child: _PhotoCard(photo: _photo.image, scale: s),
                  ),
                  SizedBox(height: 14 * s),
                  RiseIn(
                    progress: _rise(2),
                    distance: 24 * s,
                    child: _GlassCard(
                      scale: s,
                      time: _ambient.value,
                      leafIn: _rise(5),
                      padding: EdgeInsets.fromLTRB(
                        20 * s,
                        26 * s,
                        20 * s,
                        22 * s,
                      ),
                      child: _form(s, gap: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Laptop layout
  // ---------------------------------------------------------------------------

  Widget _buildWide(Size size) {
    final s = math.min(size.width / 1280, size.height / 900).clamp(0.8, 1.05);
    final showStory = size.width >= 820;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 56 * s, vertical: 28 * s),
      child: Row(
        children: [
          if (showStory) ...[
            Expanded(flex: 11, child: _brandStory(s, size)),
            SizedBox(width: 40 * s),
          ],
          Expanded(
            flex: 9,
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(vertical: 12 * s),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 440 * s),
                  child: RiseIn(
                    progress: _rise(1),
                    distance: 24 * s,
                    child: _GlassCard(
                      scale: s,
                      time: _ambient.value,
                      leafIn: _rise(5),
                      padding: EdgeInsets.fromLTRB(
                        32 * s,
                        26 * s,
                        32 * s,
                        26 * s,
                      ),
                      leafAtBottom: true,
                      child: _form(s, gap: 0.55, header: true),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Laptop left side: brand, quote and what FoodLink does, straight on the
  /// photo.
  Widget _brandStory(double s, Size size) {
    final quoteSize = (size.width / 38).clamp(26.0, 42.0 * s);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RiseIn(progress: _rise(0), distance: -10 * s, child: _brandMark(s, 24)),
        const Spacer(),
        RiseIn(
          progress: _rise(2),
          distance: 20 * s,
          child: Text(
            'Every meal shared is a step toward a hunger-free tomorrow.',
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontStyle: FontStyle.italic,
              fontSize: quoteSize,
              fontWeight: FontWeight.w600,
              height: 1.2,
              color: AppColors.white,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 16 * s,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16 * s),
        RiseIn(
          progress: _rise(3),
          distance: 16 * s,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 480 * s),
            child: Text(
              'Coordinate volunteers, track distribution and reach every '
              'community in time.',
              style: TextStyle(
                fontSize: 17 * s,
                height: 1.6,
                color: AppColors.taglineOnDark,
              ),
            ),
          ),
        ),
        SizedBox(height: 26 * s),
        RiseIn(
          progress: _rise(4),
          distance: 16 * s,
          child: Wrap(
            spacing: 10 * s,
            runSpacing: 10 * s,
            children: [
              _FeatureChip(
                icon: Icons.insights_rounded,
                label: 'Live distribution counts',
                scale: s,
              ),
              _FeatureChip(
                icon: Icons.assignment_ind_rounded,
                label: 'Volunteer assignments',
                scale: s,
              ),
              _FeatureChip(
                icon: Icons.notifications_active_rounded,
                label: 'Shortage alerts',
                scale: s,
              ),
            ],
          ),
        ),
        SizedBox(height: 12 * s),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Shared pieces
  // ---------------------------------------------------------------------------

  /// Leaf mark and "FoodLink" wordmark, light for use on the photo.
  Widget _brandMark(double s, double fontSize) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FoodLinkLogo(width: fontSize * 1.45 * s, color: AppColors.logoOnDark),
        SizedBox(width: 10 * s),
        Text(
          'FoodLink',
          style: TextStyle(
            fontFamily: AppFonts.display,
            fontSize: fontSize * s,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
      ],
    );
  }

  /// Back button (when there's somewhere to go back to), optionally the brand
  /// mark in the middle, and the avatar.
  Widget _headerRow(double s, {bool onDark = false, bool brand = false}) {
    final canGoBack = Navigator.of(context).canPop();
    return SizedBox(
      height: 44 * s,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (brand) _brandMark(s, 21),
          Row(
            children: [
              if (canGoBack)
                _IconCircle(
                  label: 'Back',
                  scale: s,
                  onDark: onDark,
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18 * s,
                    color: onDark ? AppColors.white : AppColors.ink,
                  ),
                ),
              const Spacer(),
              _Avatar(scale: s),
            ],
          ),
        ],
      ),
    );
  }

  /// The form. [gap] scales the vertical spacing; [header] adds the
  /// back/avatar row at the top (the laptop card has no separate header).
  Widget _form(double s, {double gap = 1, bool header = false}) {
    SizedBox space(double h) => SizedBox(height: h * s * gap);
    // A short, fading side-to-side shake after a failed submit.
    final t = _shake.value;
    final shake = math.sin(t * math.pi * 6) * (1 - t) * 10 * s;

    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header) ...[_headerRow(s), space(12)],
          RiseIn(
            progress: _rise(3),
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
            progress: _rise(3),
            distance: 14 * s,
            child: Text(
              'Good to see you again!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16.5 * s, color: AppColors.bodyText),
            ),
          ),
          space(48),
          Transform.translate(
            offset: Offset(shake, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RiseIn(
                  progress: _rise(4),
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
                space(28),
                RiseIn(
                  progress: _rise(5),
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
          space(26),
          RiseIn(
            progress: _rise(6),
            distance: 12 * s,
            // Side by side when there's room, stacked on narrow cards.
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 10 * s,
              children: [
                _RememberToggle(
                  value: _remember,
                  scale: s,
                  onChanged: (v) => setState(() => _remember = v),
                ),
                _TextLink(
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
          space(44),
          RiseIn(
            progress: _rise(7),
            distance: 16 * s,
            child: PrimaryButton(
              label: 'Sign In',
              scale: s * 0.92,
              time: _ambient.value,
              loading: _loading,
              onPressed: _submit,
            ),
          ),
          space(38),
          RiseIn(
            progress: _rise(8),
            distance: 12 * s,
            child: _Divider(scale: s),
          ),
          space(28),
          RiseIn(
            progress: _rise(9),
            distance: 14 * s,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 18 * s,
              runSpacing: 12 * s,
              children: [
                _SocialButton(
                  label: 'Continue with Google',
                  scale: s,
                  onTap: () => _notice(
                    "Google sign-in isn't connected yet. It will work once Firebase is set up.",
                  ),
                  child: GoogleLogo(size: 24 * s),
                ),
                _SocialButton(
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
          space(40),
          RiseIn(
            progress: _rise(10),
            distance: 12 * s,
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8 * s,
              runSpacing: 4 * s,
              children: [
                Text(
                  "Don't have an account?",
                  style: TextStyle(
                    fontSize: 15.5 * s,
                    color: AppColors.bodyText,
                  ),
                ),
                _TextLink(
                  label: 'Sign Up',
                  scale: s,
                  fontSize: 16.5,
                  onTap:
                      widget.onSignUp ??
                      () => _notice('The Sign Up screen is coming next.'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Round, frosted tap target (the back button).
class _IconCircle extends StatelessWidget {
  const _IconCircle({
    required this.label,
    required this.scale,
    required this.onTap,
    required this.child,
    this.onDark = false,
  });

  final String label;
  final double scale;
  final VoidCallback onTap;
  final Widget child;

  /// Glassy white variant for use over the photo.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final d = 40 * scale;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: d,
            height: d,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: onDark
                  ? AppColors.white.withValues(alpha: 0.18)
                  : AppColors.surface.withValues(alpha: 0.75),
              border: Border.all(
                color: onDark
                    ? AppColors.white.withValues(alpha: 0.35)
                    : AppColors.ink.withValues(alpha: 0.08),
              ),
            ),
            alignment: Alignment.center,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Profile placeholder in the top-right, as in the design.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final d = 40 * scale;
    return Semantics(
      label: 'Profile',
      child: Container(
        width: d,
        height: d,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.avatar,
          ),
          border: Border.all(color: AppColors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.earthDark.withValues(alpha: 0.25),
              blurRadius: 10 * scale,
              offset: Offset(0, 3 * scale),
            ),
          ],
        ),
        child: Icon(
          Icons.person_rounded,
          size: 24 * scale,
          color: const Color(0xFFF3E4D6),
        ),
      ),
    );
  }
}

/// Green, semi-bold text link that underlines on hover.
class _TextLink extends StatefulWidget {
  const _TextLink({
    required this.label,
    required this.scale,
    required this.fontSize,
    required this.onTap,
  });

  final String label;
  final double scale;
  final double fontSize;
  final VoidCallback onTap;

  @override
  State<_TextLink> createState() => _TextLinkState();
}

class _TextLinkState extends State<_TextLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: widget.fontSize * widget.scale,
              fontWeight: FontWeight.w700,
              color: AppColors.brand,
              decoration: _hovered ? TextDecoration.underline : null,
              decorationColor: AppColors.brand,
            ),
          ),
        ),
      ),
    );
  }
}

/// "or continue with" between two hairlines.
class _Divider extends StatelessWidget {
  const _Divider({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Container(
        height: 1,
        margin: EdgeInsets.symmetric(horizontal: 14 * scale),
        color: AppColors.ink.withValues(alpha: 0.08),
      ),
    );
    return Row(
      children: [
        line,
        Text(
          'or continue with',
          style: TextStyle(fontSize: 15 * scale, color: AppColors.bodyText),
        ),
        line,
      ],
    );
  }
}

/// Light pill for a social sign-in option; lifts on hover, dips on press.
class _SocialButton extends StatefulWidget {
  const _SocialButton({
    required this.label,
    required this.scale,
    required this.onTap,
    required this.child,
  });

  final String label;
  final double scale;
  final VoidCallback onTap;
  final Widget child;

  @override
  State<_SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<_SocialButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    return Semantics(
      button: true,
      label: widget.label,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onTap();
          },
          child: AnimatedScale(
            scale: _pressed ? 0.95 : 1,
            duration: const Duration(milliseconds: 120),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 126 * s,
              height: 54 * s,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _hovered ? AppColors.white : AppColors.socialFill,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppColors.ink.withValues(
                    alpha: _hovered ? 0.10 : 0.04,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brand.withValues(
                      alpha: _hovered ? 0.12 : 0.0,
                    ),
                    blurRadius: 16 * s,
                    offset: Offset(0, 6 * s),
                  ),
                ],
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-screen photo background with a deep green film and drifting light.
/// With [blur] it becomes a soft colour fill (phones, behind the photo card).
class _BackgroundPainter extends CustomPainter {
  _BackgroundPainter({
    required this.photo,
    required this.time,
    required this.reveal,
    required this.blur,
    required this.wide,
  });

  final ui.Image? photo;
  final double time;
  final double reveal;
  final double blur;
  final bool wide;

  static final _particles = LightParticles(top: 40, bottom: 920, count: 26);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.topCenter,
          rect.bottomCenter,
          AppColors.splashGradient,
          AppColors.splashGradientStops,
        ),
    );

    final image = photo;
    if (image != null) {
      if (blur > 0) {
        canvas.saveLayer(
          rect,
          Paint()
            ..imageFilter = ui.ImageFilter.blur(
              sigmaX: blur,
              sigmaY: blur,
              tileMode: TileMode.clamp,
            ),
        );
      }
      paintPhotoCover(
        canvas,
        image,
        rect,
        alignment: const Alignment(-0.05, 0.1),
        zoom: 1.05 + 0.04 * math.sin(time * 2 * math.pi),
        opacity: reveal,
      );
      if (blur > 0) canvas.restore();
    }

    // Film: darker on the left on laptops (behind the story text), and
    // evenly deep on phones.
    final film = wide
        ? ui.Gradient.linear(
            rect.centerLeft,
            rect.centerRight,
            [
              AppColors.splashScrim.withValues(alpha: 0.78),
              AppColors.splashScrim.withValues(alpha: 0.35),
              AppColors.splashScrim.withValues(alpha: 0.55),
            ],
            const [0.0, 0.55, 1.0],
          )
        : ui.Gradient.linear(
            rect.topCenter,
            rect.bottomCenter,
            [
              AppColors.splashScrim.withValues(alpha: 0.55),
              AppColors.splashScrim.withValues(alpha: 0.45),
              AppColors.splashScrim.withValues(alpha: 0.70),
            ],
            const [0.0, 0.5, 1.0],
          );
    canvas.drawRect(rect, Paint()..shader = film);

    _particles.paint(
      canvas,
      sx: size.width / 422,
      sy: size.height / 920,
      time: time,
      opacity: reveal,
    );
  }

  @override
  bool shouldRepaint(_BackgroundPainter oldDelegate) => true;
}

/// Phones: the complete, uncropped photo in a rounded card.
class _PhotoCard extends StatelessWidget {
  const _PhotoCard({required this.photo, required this.scale});

  final ui.Image? photo;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final image = photo;
    final aspect = image == null ? 16 / 9 : image.width / image.height;
    return AspectRatio(
      aspectRatio: aspect,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22 * s),
          border: Border.all(
            color: AppColors.white.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 24 * s,
              offset: Offset(0, 10 * s),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(21 * s),
          child: image == null
              ? const ColoredBox(color: AppColors.splashScrim)
              : RawImage(image: image, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

/// Frosted-glass card holding the form, with a leaf peeking over its corner.
class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.scale,
    required this.time,
    required this.leafIn,
    required this.padding,
    required this.child,
    this.leafAtBottom = false,
  });

  final double scale;
  final double time;
  final double leafIn;
  final EdgeInsets padding;
  final Widget child;

  /// Put the leaf at the bottom-left corner instead of the top-right (where
  /// the laptop card has its avatar).
  final bool leafAtBottom;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final radius = BorderRadius.circular(28 * s);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 40 * s,
                offset: Offset(0, 16 * s),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: padding,
                decoration: BoxDecoration(
                  borderRadius: radius,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.surface.withValues(alpha: 0.93),
                      AppColors.backdrop.last.withValues(alpha: 0.88),
                    ],
                  ),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.6),
                  ),
                ),
                child: child,
              ),
            ),
          ),
        ),
        Positioned(
          top: leafAtBottom ? null : -30 * s,
          right: leafAtBottom ? null : 6 * s,
          bottom: leafAtBottom ? -34 * s : null,
          left: leafAtBottom ? 8 * s : null,
          child: IgnorePointer(
            child: SizedBox(
              width: 60 * s,
              height: 70 * s,
              child: CustomPaint(
                painter: _CornerLeafPainter(
                  scale: s,
                  time: time,
                  appear: leafIn,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

const _cornerLeaf = LeafShape(
  tipA: Offset(48, 4),
  tipB: Offset(18, 64),
  bulgeLeft: 13,
  bulgeRight: 11,
  color: AppColors.leafLight,
  veinColor: AppColors.leafVein,
);

class _CornerLeafPainter extends CustomPainter {
  _CornerLeafPainter({
    required this.scale,
    required this.time,
    required this.appear,
  });

  final double scale;
  final double time;
  final double appear;

  @override
  void paint(Canvas canvas, Size size) {
    paintSwayingLeaf(
      canvas,
      _cornerLeaf,
      target: _cornerLeaf.centre * scale,
      scale: scale,
      time: time,
      appear: appear,
      entry: const Offset(30, -30),
    );
  }

  @override
  bool shouldRepaint(_CornerLeafPainter oldDelegate) => true;
}

/// Laptops: a frosted pill naming one thing FoodLink does.
class _FeatureChip extends StatelessWidget {
  const _FeatureChip({
    required this.icon,
    required this.label,
    required this.scale,
  });

  final IconData icon;
  final String label;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Container(
      padding: EdgeInsets.fromLTRB(10 * s, 8 * s, 14 * s, 8 * s),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17 * s, color: AppColors.logoOnDark),
          SizedBox(width: 8 * s),
          Text(
            label,
            style: TextStyle(
              fontSize: 14 * s,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Rounded green checkbox with a "Remember me" label.
class _RememberToggle extends StatelessWidget {
  const _RememberToggle({
    required this.value,
    required this.scale,
    required this.onChanged,
  });

  final bool value;
  final double scale;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Semantics(
      checked: value,
      label: 'Remember me',
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged(!value);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 20 * s,
                height: 20 * s,
                decoration: BoxDecoration(
                  color: value ? AppColors.brand : AppColors.white,
                  borderRadius: BorderRadius.circular(6 * s),
                  border: Border.all(
                    color: value ? AppColors.brand : AppColors.fieldBorder,
                    width: 1.5,
                  ),
                ),
                child: AnimatedScale(
                  scale: value ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutBack,
                  child: Icon(
                    Icons.check_rounded,
                    size: 15 * s,
                    color: AppColors.white,
                  ),
                ),
              ),
              SizedBox(width: 8 * s),
              Text(
                'Remember me',
                style: TextStyle(
                  fontSize: 14.5 * s,
                  fontWeight: FontWeight.w500,
                  color: AppColors.bodyText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
