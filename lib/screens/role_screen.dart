import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/foodlink_logo.dart';
import '../widgets/leaf.dart';
import '../widgets/light_particles.dart';
import '../widgets/onboarding_layout.dart';
import '../widgets/pulse_next_button.dart';
import '../widgets/rise_in.dart';
import '../widgets/soft_backdrop.dart';
import '../widgets/step_dots.dart';

/// How someone will use FoodLink.
enum UserRole { volunteer, coordinator }

/// Copy and icons for each role.
class _RoleInfo {
  const _RoleInfo({
    required this.title,
    required this.lines,
    required this.icon,
    required this.photo,
    required this.photoFocus,
    required this.perksTitle,
    required this.perks,
  });

  final String title;

  /// Card description, one short line each (as in the design).
  final List<String> lines;
  final IconData icon;

  /// Asset path of the card photo, and the point to keep in view when it's
  /// cropped.
  final String photo;
  final Alignment photoFocus;
  final String perksTitle;
  final List<(IconData, String)> perks;
}

const _roles = {
  UserRole.volunteer: _RoleInfo(
    title: 'Volunteer',
    lines: ['Join events,', 'help on-ground,', 'make a difference.'],
    icon: Icons.person_rounded,
    // Two volunteers packing boxes of food.
    photo: 'assets/images/role_volunteer.jpg',
    photoFocus: Alignment(0.1, -0.3),
    perksTitle: "As a volunteer, you'll",
    perks: [
      (Icons.event_available_rounded, 'Find food drives near you'),
      (Icons.schedule_rounded, 'Pick shifts that fit your day'),
      (Icons.favorite_rounded, 'See the meals you helped serve'),
    ],
  ),
  UserRole.coordinator: _RoleInfo(
    title: 'Coordinator',
    lines: ['Manage events,', 'organize volunteers,', 'track impact.'],
    icon: Icons.work_rounded,
    // A coordinator with a clipboard, her volunteer team behind her.
    photo: 'assets/images/role_coordinator.jpg',
    photoFocus: Alignment(0.25, -0.2),
    perksTitle: "As a coordinator, you'll",
    perks: [
      (Icons.add_location_alt_rounded, 'Set up distribution events'),
      (Icons.groups_rounded, 'Assign and update volunteers'),
      (Icons.insights_rounded, 'Track impact in real time'),
    ],
  ),
};

/// Account setup, step 3 of 5: "I am a..." — Volunteer or Coordinator.
///
/// Two photo cards (Volunteer chosen to start, as in the design). The chosen card
/// turns green with a check badge and a pulsing halo round its icon, and a
/// panel below lists what that role can do. Arrow keys switch roles and Enter
/// continues, for keyboards on the web.
///
/// Phones follow the Figma frame; laptops get two columns: title, perks and
/// next button left, larger cards right.
///
/// The next setup step isn't designed yet, so Next confirms the choice with
/// a notice for now.
class RoleScreen extends StatefulWidget {
  const RoleScreen({super.key});

  static const int stepCount = 5;
  static const int step = 2;

  @override
  State<RoleScreen> createState() => _RoleScreenState();
}

class _RoleScreenState extends State<RoleScreen> with TickerProviderStateMixin {
  UserRole _role = UserRole.volunteer;

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..forward();

  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  late final _button = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.55, 1.0, curve: Curves.elasticOut),
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
    // Decode both card photos up front so neither pops in.
    for (final info in _roles.values) {
      precacheImage(AssetImage(info.photo), context);
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _ambient.dispose();
    super.dispose();
  }

  void _choose(UserRole role) {
    if (role == _role) return;
    HapticFeedback.selectionClick();
    setState(() => _role = role);
  }

  void _continue() {
    showAuthNotice(
      context,
      "You're joining as a ${_roles[_role]!.title}. "
      'The next setup step is coming soon.',
    );
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.digit1) {
      _choose(UserRole.volunteer);
    } else if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.digit2) {
      _choose(UserRole.coordinator);
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      _continue();
    } else {
      return KeyEventResult.ignored;
    }
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
                          painter: _DecorPainter(
                            time: _ambient.value,
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
    // On tablets held upright, keep the cards a comfortable width.
    final width = math.min(size.width, 520 * s);
    final sx = width / OnboardingLayout.designWidth;
    final top = MediaQuery.paddingOf(context).top;
    final cardsTop = 224 * sy;
    final cardHeight = 345 * s;
    final buttonOuter = 88 * s;

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
              top: 130 * sy,
              left: 24 * sx,
              right: 24 * sx,
              child: RiseIn(
                progress: _rise(1),
                distance: 20 * s,
                child: Center(child: _title(38 * s)),
              ),
            ),
            Positioned(
              top: 182 * sy,
              left: 24 * sx,
              right: 24 * sx,
              child: RiseIn(
                progress: _rise(2),
                distance: 14 * s,
                child: Text(
                  "Choose how you'd like to help",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15 * s, color: AppColors.bodyText),
                ),
              ),
            ),
            Positioned(
              top: cardsTop,
              left: 31 * sx,
              right: 31 * sx,
              height: cardHeight,
              child: _cardRow(s, gap: 16 * sx),
            ),
            Positioned(
              top: cardsTop + cardHeight + 18 * s,
              left: 31 * sx,
              right: 31 * sx,
              child: RiseIn(
                progress: _rise(6),
                distance: 16 * s,
                child: _perksPanel(s),
              ),
            ),
            Positioned(left: 42 * sx, top: 790 * sy - 6 * s, child: _dots(s)),
            Positioned(
              left: 335 * sx - buttonOuter / 2,
              top: 790 * sy - buttonOuter / 2,
              child: _nextButton(78 * s),
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
    final cardHeight = math.min(440 * s, size.height * 0.62);

    return Stack(
      children: [
        // Back button and brand mark, top-left, like a site header.
        Positioned(
          top: 32 * s,
          left: 64 * s,
          child: RiseIn(
            progress: _rise(0),
            distance: -10 * s,
            child: Row(
              children: [
                if (Navigator.of(context).canPop()) ...[
                  _backButton(s),
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
        Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(top: 100 * s, bottom: 32 * s),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 1240 * s),
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
                            child: _title(60 * s),
                          ),
                          SizedBox(height: 16 * s),
                          RiseIn(
                            progress: _rise(2),
                            distance: 16 * s,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: 430 * s),
                              child: Text(
                                "Tell us how you'd like to help, and we'll "
                                'shape FoodLink around you. You can switch '
                                'roles anytime.',
                                style: TextStyle(
                                  fontSize: 19 * s,
                                  height: 1.65,
                                  color: AppColors.bodyText,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 28 * s),
                          RiseIn(
                            progress: _rise(6),
                            distance: 16 * s,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: 430 * s),
                              child: _perksPanel(s),
                            ),
                          ),
                          SizedBox(height: 36 * s),
                          Row(
                            children: [
                              _nextButton(72 * s),
                              SizedBox(width: 24 * s),
                              _dots(s),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 56 * s),
                    Expanded(
                      flex: 6,
                      child: SizedBox(
                        height: cardHeight,
                        child: _cardRow(s * 1.2, gap: 24 * s),
                      ),
                    ),
                  ],
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

  /// "I am a..." with the three dots hopping in a gentle wave.
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
      label: 'I am a...',
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('I am a', style: style),
            for (var i = 0; i < 3; i++)
              Transform.translate(
                offset: Offset(0, -_hop(i) * fontSize * 0.14),
                child: ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) =>
                      const LinearGradient(colors: AppColors.accentGradient)
                          .createShader(bounds),
                  child: Text('.', style: style),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// How high dot [i] of the title's ellipsis is right now (0–1): one wave
  /// every two seconds, once the entrance is done.
  double _hop(int i) {
    if (!_intro.isCompleted) return 0;
    final phase = (_ambient.value * 4 - i * 0.1) % 1.0;
    return phase < 0.3 ? math.sin(phase / 0.3 * math.pi) : 0;
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
        'STEP ${RoleScreen.step + 1} OF ${RoleScreen.stepCount}',
        style: TextStyle(
          fontSize: 12.5 * s,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4 * s,
          color: AppColors.brandText,
        ),
      ),
    );
  }

  Widget _cardRow(double s, {required double gap}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, role) in UserRole.values.indexed) ...[
          if (i > 0) SizedBox(width: gap),
          Expanded(
            child: _CardEntrance(
              progress: _rise(3 + i),
              scale: s,
              child: _RoleCard(
                info: _roles[role]!,
                selected: _role == role,
                scale: s,
                time: _ambient.value,
                onTap: () => _choose(role),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// What the chosen role can do; cross-fades when the role changes.
  Widget _perksPanel(double s) {
    final info = _roles[_role]!;
    return Container(
      padding: EdgeInsets.fromLTRB(18 * s, 14 * s, 18 * s, 12 * s),
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
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topLeft,
          children: [...previous, ?current],
        ),
        child: Column(
          key: ValueKey(_role),
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              info.perksTitle,
              style: TextStyle(
                fontSize: 13 * s,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2 * s,
                color: AppColors.brandText,
              ),
            ),
            SizedBox(height: 8 * s),
            for (final (icon, label) in info.perks)
              Padding(
                padding: EdgeInsets.only(bottom: 4 * s),
                child: Row(
                  children: [
                    Container(
                      width: 24 * s,
                      height: 24 * s,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.roleChosenCircle,
                      ),
                      child: Icon(icon, size: 14 * s, color: AppColors.brand),
                    ),
                    SizedBox(width: 10 * s),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 14.5 * s,
                          fontWeight: FontWeight.w500,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _dots(double s) => StepDots(
    count: RoleScreen.stepCount,
    current: RoleScreen.step,
    scale: s,
    time: _ambient.value,
    appear: _rise(7),
  );

  Widget _nextButton(double diameter) => PulseNextButton(
    diameter: diameter,
    time: _ambient.value,
    appear: _button.value,
    showHalo: _intro.isCompleted,
    onPressed: _continue,
  );
}

/// Rises a card in while it settles from a slight shrink.
class _CardEntrance extends StatelessWidget {
  const _CardEntrance({
    required this.progress,
    required this.scale,
    required this.child,
  });

  final double progress;
  final double scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RiseIn(
      progress: progress,
      distance: 30 * scale,
      child: Transform.scale(scale: 0.94 + 0.06 * progress, child: child),
    );
  }
}

/// One role option: a photo on top with the role's icon badge sitting on its
/// lower edge, then the title and description.
///
/// Chosen: soft green, the photo in full colour and slowly zooming, a check
/// badge, and a pulsing halo round a gently floating icon. Not chosen: cool
/// grey with the photo faded to near-greyscale. Lifts on hover and dips when
/// pressed.
class _RoleCard extends StatefulWidget {
  const _RoleCard({
    required this.info,
    required this.selected,
    required this.scale,
    required this.time,
    required this.onTap,
  });

  final _RoleInfo info;
  final bool selected;
  final double scale;
  final double time;
  final VoidCallback onTap;

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _hovered = false;
  bool _pressed = false;

  /// Colour matrix that blends between greyscale (0) and full colour (1).
  static List<double> _saturation(double amount) {
    const r = 0.2126, g = 0.7152, b = 0.0722;
    final a = amount;
    final i = 1 - a;
    return [
      r * i + a, g * i, b * i, 0, 0, //
      r * i, g * i + a, b * i, 0, 0, //
      r * i, g * i, b * i + a, 0, 0, //
      0, 0, 0, 1, 0, //
    ];
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    final selected = widget.selected;
    final info = widget.info;
    const duration = Duration(milliseconds: 320);
    final radius = BorderRadius.circular(22 * s);
    final inset = 8 * s;
    final wave = widget.time * 4 % 1.0; // one halo pulse every 2 seconds
    final float = selected
        ? math.sin(widget.time * 2 * math.pi * 3) * 3 * s
        : 0.0;
    final circle = 56 * s;

    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: '${info.title}. ${info.lines.join(' ')}',
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
            scale: _pressed ? 0.97 : 1,
            duration: const Duration(milliseconds: 120),
            child: AnimatedContainer(
              duration: duration,
              curve: Curves.easeOutCubic,
              transform: Matrix4.translationValues(0, _hovered ? -5 * s : 0, 0),
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: selected
                      ? [
                          AppColors.roleChosenFill,
                          Color.lerp(
                            AppColors.roleChosenFill,
                            AppColors.roleChosenCircle,
                            0.45,
                          )!,
                        ]
                      : [
                          AppColors.roleIdleFill.withValues(alpha: 0.95),
                          AppColors.roleIdleFill,
                        ],
                ),
                border: Border.all(
                  color: selected
                      ? AppColors.roleChosenBorder
                      : AppColors.roleIdleBorder,
                  width: selected ? 1.6 : 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brand.withValues(
                      alpha: selected
                          ? 0.16
                          : _hovered
                          ? 0.10
                          : 0.0,
                    ),
                    blurRadius: 30 * s,
                    offset: Offset(0, 12 * s),
                  ),
                ],
              ),
              // 0 → 1 as the card becomes the chosen one.
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
                tween: Tween(end: selected ? 1 : 0),
                builder: (context, t, _) => Stack(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(inset, inset, inset, 14 * s),
                      child: Column(
                        children: [
                          Expanded(
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.bottomCenter,
                              children: [
                                Positioned.fill(child: _photo(s, t)),
                                Positioned(
                                  bottom: -circle / 2 - circle * 0.25,
                                  child: _iconBadge(
                                    s,
                                    circle,
                                    t,
                                    wave: wave,
                                    float: float,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: circle / 2 + 12 * s),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              info.title,
                              style: TextStyle(
                                fontFamily: AppFonts.display,
                                fontSize: 22 * s,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          SizedBox(height: 6 * s),
                          for (final line in info.lines)
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                line,
                                style: TextStyle(
                                  fontSize: 14 * s,
                                  height: 1.7,
                                  color: AppColors.bodyText,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Check badge, springing in on the chosen card.
                    Positioned(
                      top: 16 * s,
                      right: 16 * s,
                      child: AnimatedScale(
                        scale: selected ? 1 : 0,
                        duration: const Duration(milliseconds: 500),
                        curve: selected ? Curves.elasticOut : Curves.easeIn,
                        child: Container(
                          width: 26 * s,
                          height: 26 * s,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3A7550), AppColors.brand],
                            ),
                            border: Border.all(
                              color: AppColors.white,
                              width: 2 * s,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 8 * s,
                                offset: Offset(0, 2 * s),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            size: 15 * s,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The role's photo: colour and a slow zoom fade in with [t].
  Widget _photo(double s, double t) {
    final zoom = 1.04 + 0.05 * t * math.sin(widget.time * 2 * math.pi);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16 * s),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColorFiltered(
            colorFilter: ColorFilter.matrix(_saturation(0.2 + 0.8 * t)),
            child: Transform.scale(
              scale: zoom,
              child: Image.asset(
                widget.info.photo,
                fit: BoxFit.cover,
                alignment: widget.info.photoFocus,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) =>
                    const ColoredBox(color: AppColors.roleIdleCircle),
              ),
            ),
          ),
          // Soft green wash at the foot so the icon badge sits comfortably,
          // and a pale veil over the photo when not chosen.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.splashScrim.withValues(alpha: 0),
                  AppColors.splashScrim.withValues(alpha: 0.35),
                ],
                stops: const [0.55, 1],
              ),
            ),
          ),
          ColoredBox(
            color: AppColors.roleIdleFill.withValues(alpha: 0.28 * (1 - t)),
          ),
        ],
      ),
    );
  }

  /// The role's icon in a ringed circle, with a pulsing halo when chosen.
  Widget _iconBadge(
    double s,
    double circle,
    double t, {
    required double wave,
    required double float,
  }) {
    return SizedBox(
      width: circle * 1.5,
      height: circle * 1.5,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (t > 0)
            Container(
              width: circle * (1 + 0.45 * wave),
              height: circle * (1 + 0.45 * wave),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.brand.withValues(
                    alpha: 0.3 * t * (1 - wave),
                  ),
                  width: 2 * s,
                ),
              ),
            ),
          Transform.translate(
            offset: Offset(0, float),
            child: Container(
              width: circle,
              height: circle,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.lerp(
                  AppColors.roleIdleCircle,
                  AppColors.roleChosenCircle,
                  t,
                ),
                border: Border.all(color: AppColors.white, width: 3 * s),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.splashScrim.withValues(alpha: 0.18),
                    blurRadius: 12 * s,
                    offset: Offset(0, 4 * s),
                  ),
                ],
              ),
              child: Icon(
                widget.info.icon,
                size: 26 * s,
                color: Color.lerp(AppColors.roleIdleIcon, AppColors.brand, t),
              ),
            ),
          ),
        ],
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

/// Two leaves swaying at the page edges and faint green specks drifting up.
class _DecorPainter extends CustomPainter {
  _DecorPainter({required this.time, required this.appear, required this.wide});

  final double time;
  final double appear;
  final bool wide;

  static final _specks = LightParticles(
    top: 60,
    bottom: 900,
    count: 16,
    seed: 11,
    color: AppColors.leafLight,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / OnboardingLayout.designWidth;
    final sy = size.height / OnboardingLayout.designHeight;
    final s = wide
        ? math.min(size.width / 1280, size.height / 800).clamp(0.7, 1.4)
        : math.min(sx, sy);

    _specks.paint(canvas, sx: sx, sy: sy, time: time, opacity: 0.55 * appear);

    final (a, b) = wide
        ? (
            Offset(size.width - 70 * s, 70 * s),
            Offset(40 * s, size.height - 60 * s),
          )
        : (Offset(size.width - 34 * s, 112 * sy), Offset(26 * s, 868 * sy));
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
  bool shouldRepaint(_DecorPainter oldDelegate) => true;
}
