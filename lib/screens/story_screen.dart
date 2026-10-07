import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/community.dart';
import '../navigation/tab_navigation.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../widgets/app_nav.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/community_widgets.dart';
import '../widgets/onboarding_layout.dart';
import '../widgets/primary_button.dart';
import '../widgets/rise_in.dart';
import '../widgets/soft_backdrop.dart';

/// A community story to read: its photo (grown from the tapped card), the
/// title and author, then the story itself. At the end the reader can mark
/// it as inspiring and go and find an event of their own.
///
/// The photo drifts up behind the text as you scroll. On laptops the text
/// keeps a comfortable reading width in the middle.
class StoryScreen extends StatefulWidget {
  const StoryScreen({super.key, required this.story});

  final CommunityStory story;

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen>
    with TickerProviderStateMixin {
  final _scroll = ScrollController();
  bool _inspired = false;

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  CommunityStory get _story => widget.story;

  /// How many readers found it inspiring before this one.
  int get _baseCount => 40 + _story.title.length * 3;

  double _rise(int n) {
    final start = (0.15 + n * 0.06).clamp(0.0, 0.6);
    return Curves.easeOutCubic.transform(
      ((_intro.value - start) / 0.4).clamp(0.0, 1.0),
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    _intro.dispose();
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backdrop.first,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final wide =
              size.width >= OnboardingLayout.wideBreakpoint &&
              size.width > size.height;
          final s = wide
              ? math.min(size.width / 1280, size.height / 800).clamp(0.75, 1.25)
              : math.min(
                  size.width / OnboardingLayout.designWidth,
                  size.height / OnboardingLayout.designHeight,
                );
          final top = MediaQuery.paddingOf(context).top;
          final photoHeight = (wide ? 420 : 340) * s + top * 0.5;
          return AnimatedBuilder(
            animation: Listenable.merge([_intro, _ambient, _scroll]),
            builder: (context, _) {
              final offset = _scroll.hasClients ? _scroll.offset : 0.0;
              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: SystemUiOverlayStyle.light.copyWith(
                  statusBarColor: Colors.transparent,
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: SoftBackdropPainter(
                          time: _ambient.value,
                          palette: SoftBackdropPalette.warm,
                        ),
                      ),
                    ),
                    // The photo, drifting up at half speed.
                    Positioned(
                      left: 0,
                      right: 0,
                      top: offset > 0 ? -offset * 0.45 : 0,
                      height: photoHeight + 40 * s + (offset < 0 ? -offset : 0),
                      child: Hero(
                        tag: 'story/${_story.title}',
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Transform.scale(
                              scale:
                                  1.06 +
                                  0.03 * math.sin(_ambient.value * 2 * math.pi),
                              child: Image.asset(
                                _story.photo,
                                fit: BoxFit.cover,
                                alignment: _story.focus,
                              ),
                            ),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    AppColors.splashScrim.withValues(
                                      alpha: 0.55,
                                    ),
                                    AppColors.splashScrim.withValues(alpha: 0),
                                    AppColors.splashScrim.withValues(
                                      alpha: 0.35,
                                    ),
                                  ],
                                  stops: const [0, 0.4, 1],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: SingleChildScrollView(
                        controller: _scroll,
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        child: Column(
                          children: [
                            SizedBox(height: photoHeight),
                            Container(
                              width: double.infinity,
                              constraints: BoxConstraints(
                                minHeight: size.height - photoHeight + 32 * s,
                              ),
                              transform: Matrix4.translationValues(
                                0,
                                -32 * s,
                                0,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(32 * s),
                                ),
                              ),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: (wide ? 720 : 520) * s,
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      24 * s,
                                      28 * s,
                                      24 * s,
                                      40 * s +
                                          MediaQuery.paddingOf(context).bottom,
                                    ),
                                    child: _body(s, wide),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20 * s,
                      right: 20 * s,
                      top: top + 12 * s,
                      child: Row(
                        children: [
                          AuthIconButton(
                            label: 'Back',
                            scale: s,
                            onDark: true,
                            onTap: () => Navigator.of(context).maybePop(),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18 * s,
                              color: AppColors.white,
                            ),
                          ),
                          const Spacer(),
                          StoryTag(label: _story.tag, scale: s),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _body(double s, bool wide) {
    final story = _story;
    var n = 0;
    Widget rise(Widget child) =>
        RiseIn(progress: _rise(n++), distance: 18 * s, child: child);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        rise(
          Semantics(
            header: true,
            child: Text(
              story.title,
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontSize: (wide ? 38 : 30) * s,
                height: 1.18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
        ),
        SizedBox(height: 16 * s),
        rise(
          Row(
            children: [
              MemberAvatar(member: story.author, size: 44 * s),
              SizedBox(width: 12 * s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      story.author.name,
                      style: TextStyle(
                        fontSize: 15.5 * s,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      '${story.author.about} · ${story.minutes} min read',
                      style: TextStyle(
                        fontSize: 13 * s,
                        color: AppColors.fieldIcon,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20 * s),
        rise(
          Container(
            padding: EdgeInsets.fromLTRB(16 * s, 14 * s, 16 * s, 14 * s),
            decoration: BoxDecoration(
              color: AppColors.roleChosenFill,
              borderRadius: BorderRadius.circular(18 * s),
              border: Border(
                left: BorderSide(color: AppColors.leafLight, width: 4 * s),
              ),
            ),
            child: Text(
              story.summary,
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 17 * s,
                height: 1.5,
                fontStyle: FontStyle.italic,
                color: AppColors.ink,
              ),
            ),
          ),
        ),
        SizedBox(height: 22 * s),
        for (final paragraph in story.paragraphs)
          rise(
            Padding(
              padding: EdgeInsets.only(bottom: 18 * s),
              child: Text(
                paragraph,
                style: TextStyle(
                  fontSize: 16.5 * s,
                  height: 1.75,
                  color: AppColors.bodyText,
                ),
              ),
            ),
          ),
        SizedBox(height: 8 * s),
        rise(_end(s)),
      ],
    );
  }

  /// "Inspiring" and a way to find an event.
  Widget _end(double s) {
    final count = _baseCount + (_inspired ? 1 : 0);
    return Container(
      padding: EdgeInsets.all(18 * s),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22 * s),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Did this story inspire you?',
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 18 * s,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Semantics(
                button: true,
                selected: _inspired,
                label: 'Inspiring, $count',
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _inspired = !_inspired);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: EdgeInsets.symmetric(
                      horizontal: 12 * s,
                      vertical: 8 * s,
                    ),
                    decoration: BoxDecoration(
                      color: _inspired
                          ? AppColors.brand
                          : AppColors.roleChosenFill,
                      borderRadius: BorderRadius.circular(18 * s),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedScale(
                          scale: _inspired ? 1.2 : 1,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.elasticOut,
                          child: Icon(
                            _inspired
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 17 * s,
                            color: _inspired
                                ? AppColors.white
                                : AppColors.brand,
                          ),
                        ),
                        SizedBox(width: 6 * s),
                        Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 14 * s,
                            fontWeight: FontWeight.w700,
                            color: _inspired
                                ? AppColors.white
                                : AppColors.brand,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6 * s),
          Text(
            'Write your own chapter. Find an event near you this week.',
            style: TextStyle(fontSize: 14.5 * s, color: AppColors.bodyText),
          ),
          SizedBox(height: 16 * s),
          PrimaryButton(
            label: 'Find an Event',
            scale: s * 0.9,
            time: _ambient.value,
            onPressed: () => openAppTab(context, null, AppTab.explore),
          ),
        ],
      ),
    );
  }
}
