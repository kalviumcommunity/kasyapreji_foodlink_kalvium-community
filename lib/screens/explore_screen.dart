import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/sample_events.dart';
import '../navigation/tab_navigation.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../widgets/app_nav.dart';
import '../widgets/asset_photo.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/event_tile.dart';
import '../widgets/onboarding_layout.dart';
import '../widgets/page_scene.dart';
import '../widgets/rise_in.dart';
import '../widgets/soft_backdrop.dart';
import 'event_details_screen.dart';

/// Explore: search and filter every volunteering event.
///
/// Typing in the search bar narrows the list by title, place, date or
/// category as you type, and the chips filter by category; the list fades
/// between results, and a friendly note with "Clear filters" shows when
/// nothing matches. A photo of volunteers outdoors fades into the soft page
/// backdrop behind the title.
///
/// Phones follow the Figma frame with a bottom navigation bar (hidden while
/// the keyboard is up); laptops get the side navigation rail and the events
/// as a grid of photo cards.
///
/// Tapping an event opens its [EventDetailsScreen], its photo growing out
/// of the tile.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  static const String routeName = 'explore';

  static const String photo = 'assets/images/change_volunteers.jpg';

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with TickerProviderStateMixin {
  final _photo = AssetPhoto(ExploreScreen.photo);
  final _search = TextEditingController();
  final _searchFocus = FocusNode();

  /// The chosen category, or null for All.
  EventCategory? _category;

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

  List<VolunteerEvent> get _results => [
    for (final event in sampleEvents)
      if ((_category == null || event.category == _category) &&
          event.matches(_search.text))
        event,
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _photo.resolve(context, () {
      if (mounted) setState(() {});
    });
    for (final event in sampleEvents) {
      precacheImage(AssetImage(event.photo), context);
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _ambient.dispose();
    _photo.dispose();
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _openTab(AppTab tab) => openAppTab(context, AppTab.explore, tab);

  void _choose(EventCategory? category) {
    if (category == _category) return;
    HapticFeedback.selectionClick();
    setState(() => _category = category);
  }

  void _clearFilters() {
    _search.clear();
    setState(() => _category = null);
  }

  void _openEvent(VolunteerEvent event) => openEventDetails(
    context,
    event,
    from: AppTab.explore,
    heroTag: _heroTag(event),
  );

  static Object _heroTag(VolunteerEvent event) => 'explore/${event.title}';

  @override
  Widget build(BuildContext context) {
    final keyboardUp = MediaQuery.viewInsetsOf(context).bottom > 0;
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
          // Tapping outside the search bar puts the keyboard away.
          behavior: HitTestBehavior.translucent,
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
                animation: Listenable.merge([_intro, _ambient, _search]),
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
                            height: 300,
                            focus: const Alignment(0, 0.1),
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: wide
                          ? _buildWide(size, s, railWidth)
                          : _buildCompact(size, s, keyboardUp),
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

  Widget _buildCompact(Size size, double s, bool keyboardUp) {
    // On tablets held upright, keep things a comfortable width.
    final width = math.min(size.width, 520 * s);
    final gutter = 24 * s;
    Widget padded(Widget child) => Padding(
      padding: EdgeInsets.symmetric(horizontal: gutter),
      child: child,
    );

    return Column(
      children: [
        Expanded(
          child: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(top: 14 * s, bottom: 28 * s),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Center(
                child: SizedBox(
                  width: width,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      padded(
                        RiseIn(
                          progress: _rise(0),
                          distance: -10 * s,
                          child: _headerRow(s),
                        ),
                      ),
                      SizedBox(height: 22 * s),
                      padded(
                        RiseIn(
                          progress: _rise(1),
                          distance: 18 * s,
                          child: _title(s, 40 * s),
                        ),
                      ),
                      SizedBox(height: 22 * s),
                      padded(
                        RiseIn(
                          progress: _rise(2),
                          distance: 18 * s,
                          child: _searchBar(s),
                        ),
                      ),
                      SizedBox(height: 22 * s),
                      // Chips run to the screen's edges and scroll sideways.
                      RiseIn(
                        progress: _rise(3),
                        distance: 18 * s,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          padding: EdgeInsets.symmetric(horizontal: gutter),
                          child: _chips(s),
                        ),
                      ),
                      SizedBox(height: 14 * s),
                      padded(_resultsList(s)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (!keyboardUp)
          AppBottomBar(current: AppTab.explore, scale: s, onSelect: _openTab),
      ],
    );
  }

  /// Phones: events in rows with a line between each.
  Widget _resultsList(double s) {
    final results = _results;
    return _ResultsSwitcher(
      results: results,
      child: results.isEmpty
          ? Padding(
              padding: EdgeInsets.only(top: 40 * s),
              child: _EmptyResults(scale: s, onClear: _clearFilters),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, event) in results.indexed)
                  // Each line arrives with the event below it.
                  RiseIn(
                    progress: _rise(4 + i),
                    distance: 20 * s,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (i > 0)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 18 * s),
                            child: Container(
                              height: 1,
                              color: AppColors.fieldBorder,
                            ),
                          )
                        else
                          SizedBox(height: 10 * s),
                        EventTile(
                          event: event,
                          scale: s,
                          card: false,
                          onTap: () => _openEvent(event),
                          heroTag: _heroTag(event),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // Laptop layout
  // ---------------------------------------------------------------------------

  Widget _buildWide(Size size, double s, double railWidth) {
    final mainWidth = math.min(size.width - railWidth, 1080 * s);
    final content = mainWidth - 96 * s;
    final columns = content >= 700 ? 3 : (content >= 440 ? 2 : 1);
    final gap = 20 * s;
    final cardWidth = (content - gap * (columns - 1)) / columns;
    final results = _results;

    return Row(
      children: [
        SizedBox(
          width: railWidth,
          child: AppSideRail(
            current: AppTab.explore,
            scale: s,
            onSelect: _openTab,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
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
                              'Find food drives, gardens and workshops '
                              'near you.',
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
                            constraints: BoxConstraints(maxWidth: 620 * s),
                            child: _searchBar(s),
                          ),
                        ),
                      ),
                      SizedBox(height: 18 * s),
                      RiseIn(
                        progress: _rise(3),
                        distance: 20 * s,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(child: _chips(s)),
                            SizedBox(width: 16 * s),
                            Padding(
                              padding: EdgeInsets.only(bottom: 10 * s),
                              child: _countLabel(s, results.length),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 14 * s),
                      Container(height: 1, color: AppColors.fieldBorder),
                      SizedBox(height: 24 * s),
                      _ResultsSwitcher(
                        results: results,
                        child: results.isEmpty
                            ? Padding(
                                padding: EdgeInsets.only(top: 40 * s),
                                child: _EmptyResults(
                                  scale: s,
                                  onClear: _clearFilters,
                                ),
                              )
                            : Wrap(
                                spacing: gap,
                                runSpacing: gap,
                                children: [
                                  for (final (i, event) in results.indexed)
                                    SizedBox(
                                      width: cardWidth,
                                      child: RiseIn(
                                        progress: _rise(4 + i),
                                        distance: 24 * s,
                                        child: EventTile(
                                          event: event,
                                          scale: s,
                                          card: true,
                                          onTap: () => _openEvent(event),
                                          heroTag: _heroTag(event),
                                        ),
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
        ),
      ],
    );
  }

  /// "7 events" beside the chips on laptops.
  Widget _countLabel(double s, int count) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Text(
        '$count ${count == 1 ? 'event' : 'events'}',
        key: ValueKey(count),
        style: TextStyle(
          fontSize: 14 * s,
          fontWeight: FontWeight.w600,
          color: AppColors.fieldIcon,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Shared pieces
  // ---------------------------------------------------------------------------

  /// Back button (when there's somewhere to go back to) and the avatar.
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
        AuthAvatar(scale: s * 1.1),
      ],
    );
  }

  Widget _title(double s, double fontSize) {
    return Semantics(
      header: true,
      child: Text(
        'Explore',
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

  Widget _searchBar(double s) {
    return _SearchBar(
      controller: _search,
      focusNode: _searchFocus,
      scale: s,
      onClear: () {
        HapticFeedback.selectionClick();
        _search.clear();
      },
    );
  }

  /// All, then one chip per category.
  Widget _chips(double s) {
    return Wrap(
      spacing: 10 * s,
      runSpacing: 10 * s,
      children: [
        for (final category in [null, ...EventCategory.values])
          _CategoryChip(
            label: category?.label ?? 'All',
            selected: category == _category,
            scale: s,
            onTap: () => _choose(category),
          ),
      ],
    );
  }
}

/// Fades and lifts the list into place whenever the matching events change
/// (but not on every keystroke that leaves them the same).
class _ResultsSwitcher extends StatelessWidget {
  const _ResultsSwitcher({required this.results, required this.child});

  final List<VolunteerEvent> results;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 380),
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
      child: KeyedSubtree(
        key: ValueKey(results.map((e) => e.title).join('|')),
        child: child,
      ),
    );
  }
}

/// Rounded grey search field that turns white with a green glow while
/// focused, with a clear button once there's text.
class _SearchBar extends StatefulWidget {
  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.scale,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final double scale;
  final VoidCallback onClear;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    widget.focusNode.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    final focused = widget.focusNode.hasFocus;
    final hasText = widget.controller.text.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      height: 58 * s,
      padding: EdgeInsets.only(left: 20 * s, right: 10 * s),
      decoration: BoxDecoration(
        color: focused ? AppColors.white : AppColors.socialFill,
        borderRadius: BorderRadius.circular(29 * s),
        border: Border.all(
          color: focused
              ? AppColors.brand.withValues(alpha: 0.6)
              : AppColors.white.withValues(alpha: 0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: focused ? 0.14 : 0),
            blurRadius: 18 * s,
            offset: Offset(0, 4 * s),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            size: 24 * s,
            color: focused ? AppColors.brand : AppColors.fieldIcon,
          ),
          SizedBox(width: 12 * s),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => widget.focusNode.unfocus(),
              cursorColor: AppColors.brand,
              style: TextStyle(
                fontSize: 16 * s,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
              ),
              decoration: InputDecoration.collapsed(
                hintText: 'Search events, locations...',
                hintStyle: TextStyle(
                  fontSize: 16 * s,
                  color: AppColors.fieldHint,
                ),
              ),
            ),
          ),
          AnimatedScale(
            scale: hasText ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            child: Semantics(
              button: true,
              label: 'Clear search',
              excludeSemantics: true,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: hasText ? widget.onClear : null,
                  child: Container(
                    width: 30 * s,
                    height: 30 * s,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.fieldBorder.withValues(alpha: 0.9),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 17 * s,
                      color: AppColors.bodyText,
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
}

/// A category filter: solid green when chosen, soft grey otherwise.
class _CategoryChip extends StatefulWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.scale,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final double scale;
  final VoidCallback onTap;

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    final selected = widget.selected;

    return Semantics(
      button: true,
      selected: selected,
      label: '${widget.label} filter',
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
            scale: _pressed ? 0.94 : 1,
            duration: const Duration(milliseconds: 120),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: 18 * s,
                vertical: 12 * s,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.brand
                    : _hovered
                    ? AppColors.roleChosenFill
                    : AppColors.socialFill,
                borderRadius: BorderRadius.circular(24 * s),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brand.withValues(
                      alpha: selected ? 0.28 : 0,
                    ),
                    blurRadius: 14 * s,
                    offset: Offset(0, 5 * s),
                  ),
                ],
              ),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 260),
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 15 * s,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.white : AppColors.ink,
                ),
                child: Text(widget.label),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown when no event matches the search and category.
class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.scale, required this.onClear});

  final double scale;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Column(
      children: [
        Container(
          width: 76 * s,
          height: 76 * s,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.roleChosenFill, AppColors.roleChosenCircle],
            ),
          ),
          child: Icon(
            Icons.search_off_rounded,
            size: 34 * s,
            color: AppColors.brand,
          ),
        ),
        SizedBox(height: 18 * s),
        Text(
          'No events found',
          style: TextStyle(
            fontFamily: AppFonts.display,
            fontSize: 22 * s,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        SizedBox(height: 6 * s),
        Text(
          'Try another search or category.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15 * s, color: AppColors.bodyText),
        ),
        SizedBox(height: 16 * s),
        AuthTextLink(
          label: 'Clear filters',
          scale: s,
          fontSize: 16,
          onTap: onClear,
        ),
      ],
    );
  }
}
