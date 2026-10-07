import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/coordinator.dart';
import '../../data/sample_events.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import '../../widgets/app_nav.dart';
import '../../widgets/coordinator_page.dart';
import '../../widgets/event_tile.dart';
import '../../widgets/primary_button.dart';

/// Create Event, as in the Figma: a cover photo, the title, category, date
/// and time, location and description, then Create Event. Volunteers needed
/// and how long it runs are added below the description.
///
/// The cover opens a choice of photos; the category opens its options in
/// place; Date & Time opens the date and time pickers. Create checks the
/// title, date and location, adds the event to the coordinator's list, and
/// returns its title.
class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  static const _covers = [
    'assets/images/impact_packing.jpg',
    'assets/images/event_community_meal.jpg',
    'assets/images/event_serving_line.jpg',
    'assets/images/event_harvest_greens.jpg',
    'assets/images/event_tree_planting.jpg',
    'assets/images/event_food_warehouse.jpg',
    'assets/images/notifications_community_farm.jpg',
    'assets/images/splash_giving.jpg',
  ];

  /// The Figma's category names, with the type each becomes.
  static const _categories = [
    (
      'Food Distribution',
      EventCategory.foodDrive,
      Icons.volunteer_activism_rounded,
    ),
    ('Community', EventCategory.community, Icons.diversity_3_rounded),
    ('Education', EventCategory.education, Icons.menu_book_rounded),
  ];

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  final _title = TextEditingController();
  final _location = TextEditingController();
  final _description = TextEditingController();

  String? _cover;
  int _category = 0;
  bool _categoryOpen = false;
  DateTime? _date;
  TimeOfDay? _time;
  int _hours = 3;
  int _needed = 20;
  bool _tried = false;

  static const _bringOptions = [
    'Water bottle',
    'Comfortable shoes',
    'Gloves',
    'Apron',
    'Cap or hat',
    'Notebook',
  ];
  final Set<String> _bring = {'Water bottle'};

  /// The cover shown and used: the chosen photo, or one for the category.
  String get _photo =>
      _cover ??
      switch (_categories[_category].$2) {
        EventCategory.foodDrive => 'assets/images/impact_packing.jpg',
        EventCategory.community => 'assets/images/change_volunteers.jpg',
        EventCategory.education => 'assets/images/splash_giving.jpg',
      };

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _description.dispose();
    super.dispose();
  }

  String? get _titleError =>
      _title.text.trim().length < 3 ? 'Give the event a name' : null;
  String? get _dateError =>
      _date == null || _time == null ? 'Pick a date and time' : null;
  String? get _locationError =>
      _location.text.trim().length < 2 ? 'Where is it happening?' : null;

  static String _clock(int hour, int minute) {
    final shown = hour % 12 == 0 ? 12 : hour % 12;
    return '$shown:${minute.toString().padLeft(2, '0')} '
        '${hour < 12 ? 'AM' : 'PM'}';
  }

  String? get _dateLabel {
    final date = _date;
    final time = _time;
    if (date == null) return null;
    final day =
        '${_weekdays[date.weekday - 1]}, ${date.day} ${_months[date.month - 1]}';
    return time == null ? day : '$day · ${_clock(time.hour, time.minute)}';
  }

  Theme _themed(BuildContext context, Widget child) => Theme(
    data: Theme.of(context).copyWith(
      colorScheme: Theme.of(context).colorScheme.copyWith(
        primary: AppColors.brand,
        onPrimary: AppColors.white,
        surface: AppColors.surface,
      ),
    ),
    child: child,
  );

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final now = DateUtils.dateOnly(DateTime.now());
    final date = await showDatePicker(
      context: context,
      initialDate: _date ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => _themed(context, child!),
    );
    if (date == null || !mounted) return;
    setState(() => _date = date);
    final time = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 10, minute: 0),
      builder: (context, child) => _themed(context, child!),
    );
    if (time == null || !mounted) return;
    setState(() => _time = time);
  }

  Future<void> _pickCover(double s) async {
    FocusScope.of(context).unfocus();
    final cover = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.ink.withValues(alpha: 0.4),
      constraints: BoxConstraints(maxWidth: 600 * s),
      builder: (sheetContext) => Container(
        padding: EdgeInsets.fromLTRB(20 * s, 12 * s, 20 * s, 20 * s),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28 * s)),
        ),
        child: SafeArea(
          top: false,
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
              SizedBox(height: 14 * s),
              Text(
                'Choose a cover photo',
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 20 * s,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              SizedBox(height: 14 * s),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                mainAxisSpacing: 10 * s,
                crossAxisSpacing: 10 * s,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final (i, photo) in _covers.indexed)
                    Semantics(
                      button: true,
                      selected: photo == _cover,
                      label: 'Cover photo ${i + 1}',
                      excludeSemantics: true,
                      child: GestureDetector(
                        onTap: () => Navigator.of(sheetContext).pop(photo),
                        child: Container(
                          padding: EdgeInsets.all(photo == _cover ? 3 * s : 0),
                          decoration: BoxDecoration(
                            color: AppColors.brand,
                            borderRadius: BorderRadius.circular(16 * s),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14 * s),
                            child: Image.asset(photo, fit: BoxFit.cover),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (cover != null && mounted) {
      HapticFeedback.selectionClick();
      setState(() => _cover = cover);
    }
  }

  void _create() {
    setState(() => _tried = true);
    if (_titleError != null || _dateError != null || _locationError != null) {
      HapticFeedback.heavyImpact();
      return;
    }
    HapticFeedback.mediumImpact();
    final (_, category, _) = _categories[_category];
    final date = _date!;
    final time = _time!;
    final weekday = _weekdays[date.weekday - 1];
    final month = _months[date.month - 1];
    final title = _title.text.trim();
    final place = _location.text.trim();
    final start = _clock(time.hour, time.minute);
    final end = _clock((time.hour + _hours) % 24, time.minute);
    final about = _description.text.trim();
    final event = VolunteerEvent(
      title: title,
      when: '$weekday, ${date.day} $month · $start',
      place: place,
      category: category,
      photo: _photo,
      date: '$weekday, ${date.day} $month ${date.year}',
      hours: '$start – $end',
      address: place,
      about: about.isEmpty ? 'A new event by Riverside Food Bank.' : about,
      going: 0,
      capacity: _needed,
      impact: ('0', 'Meals'),
      duration: '$_hours hrs',
      bring: [
        for (final item in _bringOptions)
          if (_bring.contains(item)) item,
      ],
      organiser: CoordinatorBoard.organisation.value.name,
    );
    CoordinatorBoard.addEvent(ManagedEvent(event: event, roster: const []));
    Navigator.of(context).pop(title);
  }

  @override
  Widget build(BuildContext context) {
    return CoordinatorPage(
      tab: CoordinatorTab.events,
      title: 'Create Event',
      centerTitle: true,
      showBar: false,
      maxWidth: 720,
      photo: 'assets/images/event_community_meal.jpg',
      action: (c) => PrimaryButton(
        label: 'Create Event',
        scale: c.scale * 0.92,
        time: c.time,
        onPressed: _create,
      ),
      body: (context, c) {
        final s = c.scale;
        return [
          _coverCard(s),
          SizedBox(height: 22 * s),
          _label('Event Title', s),
          _UnderlineField(
            controller: _title,
            hint: 'e.g. Saturday Soup Kitchen',
            scale: s,
            error: _tried ? _titleError : null,
            onChanged: (_) => setState(() {}),
          ),
          SizedBox(height: 20 * s),
          _label('Category', s),
          _categoryField(s),
          SizedBox(height: 20 * s),
          _label('Date & Time', s),
          _BoxField(
            icon: Icons.event_rounded,
            text: _dateLabel,
            hint: 'Pick a date and time',
            scale: s,
            error: _tried ? _dateError : null,
            semanticLabel: 'Date and time: ${_dateLabel ?? 'not set'}',
            onTap: _pickDate,
          ),
          SizedBox(height: 12 * s),
          _InputBox(
            controller: _location,
            icon: Icons.place_outlined,
            hint: 'Location',
            scale: s,
            error: _tried ? _locationError : null,
            onChanged: (_) => setState(() {}),
          ),
          SizedBox(height: 20 * s),
          _label('Description', s),
          _InputBox(
            controller: _description,
            hint: 'Tell us about the event...',
            scale: s,
            lines: 3,
            grey: true,
            onChanged: (_) {},
          ),
          SizedBox(height: 20 * s),
          Row(
            children: [
              Expanded(
                child: _Stepper(
                  label: 'Volunteers needed',
                  value: '$_needed',
                  scale: s,
                  onMinus: () =>
                      setState(() => _needed = (_needed - 5).clamp(5, 200)),
                  onPlus: () =>
                      setState(() => _needed = (_needed + 5).clamp(5, 200)),
                ),
              ),
              SizedBox(width: 12 * s),
              Expanded(
                child: _Stepper(
                  label: 'Length',
                  value: '$_hours hrs',
                  scale: s,
                  onMinus: () =>
                      setState(() => _hours = (_hours - 1).clamp(1, 12)),
                  onPlus: () =>
                      setState(() => _hours = (_hours + 1).clamp(1, 12)),
                ),
              ),
            ],
          ),
          SizedBox(height: 20 * s),
          _label('What to bring', s),
          Wrap(
            spacing: 8 * s,
            runSpacing: 8 * s,
            children: [
              for (final item in _bringOptions)
                Semantics(
                  button: true,
                  selected: _bring.contains(item),
                  label: item,
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        if (!_bring.remove(item)) _bring.add(item);
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                        horizontal: 12 * s,
                        vertical: 8 * s,
                      ),
                      decoration: BoxDecoration(
                        color: _bring.contains(item)
                            ? AppColors.roleChosenFill
                            : AppColors.white,
                        borderRadius: BorderRadius.circular(16 * s),
                        border: Border.all(
                          color: _bring.contains(item)
                              ? AppColors.roleChosenBorder
                              : AppColors.fieldBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _bring.contains(item)
                                ? Icons.check_rounded
                                : Icons.add_rounded,
                            size: 15 * s,
                            color: AppColors.brand,
                          ),
                          SizedBox(width: 5 * s),
                          Text(
                            item,
                            style: TextStyle(
                              fontSize: 13.5 * s,
                              fontWeight: FontWeight.w600,
                              color: _bring.contains(item)
                                  ? AppColors.brand
                                  : AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 24 * s),
          _label('How volunteers will see it', s),
          _preview(s),
        ];
      },
    );
  }

  /// A live preview of the event's card in Explore.
  Widget _preview(double s) {
    final (name, category, _) = _categories[_category];
    final title = _title.text.trim();
    final place = _location.text.trim();
    return Semantics(
      container: true,
      label: 'Preview of ${title.isEmpty ? 'your event' : title}',
      child: CoordinatorCard(
        scale: s,
        padding: EdgeInsets.all(10 * s),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16 * s),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      child: Image.asset(
                        _photo,
                        key: ValueKey(_photo),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    Positioned(
                      left: 10 * s,
                      top: 10 * s,
                      child: EventCategoryTag(
                        category: category,
                        scale: s,
                        shadow: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(6 * s, 12 * s, 6 * s, 4 * s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.isEmpty ? 'Your event title' : title,
                    style: TextStyle(
                      fontSize: 17 * s,
                      fontWeight: FontWeight.w700,
                      color: title.isEmpty
                          ? AppColors.fieldHint
                          : AppColors.ink,
                    ),
                  ),
                  SizedBox(height: 8 * s),
                  for (final (icon, text) in [
                    (Icons.schedule_rounded, _dateLabel ?? 'Date and time'),
                    (Icons.place_outlined, place.isEmpty ? 'Location' : place),
                    (
                      Icons.groups_rounded,
                      '$_needed spots · $_hours hrs · $name',
                    ),
                  ])
                    Padding(
                      padding: EdgeInsets.only(bottom: 5 * s),
                      child: Row(
                        children: [
                          Icon(icon, size: 15 * s, color: AppColors.leafLight),
                          SizedBox(width: 6 * s),
                          Expanded(
                            child: Text(
                              text,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5 * s,
                                color: AppColors.bodyText,
                              ),
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
      ),
    );
  }

  Widget _label(String text, double s) => Padding(
    padding: EdgeInsets.only(bottom: 8 * s),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 15 * s,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
    ),
  );

  /// The Figma's dark green "Add Cover Photo" card, or the chosen photo.
  Widget _coverCard(double s) {
    final cover = _cover;
    return Semantics(
      button: true,
      label: cover == null ? 'Add Cover Photo' : 'Change cover photo',
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => _pickCover(s),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 150 * s,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22 * s),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF4F5E48),
                  AppColors.brandDark,
                  Color(0xFF6E7A5E),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brand.withValues(alpha: 0.2),
                  blurRadius: 22 * s,
                  offset: Offset(0, 10 * s),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: cover == null
                      ? const SizedBox.expand()
                      : Image.asset(
                          cover,
                          key: ValueKey(cover),
                          fit: BoxFit.cover,
                        ),
                ),
                if (cover != null)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.splashScrim.withValues(alpha: 0),
                          AppColors.splashScrim.withValues(alpha: 0.55),
                        ],
                      ),
                    ),
                  ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40 * s,
                        height: 40 * s,
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(12 * s),
                        ),
                        child: Icon(
                          cover == null
                              ? Icons.add_photo_alternate_outlined
                              : Icons.edit_outlined,
                          size: 21 * s,
                          color: AppColors.ink,
                        ),
                      ),
                      SizedBox(height: 10 * s),
                      Text(
                        cover == null ? 'Add Cover Photo' : 'Change Photo',
                        style: TextStyle(
                          fontSize: 15 * s,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
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
    );
  }

  /// The Figma's category box; opens its choices just below.
  Widget _categoryField(double s) {
    final (name, _, icon) = _categories[_category];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BoxField(
          icon: icon,
          text: name,
          hint: '',
          scale: s,
          semanticLabel: 'Category: $name',
          trailing: AnimatedRotation(
            turns: _categoryOpen ? 0.5 : 0,
            duration: const Duration(milliseconds: 250),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 24 * s,
              color: AppColors.fieldIcon,
            ),
          ),
          onTap: () {
            HapticFeedback.selectionClick();
            FocusScope.of(context).unfocus();
            setState(() => _categoryOpen = !_categoryOpen);
          },
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: !_categoryOpen
              ? const SizedBox(width: double.infinity)
              : Container(
                  margin: EdgeInsets.only(top: 8 * s),
                  padding: EdgeInsets.all(6 * s),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16 * s),
                    border: Border.all(color: AppColors.fieldBorder),
                  ),
                  child: Column(
                    children: [
                      for (final (i, (label, _, icon)) in _categories.indexed)
                        Semantics(
                          button: true,
                          selected: i == _category,
                          label: label,
                          excludeSemantics: true,
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _category = i;
                                _categoryOpen = false;
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.all(12 * s),
                              decoration: BoxDecoration(
                                color: i == _category
                                    ? AppColors.roleChosenFill
                                    : AppColors.white.withValues(alpha: 0),
                                borderRadius: BorderRadius.circular(12 * s),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    icon,
                                    size: 20 * s,
                                    color: AppColors.brand,
                                  ),
                                  SizedBox(width: 12 * s),
                                  Expanded(
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 15 * s,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                  ),
                                  if (i == _category)
                                    Icon(
                                      Icons.check_rounded,
                                      size: 19 * s,
                                      color: AppColors.brand,
                                    ),
                                ],
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
  }
}

/// The Figma's title field: text over a single line that turns green when
/// focused.
class _UnderlineField extends StatefulWidget {
  const _UnderlineField({
    required this.controller,
    required this.hint,
    required this.scale,
    required this.onChanged,
    this.error,
  });

  final TextEditingController controller;
  final String hint;
  final double scale;
  final ValueChanged<String> onChanged;
  final String? error;

  @override
  State<_UnderlineField> createState() => _UnderlineFieldState();
}

class _UnderlineFieldState extends State<_UnderlineField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    final error = widget.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: widget.controller,
          focusNode: _focus,
          textCapitalization: TextCapitalization.words,
          onChanged: widget.onChanged,
          cursorColor: AppColors.brand,
          style: TextStyle(fontSize: 17 * s, color: AppColors.ink),
          decoration: InputDecoration.collapsed(
            hintText: widget.hint,
            hintStyle: TextStyle(fontSize: 17 * s, color: AppColors.fieldHint),
          ),
        ),
        SizedBox(height: 10 * s),
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: _focus.hasFocus ? 2 : 1,
          color: error != null
              ? AppColors.error
              : _focus.hasFocus
              ? AppColors.brand
              : AppColors.fieldBorder,
        ),
        if (error != null) _ErrorText(text: error, scale: s),
      ],
    );
  }
}

/// A white box that shows a value and opens a picker.
class _BoxField extends StatelessWidget {
  const _BoxField({
    required this.icon,
    required this.text,
    required this.hint,
    required this.scale,
    required this.semanticLabel,
    required this.onTap,
    this.trailing,
    this.error,
  });

  final IconData icon;
  final String? text;
  final String hint;
  final double scale;
  final String semanticLabel;
  final VoidCallback onTap;
  final Widget? trailing;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          label: semanticLabel,
          excludeSemantics: true,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                height: 56 * s,
                padding: EdgeInsets.symmetric(horizontal: 16 * s),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16 * s),
                  border: Border.all(
                    color: error != null
                        ? AppColors.error
                        : AppColors.fieldBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(icon, size: 20 * s, color: AppColors.leafLight),
                    SizedBox(width: 12 * s),
                    Expanded(
                      child: Text(
                        text ?? hint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15.5 * s,
                          color: text == null
                              ? AppColors.fieldHint
                              : AppColors.ink,
                        ),
                      ),
                    ),
                    trailing ??
                        Icon(
                          Icons.calendar_month_outlined,
                          size: 20 * s,
                          color: AppColors.fieldIcon,
                        ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (error != null) _ErrorText(text: error!, scale: s),
      ],
    );
  }
}

/// A text box: white, or [grey] as the Figma's description.
class _InputBox extends StatelessWidget {
  const _InputBox({
    required this.controller,
    required this.hint,
    required this.scale,
    required this.onChanged,
    this.icon,
    this.lines = 1,
    this.grey = false,
    this.error,
  });

  final TextEditingController controller;
  final String hint;
  final double scale;
  final ValueChanged<String> onChanged;
  final IconData? icon;
  final int lines;
  final bool grey;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          constraints: BoxConstraints(minHeight: 56 * s),
          padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 16 * s),
          decoration: BoxDecoration(
            color: grey ? AppColors.socialFill : AppColors.white,
            borderRadius: BorderRadius.circular(16 * s),
            border: Border.all(
              color: error != null ? AppColors.error : AppColors.fieldBorder,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20 * s, color: AppColors.leafLight),
                SizedBox(width: 12 * s),
              ],
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: lines,
                  maxLines: lines + 2,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: onChanged,
                  cursorColor: AppColors.brand,
                  style: TextStyle(
                    fontSize: 15.5 * s,
                    height: 1.4,
                    color: AppColors.ink,
                  ),
                  decoration: InputDecoration.collapsed(
                    hintText: hint,
                    hintStyle: TextStyle(
                      fontSize: 15.5 * s,
                      color: AppColors.fieldHint,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (error != null) _ErrorText(text: error!, scale: s),
      ],
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText({required this.text, required this.scale});

  final String text;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Padding(
      padding: EdgeInsets.only(top: 6 * s, left: 4 * s),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 15 * s,
            color: AppColors.error,
          ),
          SizedBox(width: 5 * s),
          Text(
            text,
            style: TextStyle(fontSize: 13 * s, color: AppColors.error),
          ),
        ],
      ),
    );
  }
}

/// A small − value + control.
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.scale,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;
  final String value;
  final double scale;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    Widget button(IconData icon, String what, VoidCallback onTap) => Semantics(
      button: true,
      label: '$what $label',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          width: 34 * s,
          height: 34 * s,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.roleChosenFill,
          ),
          child: Icon(icon, size: 18 * s, color: AppColors.brand),
        ),
      ),
    );
    return Container(
      padding: EdgeInsets.all(12 * s),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16 * s),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12.5 * s, color: AppColors.fieldIcon),
          ),
          SizedBox(height: 8 * s),
          Row(
            children: [
              button(Icons.remove_rounded, 'Fewer', onMinus),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 18 * s,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
              button(Icons.add_rounded, 'More', onPlus),
            ],
          ),
        ],
      ),
    );
  }
}
