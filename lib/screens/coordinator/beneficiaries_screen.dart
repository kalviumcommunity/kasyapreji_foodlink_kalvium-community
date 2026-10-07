import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/coordinator.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import '../../widgets/app_nav.dart';
import '../../widgets/coordinator_page.dart';
import '../../widgets/coordinator_widgets.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/rise_in.dart';
import '../../navigation/transitions.dart';
import 'beneficiary_details_screen.dart';

enum _Tab {
  list('List'),
  add('Add New');

  const _Tab(this.label);

  final String label;
}

/// Beneficiaries, as in the Figma: List and Add New tabs. The list can be
/// searched; each place shows how many people it serves (new ones with a
/// blue dot) and opens its details: contact, address, meals this month and
/// the next delivery, with Schedule Delivery and Copy Phone. Add New is a
/// short form that puts the place at the top of the list.
///
/// A photo of volunteers serving a meal fades into the backdrop.
class BeneficiariesScreen extends StatefulWidget {
  const BeneficiariesScreen({super.key});

  static const String routeName = 'coordinator-beneficiaries';

  @override
  State<BeneficiariesScreen> createState() => _BeneficiariesScreenState();
}

class _BeneficiariesScreenState extends State<BeneficiariesScreen> {
  final _search = TextEditingController();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _contact = TextEditingController();
  final _phone = TextEditingController();
  _Tab _tab = _Tab.list;

  /// The type shown in the list, or null for all.
  String? _typeFilter;
  String _type = beneficiaryTypes.first;
  int _people = 50;
  bool _tried = false;

  @override
  void dispose() {
    for (final controller in [_search, _name, _address, _contact, _phone]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? get _nameError =>
      _name.text.trim().length < 3 ? 'Enter the place’s name' : null;
  String? get _addressError =>
      _address.text.trim().length < 3 ? 'Enter an address' : null;

  void _save() {
    setState(() => _tried = true);
    if (_nameError != null || _addressError != null) {
      HapticFeedback.heavyImpact();
      return;
    }
    HapticFeedback.mediumImpact();
    final name = _name.text.trim();
    CoordinatorBoard.addBeneficiary(
      Beneficiary(
        name: name,
        type: _type,
        people: _people,
        address: _address.text.trim(),
        contact: _contact.text.trim().isEmpty ? '—' : _contact.text.trim(),
        phone: _phone.text.trim().isEmpty ? '—' : _phone.text.trim(),
        mealsThisMonth: 0,
        nextDelivery: 'Not scheduled yet',
        colors:
            avatarColors[CoordinatorBoard.beneficiaries.value.length %
                avatarColors.length],
        isNew: true,
      ),
    );
    for (final controller in [_name, _address, _contact, _phone]) {
      controller.clear();
    }
    setState(() {
      _tried = false;
      _people = 50;
      _tab = _Tab.list;
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.brandDark,
          content: Text('$name added to your beneficiaries.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return CoordinatorPage(
      tab: CoordinatorTab.home,
      title: 'Beneficiaries',
      photo: 'assets/images/event_serving_line.jpg',
      listenTo: CoordinatorBoard.beneficiaries,
      action: _tab == _Tab.add
          ? (c) => PrimaryButton(
              label: 'Save Beneficiary',
              scale: c.scale * 0.92,
              time: c.time,
              onPressed: _save,
            )
          : null,
      body: (context, c) {
        final s = c.scale;
        return [
          CoordinatorTabs<_Tab>(
            values: _Tab.values,
            selected: _tab,
            label: (tab) => tab.label,
            scale: s,
            onChanged: (tab) => setState(() => _tab = tab),
          ),
          SizedBox(height: 16 * s),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 380),
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topCenter,
              children: [...previous, ?current],
            ),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween(
                  begin: Offset(
                    child.key == const ValueKey(_Tab.add) ? 0.06 : -0.06,
                    0,
                  ),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: KeyedSubtree(
              key: ValueKey(_tab),
              child: _tab == _Tab.list ? _list(s) : _form(s),
            ),
          ),
        ];
      },
    );
  }

  Widget _list(double s) {
    final query = _search.text.trim().toLowerCase();
    final all = CoordinatorBoard.beneficiaries.value;
    final places = [
      for (final place in all)
        if ((_typeFilter == null || place.type == _typeFilter) &&
            (query.isEmpty ||
                place.name.toLowerCase().contains(query) ||
                place.type.toLowerCase().contains(query)))
          place,
    ];
    final people = all.fold(0, (sum, place) => sum + place.people);
    final meals = all.fold(0, (sum, place) => sum + place.mealsThisMonth);
    final types = [
      null,
      ...{for (final place in all) place.type},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Summary(places: all.length, people: people, meals: meals, scale: s),
        SizedBox(height: 16 * s),
        CoordinatorSearch(
          controller: _search,
          hint: 'Search beneficiaries...',
          scale: s,
          onChanged: (_) => setState(() {}),
        ),
        SizedBox(height: 12 * s),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              for (final (i, type) in types.indexed) ...[
                if (i > 0) SizedBox(width: 8 * s),
                Semantics(
                  button: true,
                  selected: type == _typeFilter,
                  label: '${type ?? 'All'} filter',
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _typeFilter = type);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: EdgeInsets.symmetric(
                        horizontal: 14 * s,
                        vertical: 8 * s,
                      ),
                      decoration: BoxDecoration(
                        color: type == _typeFilter
                            ? AppColors.brand
                            : AppColors.socialFill,
                        borderRadius: BorderRadius.circular(18 * s),
                      ),
                      child: Text(
                        type ?? 'All',
                        style: TextStyle(
                          fontSize: 13.5 * s,
                          fontWeight: type == _typeFilter
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: type == _typeFilter
                              ? AppColors.white
                              : AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: 4 * s),
        if (places.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 40 * s),
            child: Text(
              'No beneficiaries match your search.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15 * s, color: AppColors.bodyText),
            ),
          ),
        for (final (i, place) in places.indexed)
          TweenAnimationBuilder<double>(
            key: ValueKey(place.name),
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 320 + i * 60),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) =>
                RiseIn(progress: value, distance: 14 * s, child: child!),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (i > 0) rowDivider(),
                TappableRow(
                  label: '${place.name}, ${place.people} people',
                  scale: s,
                  onTap: () => _open(place),
                  child: Row(
                    children: [
                      InitialsAvatar(
                        initials: initialsOf(place.name),
                        colors: place.colors,
                        size: 48 * s,
                        dot: place.isNew ? const Color(0xFF4A8FE0) : null,
                      ),
                      SizedBox(width: 16 * s),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              place.name,
                              style: TextStyle(
                                fontSize: 16 * s,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            SizedBox(height: 4 * s),
                            Text(
                              '${place.people} people · ${place.type}',
                              style: TextStyle(
                                fontSize: 14 * s,
                                color: AppColors.fieldIcon,
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
      ],
    );
  }

  Widget _form(double s) {
    Widget label(String text) => Padding(
      padding: EdgeInsets.only(top: 14 * s, bottom: 8 * s),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15 * s,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
      ),
    );
    Widget field(
      TextEditingController controller,
      String hint,
      IconData icon, {
      String? error,
      TextInputType? keyboard,
    }) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 54 * s,
          padding: EdgeInsets.symmetric(horizontal: 16 * s),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16 * s),
            border: Border.all(
              color: error != null ? AppColors.error : AppColors.fieldBorder,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20 * s, color: AppColors.leafLight),
              SizedBox(width: 12 * s),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboard,
                  textCapitalization: keyboard == null
                      ? TextCapitalization.words
                      : TextCapitalization.none,
                  onChanged: (_) {
                    if (_tried) setState(() {});
                  },
                  cursorColor: AppColors.brand,
                  style: TextStyle(fontSize: 15.5 * s, color: AppColors.ink),
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
        if (error != null)
          Padding(
            padding: EdgeInsets.only(top: 6 * s, left: 4 * s),
            child: Text(
              error,
              style: TextStyle(fontSize: 13 * s, color: AppColors.error),
            ),
          ),
      ],
    );

    return CoordinatorCard(
      scale: s,
      padding: EdgeInsets.fromLTRB(16 * s, 4 * s, 16 * s, 18 * s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          label('Name'),
          field(
            _name,
            'e.g. Hope Children’s Home',
            Icons.home_work_outlined,
            error: _tried ? _nameError : null,
          ),
          label('Type'),
          Wrap(
            spacing: 8 * s,
            runSpacing: 8 * s,
            children: [
              for (final type in beneficiaryTypes)
                Semantics(
                  button: true,
                  selected: type == _type,
                  label: type,
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _type = type);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                        horizontal: 13 * s,
                        vertical: 8 * s,
                      ),
                      decoration: BoxDecoration(
                        color: type == _type
                            ? AppColors.brand
                            : AppColors.white,
                        borderRadius: BorderRadius.circular(16 * s),
                        border: Border.all(
                          color: type == _type
                              ? AppColors.brand
                              : AppColors.fieldBorder,
                        ),
                      ),
                      child: Text(
                        type,
                        style: TextStyle(
                          fontSize: 13.5 * s,
                          fontWeight: FontWeight.w600,
                          color: type == _type
                              ? AppColors.white
                              : AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          label('People served'),
          Row(
            children: [
              for (final (icon, delta, what) in [
                (Icons.remove_rounded, -10, 'Fewer people'),
                (Icons.add_rounded, 10, 'More people'),
              ]) ...[
                if (delta > 0)
                  Expanded(
                    child: Text(
                      '$_people',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 26 * s,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                Semantics(
                  button: true,
                  label: what,
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(
                        () => _people = (_people + delta).clamp(10, 1000),
                      );
                    },
                    child: Container(
                      width: 44 * s,
                      height: 44 * s,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.roleChosenFill,
                      ),
                      child: Icon(icon, size: 22 * s, color: AppColors.brand),
                    ),
                  ),
                ),
              ],
            ],
          ),
          label('Address'),
          field(
            _address,
            'Street, area, city',
            Icons.place_outlined,
            error: _tried ? _addressError : null,
          ),
          label('Contact person'),
          field(_contact, 'Who to ask for', Icons.person_outline_rounded),
          label('Phone'),
          field(
            _phone,
            '+91 ...',
            Icons.phone_outlined,
            keyboard: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  void _open(Beneficiary place) =>
      Navigator.of(context)
          .push(softRoute(BeneficiaryDetailsScreen(name: place.name)));
}

/// The places at a glance on deep green.
class _Summary extends StatelessWidget {
  const _Summary({
    required this.places,
    required this.people,
    required this.meals,
    required this.scale,
  });

  final int places;
  final int people;
  final int meals;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.favorite_rounded,
                size: 16 * s,
                color: AppColors.logoOnDark,
              ),
              SizedBox(width: 6 * s),
              Text(
                'Who your work feeds',
                style: TextStyle(
                  fontSize: 13.5 * s,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white.withValues(alpha: 0.88),
                ),
              ),
            ],
          ),
          SizedBox(height: 12 * s),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1300),
            curve: Curves.easeOutCubic,
            builder: (context, count, _) => Row(
              children: [
                for (final (i, (value, label)) in [
                  (places, 'Places'),
                  (people, 'People'),
                  (meals, 'Meals / month'),
                ].indexed) ...[
                  if (i > 0)
                    Container(
                      width: 1,
                      height: 34 * s,
                      margin: EdgeInsets.symmetric(horizontal: 12 * s),
                      color: AppColors.white.withValues(alpha: 0.2),
                    ),
                  Expanded(
                    child: Semantics(
                      container: true,
                      label: '$value $label',
                      excludeSemantics: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              formatCount((value * count).round()),
                              style: TextStyle(
                                fontSize: 22 * s,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                          Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12 * s,
                              color: AppColors.logoOnDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
