import 'package:flutter/material.dart';

import 'sample_events.dart';

/// A way to help at an event, e.g. Food Packing.
class EventRole {
  const EventRole(this.name, this.icon, this.blurb);

  final String name;
  final IconData icon;

  /// One line on what the role involves.
  final String blurb;
}

/// Part of an event a volunteer can come for, e.g. the first half.
class TimeSlot {
  const TimeSlot(this.name, this.range, this.icon);

  final String name;

  /// Short time range, e.g. "10 AM – 2 PM".
  final String range;
  final IconData icon;

  /// "Full Event (10 AM – 2 PM)".
  String get label => '$name ($range)';
}

/// What the volunteer picked when joining an event.
class JoinDetails {
  const JoinDetails({
    required this.role,
    required this.slot,
    this.notes = '',
    this.remind = true,
  });

  final EventRole role;
  final TimeSlot slot;
  final String notes;

  /// Whether to send a reminder the day before.
  final bool remind;
}

const _foodDriveRoles = [
  EventRole(
    'Food Packing',
    Icons.inventory_2_outlined,
    'Sort donations and pack meal kits',
  ),
  EventRole(
    'Distribution',
    Icons.volunteer_activism_outlined,
    'Hand out meals to families',
  ),
  EventRole(
    'Kitchen Help',
    Icons.soup_kitchen_outlined,
    'Prepare and portion fresh food',
  ),
  EventRole(
    'Welcome Desk',
    Icons.waving_hand_outlined,
    'Greet guests and check people in',
  ),
];

const _communityRoles = [
  EventRole(
    'Setup Crew',
    Icons.construction_rounded,
    'Set up stalls, tables and tools',
  ),
  EventRole(
    'Activity Helper',
    Icons.diversity_3_rounded,
    'Lend a hand wherever it’s needed',
  ),
  EventRole(
    'Welcome Desk',
    Icons.waving_hand_outlined,
    'Greet visitors and point the way',
  ),
  EventRole(
    'Clean-up Crew',
    Icons.recycling_rounded,
    'Leave the place better than we found it',
  ),
];

const _educationRoles = [
  EventRole(
    'Participant',
    Icons.school_outlined,
    'Learn, ask questions and take part',
  ),
  EventRole(
    'Session Helper',
    Icons.co_present_outlined,
    'Help set up and hand out materials',
  ),
  EventRole(
    'Note Taker',
    Icons.edit_note_rounded,
    'Write up key tips to share later',
  ),
];

/// The roles volunteers can choose from at [event].
List<EventRole> rolesFor(VolunteerEvent event) => switch (event.category) {
  EventCategory.foodDrive => _foodDriveRoles,
  EventCategory.community => _communityRoles,
  EventCategory.education => _educationRoles,
};

/// The whole event, then its first and second halves, from [event]'s hours
/// ("10:00 AM – 2:00 PM"). Only the whole event if the hours can't be read.
List<TimeSlot> timeSlotsFor(VolunteerEvent event) {
  final times = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)')
      .allMatches(event.hours)
      .map(_minutes)
      .toList();
  if (times.length < 2 || times[1] <= times[0]) {
    return [TimeSlot('Full Event', event.hours, Icons.event_available_rounded)];
  }
  final (start, end) = (times[0], times[1]);
  // Halfway, to the nearest half hour.
  final middle = ((start + end) / 2 / 30).round() * 30;
  return [
    TimeSlot(
      'Full Event',
      '${_short(start)} – ${_short(end)}',
      Icons.event_available_rounded,
    ),
    TimeSlot(
      'First Half',
      '${_short(start)} – ${_short(middle)}',
      Icons.wb_twilight_rounded,
    ),
    TimeSlot(
      'Second Half',
      '${_short(middle)} – ${_short(end)}',
      Icons.wb_sunny_outlined,
    ),
  ];
}

/// Minutes after midnight for a "10:00 AM" match.
int _minutes(RegExpMatch match) {
  final hour = int.parse(match.group(1)!) % 12;
  final minute = int.parse(match.group(2)!);
  return (hour + (match.group(3) == 'PM' ? 12 : 0)) * 60 + minute;
}

/// "10 AM", or "3:30 PM" when not on the hour.
String _short(int minutes) {
  final hour = minutes ~/ 60 % 24;
  final minute = minutes % 60;
  final shown = hour % 12 == 0 ? 12 : hour % 12;
  final period = hour < 12 ? 'AM' : 'PM';
  return minute == 0
      ? '$shown $period'
      : '$shown:${minute.toString().padLeft(2, '0')} $period';
}
