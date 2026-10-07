import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../navigation/tab_navigation.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import 'app_nav.dart';
import 'asset_photo.dart';
import 'auth_widgets.dart';
import 'onboarding_layout.dart';
import 'page_scene.dart';
import 'rise_in.dart';
import 'soft_backdrop.dart';

/// What a coordinator page's body is built with.
class CoordinatorPageContext {
  const CoordinatorPageContext({
    required this.scale,
    required this.wide,
    required this.time,
  });

  final double scale;
  final bool wide;

  /// The looping ambient clock (0–1).
  final double time;
}

/// The frame shared by the coordinator's pages: a soft backdrop with
/// [photo] washed in behind the title, drifting specks and a swaying leaf;
/// Back and the avatar (opening the coordinator's profile); the title
/// ([centerTitle] puts it in the header, as on Create Event); then [body]
/// rising in piece by piece, with an optional [action] pinned at the
/// bottom.
///
/// Phones get the coordinator's bottom bar ([showBar]) with [tab] in green;
/// laptops get the side rail and a centred column.
class CoordinatorPage extends StatefulWidget {
  const CoordinatorPage({
    super.key,
    required this.tab,
    required this.title,
    required this.photo,
    required this.body,
    this.subtitle,
    this.action,
    this.centerTitle = false,
    this.showBar = true,
    this.photoFocus = Alignment.center,
    this.listenTo,
    this.maxWidth = 900,
  });

  final CoordinatorTab tab;
  final String title;
  final String? subtitle;
  final String photo;
  final Alignment photoFocus;
  final List<Widget> Function(BuildContext context, CoordinatorPageContext c)
  body;
  final Widget Function(CoordinatorPageContext c)? action;
  final bool centerTitle;
  final bool showBar;

  /// Rebuilds the page when this changes.
  final Listenable? listenTo;
  final double maxWidth;

  @override
  State<CoordinatorPage> createState() => _CoordinatorPageState();
}

class _CoordinatorPageState extends State<CoordinatorPage>
    with TickerProviderStateMixin {
  late final AssetPhoto _photo = AssetPhoto(widget.photo);

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..forward();

  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

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
    _intro.dispose();
    _ambient.dispose();
    _photo.dispose();
    super.dispose();
  }

  void _openTab(CoordinatorTab tab) =>
      openCoordinatorTab(context, widget.tab, tab);

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
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          excludeFromSemantics: true,
          onTap: () => FocusScope.of(context).unfocus(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest;
              final wide =
                  size.width >= OnboardingLayout.wideBreakpoint &&
                  size.width > size.height;
              final s = wide
                  ? math
                        .min(size.width / 1280, size.height / 800)
                        .clamp(0.75, 1.25)
                  : math.min(
                      size.width / OnboardingLayout.designWidth,
                      size.height / OnboardingLayout.designHeight,
                    );
              final railWidth = wide ? 224 * s : 0.0;
              return AnimatedBuilder(
                animation: Listenable.merge([
                  _intro,
                  _ambient,
                  ?widget.listenTo,
                ]),
                builder: (context, _) {
                  final c = CoordinatorPageContext(
                    scale: s,
                    wide: wide,
                    time: _ambient.value,
                  );
                  return Stack(
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
                            painter: PageScenePainter(
                              photo: _photo.image,
                              time: _ambient.value,
                              reveal: _rise(0),
                              appear: _rise(4),
                              left: railWidth,
                              scale: s,
                              height: 280,
                              focus: widget.photoFocus,
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: wide
                            ? _wide(context, size, c, railWidth)
                            : _compact(context, size, c),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, CoordinatorPageContext c) {
    final s = c.scale;
    var n = 2;
    return [
      RiseIn(progress: _rise(0), distance: -10 * s, child: _header(s)),
      if (!widget.centerTitle) ...[
        SizedBox(height: 20 * s),
        RiseIn(
          progress: _rise(1),
          distance: 18 * s,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  widget.title,
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: (c.wide ? 46 : 34) * s,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              if (widget.subtitle case final subtitle?) ...[
                SizedBox(height: 6 * s),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 15.5 * s,
                    color: AppColors.bodyText,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
      SizedBox(height: 22 * s),
      for (final child in widget.body(context, c))
        RiseIn(progress: _rise(n++), distance: 18 * s, child: child),
    ];
  }

  Widget _header(double s) {
    final back = Navigator.of(context).canPop()
        ? AuthIconButton(
            label: 'Back',
            scale: s,
            onTap: () => Navigator.of(context).maybePop(),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18 * s,
              color: AppColors.ink,
            ),
          )
        : SizedBox(width: 44 * s);
    final avatar = widget.tab == CoordinatorTab.profile
        ? SizedBox(width: 44 * s)
        : AuthAvatar(
            scale: s * 1.1,
            onTap: () => _openTab(CoordinatorTab.profile),
          );
    return Row(
      children: [
        back,
        Expanded(
          child: widget.centerTitle
              ? Semantics(
                  header: true,
                  child: Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 22 * s,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                )
              : const SizedBox(),
        ),
        avatar,
      ],
    );
  }

  Widget _compact(BuildContext context, Size size, CoordinatorPageContext c) {
    final s = c.scale;
    final width = math.min(size.width, 560 * s) - 48 * s;
    final action = widget.action;
    return Column(
      children: [
        Expanded(
          child: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(24 * s, 14 * s, 24 * s, 24 * s),
              child: Center(
                child: SizedBox(
                  width: width,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _content(context, c),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (action != null)
          Padding(
            padding: EdgeInsets.fromLTRB(24 * s, 8 * s, 24 * s, 14 * s),
            child: SafeArea(
              top: false,
              bottom: !widget.showBar,
              child: Center(
                child: SizedBox(
                  width: width,
                  child: RiseIn(
                    progress: _rise(4),
                    distance: 30 * s,
                    child: action(c),
                  ),
                ),
              ),
            ),
          ),
        if (widget.showBar)
          CoordinatorBottomBar(
            current: widget.tab,
            scale: s,
            onSelect: _openTab,
          ),
      ],
    );
  }

  Widget _wide(
    BuildContext context,
    Size size,
    CoordinatorPageContext c,
    double railWidth,
  ) {
    final s = c.scale;
    final action = widget.action;
    return Row(
      children: [
        SizedBox(
          width: railWidth,
          child: CoordinatorSideRail(
            current: widget.tab,
            scale: s,
            onSelect: _openTab,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(vertical: 30 * s, horizontal: 48 * s),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: widget.maxWidth * s),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ..._content(context, c),
                    if (action != null) ...[
                      SizedBox(height: 24 * s),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(width: 380 * s, child: action(c)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A frosted white card, for groups on coordinator pages.
class CoordinatorCard extends StatelessWidget {
  const CoordinatorCard({
    super.key,
    required this.scale,
    required this.child,
    this.padding,
  });

  final double scale;
  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Container(
      padding: padding ?? EdgeInsets.all(16 * s),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(22 * s),
        border: Border.all(color: AppColors.white),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.07),
            blurRadius: 24 * s,
            offset: Offset(0, 9 * s),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// The Figma's tab strip: a soft grey track with the chosen tab white and
/// underlined in green.
class CoordinatorTabs<T> extends StatelessWidget {
  const CoordinatorTabs({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.scale,
    required this.onChanged,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final double scale;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final index = values.indexOf(selected);
    return Container(
      height: 52 * s,
      padding: EdgeInsets.all(4 * s),
      decoration: BoxDecoration(
        color: AppColors.socialFill.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16 * s),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth / values.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                left: width * index,
                top: 0,
                bottom: 0,
                width: width,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(13 * s),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.ink.withValues(alpha: 0.08),
                        blurRadius: 10 * s,
                        offset: Offset(0, 3 * s),
                      ),
                    ],
                  ),
                  alignment: Alignment.bottomCenter,
                  padding: EdgeInsets.only(bottom: 4 * s),
                  child: FractionallySizedBox(
                    widthFactor: 0.55,
                    child: Container(
                      height: 3 * s,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: AppColors.accentGradient,
                        ),
                        borderRadius: BorderRadius.circular(2 * s),
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  for (final value in values)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: value == selected,
                        label: '${label(value)} tab',
                        excludeSemantics: true,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              if (value == selected) return;
                              HapticFeedback.selectionClick();
                              onChanged(value);
                            },
                            child: Center(
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 220),
                                style: TextStyle(
                                  fontFamily: AppFonts.body,
                                  fontSize: 15 * s,
                                  fontWeight: value == selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: value == selected
                                      ? AppColors.brand
                                      : AppColors.fieldIcon,
                                ),
                                child: Text(label(value)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The grey search field from the Figma.
class CoordinatorSearch extends StatelessWidget {
  const CoordinatorSearch({
    super.key,
    required this.controller,
    required this.hint,
    required this.scale,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final double scale;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Container(
      height: 50 * s,
      padding: EdgeInsets.only(left: 16 * s, right: 8 * s),
      decoration: BoxDecoration(
        color: AppColors.socialFill.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(25 * s),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 21 * s, color: AppColors.fieldIcon),
          SizedBox(width: 10 * s),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              cursorColor: AppColors.brand,
              style: TextStyle(fontSize: 15 * s, color: AppColors.ink),
              decoration: InputDecoration.collapsed(
                hintText: hint,
                hintStyle: TextStyle(
                  fontSize: 15 * s,
                  color: AppColors.fieldHint,
                ),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            Semantics(
              button: true,
              label: 'Clear search',
              excludeSemantics: true,
              child: GestureDetector(
                onTap: () {
                  controller.clear();
                  onChanged('');
                },
                child: Padding(
                  padding: EdgeInsets.all(6 * s),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18 * s,
                    color: AppColors.fieldIcon,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A round avatar with initials (or a person, for [person]).
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    required this.initials,
    required this.colors,
    required this.size,
    this.person = false,
    this.dot,
  });

  final String initials;
  final List<Color> colors;
  final double size;
  final bool person;

  /// A small coloured dot at the corner.
  final Color? dot;

  @override
  Widget build(BuildContext context) {
    final d = size;
    return SizedBox.square(
      dimension: d,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: d,
            height: d,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: colors,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.last.withValues(alpha: 0.25),
                  blurRadius: d * 0.2,
                  offset: Offset(0, d * 0.06),
                ),
              ],
            ),
            child: person
                ? Icon(
                    Icons.person_rounded,
                    size: d * 0.58,
                    color: const Color(0xFFF3E4D6),
                  )
                : Text(
                    initials,
                    style: TextStyle(
                      fontSize: d * 0.33,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
          ),
          if (dot case final dot?)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: d * 0.26,
                height: d * 0.26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dot,
                  border: Border.all(color: AppColors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A coloured status pill: Ongoing, Upcoming, Confirmed, Pending...
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.fill,
    required this.ink,
    required this.scale,
  });

  final String label;
  final Color fill;
  final Color ink;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9 * s, vertical: 3 * s),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(10 * s),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12 * s,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
      ),
    );
  }
}

/// A list row that lifts on hover and dips when pressed, with a chevron.
class TappableRow extends StatefulWidget {
  const TappableRow({
    super.key,
    required this.label,
    required this.scale,
    required this.onTap,
    required this.child,
    this.chevron = true,
  });

  final String label;
  final double scale;
  final VoidCallback onTap;
  final Widget child;
  final bool chevron;

  @override
  State<TappableRow> createState() => _TappableRowState();
}

class _TappableRowState extends State<TappableRow> {
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
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) {
            setState(() => _pressed = false);
            HapticFeedback.selectionClick();
            widget.onTap();
          },
          child: AnimatedScale(
            scale: _pressed ? 0.98 : 1,
            duration: const Duration(milliseconds: 120),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                vertical: 14 * s,
                horizontal: 6 * s,
              ),
              decoration: BoxDecoration(
                color: _hovered
                    ? AppColors.white.withValues(alpha: 0.7)
                    : AppColors.white.withValues(alpha: 0),
                borderRadius: BorderRadius.circular(16 * s),
              ),
              child: Row(
                children: [
                  Expanded(child: widget.child),
                  if (widget.chevron)
                    AnimatedSlide(
                      offset: Offset(_hovered ? 0.3 : 0, 0),
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 26 * s,
                        color: _hovered ? AppColors.brand : AppColors.fieldIcon,
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

/// A divider line between list rows.
Widget rowDivider() => Container(height: 1, color: AppColors.fieldBorder);
