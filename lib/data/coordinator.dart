import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'join_options.dart';
import 'my_events.dart';
import 'sample_events.dart';

/// A volunteer on an event's roster.
class RosterEntry {
  const RosterEntry({
    required this.name,
    required this.role,
    required this.colors,
  });

  final String name;
  final EventRole role;

  /// Avatar gradient.
  final List<Color> colors;

  String get initials => initialsOf(name);
}

/// "Riya Sen" → "RS".
String initialsOf(String name) => name
    .split(' ')
    .where((word) => word.isNotEmpty)
    .take(2)
    .map((word) => word[0])
    .join();

/// Where an event is in its life.
enum EventStatus {
  ongoing('Ongoing'),
  upcoming('Upcoming'),
  completed('Completed');

  const EventStatus(this.label);

  final String label;
}

/// An event the coordinator runs.
class ManagedEvent {
  const ManagedEvent({
    required this.event,
    required this.roster,
    this.status = EventStatus.upcoming,
    this.mealsSoFar = 0,
  });

  final VolunteerEvent event;

  /// Who is signed up.
  final List<RosterEntry> roster;
  final EventStatus status;

  /// Meals handed out so far (today, for an ongoing event; in all, for a
  /// completed one).
  final int mealsSoFar;

  /// Happening right now (volunteers can be checked in).
  bool get ongoing => status == EventStatus.ongoing;

  String get title => event.title;

  /// How full the event is (0–1).
  double get fill =>
      event.capacity == 0 ? 0 : (roster.length / event.capacity).clamp(0, 1);

  ManagedEvent copyWith({List<RosterEntry>? roster, EventStatus? status}) =>
      ManagedEvent(
        event: event,
        roster: roster ?? this.roster,
        status: status ?? this.status,
        mealsSoFar: mealsSoFar,
      );
}

/// The prep list for [managed], by where it is in its life.
List<String> eventTasks(ManagedEvent managed) => switch (managed.status) {
  EventStatus.ongoing => [
    'Set up the registration desk',
    'Brief volunteers on their roles',
    'Log meals every hour',
    'Take a team photo for Community',
  ],
  EventStatus.upcoming => [
    'Confirm the venue',
    'Arrange supplies and transport',
    'Send a reminder to volunteers',
    'Print the sign-in sheet',
  ],
  EventStatus.completed => [
    'Log the final meal count',
    'Send a thank-you note',
    'Share photos in Community',
  ],
};

const avatarColors = [
  AppColors.avatar,
  [Color(0xFF7FA6C4), Color(0xFF3D6683)],
  [Color(0xFF9DBB80), Color(0xFF4F7539)],
  [Color(0xFFE0A63A), Color(0xFFB0702A)],
  [Color(0xFFD99A8E), Color(0xFF9A5448)],
  AppColors.accentGradient,
];

/// The coordinator's volunteers, the first five as in the Figma.
const _names = [
  'Riya Sen',
  'Arjun Mehta',
  'Sneha Das',
  'Rahul Verma',
  'Priya Kapoor',
  'Kabir Das',
  'Ananya Roy',
  'Rohan Gupta',
  'Sneha Iyer',
  'Vikram Sen',
  'Meera Pillai',
  'Aditya Bose',
  'Ishita Paul',
  'Karan Malhotra',
  'Diya Chatterjee',
  'Nikhil Rao',
  'Pooja Banerjee',
  'Siddharth Ghosh',
  'Tanya Kapoor',
  'Aman Verma',
  'Neha Joshi',
  'Rahul Dutta',
  'Kavya Menon',
  'Varun Saha',
  'Shreya Basu',
  'Manish Kumar',
  'Aisha Khan',
  'Dev Mukherjee',
  'Lakshmi Reddy',
  'Arnav Sinha',
  'Zoya Ahmed',
  'Om Prakash',
];

/// Volunteers still to be approved.
const _pending = {'Sneha Das', 'Tanya Kapoor', 'Varun Saha', 'Zoya Ahmed'};

/// [count] volunteers spread across [event]'s roles.
List<RosterEntry> _roster(VolunteerEvent event, int count, int offset) {
  final roles = rolesFor(event);
  return [
    for (var i = 0; i < count; i++)
      RosterEntry(
        name: _names[(i + offset) % _names.length],
        role: roles[i % roles.length],
        colors: avatarColors[(i + offset) % avatarColors.length],
      ),
  ];
}

VolunteerEvent _event(String title) =>
    sampleEvents.firstWhere((event) => event.title == title);

VolunteerEvent _past(String title) =>
    pastVisits.firstWhere((visit) => visit.event.title == title).event;

const _educationDrive = VolunteerEvent(
  title: 'Education Support Drive',
  when: 'Sat, 17 Oct · 10:00 AM',
  place: 'Community Library',
  category: EventCategory.education,
  photo: 'assets/images/splash_giving.jpg',
  date: 'Sat, 17 Oct 2026',
  hours: '10:00 AM – 1:00 PM',
  address: 'Community Library, Kolkata',
  about:
      'Collect school books and stationery, then run a short nutrition '
      'session for children at the library.',
  going: 8,
  capacity: 20,
  impact: ('150', 'Kits'),
  duration: '3 hrs',
  bring: ['Notebook', 'Pen', 'Water bottle'],
  organiser: 'Riverside Food Bank',
);

/// The coordinator's sample events, as in the Figma's Events list: today's
/// first, then what's coming up, then what's done.
final managedEvents = [
  ManagedEvent(
    event: _event('Community Food Drive'),
    roster: _roster(_event('Community Food Drive'), 30, 0),
    status: EventStatus.ongoing,
    mealsSoFar: 312,
  ),
  ManagedEvent(
    event: _event('Urban Garden Setup'),
    roster: _roster(_event('Urban Garden Setup'), 15, 5),
  ),
  ManagedEvent(event: _educationDrive, roster: _roster(_educationDrive, 8, 12)),
  ManagedEvent(
    event: _event('Weekend Meal Packing'),
    roster: _roster(_event('Weekend Meal Packing'), 28, 3),
  ),
  ManagedEvent(
    event: _event('Shelter Dinner Service'),
    roster: _roster(_event('Shelter Dinner Service'), 18, 9),
  ),
  ManagedEvent(
    event: _past('Monsoon Relief Kits'),
    roster: _roster(_past('Monsoon Relief Kits'), 26, 2),
    status: EventStatus.completed,
    mealsSoFar: 480,
  ),
  ManagedEvent(
    event: _past('Independence Day Meal Drive'),
    roster: _roster(_past('Independence Day Meal Drive'), 31, 6),
    status: EventStatus.completed,
    mealsSoFar: 450,
  ),
  ManagedEvent(
    event: _past('Food Bank Sort-a-thon'),
    roster: _roster(_past('Food Bank Sort-a-thon'), 22, 14),
    status: EventStatus.completed,
    mealsSoFar: 310,
  ),
];

/// The coordinator's headline numbers on the home, as in the Figma.
const coordinatorMealsDistributed = 1240;
const coordinatorVolunteers = 42;

/// One of the coordinator's volunteers.
class VolunteerContact {
  const VolunteerContact({
    required this.name,
    required this.colors,
    required this.phone,
    required this.hours,
  });

  final String name;
  final List<Color> colors;
  final String phone;

  /// Hours given on the coordinator's events.
  final int hours;

  String get initials => initialsOf(name);

  /// The coordinator's events this volunteer is on.
  List<ManagedEvent> get events => [
    for (final managed in CoordinatorBoard.events.value)
      if (managed.roster.any((entry) => entry.name == name)) managed,
  ];
}

final volunteerContacts = [
  for (final (i, name) in _names.indexed)
    VolunteerContact(
      name: name,
      colors: avatarColors[i % avatarColors.length],
      phone: '+91 98${300 + i * 17} ${10000 + i * 731}',
      hours: 4 + (i * 7) % 30,
    ),
];

/// Someone the coordinator's events feed.
class Beneficiary {
  const Beneficiary({
    required this.name,
    required this.type,
    required this.people,
    required this.address,
    required this.contact,
    required this.phone,
    required this.mealsThisMonth,
    required this.nextDelivery,
    required this.colors,
    this.isNew = false,
  });

  final String name;
  final String type;

  /// People it serves.
  final int people;
  final String address;
  final String contact;
  final String phone;
  final int mealsThisMonth;
  final String nextDelivery;
  final List<Color> colors;

  /// Added recently (a blue dot, as in the Figma).
  final bool isNew;
}

const beneficiaryTypes = [
  'Shelter',
  'Community',
  'Children’s Home',
  'Elderly Home',
  'Night Shelter',
];

const _sampleBeneficiaries = [
  Beneficiary(
    name: 'Kolkata Hope Shelter',
    type: 'Shelter',
    people: 120,
    address: '12 Park Street, Kolkata',
    contact: 'Meena Ghosh',
    phone: '+91 33 4012 1100',
    mealsThisMonth: 360,
    nextDelivery: 'Sat, 10 Oct · 12:00 PM',
    colors: AppColors.avatar,
    isNew: true,
  ),
  Beneficiary(
    name: 'Riverside Community',
    type: 'Community',
    people: 80,
    address: 'Strand Road, Kolkata',
    contact: 'Abdul Rahman',
    phone: '+91 33 4012 2200',
    mealsThisMonth: 240,
    nextDelivery: 'Sun, 11 Oct · 1:00 PM',
    colors: [Color(0xFFC9A27A), Color(0xFF8A6A4A)],
  ),
  Beneficiary(
    name: 'Greenfield Park',
    type: 'Community',
    people: 60,
    address: 'Greenfield Park, Salt Lake',
    contact: 'Priya Nair',
    phone: '+91 33 4012 3300',
    mealsThisMonth: 180,
    nextDelivery: 'Wed, 14 Oct · 5:00 PM',
    colors: [Color(0xFF9DBB80), Color(0xFF4F7539)],
  ),
  Beneficiary(
    name: 'Sunrise Home',
    type: 'Elderly Home',
    people: 95,
    address: '4 Lake Road, Behala',
    contact: 'Sister Agnes',
    phone: '+91 33 4012 4400',
    mealsThisMonth: 285,
    nextDelivery: 'Fri, 16 Oct · 11:00 AM',
    colors: [Color(0xFFD9B99A), Color(0xFF9A7454)],
  ),
  Beneficiary(
    name: 'City Night Shelter',
    type: 'Night Shelter',
    people: 150,
    address: 'Howrah Station Road, Howrah',
    contact: 'Rakesh Pal',
    phone: '+91 33 4012 5500',
    mealsThisMonth: 450,
    nextDelivery: 'Every night · 8:00 PM',
    colors: [Color(0xFFE0A63A), Color(0xFFB0702A)],
  ),
];

/// A report period's numbers.
class ReportPeriod {
  const ReportPeriod({
    required this.label,
    required this.meals,
    required this.volunteers,
    required this.communities,
    required this.months,
    required this.previous,
    required this.compareLabel,
  });

  final String label;
  final int meals;
  final int volunteers;
  final int communities;

  /// The period before: meals, volunteers and communities.
  final (int, int, int) previous;

  /// "vs last month".
  final String compareLabel;

  /// How many of the chart's last months the period covers.
  final int months;
}

/// Meals distributed each month, as in the Figma's chart.
const reportMonths = [
  ('Jan', 620),
  ('Feb', 860),
  ('Mar', 1180),
  ('Apr', 790),
  ('May', 1150),
  ('Jun', 1240),
];

/// This year's meal goal.
const coordinatorMealGoal = 8000;

/// How the period's meals split across kinds of event.
const mealsByCategory = [
  ('Food Distribution', 0.58, Icons.volunteer_activism_rounded),
  ('Community Kitchens', 0.27, Icons.soup_kitchen_outlined),
  ('Education', 0.15, Icons.menu_book_rounded),
];

const reportPeriods = [
  ReportPeriod(
    label: 'This Month',
    meals: 1240,
    volunteers: 86,
    communities: 12,
    months: 1,
    previous: (1150, 79, 11),
    compareLabel: 'vs last month',
  ),
  ReportPeriod(
    label: 'Last 3 Months',
    meals: 3180,
    volunteers: 184,
    communities: 18,
    months: 3,
    previous: (2660, 160, 16),
    compareLabel: 'vs the 3 months before',
  ),
  ReportPeriod(
    label: 'This Year',
    meals: 5840,
    volunteers: 312,
    communities: 24,
    months: 6,
    previous: (4900, 260, 19),
    compareLabel: 'vs last year',
  ),
];

/// A member of the coordinator's organisation team.
class TeamMember {
  const TeamMember({
    required this.name,
    required this.role,
    required this.email,
    required this.colors,
    this.invited = false,
    this.you = false,
  });

  final String name;
  final String role;
  final String email;
  final List<Color> colors;

  /// Invited but not joined yet.
  final bool invited;
  final bool you;

  String get initials => initialsOf(name);
}

const teamRoles = ['Admin', 'Coordinator', 'Logistics Lead', 'Volunteer Lead'];

const _sampleTeam = [
  TeamMember(
    name: 'Agnibha Bhattacharya',
    role: 'Admin',
    email: 'demo@foodlink.org',
    colors: AppColors.avatar,
    you: true,
  ),
  TeamMember(
    name: 'Meera Pillai',
    role: 'Coordinator',
    email: 'meera@riversidefoodbank.org',
    colors: [Color(0xFF9DBB80), Color(0xFF4F7539)],
  ),
  TeamMember(
    name: 'Imran Qureshi',
    role: 'Logistics Lead',
    email: 'imran@riversidefoodbank.org',
    colors: [Color(0xFF7FA6C4), Color(0xFF3D6683)],
  ),
  TeamMember(
    name: 'Bhavna Shah',
    role: 'Volunteer Lead',
    email: 'bhavna@riversidefoodbank.org',
    colors: [Color(0xFFD99A8E), Color(0xFF9A5448)],
  ),
];

/// The coordinator's organisation.
class Organisation {
  const Organisation({
    required this.name,
    required this.type,
    required this.registration,
    required this.address,
    required this.email,
    required this.phone,
    required this.about,
  });

  final String name;
  final String type;
  final String registration;
  final String address;
  final String email;
  final String phone;
  final String about;
}

const _sampleOrganisation = Organisation(
  name: 'Riverside Food Bank',
  type: 'Non-profit (NGO)',
  registration: 'WB/2019/0042871',
  address: 'Riverside Center, Strand Road, Kolkata 700001',
  email: 'hello@riversidefoodbank.org',
  phone: '+91 33 4012 0000',
  about:
      'We rescue surplus food and share it with shelters, communities and '
      'families across Kolkata, with the help of hundreds of volunteers.',
);

/// How the coordinator runs their events.
class CoordinatorSettings {
  const CoordinatorSettings({
    this.autoApprove = false,
    this.waitlist = true,
    this.checkInReminders = true,
    this.newSignUps = true,
    this.lowSupplies = true,
    this.weeklyReport = true,
    this.publicProfile = true,
    this.shareContacts = false,
    this.reminderHours = 24,
  });

  /// Approve new volunteers without a review.
  final bool autoApprove;

  /// Let volunteers queue when an event is full.
  final bool waitlist;

  /// Remind volunteers to check in when an event starts.
  final bool checkInReminders;
  final bool newSignUps;
  final bool lowSupplies;

  /// Email the impact report every Monday.
  final bool weeklyReport;

  /// Show the organisation on Explore.
  final bool publicProfile;

  /// Share volunteers' phone numbers with team members.
  final bool shareContacts;

  /// How long before an event volunteers get their reminder.
  final int reminderHours;

  CoordinatorSettings copyWith({
    bool? autoApprove,
    bool? waitlist,
    bool? checkInReminders,
    bool? newSignUps,
    bool? lowSupplies,
    bool? weeklyReport,
    bool? publicProfile,
    bool? shareContacts,
    int? reminderHours,
  }) => CoordinatorSettings(
    autoApprove: autoApprove ?? this.autoApprove,
    waitlist: waitlist ?? this.waitlist,
    checkInReminders: checkInReminders ?? this.checkInReminders,
    newSignUps: newSignUps ?? this.newSignUps,
    lowSupplies: lowSupplies ?? this.lowSupplies,
    weeklyReport: weeklyReport ?? this.weeklyReport,
    publicProfile: publicProfile ?? this.publicProfile,
    shareContacts: shareContacts ?? this.shareContacts,
    reminderHours: reminderHours ?? this.reminderHours,
  );
}

/// Questions coordinators often ask.
const coordinatorHelpTopics = [
  (
    'How do I check volunteers in?',
    'Open an ongoing event from Home or Events and tap Manage Event. Tap '
        'Check In next to each volunteer as they arrive.',
  ),
  (
    'How do I approve new volunteers?',
    'Open Volunteers and filter by Pending. Open a volunteer to approve '
        'them, or turn on auto-approve in Settings.',
  ),
  (
    'Can I message everyone at once?',
    'Yes. Use Message Volunteers on Home to write to everyone, or to the '
        'volunteers of one event.',
  ),
  (
    'How do I add a shelter or community we feed?',
    'Open Beneficiaries from Home and choose Add New. They’ll appear in '
        'your list and in your reports.',
  ),
  (
    'Where do the report numbers come from?',
    'Meals are logged at each event, and volunteers are counted when they '
        'check in. Download Report gives you the full figures.',
  ),
];

/// Something on the coordinator's events that needs a look.
class CoordinatorAlert {
  const CoordinatorAlert({
    required this.id,
    required this.icon,
    required this.color,
    required this.title,
    required this.detail,
    required this.action,
    required this.done,
  });

  final String id;
  final IconData icon;
  final Color color;
  final String title;
  final String detail;

  /// The button's label, and what to say once it's done.
  final String action;
  final String done;
}

const coordinatorAlerts = [
  CoordinatorAlert(
    id: 'short',
    icon: Icons.group_add_rounded,
    color: AppColors.badge,
    title: 'Urban Garden Setup is short',
    detail: '15 more volunteers needed by Sunday.',
    action: 'Ask for help',
    done: 'Request sent to 18 volunteers who are free.',
  ),
  CoordinatorAlert(
    id: 'approve',
    icon: Icons.how_to_reg_rounded,
    color: AppColors.sun,
    title: '4 new sign-ups to review',
    detail: 'Waiting for approval in Volunteers.',
    action: 'Approve all',
    done: '4 volunteers approved and welcomed.',
  ),
  CoordinatorAlert(
    id: 'supplies',
    icon: Icons.inventory_2_outlined,
    color: Color(0xFF3D6683),
    title: 'Low on packing bags',
    detail: 'About 40 bags left at Riverside Center.',
    action: 'Notify depot',
    done: 'Howrah Depot will send 200 bags.',
  ),
];

/// Recent things volunteers did on the coordinator's events: who, what,
/// when, an icon, and which event.
const coordinatorActivity = [
  (
    'Riya Sen',
    'checked in at Community Food Drive',
    '2m ago',
    Icons.login_rounded,
    'Community Food Drive',
  ),
  (
    'Arjun Mehta',
    'joined Urban Garden Setup',
    '15m ago',
    Icons.person_add_alt_1_rounded,
    'Urban Garden Setup',
  ),
  (
    'Sneha Das',
    'asked to join Education Support Drive',
    '1h ago',
    Icons.pending_actions_rounded,
    'Education Support Drive',
  ),
  (
    'Kabir Das',
    'left a note: “Bringing my own gloves”',
    '2h ago',
    Icons.sticky_note_2_outlined,
    'Community Food Drive',
  ),
];

/// What the coordinator has done, kept in memory until it comes from the
/// database: their events, volunteers' approval, who is checked in, alerts
/// handled, messages sent, beneficiaries, team, organisation and settings.
class CoordinatorBoard {
  CoordinatorBoard._();

  /// The coordinator's events: the sample ones, then any created.
  static final ValueNotifier<List<ManagedEvent>> events = ValueNotifier([
    ...managedEvents,
  ]);

  /// Volunteers still waiting for approval.
  static final ValueNotifier<Set<String>> pending = ValueNotifier({
    ..._pending,
  });

  /// Names checked in, by event title. The first 20 at today's event are
  /// already in.
  static final ValueNotifier<Map<String, Set<String>>> checkedIn =
      ValueNotifier(_initialCheckIns());

  static final ValueNotifier<Set<String>> handledAlerts = ValueNotifier({});

  /// Messages sent to volunteers, newest last.
  static final ValueNotifier<List<String>> broadcasts = ValueNotifier([]);

  static final ValueNotifier<List<Beneficiary>> beneficiaries = ValueNotifier([
    ..._sampleBeneficiaries,
  ]);

  static final ValueNotifier<List<TeamMember>> team = ValueNotifier([
    ..._sampleTeam,
  ]);

  static final ValueNotifier<Organisation> organisation = ValueNotifier(
    _sampleOrganisation,
  );

  static final ValueNotifier<CoordinatorSettings> settings = ValueNotifier(
    const CoordinatorSettings(),
  );

  /// Prep tasks ticked off, by event title.
  static final ValueNotifier<Map<String, Set<String>>> doneTasks =
      ValueNotifier(_initialTasks());

  /// The coordinator's private notes on volunteers, by name.
  static final ValueNotifier<Map<String, String>> notes = ValueNotifier({});

  /// Deliveries scheduled from Beneficiaries, by place.
  static final ValueNotifier<Map<String, List<String>>> deliveries =
      ValueNotifier({});

  static Map<String, Set<String>> _initialTasks() => {
    for (final managed in managedEvents)
      managed.title: {
        ...eventTasks(managed).take(switch (managed.status) {
          EventStatus.ongoing => 2,
          EventStatus.upcoming => 1,
          EventStatus.completed => 3,
        }),
      },
  };

  static Set<String> tasksDone(String title) =>
      doneTasks.value[title] ?? const {};

  static void toggleTask(String title, String task) {
    final next = {...tasksDone(title)};
    if (!next.remove(task)) next.add(task);
    doneTasks.value = {...doneTasks.value, title: next};
  }

  static void setNote(String name, String note) =>
      notes.value = {...notes.value, name: note};

  static void _replace(String title, ManagedEvent Function(ManagedEvent) f) {
    events.value = [
      for (final managed in events.value)
        managed.title == title ? f(managed) : managed,
    ];
  }

  /// Puts [name] on [title]'s roster, in its first role.
  static void assign(String title, String name) {
    final contact = volunteerContacts.firstWhere((c) => c.name == name);
    _replace(title, (managed) {
      if (managed.roster.any((entry) => entry.name == name)) return managed;
      return managed.copyWith(
        roster: [
          ...managed.roster,
          RosterEntry(
            name: name,
            role: rolesFor(managed.event).first,
            colors: contact.colors,
          ),
        ],
      );
    });
  }

  /// Marks [title] as done.
  static void complete(String title) => _replace(
    title,
    (managed) => managed.copyWith(status: EventStatus.completed),
  );

  /// Removes [title] from the coordinator's events.
  static void cancel(String title) => events.value = [
    for (final managed in events.value)
      if (managed.title != title) managed,
  ];

  static void scheduleDelivery(String place, String when) =>
      deliveries.value = {
        ...deliveries.value,
        place: [...?deliveries.value[place], when],
      };

  /// Events that aren't finished yet.
  static List<ManagedEvent> get active => [
    for (final managed in events.value)
      if (managed.status != EventStatus.completed) managed,
  ];

  static ManagedEvent? eventNamed(String title) {
    for (final managed in events.value) {
      if (managed.title == title) return managed;
    }
    return null;
  }

  /// Adds [managed] after the other active events.
  static void addEvent(ManagedEvent managed) {
    final list = [...events.value];
    final firstDone = list.indexWhere(
      (event) => event.status == EventStatus.completed,
    );
    list.insert(firstDone < 0 ? list.length : firstDone, managed);
    events.value = list;
  }

  static bool isPending(String name) => pending.value.contains(name);

  static void approve(String name) =>
      pending.value = {...pending.value}..remove(name);

  static Map<String, Set<String>> _initialCheckIns() => {
    for (final managed in managedEvents)
      if (managed.ongoing)
        managed.title: {
          for (final entry in managed.roster.take(20)) entry.name,
        },
  };

  static Set<String> checkedInAt(String title) =>
      checkedIn.value[title] ?? const {};

  static bool isCheckedIn(String title, String name) =>
      checkedInAt(title).contains(name);

  static void toggleCheckIn(String title, String name) {
    final next = {...checkedInAt(title)};
    if (!next.remove(name)) next.add(name);
    checkedIn.value = {...checkedIn.value, title: next};
  }

  /// Handles an alert; approving all also clears the pending volunteers.
  static void handle(String alertId) {
    handledAlerts.value = {...handledAlerts.value, alertId};
    if (alertId == 'approve') pending.value = {};
  }

  static void broadcast(String message) =>
      broadcasts.value = [...broadcasts.value, message];

  static void addBeneficiary(Beneficiary beneficiary) =>
      beneficiaries.value = [beneficiary, ...beneficiaries.value];

  static void invite(TeamMember member) => team.value = [...team.value, member];

  @visibleForTesting
  static void reset() {
    events.value = [...managedEvents];
    pending.value = {..._pending};
    checkedIn.value = _initialCheckIns();
    handledAlerts.value = {};
    broadcasts.value = [];
    beneficiaries.value = [..._sampleBeneficiaries];
    team.value = [..._sampleTeam];
    organisation.value = _sampleOrganisation;
    settings.value = const CoordinatorSettings();
    doneTasks.value = _initialTasks();
    notes.value = {};
    deliveries.value = {};
  }
}

/// The coordinator's milestones: name, icon, colour, how it's earned, and
/// whether it is.
List<(String, IconData, Color, String, bool)> coordinatorAchievements() {
  final done = CoordinatorBoard.events.value
      .where((e) => e.status == EventStatus.completed)
      .length;
  return [
    (
      'First Event',
      Icons.flag_rounded,
      const Color(0xFF6A9A51),
      'Run your first event',
      done >= 1,
    ),
    (
      '1,000 Meals',
      Icons.restaurant_rounded,
      const Color(0xFFE0A63A),
      'Share 1,000 meals in a month',
      coordinatorMealsDistributed >= 1000,
    ),
    (
      'Team Builder',
      Icons.groups_rounded,
      const Color(0xFF3D6683),
      'Grow a team of four',
      CoordinatorBoard.team.value.length >= 4,
    ),
    (
      'Good Neighbour',
      Icons.home_work_rounded,
      const Color(0xFFDC6558),
      'Feed five places regularly',
      CoordinatorBoard.beneficiaries.value.length >= 5,
    ),
    (
      'Ten Events',
      Icons.event_available_rounded,
      const Color(0xFF8A5A1E),
      'Run ten events',
      done >= 10,
    ),
  ];
}
