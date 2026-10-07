import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/coordinator.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import '../../widgets/app_nav.dart';
import '../../widgets/coordinator_page.dart';
import '../../widgets/coordinator_widgets.dart';
import '../../widgets/rise_in.dart';

enum _Filter {
  all('All'),
  confirmed('Confirmed'),
  pending('Pending');

  const _Filter(this.label);

  final String label;
}

/// Volunteers, as in the Figma: the count in the title, a search bar, All,
/// Confirmed and Pending filters, and everyone with their status. Opening a
/// volunteer shows their details, events and hours, with Approve (for
/// pending volunteers), Message and Copy Phone.
///
/// A photo of volunteers outdoors fades into the backdrop behind the title.
class CoordinatorVolunteersScreen extends StatefulWidget {
  const CoordinatorVolunteersScreen({super.key});

  static const String routeName = 'coordinator-volunteers';

  @override
  State<CoordinatorVolunteersScreen> createState() =>
      _CoordinatorVolunteersScreenState();
}

class _CoordinatorVolunteersScreenState
    extends State<CoordinatorVolunteersScreen> {
  final _search = TextEditingController();
  _Filter _filter = _Filter.all;

  /// Most hours first, instead of A to Z.
  bool _byHours = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<VolunteerContact> get _people {
    final query = _search.text.trim().toLowerCase();
    return [
      for (final person in volunteerContacts)
        if ((query.isEmpty || person.name.toLowerCase().contains(query)) &&
            switch (_filter) {
              _Filter.all => true,
              _Filter.confirmed => !CoordinatorBoard.isPending(person.name),
              _Filter.pending => CoordinatorBoard.isPending(person.name),
            })
          person,
    ]..sort(
      (a, b) =>
          _byHours ? b.hours.compareTo(a.hours) : a.name.compareTo(b.name),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CoordinatorPage(
      tab: CoordinatorTab.volunteers,
      title: 'Volunteers (${volunteerContacts.length})',
      photo: 'assets/images/change_volunteers.jpg',
      listenTo: Listenable.merge([
        CoordinatorBoard.pending,
        CoordinatorBoard.events,
      ]),
      body: (context, c) {
        final s = c.scale;
        final people = _people;
        final pending = CoordinatorBoard.pending.value.length;
        final top = [...volunteerContacts]
          ..sort((a, b) => b.hours.compareTo(a.hours));
        return [
          _StatsStrip(
            confirmed: volunteerContacts.length - pending,
            pending: pending,
            hours: volunteerContacts.fold(0, (sum, p) => sum + p.hours),
            scale: s,
          ),
          SizedBox(height: 20 * s),
          Text(
            'Most hours this month',
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 19 * s,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          SizedBox(height: 12 * s),
          SizedBox(
            height: 150 * s,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: 6,
              separatorBuilder: (_, _) => SizedBox(width: 12 * s),
              itemBuilder: (context, i) => _TopCard(
                person: top[i],
                rank: i + 1,
                scale: s,
                onTap: () => _openPerson(top[i], s),
              ),
            ),
          ),
          SizedBox(height: 20 * s),
          CoordinatorSearch(
            controller: _search,
            hint: 'Search volunteers...',
            scale: s,
            onChanged: (_) => setState(() {}),
          ),
          SizedBox(height: 14 * s),
          Row(
            children: [
              for (final (i, filter) in _Filter.values.indexed) ...[
                if (i > 0) SizedBox(width: 10 * s),
                Expanded(
                  child: _FilterPill(
                    label: filter == _Filter.pending && pending > 0
                        ? '${filter.label} ($pending)'
                        : filter.label,
                    selected: filter == _filter,
                    scale: s,
                    onTap: () => setState(() => _filter = filter),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 10 * s),
          Row(
            children: [
              Text(
                '${people.length} shown',
                style: TextStyle(
                  fontSize: 13 * s,
                  fontWeight: FontWeight.w600,
                  color: AppColors.fieldIcon,
                ),
              ),
              const Spacer(),
              Semantics(
                button: true,
                label: _byHours ? 'Sort A to Z' : 'Sort by most hours',
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _byHours = !_byHours);
                  },
                  child: Row(
                    children: [
                      Icon(
                        Icons.swap_vert_rounded,
                        size: 18 * s,
                        color: AppColors.brand,
                      ),
                      SizedBox(width: 4 * s),
                      Text(
                        _byHours ? 'Most hours' : 'A to Z',
                        style: TextStyle(
                          fontSize: 13.5 * s,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brand,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topCenter,
              children: [...previous, ?current],
            ),
            child: Column(
              key: ValueKey(
                '$_filter/${people.length}/${_search.text}/$_byHours',
              ),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (people.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 40 * s),
                    child: Text(
                      _filter == _Filter.pending
                          ? 'Everyone has been approved.'
                          : 'No volunteers match your search.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15 * s,
                        color: AppColors.bodyText,
                      ),
                    ),
                  ),
                for (final (i, person) in people.indexed)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 300 + (i % 10) * 50),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) => RiseIn(
                      progress: value,
                      distance: 14 * s,
                      child: child!,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (i > 0) rowDivider(),
                        _VolunteerRow(
                          person: person,
                          scale: s,
                          onTap: () => _openPerson(person, s),
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

  void _openPerson(VolunteerContact person, double s) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.ink.withValues(alpha: 0.4),
      constraints: BoxConstraints(maxWidth: 600 * s),
      builder: (_) => _VolunteerSheet(person: person, scale: s),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
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
  Widget build(BuildContext context) {
    final s = scale;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label filter',
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            height: 46 * s,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.brand : AppColors.socialFill,
              borderRadius: BorderRadius.circular(23 * s),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brand.withValues(alpha: selected ? 0.25 : 0),
                  blurRadius: 12 * s,
                  offset: Offset(0, 4 * s),
                ),
              ],
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8 * s),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14.5 * s,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? AppColors.white : AppColors.bodyText,
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

class _VolunteerRow extends StatelessWidget {
  const _VolunteerRow({
    required this.person,
    required this.scale,
    required this.onTap,
  });

  final VolunteerContact person;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final pending = CoordinatorBoard.isPending(person.name);
    return TappableRow(
      label: '${person.name}, ${pending ? 'Pending' : 'Confirmed'}',
      scale: s,
      onTap: onTap,
      child: Row(
        children: [
          InitialsAvatar(
            initials: person.initials,
            colors: AppColors.avatar,
            size: 54 * s,
            person: true,
          ),
          SizedBox(width: 16 * s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person.name,
                  style: TextStyle(
                    fontSize: 16 * s,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                SizedBox(height: 4 * s),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    pending ? 'Pending' : 'Confirmed',
                    key: ValueKey(pending),
                    style: TextStyle(
                      fontSize: 14 * s,
                      fontWeight: FontWeight.w600,
                      color: pending ? AppColors.sun : AppColors.leafMid,
                    ),
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

/// A volunteer's details: status, contact, hours and events, with Approve,
/// Message and Copy Phone.
class _VolunteerSheet extends StatefulWidget {
  const _VolunteerSheet({required this.person, required this.scale});

  final VolunteerContact person;
  final double scale;

  @override
  State<_VolunteerSheet> createState() => _VolunteerSheetState();
}

class _VolunteerSheetState extends State<_VolunteerSheet> {
  late final _note = TextEditingController(
    text: CoordinatorBoard.notes.value[widget.person.name] ?? '',
  );

  VolunteerContact get person => widget.person;

  @override
  void dispose() {
    CoordinatorBoard.setNote(person.name, _note.text.trim());
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    return ValueListenableBuilder(
      valueListenable: CoordinatorBoard.pending,
      builder: (context, _, _) {
        final pending = CoordinatorBoard.isPending(person.name);
        final events = person.events;
        return Container(
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
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.fieldBorder,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  SizedBox(height: 18 * s),
                  Row(
                    children: [
                      InitialsAvatar(
                        initials: person.initials,
                        colors: person.colors,
                        size: 64 * s,
                      ),
                      SizedBox(width: 14 * s),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              person.name,
                              style: TextStyle(
                                fontFamily: AppFonts.display,
                                fontSize: 22 * s,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            SizedBox(height: 4 * s),
                            StatusPill(
                              label: pending ? 'Pending' : 'Confirmed',
                              fill: pending
                                  ? AppColors.tagFoodFill
                                  : AppColors.roleChosenFill,
                              ink: pending
                                  ? AppColors.tagFoodText
                                  : AppColors.brand,
                              scale: s,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 18 * s),
                  Row(
                    children: [
                      for (final (i, (value, label)) in [
                        ('${events.length}', 'Events'),
                        ('${person.hours}', 'Hours'),
                        (
                          '${{for (final e in events) ...e.roster.where((r) => r.name == person.name).map((r) => r.role.name)}.length}',
                          'Roles',
                        ),
                      ].indexed) ...[
                        if (i > 0) SizedBox(width: 10 * s),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12 * s),
                            decoration: BoxDecoration(
                              color: AppColors.roleChosenFill,
                              borderRadius: BorderRadius.circular(16 * s),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  value,
                                  style: TextStyle(
                                    fontSize: 20 * s,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 12.5 * s,
                                    color: AppColors.bodyText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 16 * s),
                  Row(
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        size: 18 * s,
                        color: AppColors.leafLight,
                      ),
                      SizedBox(width: 8 * s),
                      Text(
                        person.phone,
                        style: TextStyle(
                          fontSize: 15 * s,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                  if (events.isNotEmpty) ...[
                    SizedBox(height: 16 * s),
                    Text(
                      'Signed up for',
                      style: TextStyle(
                        fontSize: 14.5 * s,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    SizedBox(height: 8 * s),
                    Wrap(
                      spacing: 8 * s,
                      runSpacing: 8 * s,
                      children: [
                        for (final managed in events)
                          StatusPill(
                            label: managed.title,
                            fill: AppColors.white,
                            ink: AppColors.ink,
                            scale: s,
                          ),
                      ],
                    ),
                  ],
                  ..._assign(events, s),
                  SizedBox(height: 16 * s),
                  Text(
                    'Private note',
                    style: TextStyle(
                      fontSize: 14.5 * s,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  SizedBox(height: 8 * s),
                  Container(
                    padding: EdgeInsets.all(14 * s),
                    decoration: BoxDecoration(
                      color: AppColors.tagFoodFill.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16 * s),
                    ),
                    child: TextField(
                      controller: _note,
                      minLines: 2,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      cursorColor: AppColors.brand,
                      style: TextStyle(
                        fontSize: 14.5 * s,
                        color: AppColors.ink,
                      ),
                      decoration: InputDecoration.collapsed(
                        hintText:
                            'Only you can see this, e.g. great with kids, '
                            'has a van...',
                        hintStyle: TextStyle(
                          fontSize: 14.5 * s,
                          color: AppColors.fieldHint,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 22 * s),
                  if (pending) ...[
                    _SheetAction(
                      icon: Icons.how_to_reg_rounded,
                      label: 'Approve ${person.name.split(' ').first}',
                      fill: AppColors.brand,
                      ink: AppColors.white,
                      scale: s,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        CoordinatorBoard.approve(person.name);
                      },
                    ),
                    SizedBox(height: 10 * s),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: _SheetAction(
                          icon: Icons.chat_bubble_outline_rounded,
                          label: 'Message',
                          fill: pending
                              ? AppColors.roleChosenFill
                              : AppColors.brand,
                          ink: pending ? AppColors.brand : AppColors.white,
                          scale: s,
                          onTap: () async {
                            final sent = await showBroadcastSheet(
                              context,
                              scale: s,
                              recipient: person.name,
                            );
                            if (sent != null && context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                      ),
                      SizedBox(width: 10 * s),
                      Expanded(
                        child: _SheetAction(
                          icon: Icons.copy_rounded,
                          label: 'Copy Phone',
                          fill: AppColors.socialFill,
                          ink: AppColors.ink,
                          scale: s,
                          onTap: () {
                            Clipboard.setData(
                              ClipboardData(text: person.phone),
                            );
                            HapticFeedback.selectionClick();
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Upcoming events they're not on yet, each a tap away from adding them.
  List<Widget> _assign(List<ManagedEvent> events, double s) {
    final open = [
      for (final managed in CoordinatorBoard.active)
        if (!events.contains(managed) &&
            managed.roster.length < managed.event.capacity)
          managed,
    ];
    if (open.isEmpty) return const [];
    return [
      SizedBox(height: 16 * s),
      Text(
        'Add to an event',
        style: TextStyle(
          fontSize: 14.5 * s,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
      ),
      SizedBox(height: 8 * s),
      Wrap(
        spacing: 8 * s,
        runSpacing: 8 * s,
        children: [
          for (final managed in open)
            Semantics(
              button: true,
              label: 'Add to ${managed.title}',
              excludeSemantics: true,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  CoordinatorBoard.assign(managed.title, person.name);
                  setState(() {});
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12 * s,
                    vertical: 8 * s,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16 * s),
                    border: Border.all(color: AppColors.roleChosenBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_rounded,
                        size: 16 * s,
                        color: AppColors.brand,
                      ),
                      SizedBox(width: 4 * s),
                      Text(
                        managed.title,
                        style: TextStyle(
                          fontSize: 13 * s,
                          fontWeight: FontWeight.w600,
                          color: AppColors.brand,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    ];
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.fill,
    required this.ink,
    required this.scale,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color fill;
  final Color ink;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 52 * s,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(26 * s),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 19 * s, color: ink),
                SizedBox(width: 8 * s),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.5 * s,
                      fontWeight: FontWeight.w700,
                      color: ink,
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
}

/// Confirmed, pending and hours given, as three tiles.
class _StatsStrip extends StatelessWidget {
  const _StatsStrip({
    required this.confirmed,
    required this.pending,
    required this.hours,
    required this.scale,
  });

  final int confirmed;
  final int pending;
  final int hours;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Row(
      children: [
        for (final (i, (value, label, icon, color)) in [
          (confirmed, 'Confirmed', Icons.verified_rounded, AppColors.brand),
          (pending, 'Pending', Icons.hourglass_top_rounded, AppColors.sun),
          (
            hours,
            'Hours given',
            Icons.schedule_rounded,
            AppColors.tagLearnText,
          ),
        ].indexed) ...[
          if (i > 0) SizedBox(width: 10 * s),
          Expanded(
            child: Semantics(
              container: true,
              label: '$value $label',
              excludeSemantics: true,
              child: CoordinatorCard(
                scale: s,
                padding: EdgeInsets.symmetric(
                  vertical: 12 * s,
                  horizontal: 8 * s,
                ),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: value.toDouble()),
                  duration: Duration(milliseconds: 900 + i * 150),
                  curve: Curves.easeOutCubic,
                  builder: (context, shown, _) => Column(
                    children: [
                      Icon(icon, size: 18 * s, color: color),
                      SizedBox(height: 4 * s),
                      Text(
                        '${shown.round()}',
                        style: TextStyle(
                          fontSize: 21 * s,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12 * s,
                          color: AppColors.bodyText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// A top volunteer: rank medal, avatar, name and hours.
class _TopCard extends StatelessWidget {
  const _TopCard({
    required this.person,
    required this.rank,
    required this.scale,
    required this.onTap,
  });

  final VolunteerContact person;
  final int rank;
  final double scale;
  final VoidCallback onTap;

  static const _medals = [
    Color(0xFFE0A63A),
    Color(0xFFA9B4BE),
    Color(0xFFC08457),
  ];

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Semantics(
      button: true,
      label: 'Number $rank: ${person.name}, ${person.hours} hours',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 500 + rank * 90),
          curve: Curves.easeOutBack,
          builder: (context, pop, child) =>
              Transform.scale(scale: pop.clamp(0.0, 1.2), child: child),
          child: Container(
            width: 116 * s,
            padding: EdgeInsets.all(12 * s),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(20 * s),
              border: Border.all(color: AppColors.white),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brand.withValues(alpha: 0.08),
                  blurRadius: 18 * s,
                  offset: Offset(0, 6 * s),
                ),
              ],
            ),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    InitialsAvatar(
                      initials: person.initials,
                      colors: person.colors,
                      size: 52 * s,
                    ),
                    Positioned(
                      right: -4 * s,
                      top: -4 * s,
                      child: Container(
                        width: 22 * s,
                        height: 22 * s,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: rank <= 3
                              ? _medals[rank - 1]
                              : AppColors.brand,
                          border: Border.all(color: AppColors.white, width: 2),
                        ),
                        child: Text(
                          '$rank',
                          style: TextStyle(
                            fontSize: 11 * s,
                            fontWeight: FontWeight.w800,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8 * s),
                Text(
                  person.name.split(' ').first,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14 * s,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  '${person.hours} hrs',
                  style: TextStyle(
                    fontSize: 12.5 * s,
                    fontWeight: FontWeight.w600,
                    color: AppColors.leafMid,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
