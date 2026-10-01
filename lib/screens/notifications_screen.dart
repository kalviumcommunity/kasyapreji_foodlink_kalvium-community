import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../navigation/transitions.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../widgets/asset_photo.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/foodlink_logo.dart';
import '../widgets/leaf.dart';
import '../widgets/light_particles.dart';
import '../widgets/onboarding_layout.dart';
import '../widgets/primary_button.dart';
import '../widgets/rise_in.dart';
import '../widgets/soft_backdrop.dart';
import '../widgets/step_dots.dart';
import 'role_screen.dart';
import 'volunteer_home_screen.dart';

/// What FoodLink sends notifications about: icon, name, one-line detail.
const _topics = [
  (
    Icons.event_available_rounded,
    'New events',
    'Food drives and shifts near you',
  ),
  (Icons.campaign_rounded, 'Updates', 'Changes to the events you joined'),
  (Icons.favorite_rounded, 'Impact stories', 'The difference your help makes'),
];

/// Sample notifications floating round the bell on laptops.
const _previews = [
  (
    Icons.event_available_rounded,
    'New food drive near you',
    'Saturday, 10:00 AM · Community Hall',
  ),
  (Icons.favorite_rounded, 'Impact story', '120 meals shared this week'),
];

/// Account setup, step 4 of 5: "Stay in the Loop" — allow notifications, or
/// maybe later.
///
/// A community-farm photo melts into the soft page backdrop behind a bell
/// that rings every few seconds, with a pulsing red dot. Allowing turns the
/// dot into a green check. Enter allows, for keyboards on the web.
///
/// Phones follow the Figma frame; laptops get two columns: title, topics and
/// buttons left, the bell and sample notifications over the photo right.
///
/// Maybe Later (Continue, once allowed) opens the home for the chosen
/// [role]: volunteers go to [VolunteerHomeScreen]; the coordinator's home
/// isn't designed yet, so coordinators get a notice for now. The device's own
/// permission prompt isn't wired up yet either.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, this.role = UserRole.volunteer});

  /// The role chosen on the previous step.
  final UserRole role;

  static const int stepCount = 5;
  static const int step = 3;

  static const String photo = 'assets/images/notifications_community_farm.jpg';

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with TickerProviderStateMixin {
  final _photo = AssetPhoto(NotificationsScreen.photo);

  bool _allowed = false;
  bool _busy = false;

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..forward();

  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  late final _bell = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.1, 0.7, curve: Curves.elasticOut),
  );

  /// Staggered entrance progress (0–1) for the n-th element.
  double _rise(int n) {
    final start = (n * 0.07).clamp(0.0, 0.6);
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
    _intro.dispose();
    _ambient.dispose();
    _photo.dispose();
    super.dispose();
  }

  Future<void> _allow() async {
    if (_busy || _allowed) return;
    setState(() => _busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _busy = false;
      _allowed = true;
    });
    showAuthNotice(context, "You're in the loop! Notifications are on.");
  }

  void _later() {
    if (widget.role == UserRole.volunteer) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      Navigator.of(context).push(softRoute(const VolunteerHomeScreen()));
      return;
    }
    showAuthNotice(context, 'The coordinator home is coming soon.');
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key != LogicalKeyboardKey.enter &&
        key != LogicalKeyboardKey.numpadEnter) {
      return KeyEventResult.ignored;
    }
    _allowed ? _later() : _allow();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: AppColors.backdrop.first,
        body: Focus(
          autofocus: true,
          onKeyEvent: _onKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest;
              final wide =
                  size.width >= OnboardingLayout.wideBreakpoint &&
                  size.width > size.height;
              return AnimatedBuilder(
                animation: Listenable.merge([_intro, _ambient]),
                builder: (context, _) => Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: SoftBackdropPainter(time: _ambient.value),
                      ),
                    ),
                    const Positioned.fill(
                      child: RepaintBoundary(
                        child: CustomPaint(painter: DotTexturePainter()),
                      ),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _ScenePainter(
                            photo: _photo.image,
                            time: _ambient.value,
                            reveal: _rise(0),
                            appear: _rise(5),
                            wide: wide,
                          ),
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
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Phone layout
  // ---------------------------------------------------------------------------

  Widget _buildCompact(Size size) {
    final sy = size.height / OnboardingLayout.designHeight;
    final s = math.min(size.width / OnboardingLayout.designWidth, sy);
    // On tablets held upright, keep the buttons a comfortable width.
    final width = math.min(size.width, 520 * s);
    final sx = width / OnboardingLayout.designWidth;
    final top = MediaQuery.paddingOf(context).top;
    final bell = 150 * s;
    final hero = bell * _BellHero.extent;

    return Center(
      child: SizedBox(
        width: width,
        child: Stack(
          children: [
            if (Navigator.of(context).canPop())
              Positioned(
                top: math.max(top + 6 * s, 96 * sy - 20 * s),
                left: 22 * sx,
                child: RiseIn(
                  progress: _rise(0),
                  distance: -10 * s,
                  child: _backButton(s),
                ),
              ),
            Positioned(
              top: 259 * sy - hero / 2,
              left: 0,
              right: 0,
              child: Center(child: _bellHero(bell, onPhoto: false)),
            ),
            Positioned(
              top: 362 * sy,
              left: 24 * sx,
              right: 24 * sx,
              child: RiseIn(
                progress: _rise(2),
                distance: 20 * s,
                child: Center(child: _title(36 * s)),
              ),
            ),
            Positioned(
              top: 428 * sy,
              left: 24 * sx,
              right: 24 * sx,
              child: RiseIn(
                progress: _rise(3),
                distance: 14 * s,
                child: Text(
                  'Get notified about new events,\n'
                  'updates and impact stories.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16 * s,
                    height: 1.75,
                    color: AppColors.bodyText,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 518 * sy,
              left: 20 * sx,
              right: 20 * sx,
              child: RiseIn(
                progress: _rise(4),
                distance: 14 * s,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final (i, (icon, label, _)) in _topics.indexed) ...[
                        if (i > 0) SizedBox(width: 8 * s),
                        _TopicChip(icon: icon, label: label, scale: s),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 613 * sy,
              left: 40 * sx,
              right: 40 * sx,
              child: RiseIn(
                progress: _rise(5),
                distance: 18 * s,
                child: _allowButton(s),
              ),
            ),
            Positioned(
              top: 707 * sy,
              left: 40 * sx,
              right: 40 * sx,
              child: RiseIn(
                progress: _rise(6),
                distance: 18 * s,
                child: _laterButton(s),
              ),
            ),
            Positioned(
              top: 790 * sy,
              left: 24 * sx,
              right: 24 * sx,
              child: RiseIn(
                progress: _rise(7),
                distance: 10 * s,
                child: Center(child: _settingsNote(s)),
              ),
            ),
            Positioned(
              top: 834 * sy,
              left: 0,
              right: 0,
              child: Center(child: _dots(s)),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Laptop layout
  // ---------------------------------------------------------------------------

  Widget _buildWide(Size size) {
    final s = math.min(size.width / 1280, size.height / 800).clamp(0.7, 1.4);
    final sceneHeight = math.min(500 * s, size.height * 0.68);

    return Stack(
      children: [
        Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(top: 100 * s, bottom: 32 * s),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 72 * s),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RiseIn(
                          progress: _rise(1),
                          distance: 14 * s,
                          child: _stepChip(s),
                        ),
                        SizedBox(height: 18 * s),
                        RiseIn(
                          progress: _rise(1),
                          distance: 24 * s,
                          child: _title(58 * s),
                        ),
                        SizedBox(height: 14 * s),
                        RiseIn(
                          progress: _rise(2),
                          distance: 16 * s,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 440 * s),
                            child: Text(
                              'Get notified about new events, updates and '
                              'impact stories, right when they happen.',
                              style: TextStyle(
                                fontSize: 19 * s,
                                height: 1.65,
                                color: AppColors.bodyText,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 24 * s),
                        RiseIn(
                          progress: _rise(4),
                          distance: 16 * s,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 440 * s),
                            child: _topicsPanel(s),
                          ),
                        ),
                        SizedBox(height: 28 * s),
                        RiseIn(
                          progress: _rise(5),
                          distance: 18 * s,
                          child: Wrap(
                            spacing: 14 * s,
                            runSpacing: 12 * s,
                            children: [
                              SizedBox(
                                width: 250 * s,
                                child: _allowButton(s * 0.9),
                              ),
                              SizedBox(
                                width: 176 * s,
                                child: _laterButton(s * 0.9),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 18 * s),
                        RiseIn(
                          progress: _rise(7),
                          distance: 10 * s,
                          child: _settingsNote(s),
                        ),
                        SizedBox(height: 22 * s),
                        _dots(s),
                      ],
                    ),
                  ),
                  SizedBox(width: 56 * s),
                  Expanded(
                    flex: 6,
                    child: SizedBox(height: sceneHeight, child: _scene(s)),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Back button and brand mark, top-left, like a site header. Drawn
        // last so the scrolling content never covers the back button.
        Positioned(
          top: 32 * s,
          left: 64 * s,
          child: RiseIn(
            progress: _rise(0),
            distance: -10 * s,
            child: Row(
              children: [
                if (Navigator.of(context).canPop()) ...[
                  // Its own node, so it isn't read out as "Back FoodLink".
                  Semantics(container: true, child: _backButton(s)),
                  SizedBox(width: 18 * s),
                ],
                FoodLinkLogo(width: 36 * s),
                SizedBox(width: 12 * s),
                Text(
                  'FoodLink',
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 24 * s,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3 * s,
                    color: AppColors.brandDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Laptops: the bell over the photo, with sample notifications bobbing
  /// above and below it.
  Widget _scene(double s) {
    final wave = _ambient.value * 2 * math.pi * 2;
    return Stack(
      alignment: Alignment.center,
      children: [
        _bellHero(180 * s, onPhoto: true),
        for (final (i, (icon, title, detail)) in _previews.indexed)
          Align(
            alignment: i == 0
                ? const Alignment(-0.85, -1)
                : const Alignment(0.85, 1),
            child: Transform.translate(
              offset: Offset(0, math.sin(wave + i * 2.2) * 5 * s),
              child: RiseIn(
                progress: _rise(6 + i * 2),
                distance: (i == 0 ? -24 : 24) * s,
                child: ExcludeSemantics(
                  child: _PreviewCard(
                    icon: icon,
                    title: title,
                    detail: detail,
                    scale: s,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Shared pieces
  // ---------------------------------------------------------------------------

  Widget _backButton(double s) => AuthIconButton(
    label: 'Back',
    scale: s,
    onTap: () => Navigator.of(context).maybePop(),
    child: Icon(
      Icons.arrow_back_ios_new_rounded,
      size: 18 * s,
      color: AppColors.ink,
    ),
  );

  Widget _bellHero(double diameter, {required bool onPhoto}) => _BellHero(
    diameter: diameter,
    time: _ambient.value,
    appear: _bell.value,
    ringing: _intro.isCompleted && !_allowed,
    allowed: _allowed,
    waveColor: onPhoto ? AppColors.white : AppColors.brand,
  );

  /// "Stay in the Loop", with "Loop" in the brand gradient.
  Widget _title(double fontSize) {
    final style = TextStyle(
      fontFamily: AppFonts.display,
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      letterSpacing: -fontSize * 0.01,
      color: AppColors.ink,
    );
    return Semantics(
      header: true,
      label: 'Stay in the Loop',
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('Stay in the ', style: style),
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) =>
                  const LinearGradient(colors: AppColors.accentGradient)
                      .createShader(bounds),
              child: Text('Loop', style: style),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepChip(double s) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 7 * s),
      decoration: BoxDecoration(
        color: AppColors.roleChosenFill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.roleChosenBorder),
      ),
      child: Text(
        'STEP ${NotificationsScreen.step + 1} OF '
        '${NotificationsScreen.stepCount}',
        style: TextStyle(
          fontSize: 12.5 * s,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4 * s,
          color: AppColors.brandText,
        ),
      ),
    );
  }

  /// Laptops: what each kind of notification is about.
  Widget _topicsPanel(double s) {
    return Container(
      padding: EdgeInsets.fromLTRB(18 * s, 14 * s, 18 * s, 6 * s),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20 * s),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.9)),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.06),
            blurRadius: 20 * s,
            offset: Offset(0, 6 * s),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (icon, label, detail) in _topics)
            Padding(
              padding: EdgeInsets.only(bottom: 10 * s),
              child: Row(
                children: [
                  Container(
                    width: 34 * s,
                    height: 34 * s,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.roleChosenCircle,
                    ),
                    child: Icon(icon, size: 18 * s, color: AppColors.brand),
                  ),
                  SizedBox(width: 12 * s),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 15 * s,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          detail,
                          style: TextStyle(
                            fontSize: 13.5 * s,
                            color: AppColors.bodyText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _allowButton(double s) => PrimaryButton(
    label: _allowed ? 'Notifications On' : 'Allow Notifications',
    scale: s,
    time: _ambient.value,
    loading: _busy,
    onPressed: _allowed ? null : _allow,
  );

  Widget _laterButton(double s) => _QuietButton(
    label: _allowed ? 'Continue' : 'Maybe Later',
    scale: s,
    onPressed: _busy ? null : _later,
  );

  Widget _settingsNote(double s) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.lock_outline_rounded,
          size: 14 * s,
          color: AppColors.fieldIcon,
        ),
        SizedBox(width: 6 * s),
        Flexible(
          child: Text(
            'No spam. Change this anytime in Settings.',
            style: TextStyle(fontSize: 12.5 * s, color: AppColors.fieldIcon),
          ),
        ),
      ],
    );
  }

  Widget _dots(double s) => StepDots(
    count: NotificationsScreen.stepCount,
    current: NotificationsScreen.step,
    scale: s,
    time: _ambient.value,
    appear: _rise(7),
  );
}

/// The bell in its pale green circle, with a red dot on the rim.
///
/// While [ringing], the bell swings every four seconds, the dot pulses and
/// soft rings spread outwards. Once [allowed], the dot becomes a green check.
class _BellHero extends StatelessWidget {
  const _BellHero({
    required this.diameter,
    required this.time,
    required this.appear,
    required this.ringing,
    required this.allowed,
    required this.waveColor,
  });

  /// Size of the whole widget (room for the spreading rings), as a multiple
  /// of the circle's diameter.
  static const double extent = 1.6;

  final double diameter;
  final double time;
  final double appear;
  final bool ringing;
  final bool allowed;
  final Color waveColor;

  @override
  Widget build(BuildContext context) {
    final d = diameter;
    final box = d * extent;
    final cycle = time * 2 % 1.0;
    final swing = ringing && cycle < 0.35
        ? math.sin(cycle / 0.35 * math.pi * 5) * 0.32 * (1 - cycle / 0.35)
        : 0.0;
    final badge = d * 0.17;
    // The badge sits on the rim, up and to the right.
    final reach = d / 2 * math.sqrt1_2;
    final pulse = ringing ? 1 + 0.12 * math.sin(time * 2 * math.pi * 4) : 1.0;

    return Semantics(
      image: true,
      label: allowed ? 'Notifications on' : 'Notification bell',
      excludeSemantics: true,
      child: Transform.scale(
        scale: appear,
        child: SizedBox(
          width: box,
          height: box,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (ringing)
                for (var i = 0; i < 2; i++)
                  Builder(
                    builder: (context) {
                      final phase = (time * 4 + i * 0.5) % 1.0;
                      final size = d * (1 + (extent - 1) * phase);
                      return Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: waveColor.withValues(
                              alpha: 0.4 * (1 - phase),
                            ),
                            width: d * 0.012,
                          ),
                        ),
                      );
                    },
                  ),
              Container(
                width: d,
                height: d,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.roleChosenFill,
                      AppColors.roleChosenCircle,
                    ],
                  ),
                  border: Border.all(color: AppColors.white, width: d * 0.028),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.splashScrim.withValues(alpha: 0.18),
                      blurRadius: d * 0.2,
                      offset: Offset(0, d * 0.07),
                    ),
                  ],
                ),
                child: Transform.rotate(
                  angle: swing,
                  alignment: const Alignment(0, -0.7),
                  child: Icon(
                    Icons.notifications_rounded,
                    size: d * 0.46,
                    color: AppColors.brand,
                  ),
                ),
              ),
              Positioned(
                left: box / 2 + reach - badge,
                top: box / 2 - reach - badge,
                width: badge * 2,
                height: badge * 2,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 450),
                    switchInCurve: Curves.elasticOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: allowed
                        ? Container(
                            key: const ValueKey('on'),
                            width: badge * 1.5,
                            height: badge * 1.5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF3A7550), AppColors.brand],
                              ),
                              border: Border.all(
                                color: AppColors.white,
                                width: badge * 0.14,
                              ),
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              size: badge * 0.95,
                              color: AppColors.white,
                            ),
                          )
                        : Transform.scale(
                            key: const ValueKey('dot'),
                            scale: pulse,
                            child: Container(
                              width: badge,
                              height: badge,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.badge,
                                border: Border.all(
                                  color: AppColors.badgeRing,
                                  width: badge * 0.12,
                                  strokeAlign: BorderSide.strokeAlignOutside,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Phones: a small pill naming one kind of notification.
class _TopicChip extends StatelessWidget {
  const _TopicChip({
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
      padding: EdgeInsets.fromLTRB(9 * s, 7 * s, 12 * s, 7 * s),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.roleChosenBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15 * s, color: AppColors.brand),
          SizedBox(width: 6 * s),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5 * s,
              fontWeight: FontWeight.w600,
              color: AppColors.brandText,
            ),
          ),
        ],
      ),
    );
  }
}

/// Laptops: a sample notification on a frosted card.
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.icon,
    required this.title,
    required this.detail,
    required this.scale,
  });

  final IconData icon;
  final String title;
  final String detail;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final radius = BorderRadius.circular(20 * s);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 330 * s),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: AppColors.splashScrim.withValues(alpha: 0.25),
              blurRadius: 28 * s,
              offset: Offset(0, 12 * s),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: EdgeInsets.fromLTRB(14 * s, 12 * s, 16 * s, 12 * s),
              decoration: BoxDecoration(
                borderRadius: radius,
                color: AppColors.surface.withValues(alpha: 0.9),
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.7),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40 * s,
                    height: 40 * s,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12 * s),
                      color: AppColors.roleChosenCircle,
                    ),
                    child: Icon(icon, size: 21 * s, color: AppColors.brand),
                  ),
                  SizedBox(width: 12 * s),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14.5 * s,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            SizedBox(width: 10 * s),
                            Text(
                              'now',
                              style: TextStyle(
                                fontSize: 12 * s,
                                color: AppColors.fieldHint,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 2 * s),
                        Text(
                          detail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13 * s,
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
      ),
    );
  }
}

/// Soft grey pill for the secondary action, the same size as a
/// [PrimaryButton].
class _QuietButton extends StatefulWidget {
  const _QuietButton({
    required this.label,
    required this.scale,
    required this.onPressed,
  });

  final String label;
  final double scale;
  final VoidCallback? onPressed;

  @override
  State<_QuietButton> createState() => _QuietButtonState();
}

class _QuietButtonState extends State<_QuietButton> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    final enabled = widget.onPressed != null;
    return Semantics(
      button: true,
      label: widget.label,
      enabled: enabled,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: enabled
              ? (_) {
                  setState(() => _pressed = false);
                  widget.onPressed!();
                }
              : null,
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1,
            duration: const Duration(milliseconds: 120),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 68 * s,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: _hovered ? AppColors.fieldBorder : AppColors.socialFill,
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.7),
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  widget.label,
                  key: ValueKey(widget.label),
                  style: TextStyle(
                    fontSize: 18 * s,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink.withValues(
                      alpha: enabled ? 0.85 : 0.4,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const _leafA = LeafShape(
  tipA: Offset(52, 6),
  tipB: Offset(14, 70),
  bulgeLeft: 14,
  bulgeRight: 12,
  color: AppColors.onboardingLeaf,
  veinColor: AppColors.leafVein,
);

const _leafB = LeafShape(
  tipA: Offset(8, 10),
  tipB: Offset(44, 58),
  bulgeLeft: 10,
  bulgeRight: 11,
  color: AppColors.leafLight,
  veinColor: AppColors.leafVein,
);

/// The photo melting into the page (downwards on phones, leftwards on
/// laptops), with green specks drifting up and two leaves swaying at the
/// page edges.
class _ScenePainter extends CustomPainter {
  _ScenePainter({
    required this.photo,
    required this.time,
    required this.reveal,
    required this.appear,
    required this.wide,
  });

  final ui.Image? photo;
  final double time;
  final double reveal;
  final double appear;
  final bool wide;

  static final _specks = LightParticles(
    top: 60,
    bottom: 900,
    count: 16,
    seed: 23,
    color: AppColors.leafLight,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / OnboardingLayout.designWidth;
    final sy = size.height / OnboardingLayout.designHeight;
    final s = wide
        ? math.min(size.width / 1280, size.height / 800).clamp(0.7, 1.4)
        : math.min(sx, sy);

    final image = photo;
    if (image != null && reveal > 0) {
      final rect = wide
          ? Rect.fromLTRB(size.width * 0.44, 0, size.width, size.height)
          : Rect.fromLTWH(0, 0, size.width, 350 * sy);
      canvas.saveLayer(rect, Paint());
      paintPhotoCover(
        canvas,
        image,
        rect,
        // Keep the greenhouse and crop rows in view.
        alignment: wide
            ? const Alignment(-0.5, 0)
            : const Alignment(-0.45, 0.1),
        zoom: 1.05 + 0.04 * math.sin(time * 2 * math.pi),
        opacity: reveal,
      );
      // A light green film so the bell and cards stand out.
      canvas.drawRect(
        rect,
        Paint()
          ..shader = ui.Gradient.linear(rect.topCenter, rect.bottomCenter, [
            AppColors.splashScrim.withValues(
              alpha: (wide ? 0.34 : 0.22) * reveal,
            ),
            AppColors.splashScrim.withValues(
              alpha: (wide ? 0.22 : 0.08) * reveal,
            ),
          ]),
      );
      // Fade the photo out towards the text.
      canvas.drawRect(
        rect.inflate(2),
        Paint()
          ..blendMode = BlendMode.dstIn
          ..shader = wide
              ? ui.Gradient.linear(
                  rect.centerLeft,
                  Offset(rect.left + rect.width * 0.32, rect.center.dy),
                  const [Color(0x00000000), Color(0xFF000000)],
                )
              : ui.Gradient.linear(
                  Offset(rect.center.dx, rect.top + rect.height * 0.42),
                  rect.bottomCenter,
                  const [Color(0xFF000000), Color(0x00000000)],
                ),
      );
      canvas.restore();
    }

    _specks.paint(canvas, sx: sx, sy: sy, time: time, opacity: 0.55 * appear);

    final (a, b) = wide
        ? (
            Offset(size.width * 0.40, 76 * s),
            Offset(40 * s, size.height - 60 * s),
          )
        : (Offset(size.width - 30 * s, 400 * sy), Offset(26 * s, 868 * sy));
    paintSwayingLeaf(
      canvas,
      _leafA,
      target: a,
      scale: s * 0.8,
      time: time,
      appear: appear,
    );
    paintSwayingLeaf(
      canvas,
      _leafB,
      target: b,
      scale: s * 0.7,
      time: time,
      appear: appear,
      phase: 0.6,
      entry: const Offset(-50, 40),
    );
  }

  @override
  bool shouldRepaint(_ScenePainter oldDelegate) => true;
}
