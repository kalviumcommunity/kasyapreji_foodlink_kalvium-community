import 'package:flutter/material.dart';

import '../../data/coordinator.dart';
import '../../navigation/transitions.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_nav.dart';
import '../../widgets/coordinator_page.dart';
import '../../widgets/coordinator_widgets.dart';
import '../../widgets/event_tile.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/rise_in.dart';
import 'create_event_screen.dart';
import 'event_details_screen.dart';

enum _Filter {
  all('All'),
  ongoing('Ongoing'),
  completed('Completed');

  const _Filter(this.label);

  final String label;
}

/// The coordinator's events, as in the Figma: All, Ongoing and Completed
/// tabs over a list of events with their status and volunteers, and Create
/// Event pinned below. Each event opens its Manage Event panel; a newly
/// created event appears at once.
///
/// A photo of a food warehouse fades into the backdrop behind the title.
class CoordinatorEventsScreen extends StatefulWidget {
  const CoordinatorEventsScreen({super.key});

  static const String routeName = 'coordinator-events';

  @override
  State<CoordinatorEventsScreen> createState() =>
      _CoordinatorEventsScreenState();
}

class _CoordinatorEventsScreenState extends State<CoordinatorEventsScreen> {
  final _search = TextEditingController();
  _Filter _filter = _Filter.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _open(ManagedEvent managed) => Navigator.of(context).push(
    softRoute(
      CoordinatorEventDetailsScreen(
        title: managed.title,
        heroTag: 'coord/${managed.title}',
      ),
    ),
  );

  List<ManagedEvent> get _events => [
    for (final managed in CoordinatorBoard.events.value)
      if (managed.event.matches(_search.text) &&
          switch (_filter) {
            _Filter.all => true,
            _Filter.ongoing => managed.status == EventStatus.ongoing,
            _Filter.completed => managed.status == EventStatus.completed,
          })
        managed,
  ];

  Future<void> _create() async {
    final created = await Navigator.of(context)
        .push<String>(softRoute(const CreateEventScreen()));
    if (created == null || !mounted) return;
    setState(() => _filter = _Filter.all);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.brandDark,
          content: Text('$created is live. Volunteers can sign up now.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return CoordinatorPage(
      tab: CoordinatorTab.events,
      title: 'Events',
      photo: 'assets/images/event_food_warehouse.jpg',
      photoFocus: const Alignment(0, 0.2),
      listenTo: Listenable.merge([
        CoordinatorBoard.events,
        CoordinatorBoard.checkedIn,
      ]),
      action: (c) => PrimaryButton(
        label: '+  Create Event',
        scale: c.scale * 0.92,
        time: c.time,
        onPressed: _create,
      ),
      body: (context, c) {
        final s = c.scale;
        final events = _events;
        return [
          _EventsSummary(scale: s, time: c.time),
          SizedBox(height: 18 * s),
          CoordinatorSearch(
            controller: _search,
            hint: 'Search events or places...',
            scale: s,
            onChanged: (_) => setState(() {}),
          ),
          SizedBox(height: 14 * s),
          CoordinatorTabs<_Filter>(
            values: _Filter.values,
            selected: _filter,
            label: (filter) => filter.label,
            scale: s,
            onChanged: (filter) => setState(() => _filter = filter),
          ),
          SizedBox(height: 8 * s),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 380),
            switchInCurve: Curves.easeOutCubic,
            // The outgoing list's photos mustn't take part in photo
            // transitions alongside the new one's.
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topCenter,
              children: [
                for (final child in previous)
                  HeroMode(enabled: false, child: child),
                ?current,
              ],
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
            child: Column(
              key: ValueKey('$_filter/${_search.text}'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (events.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 40 * s),
                    child: Text(
                      _search.text.trim().isEmpty
                          ? 'No ${_filter.label.toLowerCase()} events.'
                          : 'No events match “${_search.text.trim()}”.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15 * s,
                        color: AppColors.bodyText,
                      ),
                    ),
                  ),
                if (c.wide)
                  Padding(
                    padding: EdgeInsets.only(top: 10 * s),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final gap = 16 * s;
                        final width = (constraints.maxWidth - gap) / 2;
                        return Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: [
                            for (final (i, managed) in events.indexed)
                              SizedBox(
                                width: width,
                                child: _Arrive(
                                  index: i,
                                  scale: s,
                                  child: CoordinatorCard(
                                    scale: s,
                                    padding: EdgeInsets.all(4 * s),
                                    child: _EventRow(
                                      managed: managed,
                                      scale: s,
                                      time: c.time,
                                      onTap: () => _open(managed),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  )
                else
                  for (final (i, managed) in events.indexed)
                    _Arrive(
                      index: i,
                      scale: s,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (i > 0) rowDivider(),
                          _EventRow(
                            managed: managed,
                            scale: s,
                            time: c.time,
                            onTap: () => _open(managed),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ];
      },
    );
  }
}

/// The Figma's event row: photo, title, status and volunteers.
class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.managed,
    required this.scale,
    required this.time,
    required this.onTap,
  });

  final ManagedEvent managed;
  final double scale;
  final double time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final event = managed.event;
    final (fill, ink) = switch (managed.status) {
      EventStatus.ongoing => (AppColors.roleChosenFill, AppColors.brand),
      EventStatus.upcoming => (AppColors.tagLearnFill, AppColors.tagLearnText),
      EventStatus.completed => (AppColors.socialFill, AppColors.fieldIcon),
    };
    final here = CoordinatorBoard.checkedInAt(managed.title).length;
    final volunteers = switch (managed.status) {
      EventStatus.ongoing => '$here/${managed.roster.length} volunteers',
      EventStatus.upcoming => '${managed.roster.length} volunteers',
      EventStatus.completed =>
        '${managed.roster.length} volunteers · ${managed.mealsSoFar} meals',
    };
    return TappableRow(
      label:
          '${event.title}. ${managed.status.label}. $volunteers. '
          '${event.when}',
      scale: s,
      onTap: onTap,
      child: Row(
        children: [
          SizedBox.square(
            dimension: 92 * s,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: 'coord/${managed.title}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18 * s),
                    child: ColorFiltered(
                      colorFilter: managed.status == EventStatus.completed
                          ? const ColorFilter.matrix([
                              0.6, 0.3, 0.1, 0, 10, //
                              0.3, 0.6, 0.1, 0, 10, //
                              0.3, 0.3, 0.4, 0, 10, //
                              0, 0, 0, 1, 0,
                            ])
                          : const ColorFilter.mode(
                              Colors.transparent,
                              BlendMode.dst,
                            ),
                      child: EventPhoto(event: event),
                    ),
                  ),
                ),
                if (managed.ongoing)
                  Positioned(
                    left: 6 * s,
                    top: 6 * s,
                    child: PulseDot(
                      time: time,
                      size: 8 * s,
                      color: AppColors.badge,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 16 * s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16.5 * s,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                SizedBox(height: 6 * s),
                StatusPill(
                  label: managed.status.label,
                  fill: fill,
                  ink: ink,
                  scale: s,
                ),
                SizedBox(height: 6 * s),
                Text(
                  volunteers,
                  style: TextStyle(
                    fontSize: 14 * s,
                    fontWeight: managed.ongoing
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: managed.ongoing
                        ? AppColors.leafMid
                        : AppColors.bodyText,
                  ),
                ),
                SizedBox(height: 2 * s),
                Text(
                  event.when,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5 * s,
                    color: AppColors.fieldHint,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Rises into place a moment after the one before.
class _Arrive extends StatelessWidget {
  const _Arrive({
    required this.index,
    required this.scale,
    required this.child,
  });

  final int index;
  final double scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + index * 70),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) =>
          RiseIn(progress: value, distance: 16 * scale, child: child!),
      child: child,
    );
  }
}

/// The week at a glance on deep green: active events, volunteers signed up,
/// spots still to fill, and a ring of how full everything is.
class _EventsSummary extends StatelessWidget {
  const _EventsSummary({required this.scale, required this.time});

  final double scale;
  final double time;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final active = CoordinatorBoard.active;
    final signed = active.fold(0, (sum, e) => sum + e.roster.length);
    final capacity = active.fold(0, (sum, e) => sum + e.event.capacity);
    final toFill = (capacity - signed).clamp(0, 1 << 30);
    final fill = capacity == 0 ? 0.0 : signed / capacity;
    return Container(
      padding: EdgeInsets.all(18 * s),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24 * s),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brandDark, AppColors.brand, AppColors.leafMid],
          stops: [0, 0.55, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.28),
            blurRadius: 26 * s,
            spreadRadius: -6 * s,
            offset: Offset(0, 14 * s),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your events at a glance',
                  style: TextStyle(
                    fontSize: 13.5 * s,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white.withValues(alpha: 0.85),
                  ),
                ),
                SizedBox(height: 10 * s),
                Row(
                  children: [
                    for (final (i, (value, label)) in [
                      ('${active.length}', 'Active'),
                      ('$signed', 'Signed up'),
                      ('$toFill', 'To fill'),
                    ].indexed) ...[
                      if (i > 0)
                        Container(
                          width: 1,
                          height: 34 * s,
                          margin: EdgeInsets.symmetric(horizontal: 12 * s),
                          color: AppColors.white.withValues(alpha: 0.2),
                        ),
                      Flexible(
                        child: Semantics(
                          container: true,
                          label: '$value $label',
                          excludeSemantics: true,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  value,
                                  style: TextStyle(
                                    fontSize: 22 * s,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.white,
                                  ),
                                ),
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 12 * s,
                                    color: AppColors.logoOnDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 12 * s),
          Semantics(
            label: '${(fill * 100).round()} percent of spots filled',
            excludeSemantics: true,
            child: SizedBox.square(
              dimension: 70 * s,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: fill),
                duration: const Duration(milliseconds: 1300),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: value,
                      strokeWidth: 7 * s,
                      strokeCap: StrokeCap.round,
                      backgroundColor: AppColors.white.withValues(alpha: 0.18),
                      color: AppColors.sun,
                    ),
                    Center(
                      child: Text(
                        '${(value * 100).round()}%',
                        style: TextStyle(
                          fontSize: 15 * s,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
