import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/community.dart';
import '../data/event_plans.dart';
import '../data/sample_events.dart';
import '../navigation/tab_navigation.dart';
import '../navigation/transitions.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../widgets/app_nav.dart';
import '../widgets/asset_photo.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/community_impact.dart';
import '../widgets/community_widgets.dart';
import '../widgets/onboarding_layout.dart';
import '../widgets/page_scene.dart';
import '../widgets/rise_in.dart';
import '../widgets/soft_backdrop.dart';
import 'story_screen.dart';

/// Community: what volunteers and organisers are sharing.
///
/// Posts is the feed. Volunteers can share a moment of their own (with a
/// photo and an event if they like), like posts with the heart or a double
/// tap on the photo, comment, save, copy a link, and open the event a post
/// is about. Stories are longer reads from the community, opening in a
/// reader. Impact shows what everyone has achieved together this year: the
/// meals shared, progress towards the year's goal, a month-by-month chart,
/// the volunteer's own share and this month's top volunteers.
///
/// A photo of a shared meal fades into the soft backdrop behind the title.
/// Phones follow the Figma frame with the bottom navigation bar; laptops get
/// the side navigation rail, with the feed beside a column of highlights.
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  static const String routeName = 'community';

  static const String photo = 'assets/images/onboarding_community_meal.jpg';

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

enum _Tab { posts, stories, impact }

class _CommunityScreenState extends State<CommunityScreen>
    with TickerProviderStateMixin {
  final _photo = AssetPhoto(CommunityScreen.photo);
  final _scroll = ScrollController();
  _Tab _tab = _Tab.posts;

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..forward();

  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

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
    _scroll.dispose();
    super.dispose();
  }

  void _openTab(AppTab tab) => openAppTab(context, AppTab.community, tab);

  void _show(_Tab tab) {
    if (tab == _tab) return;
    HapticFeedback.selectionClick();
    setState(() => _tab = tab);
  }

  void _openEvent(VolunteerEvent event, Object heroTag) => openEventDetails(
    context,
    event,
    from: AppTab.community,
    heroTag: heroTag,
  );

  void _openStory(CommunityStory story) {
    Navigator.of(context).push(softRoute(StoryScreen(story: story)));
  }

  Future<void> _compose(double s) async {
    final post = await showComposeSheet(context, scale: s);
    if (post == null || !mounted) return;
    if (_scroll.hasClients) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
    showAuthNotice(context, 'Shared with the community.');
  }

  void _openComments(CommunityPost post, double s) =>
      showCommentsSheet(context, postId: post.id, scale: s);

  void _postMenu(CommunityPost post, String action) {
    switch (action) {
      case 'save':
        CommunityFeed.toggleSave(post.id);
        showAuthNotice(
          context,
          CommunityFeed.hasSaved(post.id)
              ? 'Post saved.'
              : 'Removed from saved posts.',
        );
      case 'link':
        Clipboard.setData(
          ClipboardData(text: 'https://foodlink.app/community/${post.id}'),
        );
        showAuthNotice(context, 'Link copied.');
      case 'report':
        showAuthNotice(
          context,
          'Thanks for letting us know. We’ll take a look.',
        );
      case 'delete':
        CommunityFeed.delete(post.id);
        showAuthNotice(context, 'Post deleted.');
    }
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
        body: LayoutBuilder(
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
                CommunityFeed.posts,
                CommunityFeed.liked,
                CommunityFeed.saved,
              ]),
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
                        painter: PageScenePainter(
                          photo: _photo.image,
                          time: _ambient.value,
                          reveal: _rise(0),
                          appear: _rise(4),
                          left: railWidth,
                          scale: s,
                          height: 290,
                          focus: const Alignment(0, -0.1),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: wide
                        ? _buildWide(size, s, railWidth)
                        : _buildCompact(size, s),
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

  Widget _buildCompact(Size size, double s) {
    final width = math.min(size.width, 520 * s) - 48 * s;
    return Column(
      children: [
        Expanded(
          child: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              controller: _scroll,
              padding: EdgeInsets.fromLTRB(24 * s, 14 * s, 24 * s, 28 * s),
              child: Center(
                child: SizedBox(
                  width: width,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      RiseIn(
                        progress: _rise(0),
                        distance: -10 * s,
                        child: _headerRow(s),
                      ),
                      SizedBox(height: 22 * s),
                      RiseIn(
                        progress: _rise(1),
                        distance: 18 * s,
                        child: _title(s, 40 * s),
                      ),
                      SizedBox(height: 22 * s),
                      RiseIn(
                        progress: _rise(2),
                        distance: 18 * s,
                        child: _tabs(s),
                      ),
                      SizedBox(height: 22 * s),
                      _content(s, wide: false),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        AppBottomBar(current: AppTab.community, scale: s, onSelect: _openTab),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Laptop layout
  // ---------------------------------------------------------------------------

  Widget _buildWide(Size size, double s, double railWidth) {
    final mainWidth = math.min(size.width - railWidth, 1120 * s);
    return Row(
      children: [
        SizedBox(
          width: railWidth,
          child: AppSideRail(
            current: AppTab.community,
            scale: s,
            onSelect: _openTab,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: _scroll,
            padding: EdgeInsets.symmetric(vertical: 30 * s),
            child: Center(
              child: SizedBox(
                width: mainWidth,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 48 * s),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      RiseIn(
                        progress: _rise(0),
                        distance: -10 * s,
                        child: _headerRow(s),
                      ),
                      SizedBox(height: 22 * s),
                      RiseIn(
                        progress: _rise(1),
                        distance: 20 * s,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _title(s, 52 * s),
                            SizedBox(height: 6 * s),
                            Text(
                              'Moments, stories and the difference we’re '
                              'making together.',
                              style: TextStyle(
                                fontSize: 17 * s,
                                color: AppColors.bodyText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 26 * s),
                      RiseIn(
                        progress: _rise(2),
                        distance: 20 * s,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 520 * s),
                            child: _tabs(s),
                          ),
                        ),
                      ),
                      SizedBox(height: 26 * s),
                      _content(s, wide: true),
                    ],
                  ),
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

  Widget _headerRow(double s) {
    return Row(
      children: [
        if (Navigator.of(context).canPop())
          AuthIconButton(
            label: 'Back',
            scale: s,
            onTap: () => Navigator.of(context).maybePop(),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18 * s,
              color: AppColors.ink,
            ),
          ),
        const Spacer(),
        AuthAvatar(
          scale: s * 1.1,
          onTap: () => openAppTab(context, AppTab.community, AppTab.profile),
        ),
      ],
    );
  }

  Widget _title(double s, double fontSize) {
    return Semantics(
      header: true,
      child: Text(
        'Community',
        style: TextStyle(
          fontFamily: AppFonts.display,
          fontSize: fontSize,
          height: 1.1,
          fontWeight: FontWeight.w700,
          letterSpacing: -fontSize * 0.01,
          color: AppColors.ink,
        ),
      ),
    );
  }

  Widget _tabs(double s) {
    return Row(
      children: [
        for (final (i, tab) in _Tab.values.indexed) ...[
          if (i > 0) SizedBox(width: 10 * s),
          Expanded(
            child: CommunityTabButton(
              label: switch (tab) {
                _Tab.posts => 'Posts',
                _Tab.stories => 'Stories',
                _Tab.impact => 'Impact',
              },
              selected: tab == _tab,
              scale: s,
              onTap: () => _show(tab),
            ),
          ),
        ],
      ],
    );
  }

  Widget _content(double s, {required bool wide}) {
    final Widget child = switch (_tab) {
      _Tab.posts => _posts(s, wide: wide),
      _Tab.stories => _stories(s, wide: wide),
      _Tab.impact => CommunityImpact(
        scale: s,
        wide: wide,
        time: _ambient.value,
        onSeeYourEvents: () => _openTab(AppTab.events),
      ),
    };
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        children: [...previous, ?current],
      ),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.03),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: KeyedSubtree(key: ValueKey(_tab), child: child),
    );
  }

  // ---------------------------------------------------------------------------
  // Posts
  // ---------------------------------------------------------------------------

  Widget _posts(double s, {required bool wide}) {
    final posts = CommunityFeed.posts.value;
    final feed = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RiseIn(
          progress: _rise(3),
          distance: 18 * s,
          child: ComposerPrompt(scale: s, onTap: () => _compose(s)),
        ),
        SizedBox(height: 8 * s),
        for (final (i, post) in posts.indexed)
          RiseIn(
            progress: _rise(4 + i),
            distance: 20 * s,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (i > 0) Container(height: 1, color: AppColors.fieldBorder),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 22 * s),
                  child: PostCard(
                    key: ValueKey(post.id),
                    post: post,
                    scale: s,
                    onComments: () => _openComments(post, s),
                    onMenu: (action) => _postMenu(post, action),
                    onOpenEvent: _openEvent,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
    if (!wide) return feed;

    // Laptops: the feed on a white panel, highlights beside it.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Container(
            padding: EdgeInsets.fromLTRB(26 * s, 22 * s, 26 * s, 6 * s),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(28 * s),
              border: Border.all(color: AppColors.white),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brand.withValues(alpha: 0.07),
                  blurRadius: 30 * s,
                  offset: Offset(0, 12 * s),
                ),
              ],
            ),
            child: feed,
          ),
        ),
        SizedBox(width: 28 * s),
        Expanded(
          flex: 2,
          child: RiseIn(
            progress: _rise(4),
            distance: 24 * s,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CommunityPulseCard(scale: s, time: _ambient.value),
                SizedBox(height: 20 * s),
                FeaturedStoryCard(
                  story: communityStories.first,
                  scale: s,
                  height: 240 * s,
                  onTap: () => _openStory(communityStories.first),
                ),
                SizedBox(height: 20 * s),
                TopVolunteersCard(scale: s),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Stories
  // ---------------------------------------------------------------------------

  Widget _stories(double s, {required bool wide}) {
    final featured = communityStories.first;
    final rest = communityStories.skip(1).toList();
    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FeaturedStoryCard(
            story: featured,
            scale: s,
            height: 280 * s,
            onTap: () => _openStory(featured),
          ),
          SizedBox(height: 22 * s),
          for (final (i, story) in rest.indexed) ...[
            if (i > 0)
              Container(
                height: 1,
                margin: EdgeInsets.symmetric(vertical: 16 * s),
                color: AppColors.fieldBorder,
              ),
            StoryRow(story: story, scale: s, onTap: () => _openStory(story)),
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FeaturedStoryCard(
          story: featured,
          scale: s,
          height: 340 * s,
          onTap: () => _openStory(featured),
        ),
        SizedBox(height: 24 * s),
        LayoutBuilder(
          builder: (context, constraints) {
            final gap = 20 * s;
            final width = (constraints.maxWidth - gap) / 2;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final story in rest)
                  SizedBox(
                    width: width,
                    child: StoryRow(
                      story: story,
                      scale: s,
                      card: true,
                      onTap: () => _openStory(story),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Opens the sheet for sharing a post, and returns the post once shared.
Future<CommunityPost?> showComposeSheet(
  BuildContext context, {
  required double scale,
}) {
  return showModalBottomSheet<CommunityPost>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.ink.withValues(alpha: 0.4),
    constraints: BoxConstraints(maxWidth: 600 * scale),
    builder: (context) => _ComposeSheet(scale: scale),
  );
}

/// Write a post, optionally pick a photo and tag an event, then Share.
class _ComposeSheet extends StatefulWidget {
  const _ComposeSheet({required this.scale});

  final double scale;

  @override
  State<_ComposeSheet> createState() => _ComposeSheetState();
}

class _ComposeSheetState extends State<_ComposeSheet> {
  static const _maxLength = 280;

  static const _photos = [
    'assets/images/impact_packing.jpg',
    'assets/images/event_harvest_greens.jpg',
    'assets/images/event_community_meal.jpg',
    'assets/images/event_tree_planting.jpg',
    'assets/images/notifications_community_farm.jpg',
    'assets/images/event_potato_sorting.jpg',
  ];

  final _text = TextEditingController();
  String? _photo;
  String? _event;

  /// Events the volunteer has joined, to tag.
  List<String> get _events => [
    for (final event in sampleEvents)
      if (EventPlans.hasJoined(event.title)) event.title,
  ];

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _share() {
    final text = _text.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.mediumImpact();
    final post = CommunityFeed.share(text, photo: _photo, event: _event);
    Navigator.of(context).pop(post);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    final canShare = _text.text.trim().isNotEmpty;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30 * s)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(22 * s, 12 * s, 22 * s, 18 * s),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SheetHandle(),
                SizedBox(height: 14 * s),
                Row(
                  children: [
                    MemberAvatar(member: you, size: 44 * s),
                    SizedBox(width: 12 * s),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Share a moment',
                            style: TextStyle(
                              fontFamily: AppFonts.display,
                              fontSize: 20 * s,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          Text(
                            'Posting as ${you.name} · Everyone can see this',
                            style: TextStyle(
                              fontSize: 12.5 * s,
                              color: AppColors.fieldIcon,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16 * s),
                Container(
                  padding: EdgeInsets.fromLTRB(16 * s, 14 * s, 14 * s, 8 * s),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(18 * s),
                    border: Border.all(color: AppColors.fieldBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _text,
                        autofocus: true,
                        minLines: 3,
                        maxLines: 6,
                        textCapitalization: TextCapitalization.sentences,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(_maxLength),
                        ],
                        onChanged: (_) => setState(() {}),
                        cursorColor: AppColors.brand,
                        style: TextStyle(
                          fontSize: 16 * s,
                          height: 1.45,
                          color: AppColors.ink,
                        ),
                        decoration: InputDecoration.collapsed(
                          hintText: 'What did you do today? Who did you meet?',
                          hintStyle: TextStyle(
                            fontSize: 16 * s,
                            color: AppColors.fieldHint,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${_text.text.length}/$_maxLength',
                          style: TextStyle(
                            fontSize: 12 * s,
                            color: AppColors.fieldHint,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16 * s),
                _label('Add a photo', s),
                SizedBox(height: 10 * s),
                SizedBox(
                  height: 70 * s,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _photos.length,
                    separatorBuilder: (_, _) => SizedBox(width: 10 * s),
                    itemBuilder: (context, i) {
                      final photo = _photos[i];
                      final chosen = photo == _photo;
                      return Semantics(
                        button: true,
                        selected: chosen,
                        label: 'Photo ${i + 1}',
                        excludeSemantics: true,
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _photo = chosen ? null : photo);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 70 * s,
                            padding: EdgeInsets.all(chosen ? 3 * s : 0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16 * s),
                              color: AppColors.brand,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                (chosen ? 13 : 16) * s,
                              ),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.asset(photo, fit: BoxFit.cover),
                                  if (chosen)
                                    ColoredBox(
                                      color: AppColors.brand.withValues(
                                        alpha: 0.35,
                                      ),
                                      child: Icon(
                                        Icons.check_rounded,
                                        color: AppColors.white,
                                        size: 26 * s,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_events.isNotEmpty) ...[
                  SizedBox(height: 16 * s),
                  _label('Tag an event', s),
                  SizedBox(height: 10 * s),
                  Wrap(
                    spacing: 8 * s,
                    runSpacing: 8 * s,
                    children: [
                      for (final title in _events)
                        ChoicePill(
                          label: title,
                          icon: Icons.event_available_rounded,
                          selected: title == _event,
                          scale: s,
                          onTap: () => setState(
                            () => _event = title == _event ? null : title,
                          ),
                        ),
                    ],
                  ),
                ],
                SizedBox(height: 20 * s),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: canShare ? 1 : 0.5,
                  child: SizedBox(
                    height: 56 * s,
                    child: Semantics(
                      button: true,
                      enabled: canShare,
                      label: 'Share post',
                      excludeSemantics: true,
                      child: GestureDetector(
                        onTap: canShare ? _share : null,
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF356B48), AppColors.brand],
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.send_rounded,
                                size: 19 * s,
                                color: AppColors.white,
                              ),
                              SizedBox(width: 8 * s),
                              Text(
                                'Share',
                                style: TextStyle(
                                  fontSize: 17 * s,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.white,
                                ),
                              ),
                            ],
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
      ),
    );
  }

  Widget _label(String text, double s) => Text(
    text,
    style: TextStyle(
      fontSize: 15 * s,
      fontWeight: FontWeight.w600,
      color: AppColors.ink,
    ),
  );
}

/// Opens the comments for the post [postId].
Future<void> showCommentsSheet(
  BuildContext context, {
  required String postId,
  required double scale,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.ink.withValues(alpha: 0.4),
    constraints: BoxConstraints(maxWidth: 600 * scale),
    builder: (context) => _CommentsSheet(postId: postId, scale: scale),
  );
}

class _CommentsSheet extends StatefulWidget {
  const _CommentsSheet({required this.postId, required this.scale});

  final String postId;
  final double scale;

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _text = TextEditingController();
  final _list = ScrollController();

  @override
  void dispose() {
    _text.dispose();
    _list.dispose();
    super.dispose();
  }

  void _send() {
    final text = _text.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();
    CommunityFeed.comment(widget.postId, text);
    _text.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_list.hasClients) {
        _list.animateTo(
          _list.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    final height = MediaQuery.sizeOf(context).height;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: height * 0.78),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30 * s)),
        ),
        child: ValueListenableBuilder(
          valueListenable: CommunityFeed.posts,
          builder: (context, _, _) {
            final post = CommunityFeed.byId(widget.postId);
            if (post == null) return const SizedBox.shrink();
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 12 * s),
                const SheetHandle(),
                Padding(
                  padding: EdgeInsets.fromLTRB(22 * s, 14 * s, 22 * s, 8 * s),
                  child: Row(
                    children: [
                      Text(
                        'Comments',
                        style: TextStyle(
                          fontFamily: AppFonts.display,
                          fontSize: 21 * s,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      SizedBox(width: 8 * s),
                      CountBadge(count: post.commentCount, scale: s),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView(
                    controller: _list,
                    shrinkWrap: true,
                    padding: EdgeInsets.fromLTRB(22 * s, 4 * s, 22 * s, 12 * s),
                    children: [
                      if (post.earlierComments > 0)
                        Padding(
                          padding: EdgeInsets.only(bottom: 12 * s),
                          child: Text(
                            '${post.earlierComments} earlier comments',
                            style: TextStyle(
                              fontSize: 13 * s,
                              fontWeight: FontWeight.w600,
                              color: AppColors.fieldHint,
                            ),
                          ),
                        ),
                      if (post.comments.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 20 * s),
                          child: Text(
                            'Be the first to say something kind.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15 * s,
                              color: AppColors.bodyText,
                            ),
                          ),
                        ),
                      for (final comment in post.comments)
                        TweenAnimationBuilder<double>(
                          key: ObjectKey(comment),
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 380),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) => RiseIn(
                            progress: value,
                            distance: 12 * s,
                            child: child!,
                          ),
                          child: CommentTile(comment: comment, scale: s),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(16 * s, 10 * s, 12 * s, 10 * s),
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    border: Border(
                      top: BorderSide(color: AppColors.fieldBorder),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        MemberAvatar(member: you, size: 36 * s),
                        SizedBox(width: 10 * s),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16 * s,
                              vertical: 12 * s,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.socialFill,
                              borderRadius: BorderRadius.circular(22 * s),
                            ),
                            child: TextField(
                              controller: _text,
                              textInputAction: TextInputAction.send,
                              textCapitalization: TextCapitalization.sentences,
                              onSubmitted: (_) => _send(),
                              onChanged: (_) => setState(() {}),
                              cursorColor: AppColors.brand,
                              style: TextStyle(
                                fontSize: 15 * s,
                                color: AppColors.ink,
                              ),
                              decoration: InputDecoration.collapsed(
                                hintText: 'Add a kind comment...',
                                hintStyle: TextStyle(
                                  fontSize: 15 * s,
                                  color: AppColors.fieldHint,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8 * s),
                        Semantics(
                          button: true,
                          label: 'Send comment',
                          excludeSemantics: true,
                          child: GestureDetector(
                            onTap: _send,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 44 * s,
                              height: 44 * s,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _text.text.trim().isEmpty
                                    ? AppColors.stepTodo
                                    : AppColors.brand,
                              ),
                              child: Icon(
                                Icons.arrow_upward_rounded,
                                size: 22 * s,
                                color: _text.text.trim().isEmpty
                                    ? AppColors.fieldIcon
                                    : AppColors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
