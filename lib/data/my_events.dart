import 'package:flutter/material.dart';

import 'join_options.dart';
import 'sample_events.dart';

/// An event the volunteer has already been to, with what they did there.
class PastVisit {
  const PastVisit({
    required this.event,
    required this.role,
    required this.hours,
    required this.contribution,
    required this.helped,
    required this.thanks,
    this.certificate = false,
  });

  final VolunteerEvent event;

  /// The role they took, e.g. "Food Packing".
  final String role;

  /// Hours they gave.
  final int hours;

  /// What they helped achieve, e.g. ('120', 'Kits packed').
  final (String, String) contribution;

  /// Roughly how many people their work reached.
  final int helped;

  /// A thank-you note from the organiser.
  final String thanks;

  /// Whether the event gave a certificate of participation.
  final bool certificate;

  /// The role's icon, or a helping hand for roles no longer offered.
  IconData get roleIcon {
    for (final category in EventCategory.values) {
      for (final option in rolesFor(_categoryEvent(category))) {
        if (option.name == role) return option.icon;
      }
    }
    return Icons.volunteer_activism_outlined;
  }
}

VolunteerEvent _categoryEvent(EventCategory category) =>
    sampleEvents.firstWhere((event) => event.category == category);

/// The volunteer's past events, newest first, until they come from the
/// database. Their totals are the numbers on the volunteer home.
final pastVisits = [
  _visit(
    title: 'Monsoon Relief Kits',
    day: ('Sun', 13, 'Sep'),
    hours: ('9:00 AM', '1:00 PM'),
    place: 'Hope Kitchen',
    area: 'Kolkata',
    category: EventCategory.foodDrive,
    photo: 'assets/images/impact_packing.jpg',
    organiser: 'Hope Kitchen Trust',
    about:
        'Packed rice, lentils, oil and tarpaulin into relief kits for '
        'families hit by the monsoon floods.',
    role: 'Food Packing',
    given: 4,
    contribution: ('120', 'Kits packed'),
    helped: 120,
    thanks:
        'Your kits reached 120 families before the second flood warning. '
        'Thank you for showing up when it mattered.',
  ),
  _visit(
    title: 'Riverside Breakfast Club',
    day: ('Mon', 7, 'Sep'),
    hours: ('7:00 AM', '10:00 AM'),
    place: 'Riverside Center',
    area: 'Kolkata',
    category: EventCategory.community,
    photo: 'assets/images/onboarding_community_meal.jpg',
    organiser: 'Riverside Food Bank',
    about:
        'A warm breakfast for children on their way to school, served '
        'with fruit and a smile.',
    role: 'Activity Helper',
    given: 3,
    contribution: ('90', 'Breakfasts'),
    helped: 90,
    thanks:
        'Ninety children started their day with a full plate. The kids '
        'are already asking when you’re coming back!',
  ),
  _visit(
    title: 'Seed Swap & Garden Talk',
    day: ('Sun', 30, 'Aug'),
    hours: ('4:00 PM', '6:00 PM'),
    place: 'Greenfield Park',
    area: 'Salt Lake',
    category: EventCategory.education,
    photo: 'assets/images/notifications_community_farm.jpg',
    organiser: 'Green Roots Collective',
    about:
        'An afternoon of swapping seeds and learning to grow vegetables '
        'on balconies and rooftops.',
    role: 'Participant',
    given: 2,
    contribution: ('25', 'Seed packs'),
    helped: 25,
    thanks:
        'Thanks for joining the talk and sharing your seeds. We hope your '
        'balcony is full of greens soon.',
    certificate: true,
  ),
  _visit(
    title: 'Farm Gleaning Trip',
    day: ('Sun', 23, 'Aug'),
    hours: ('6:30 AM', '10:30 AM'),
    place: 'Sunrise Farms',
    area: 'Baruipur',
    category: EventCategory.community,
    photo: 'assets/images/event_harvest_greens.jpg',
    organiser: 'Green Roots Collective',
    about:
        'Gathered the greens left in the fields after harvest and sent '
        'them to three community kitchens.',
    role: 'Activity Helper',
    given: 4,
    contribution: ('300 kg', 'Produce saved'),
    helped: 200,
    thanks:
        'Three hundred kilos of fresh greens saved from going to waste. '
        'An early start well spent!',
  ),
  _visit(
    title: 'Independence Day Meal Drive',
    day: ('Sat', 15, 'Aug'),
    hours: ('11:00 AM', '3:00 PM'),
    place: 'Town Hall',
    area: 'Esplanade',
    category: EventCategory.foodDrive,
    photo: 'assets/images/event_serving_line.jpg',
    organiser: 'Hope Kitchen Trust',
    about:
        'A celebratory lunch for anyone who walked in, served from the '
        'Town Hall steps.',
    role: 'Distribution',
    given: 4,
    contribution: ('450', 'Meals served'),
    helped: 450,
    thanks:
        'Four hundred and fifty plates, served with care. You made the '
        'holiday feel like a celebration for everyone.',
  ),
  _visit(
    title: 'Food Bank Sort-a-thon',
    day: ('Sun', 2, 'Aug'),
    hours: ('10:00 AM', '2:00 PM'),
    place: 'Central Food Bank',
    area: 'Park Circus',
    category: EventCategory.foodDrive,
    photo: 'assets/images/event_potato_sorting.jpg',
    organiser: 'Kolkata Food Bank',
    about:
        'A race against the clock to sort a full truck of donated '
        'vegetables before the weekend.',
    role: 'Food Packing',
    given: 4,
    contribution: ('1.2 t', 'Food sorted'),
    helped: 300,
    thanks:
        'Over a tonne of food sorted in one afternoon. Our shelves have '
        'never looked so tidy!',
  ),
  _visit(
    title: 'Park Clean & Picnic',
    day: ('Sun', 19, 'Jul'),
    hours: ('8:00 AM', '11:00 AM'),
    place: 'Eco Park',
    area: 'New Town',
    category: EventCategory.community,
    photo: 'assets/images/change_volunteers.jpg',
    organiser: 'Green Roots Collective',
    about:
        'Cleared litter from the lakeside paths, then shared a picnic '
        'made from rescued food.',
    role: 'Clean-up Crew',
    given: 3,
    contribution: ('40', 'Bags collected'),
    helped: 60,
    thanks:
        'Forty bags of litter gone and a lake that sparkles again. Thank '
        'you for caring for our green spaces.',
  ),
  _visit(
    title: 'Kitchen Hygiene Workshop',
    day: ('Wed', 8, 'Jul'),
    hours: ('6:00 PM', '8:00 PM'),
    place: 'Community Library',
    area: 'Kolkata',
    category: EventCategory.education,
    photo: 'assets/images/role_coordinator.jpg',
    organiser: 'FoodLink Learning',
    about:
        'The basics of handwashing, storage temperatures and keeping '
        'shared kitchens safe.',
    role: 'Participant',
    given: 2,
    contribution: ('1', 'Certificate'),
    helped: 15,
    thanks:
        'Congratulations on completing the workshop. Every kitchen you '
        'help in is a little safer now.',
    certificate: true,
  ),
  _visit(
    title: 'Rainy Day Soup Kitchen',
    day: ('Sat', 27, 'Jun'),
    hours: ('5:00 PM', '8:00 PM'),
    place: 'Hope Shelter',
    area: 'Howrah',
    category: EventCategory.foodDrive,
    photo: 'assets/images/event_community_meal.jpg',
    organiser: 'Hope Kitchen Trust',
    about:
        'Cooked and served hot vegetable soup and bread on the first '
        'rainy evening of the season.',
    role: 'Kitchen Help',
    given: 3,
    contribution: ('200', 'Bowls served'),
    helped: 200,
    thanks:
        'Two hundred warm bowls on a cold, wet night. The shelter felt '
        'like home because of you.',
  ),
  _visit(
    title: 'Nutrition for Kids Talk',
    day: ('Thu', 18, 'Jun'),
    hours: ('4:00 PM', '6:00 PM'),
    place: 'Sunrise School',
    area: 'Behala',
    category: EventCategory.education,
    photo: 'assets/images/splash_giving.jpg',
    organiser: 'FoodLink Learning',
    about:
        'Fun games about fruit, vegetables and balanced meals for '
        'primary school children.',
    role: 'Session Helper',
    given: 2,
    contribution: ('60', 'Children'),
    helped: 60,
    thanks:
        'Sixty children now know their fruits from their veggies. Thank '
        'you for making learning fun!',
    certificate: true,
  ),
  _visit(
    title: 'Warehouse Restock',
    day: ('Sat', 6, 'Jun'),
    hours: ('9:00 AM', '12:00 PM'),
    place: 'Howrah Depot',
    area: 'Howrah',
    category: EventCategory.foodDrive,
    photo: 'assets/images/event_food_warehouse.jpg',
    organiser: 'Kolkata Food Bank',
    about:
        'Unloaded and stacked donated groceries ahead of the monthly '
        'pantry delivery.',
    role: 'Food Packing',
    given: 3,
    contribution: ('500', 'Boxes'),
    helped: 250,
    thanks:
        'Five hundred boxes stacked and ready. The pantries were stocked '
        'on time thanks to you.',
  ),
  _visit(
    title: 'Environment Day Planting',
    day: ('Fri', 5, 'Jun'),
    hours: ('7:00 AM', '9:00 AM'),
    place: 'Eco Park',
    area: 'New Town',
    category: EventCategory.community,
    photo: 'assets/images/event_tree_planting.jpg',
    organiser: 'Green Roots Collective',
    about:
        'Planted native saplings along the park’s edge to mark World '
        'Environment Day.',
    role: 'Setup Crew',
    given: 2,
    contribution: ('80', 'Saplings'),
    helped: 40,
    thanks:
        'Eighty saplings in the ground before breakfast. Come back and '
        'see them grow!',
  ),
];

PastVisit _visit({
  required String title,
  required (String, int, String) day,
  required (String, String) hours,
  required String place,
  required String area,
  required EventCategory category,
  required String photo,
  required String organiser,
  required String about,
  required String role,
  required int given,
  required (String, String) contribution,
  required int helped,
  required String thanks,
  bool certificate = false,
}) {
  final (weekday, date, month) = day;
  final (from, to) = hours;
  return PastVisit(
    event: VolunteerEvent(
      title: title,
      when: '$weekday, $date $month · $from',
      place: place,
      category: category,
      photo: photo,
      date: '$weekday, $date $month 2026',
      hours: '$from – $to',
      address: '$place, $area',
      about: about,
      going: 20 + title.length,
      capacity: 30 + title.length,
      impact: contribution,
      duration: '$given hrs',
      bring: const ['Water bottle'],
      organiser: organiser,
    ),
    role: role,
    hours: given,
    contribution: contribution,
    helped: helped,
    thanks: thanks,
    certificate: certificate,
  );
}

/// Events the volunteer had already signed up for, with their role and time
/// slot, until plans come from the database.
Map<String, JoinDetails> initialPlans() {
  JoinDetails plan(String title, String role, String slot) {
    final event = sampleEvents.firstWhere((event) => event.title == title);
    return JoinDetails(
      role: rolesFor(event).firstWhere((option) => option.name == role),
      slot: timeSlotsFor(event).firstWhere((option) => option.name == slot),
    );
  }

  return {
    'Community Food Drive': plan(
      'Community Food Drive',
      'Food Packing',
      'Full Event',
    ),
    'Urban Garden Setup': plan(
      'Urban Garden Setup',
      'Setup Crew',
      'First Half',
    ),
    'Weekend Meal Distribution': plan(
      'Weekend Meal Distribution',
      'Distribution',
      'Full Event',
    ),
    'Food Safety Basics': plan(
      'Food Safety Basics',
      'Participant',
      'Full Event',
    ),
    'Harvest Gleaning Day': plan(
      'Harvest Gleaning Day',
      'Activity Helper',
      'First Half',
    ),
    'Tree Planting Morning': plan(
      'Tree Planting Morning',
      'Setup Crew',
      'Full Event',
    ),
    'Shelter Dinner Service': plan(
      'Shelter Dinner Service',
      'Distribution',
      'Second Half',
    ),
  };
}

const _months = [
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

/// The day [event] happens, read from its date ("Sat, 20 Sep 2026").
DateTime eventDay(VolunteerEvent event) {
  final parts = event.date.replaceAll(',', '').split(' ');
  if (parts.length < 4) return DateTime(2026);
  final month = _months.indexOf(parts[2]) + 1;
  return DateTime(
    int.tryParse(parts[3]) ?? 2026,
    month == 0 ? 1 : month,
    int.tryParse(parts[1]) ?? 1,
  );
}

/// "September 2026".
String monthLabel(DateTime day) {
  const names = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${names[day.month - 1]} ${day.year}';
}
