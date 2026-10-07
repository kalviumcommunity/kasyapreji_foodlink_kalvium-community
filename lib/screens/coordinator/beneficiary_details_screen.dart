import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/coordinator.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import '../../widgets/app_nav.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/coordinator_page.dart';
import '../../widgets/coordinator_widgets.dart';
import '../../widgets/primary_button.dart';

/// One place the coordinator's events feed: who they are, how many people
/// they serve and how many meals they've had, meals over the last four
/// months as bars, upcoming deliveries (with any just scheduled), and their
/// contact, each detail copied with a tap. Schedule Delivery picks a day
/// and time and adds it to the list.
class BeneficiaryDetailsScreen extends StatelessWidget {
  const BeneficiaryDetailsScreen({super.key, required this.name});

  final String name;

  Beneficiary get _place => CoordinatorBoard.beneficiaries.value.firstWhere(
    (place) => place.name == name,
  );

  static const _months = ['Jul', 'Aug', 'Sep', 'Oct'];
  static const _shape = [0.72, 0.84, 0.93, 1.0];

  Future<void> _schedule(BuildContext context) async {
    final now = DateUtils.dateOnly(DateTime.now());
    Widget themed(BuildContext context, Widget? child) => Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme
            .copyWith(primary: AppColors.brand),
      ),
      child: child!,
    );
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      builder: themed,
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 12, minute: 0),
      builder: themed,
    );
    if (time == null || !context.mounted) return;
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
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
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final label =
        '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} · '
        '$hour:${time.minute.toString().padLeft(2, '0')} '
        '${time.hour < 12 ? 'AM' : 'PM'}';
    HapticFeedback.mediumImpact();
    CoordinatorBoard.scheduleDelivery(name, label);
    showAuthNotice(context, 'Delivery to $name scheduled for $label.');
  }

  void _copy(BuildContext context, String text, String what) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.selectionClick();
    showAuthNotice(context, '$what copied.');
  }

  @override
  Widget build(BuildContext context) {
    return CoordinatorPage(
      tab: CoordinatorTab.home,
      title: name,
      subtitle: '${_place.type} · ${_place.people} people',
      showBar: false,
      maxWidth: 760,
      photo: 'assets/images/event_serving_line.jpg',
      listenTo: CoordinatorBoard.deliveries,
      action: (c) => PrimaryButton(
        label: 'Schedule Delivery',
        scale: c.scale * 0.92,
        time: c.time,
        onPressed: () => _schedule(context),
      ),
      body: (context, c) {
        final s = c.scale;
        final place = _place;
        final scheduled = CoordinatorBoard.deliveries.value[name] ?? const [];
        final history = [
          for (final factor in _shape) (place.mealsThisMonth * factor).round(),
        ];
        final most = history.fold(1, (m, v) => v > m ? v : m);
        return [
          Row(
            children: [
              InitialsAvatar(
                initials: initialsOf(place.name),
                colors: place.colors,
                size: 64 * s,
                dot: place.isNew ? const Color(0xFF4A8FE0) : null,
              ),
              SizedBox(width: 14 * s),
              Expanded(
                child: Text(
                  place.isNew
                      ? 'Added recently. Plan their first delivery below.'
                      : 'Fed by your events every week.',
                  style: TextStyle(
                    fontSize: 14.5 * s,
                    height: 1.45,
                    color: AppColors.bodyText,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 18 * s),
          Row(
            children: [
              for (final (i, (value, label, icon)) in [
                (place.people, 'People', Icons.groups_rounded),
                (
                  place.mealsThisMonth,
                  'Meals this month',
                  Icons.restaurant_rounded,
                ),
                (
                  history.fold(0, (a, b) => a + b),
                  'Meals since July',
                  Icons.insights_rounded,
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
                        horizontal: 6 * s,
                      ),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: value.toDouble()),
                        duration: Duration(milliseconds: 900 + i * 150),
                        curve: Curves.easeOutCubic,
                        builder: (context, shown, _) => Column(
                          children: [
                            Icon(
                              icon,
                              size: 18 * s,
                              color: AppColors.leafLight,
                            ),
                            SizedBox(height: 4 * s),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                formatCount(shown.round()),
                                style: TextStyle(
                                  fontSize: 20 * s,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            Text(
                              label,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style: TextStyle(
                                fontSize: 11.5 * s,
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
          ),
          SizedBox(height: 18 * s),
          CoordinatorCard(
            scale: s,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Title(text: 'Meals delivered', scale: s),
                SizedBox(height: 14 * s),
                SizedBox(
                  height: 120 * s,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final (i, meals) in history.indexed)
                        Expanded(
                          child: Semantics(
                            label: '${_months[i]}: $meals meals',
                            excludeSemantics: true,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  '$meals',
                                  style: TextStyle(
                                    fontSize: 11.5 * s,
                                    fontWeight: FontWeight.w700,
                                    color: i == history.length - 1
                                        ? AppColors.brand
                                        : AppColors.fieldIcon,
                                  ),
                                ),
                                SizedBox(height: 4 * s),
                                TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: meals / most),
                                  duration: Duration(
                                    milliseconds: 700 + i * 120,
                                  ),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, grown, _) => Container(
                                    width: 28 * s,
                                    height: 70 * s * grown,
                                    decoration: BoxDecoration(
                                      color: i == history.length - 1
                                          ? AppColors.brand
                                          : AppColors.roleChosenBorder,
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(5 * s),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 6 * s),
                                Text(
                                  _months[i],
                                  style: TextStyle(
                                    fontSize: 12 * s,
                                    color: AppColors.fieldIcon,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 18 * s),
          CoordinatorCard(
            scale: s,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Title(text: 'Upcoming deliveries', scale: s),
                SizedBox(height: 8 * s),
                for (final (i, slot) in [
                  if (place.nextDelivery != 'Not scheduled yet')
                    place.nextDelivery,
                  ...scheduled,
                ].indexed)
                  TweenAnimationBuilder<double>(
                    key: ValueKey(slot),
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 350 + i * 80),
                    curve: Curves.easeOutBack,
                    builder: (context, pop, child) => Transform.scale(
                      scale: 0.9 + 0.1 * pop.clamp(0.0, 1.0),
                      child: Opacity(
                        opacity: pop.clamp(0.0, 1.0),
                        child: child,
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8 * s),
                      child: Row(
                        children: [
                          Container(
                            width: 36 * s,
                            height: 36 * s,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.roleChosenFill,
                            ),
                            child: Icon(
                              Icons.local_shipping_outlined,
                              size: 18 * s,
                              color: AppColors.brand,
                            ),
                          ),
                          SizedBox(width: 12 * s),
                          Expanded(
                            child: Text(
                              slot,
                              style: TextStyle(
                                fontSize: 15 * s,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (place.nextDelivery == 'Not scheduled yet' &&
                    scheduled.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8 * s),
                    child: Text(
                      'Nothing planned yet. Tap Schedule Delivery.',
                      style: TextStyle(
                        fontSize: 14.5 * s,
                        color: AppColors.bodyText,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 18 * s),
          CoordinatorCard(
            scale: s,
            padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 6 * s),
            child: Column(
              children: [
                for (final (i, (icon, label, value, what)) in [
                  (
                    Icons.person_outline_rounded,
                    'Contact person',
                    place.contact,
                    'Name',
                  ),
                  (Icons.phone_outlined, 'Phone', place.phone, 'Phone number'),
                  (Icons.place_outlined, 'Address', place.address, 'Address'),
                ].indexed) ...[
                  if (i > 0) rowDivider(),
                  Semantics(
                    button: true,
                    label: '$label: $value. Copy',
                    excludeSemantics: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _copy(context, value, what),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12 * s),
                        child: Row(
                          children: [
                            Icon(
                              icon,
                              size: 20 * s,
                              color: AppColors.leafLight,
                            ),
                            SizedBox(width: 12 * s),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 12.5 * s,
                                      color: AppColors.fieldIcon,
                                    ),
                                  ),
                                  Text(
                                    value,
                                    style: TextStyle(
                                      fontSize: 15 * s,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.copy_rounded,
                              size: 17 * s,
                              color: AppColors.fieldHint,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ];
      },
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({required this.text, required this.scale});

  final String text;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Row(
      children: [
        Icon(Icons.eco_rounded, size: 18 * s, color: AppColors.leafLight),
        SizedBox(width: 8 * s),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 18 * s,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }
}
