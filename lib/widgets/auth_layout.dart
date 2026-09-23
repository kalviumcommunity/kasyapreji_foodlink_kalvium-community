import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import 'asset_photo.dart';
import 'auth_widgets.dart';
import 'foodlink_logo.dart';
import 'leaf.dart';
import 'light_particles.dart';
import 'onboarding_layout.dart';
import 'rise_in.dart';

/// Values handed to an auth screen's form builder.
class AuthFormArgs {
  const AuthFormArgs({
    required this.scale,
    required this.gap,
    required this.time,
    required this.rise,
  });

  /// Size scale for text and controls.
  final double scale;

  /// Multiplier for vertical spacing (tighter on phones, under the photo).
  final double gap;

  /// Looping 0–1 ambient clock (for the button's light sweep).
  final double time;

  /// Staggered entrance progress (0–1) for the n-th element from the top.
  final double Function(int n) rise;

  /// Vertical space of [h] design units.
  SizedBox space(double h) => SizedBox(height: h * scale * gap);
}

typedef AuthFormBuilder = Widget Function(BuildContext, AuthFormArgs);

/// Shared frame for the sign-in and sign-up screens.
///
/// The [photo] fills the background under a deep green film with drifting
/// light. Phones show it whole in a rounded card over a soft blurred fill,
/// with the form below in a frosted-glass card; laptops show it full-bleed
/// with a brand story ([quote], [caption], [features]) on the left and the
/// glass form card on the right.
class AuthLayout extends StatefulWidget {
  const AuthLayout({
    super.key,
    required this.photo,
    required this.quote,
    required this.caption,
    required this.features,
    required this.form,
    this.photoFocus = Alignment.center,
  });

  /// Asset path of the background photo.
  final String photo;
  final Alignment photoFocus;
  final String quote;
  final String caption;
  final List<(IconData, String)> features;
  final AuthFormBuilder form;

  @override
  State<AuthLayout> createState() => _AuthLayoutState();
}

class _AuthLayoutState extends State<AuthLayout> with TickerProviderStateMixin {
  late final _photo = AssetPhoto(widget.photo);

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
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
              animation: Listenable.merge([_intro, _ambient]),
              builder: (context, _) => Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _BackgroundPainter(
                        photo: _photo.image,
                        focus: widget.photoFocus,
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
    final args = AuthFormArgs(
      scale: s,
      gap: 0.5,
      time: _ambient.value,
      rise: _rise,
    );

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
                      child: widget.form(context, args),
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
    final args = AuthFormArgs(
      scale: s,
      gap: 0.55,
      time: _ambient.value,
      rise: _rise,
    );
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
                      leafAtBottom: true,
                      padding: EdgeInsets.fromLTRB(
                        32 * s,
                        26 * s,
                        32 * s,
                        26 * s,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _headerRow(s),
                          SizedBox(height: 12 * s * args.gap),
                          widget.form(context, args),
                        ],
                      ),
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

  /// Laptop left side: brand, quote and what FoodLink does, on the photo.
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
            widget.quote,
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
              widget.caption,
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
              for (final (icon, label) in widget.features)
                _FeatureChip(icon: icon, label: label, scale: s),
            ],
          ),
        ),
        SizedBox(height: 12 * s),
      ],
    );
  }

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
                AuthIconButton(
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
              AuthAvatar(scale: s),
            ],
          ),
        ],
      ),
    );
  }
}

/// Full-screen photo background with a deep green film and drifting light.
/// With [blur] it becomes a soft colour fill (phones, behind the photo card).
class _BackgroundPainter extends CustomPainter {
  _BackgroundPainter({
    required this.photo,
    required this.focus,
    required this.time,
    required this.reveal,
    required this.blur,
    required this.wide,
  });

  final ui.Image? photo;
  final Alignment focus;
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
        alignment: focus,
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

/// Frosted-glass card holding the form, with a leaf peeking over a corner.
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
