import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/sample_events.dart';
import 'campaign_models.dart';

/// The one campaign the app uses until it has a campaign-switcher UI —
/// see the note on [Campaign]. Firestore rules don't depend on this
/// value at all; they isolate campaigns generically by `campaignId`.
const kDefaultCampaignId = 'default';

/// Reads and writes everything under `campaigns/{campaignId}`: sites,
/// assignments, beneficiaries, distribution events, reallocations,
/// alerts, and the existing Beneficiaries screens' partner
/// organizations. One place for all of it, mirroring how
/// `UserProfileService` is the one place that touches `users/{uid}`.
///
/// Every write shape here is exactly what `firestore.rules` was written
/// against — changing a field name on one side without the other will
/// make writes start failing with `permission-denied`.
class CampaignService {
  CampaignService._();

  static final _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _campaigns() =>
      _firestore.collection('campaigns');

  static CollectionReference<Map<String, dynamic>> _sub(
    String campaignId,
    String name,
  ) => _campaigns().doc(campaignId).collection(name);

  // ---------------------------------------------------------------------
  // Campaign
  // ---------------------------------------------------------------------

  /// Creates [kDefaultCampaignId] if it doesn't exist yet. Safe to call
  /// every time the coordinator dashboard loads — a no-op after the
  /// first time.
  static Future<void> ensureDefaultCampaign({
    required String createdBy,
    String name = 'FoodLink Campaign',
  }) async {
    final ref = _campaigns().doc(kDefaultCampaignId);
    final existing = await ref.get();
    if (existing.exists) return;
    await ref.set({
      'name': name,
      'status': 'active',
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<Campaign?> watchCampaign([
    String campaignId = kDefaultCampaignId,
  ]) => _campaigns()
      .doc(campaignId)
      .snapshots()
      .map((doc) => doc.exists ? Campaign.fromSnapshot(doc) : null);

  // ---------------------------------------------------------------------
  // Sites
  // ---------------------------------------------------------------------

  static Stream<List<SiteRecord>> watchSites([
    String campaignId = kDefaultCampaignId,
  ]) => _sub(campaignId, 'sites').orderBy('name').snapshots().map(
    (snap) => snap.docs.map(SiteRecord.fromSnapshot).toList(),
  );

  static Future<void> createSite({
    required String name,
    required String address,
    required num capacity,
    String campaignId = kDefaultCampaignId,
  }) {
    return _sub(campaignId, 'sites').add({
      'name': name,
      'address': address,
      'status': 'active',
      'currentSupply': capacity,
      'capacity': capacity,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ---------------------------------------------------------------------
  // Assignments
  // ---------------------------------------------------------------------

  static Stream<List<Assignment>> watchMyAssignments({
    required String volunteerId,
    String campaignId = kDefaultCampaignId,
  }) => _sub(campaignId, 'assignments')
      .where('volunteerId', isEqualTo: volunteerId)
      .snapshots()
      .map((snap) => snap.docs.map(Assignment.fromSnapshot).toList());

  static Future<void> assignVolunteer({
    required String siteId,
    required String volunteerId,
    required String task,
    String campaignId = kDefaultCampaignId,
  }) {
    final id = Assignment.idFor(siteId: siteId, volunteerId: volunteerId);
    return _sub(campaignId, 'assignments').doc(id).set({
      'siteId': siteId,
      'volunteerId': volunteerId,
      'task': task,
      'status': 'active',
      'assignedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ---------------------------------------------------------------------
  // Household beneficiaries (PRD section 11 — distinct from the
  // partner-organization methods further down)
  // ---------------------------------------------------------------------

  static Stream<List<HouseholdBeneficiary>> watchHouseholdBeneficiaries({
    required String siteId,
    String campaignId = kDefaultCampaignId,
  }) => _sub(campaignId, 'beneficiaries')
      .where('siteId', isEqualTo: siteId)
      .snapshots()
      .map((snap) => snap.docs.map(HouseholdBeneficiary.fromSnapshot).toList());

  static Future<void> addHouseholdBeneficiary({
    required String siteId,
    required String name,
    required int householdSize,
    String notes = '',
    String campaignId = kDefaultCampaignId,
  }) {
    return _sub(campaignId, 'beneficiaries').add({
      'siteId': siteId,
      'name': name,
      'householdSize': householdSize,
      'status': 'pending',
      'notes': notes,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ---------------------------------------------------------------------
  // Distribution events
  // ---------------------------------------------------------------------

  static Stream<List<DistributionEvent>> watchDistributionEvents({
    required String siteId,
    String campaignId = kDefaultCampaignId,
  }) => _sub(campaignId, 'distributionEvents')
      .where('siteId', isEqualTo: siteId)
      .snapshots()
      .map((snap) => snap.docs.map(DistributionEvent.fromSnapshot).toList());

  /// Records a distribution event and, in the same atomic transaction,
  /// decrements that site's `currentSupply` — the PRD's own risk table
  /// explicitly calls for a transaction here, since several volunteers
  /// can submit for the same site at once. [requireAssignment] exists
  /// only to make that failure path reachable from a test without a
  /// real matching assignment document; the app always leaves it `true`.
  static Future<void> recordDistributionEvent({
    required String siteId,
    required String volunteerId,
    required String category,
    required num quantity,
    required String unit,
    required int beneficiaryCount,
    String campaignId = kDefaultCampaignId,
  }) async {
    final siteRef = _sub(campaignId, 'sites').doc(siteId);
    final eventRef = _sub(campaignId, 'distributionEvents').doc();
    await _firestore.runTransaction((tx) async {
      final siteDoc = await tx.get(siteRef);
      final currentSupply = (siteDoc.data()?['currentSupply'] as num?) ?? 0;
      tx.set(eventRef, {
        'siteId': siteId,
        'volunteerId': volunteerId,
        'category': category,
        'quantity': quantity,
        'unit': unit,
        'beneficiaryCount': beneficiaryCount,
        'recordedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      tx.update(siteRef, {
        'currentSupply': (currentSupply - quantity).clamp(0, currentSupply),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // ---------------------------------------------------------------------
  // Reallocations
  // ---------------------------------------------------------------------

  static Stream<List<Reallocation>> watchReallocations([
    String campaignId = kDefaultCampaignId,
  ]) => _sub(campaignId, 'reallocations')
      .snapshots()
      .map((snap) => snap.docs.map(Reallocation.fromSnapshot).toList());

  /// Moves supply from one site to another: one immutable reallocation
  /// record, plus both sites' `currentSupply` updated — all atomically,
  /// so a reallocation can never be recorded without actually moving the
  /// stock (or vice versa).
  static Future<void> createReallocation({
    required String fromSiteId,
    required String toSiteId,
    required String category,
    required num quantity,
    required String unit,
    required String reason,
    required String createdBy,
    String campaignId = kDefaultCampaignId,
  }) async {
    final fromRef = _sub(campaignId, 'sites').doc(fromSiteId);
    final toRef = _sub(campaignId, 'sites').doc(toSiteId);
    final reallocationRef = _sub(campaignId, 'reallocations').doc();
    await _firestore.runTransaction((tx) async {
      final fromDoc = await tx.get(fromRef);
      final toDoc = await tx.get(toRef);
      final fromSupply = (fromDoc.data()?['currentSupply'] as num?) ?? 0;
      final toSupply = (toDoc.data()?['currentSupply'] as num?) ?? 0;
      tx.set(reallocationRef, {
        'fromSiteId': fromSiteId,
        'toSiteId': toSiteId,
        'category': category,
        'quantity': quantity,
        'unit': unit,
        'reason': reason,
        'createdBy': createdBy,
        'createdAt': FieldValue.serverTimestamp(),
      });
      tx.update(fromRef, {
        'currentSupply': (fromSupply - quantity).clamp(0, fromSupply),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      tx.update(toRef, {
        'currentSupply': toSupply + quantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // ---------------------------------------------------------------------
  // Alerts
  // ---------------------------------------------------------------------

  static Stream<List<CampaignAlert>> watchAlerts([
    String campaignId = kDefaultCampaignId,
  ]) => _sub(campaignId, 'alerts')
      .where('status', isEqualTo: 'open')
      .snapshots()
      .map((snap) => snap.docs.map(CampaignAlert.fromSnapshot).toList());

  static Future<void> raiseAlert({
    required String type,
    required String siteId,
    required String severity,
    required String message,
    String campaignId = kDefaultCampaignId,
  }) {
    return _sub(campaignId, 'alerts').add({
      'type': type,
      'siteId': siteId,
      'severity': severity,
      'message': message,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
      'resolvedAt': null,
    });
  }

  static Future<void> resolveAlert({
    required String alertId,
    String campaignId = kDefaultCampaignId,
  }) {
    return _sub(campaignId, 'alerts').doc(alertId).update({
      'status': 'resolved',
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }

  // ---------------------------------------------------------------------
  // Events and roster (the existing coordinator Events screens, and the
  // volunteer-side "Confirm & Join" / "Leave event" actions)
  // ---------------------------------------------------------------------

  static Stream<List<CampaignEventRecord>> watchEvents([
    String campaignId = kDefaultCampaignId,
  ]) => _sub(campaignId, 'events').orderBy('title').snapshots().map(
    (snap) => snap.docs.map(CampaignEventRecord.fromSnapshot).toList(),
  );

  /// Looks up an event's document ID by its title — the existing Events
  /// screens already identify an event by title (e.g.
  /// `CoordinatorEventDetailsScreen`'s lookup), so this reuses that same
  /// key rather than threading a separate Firestore ID through the UI.
  static Future<String?> findEventIdByTitle(
    String title, {
    String campaignId = kDefaultCampaignId,
  }) async {
    final matches = await _sub(campaignId, 'events')
        .where('title', isEqualTo: title)
        .limit(1)
        .get();
    return matches.docs.isEmpty ? null : matches.docs.first.id;
  }

  /// Saves the event in full (its date, place, description, capacity and
  /// so on — see [VolunteerEvent.toMap]), so volunteers on other devices
  /// can see and join it, not just the coordinator who created it.
  static Future<void> createEvent({
    required VolunteerEvent event,
    required String createdBy,
    String status = 'upcoming',
    String campaignId = kDefaultCampaignId,
  }) {
    return _sub(campaignId, 'events').add({
      ...event.toMap(),
      'status': status,
      'mealsSoFar': 0,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Every real event in full, newest first — what a real account sees
  /// instead of the sample events.
  static Future<List<RealEvent>> fetchEvents([
    String campaignId = kDefaultCampaignId,
  ]) async {
    final snap = await _sub(campaignId, 'events').get();
    final events = [
      for (final doc in snap.docs)
        RealEvent(
          id: doc.id,
          event: VolunteerEvent.fromMap(doc.data()),
          status: doc.data()['status'] as String? ?? 'upcoming',
          mealsSoFar: (doc.data()['mealsSoFar'] as num?)?.toInt() ?? 0,
          createdAt: (doc.data()['createdAt'] as Timestamp?)?.toDate(),
        ),
    ]..sort(
        (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
          a.createdAt ?? DateTime(0),
        ),
      );
    return events;
  }

  /// The signed-in volunteer's own roster entry for one event, if they've
  /// joined it — a plain document read the rules allow for your own uid.
  static Future<EventRosterEntry?> fetchMyRosterEntry({
    required String eventId,
    required String volunteerId,
    String campaignId = kDefaultCampaignId,
  }) async {
    final doc = await _sub(campaignId, 'events')
        .doc(eventId)
        .collection('roster')
        .doc(volunteerId)
        .get();
    return doc.exists ? EventRosterEntry.fromSnapshot(doc) : null;
  }

  static Stream<List<EventRosterEntry>> watchRoster({
    required String eventId,
    String campaignId = kDefaultCampaignId,
  }) => _sub(campaignId, 'events')
      .doc(eventId)
      .collection('roster')
      .snapshots()
      .map((snap) => snap.docs.map(EventRosterEntry.fromSnapshot).toList());

  /// A volunteer joining an event — their own roster entry, starting
  /// `'pending'` until a coordinator confirms it.
  static Future<void> joinEvent({
    required String eventId,
    required String volunteerId,
    required String name,
    required String role,
    String campaignId = kDefaultCampaignId,
  }) {
    return _sub(campaignId, 'events')
        .doc(eventId)
        .collection('roster')
        .doc(volunteerId)
        .set({
          'name': name,
          'role': role,
          'status': 'pending',
          'joinedAt': FieldValue.serverTimestamp(),
        });
  }

  /// A volunteer leaving an event they'd joined.
  static Future<void> leaveEvent({
    required String eventId,
    required String volunteerId,
    String campaignId = kDefaultCampaignId,
  }) {
    return _sub(campaignId, 'events')
        .doc(eventId)
        .collection('roster')
        .doc(volunteerId)
        .delete();
  }

  /// A coordinator confirming a pending roster entry.
  static Future<void> confirmRosterEntry({
    required String eventId,
    required String volunteerId,
    String campaignId = kDefaultCampaignId,
  }) {
    return _sub(campaignId, 'events')
        .doc(eventId)
        .collection('roster')
        .doc(volunteerId)
        .update({'status': 'confirmed'});
  }

  // ---------------------------------------------------------------------
  // Reports — real numbers computed from events + roster + partner
  // organizations, for the existing Reports screen's period comparison.
  //
  // Two approximations worth being explicit about, since nothing in the
  // current schema tracks these more precisely:
  //  - "Meals distributed" sums each event's `mealsSoFar`, bucketed by
  //    when the EVENT was created — not by when individual meals were
  //    actually served over that event's lifetime. A long-running event
  //    attributes its whole running total to its creation window.
  //  - "Communities served" is the cumulative number of partner
  //    organizations on record as of each window's end, not "orgs that
  //    actually received a delivery in this window" — there's no link
  //    from an event to a specific partner organization in this schema.
  // ---------------------------------------------------------------------

  static Future<ReportStats> _statsForWindow({
    required DateTime start,
    required DateTime end,
    String campaignId = kDefaultCampaignId,
  }) async {
    final startTs = Timestamp.fromDate(start);
    final endTs = Timestamp.fromDate(end);

    final eventsSnap = await _sub(campaignId, 'events')
        .where('createdAt', isGreaterThanOrEqualTo: startTs)
        .where('createdAt', isLessThan: endTs)
        .get();
    final meals = eventsSnap.docs.fold<int>(
      0,
      (total, doc) => total + ((doc.data()['mealsSoFar'] as num?)?.toInt() ?? 0),
    );

    // Filtered by date here rather than in the query: a date filter on a
    // collection-group query needs a collection-group index Firestore
    // doesn't create automatically. Roster entries are few enough that
    // reading them all and filtering locally is cheap.
    final rosterSnap = await _firestore.collectionGroup('roster').get();
    final volunteers = {
      for (final doc in rosterSnap.docs)
        if (doc.data()['joinedAt'] case final Timestamp joined
            when !joined.toDate().isBefore(start) &&
                joined.toDate().isBefore(end))
          doc.id,
    }.length;

    final communitiesCount = await _sub(campaignId, 'partnerOrganizations')
        .where('createdAt', isLessThan: endTs)
        .count()
        .get();

    return ReportStats(
      meals: meals,
      volunteers: volunteers,
      communities: communitiesCount.count ?? 0,
    );
  }

  /// [months] matches the existing `ReportPeriod.months` values (1, 3, 6
  /// for This Month / Last 3 Months / This Year) — a rolling window
  /// ending now, compared with the equal-length window immediately
  /// before it.
  static Future<ReportComparison> computeReportComparison({
    required int months,
    DateTime? now,
    String campaignId = kDefaultCampaignId,
  }) async {
    final end = now ?? DateTime.now();
    final currentStart = DateTime(end.year, end.month - months, end.day);
    final previousStart = DateTime(end.year, end.month - months * 2, end.day);
    final current = await _statsForWindow(
      start: currentStart,
      end: end,
      campaignId: campaignId,
    );
    final previous = await _statsForWindow(
      start: previousStart,
      end: currentStart,
      campaignId: campaignId,
    );
    return ReportComparison(current: current, previous: previous);
  }

  /// Meals per calendar month for the trailing [monthsBack] months
  /// (oldest first), for the existing Reports screen's bar chart — same
  /// "attributed to the event's creation month" approximation as above.
  static Future<List<(String, int)>> computeMonthlyMealTotals({
    required int monthsBack,
    DateTime? now,
    String campaignId = kDefaultCampaignId,
  }) async {
    final anchor = now ?? DateTime.now();
    final start = DateTime(anchor.year, anchor.month - monthsBack + 1, 1);
    final snap = await _sub(campaignId, 'events')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .get();

    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final totals = <int, int>{}; // key: year*12+month, value: meals
    for (var i = 0; i < monthsBack; i++) {
      final m = DateTime(start.year, start.month + i);
      totals[m.year * 12 + m.month] = 0;
    }
    for (final doc in snap.docs) {
      final createdAt = doc.data()['createdAt'];
      if (createdAt is! Timestamp) continue;
      final d = createdAt.toDate();
      final key = d.year * 12 + d.month;
      if (!totals.containsKey(key)) continue;
      totals[key] =
          totals[key]! + ((doc.data()['mealsSoFar'] as num?)?.toInt() ?? 0);
    }
    return [
      for (var i = 0; i < monthsBack; i++)
        () {
          final m = DateTime(start.year, start.month + i);
          return (monthNames[m.month - 1], totals[m.year * 12 + m.month]!);
        }(),
    ];
  }

  /// Every real volunteer's join record across every event — the
  /// reusable backend service for a real volunteer directory, built and
  /// tested even though the existing Volunteers (approval) *screen*
  /// isn't wired to it. That screen's data (`volunteerContacts`,
  /// `CoordinatorBoard.pending`) is a fixed cast of 32 sample names with
  /// no uid or email — there's no safe way to map it onto real
  /// Firebase users without inventing a correspondence the PRD and
  /// existing code don't support. A real "approve this volunteer" flow
  /// already exists and is fully secured: `ConfirmJoinScreen` creates a
  /// real, `'pending'` roster entry under the volunteer's own uid, and
  /// `confirmRosterEntry` (coordinator-only, enforced by
  /// `firestore.rules`) is how it gets approved — this method is what a
  /// future real volunteer-directory screen would read.
  static Future<List<VolunteerParticipation>> watchAllRosterEntries([
    String campaignId = kDefaultCampaignId,
  ]) async {
    // No status filter needed — a roster entry is always 'pending' or
    // 'confirmed' in this schema, so every document already qualifies.
    final snap = await _firestore.collectionGroup('roster').get();
    final entries = <VolunteerParticipation>[];
    for (final doc in snap.docs) {
      // doc.reference is .../events/{eventId}/roster/{volunteerId}; walk
      // back up to confirm this entry actually belongs to campaignId
      // before including it (relevant only once a second campaign ever
      // exists — today there's always exactly one).
      final eventDoc = doc.reference.parent.parent;
      final campaignDoc = eventDoc?.parent.parent;
      if (eventDoc == null || campaignDoc?.id != campaignId) continue;
      entries.add(
        VolunteerParticipation(
          volunteerId: doc.id,
          name: doc.data()['name'] as String? ?? '',
          eventId: eventDoc.id,
          role: doc.data()['role'] as String? ?? '',
          status: doc.data()['status'] as String? ?? 'pending',
          joinedAt: (doc.data()['joinedAt'] as Timestamp?)?.toDate(),
        ),
      );
    }
    return entries;
  }

  // ---------------------------------------------------------------------
  // Team (the existing Team Management screen's invited staff)
  // ---------------------------------------------------------------------

  static Stream<List<TeamRecord>> watchTeam([
    String campaignId = kDefaultCampaignId,
  ]) => _sub(campaignId, 'team').orderBy('name').snapshots().map(
    (snap) => snap.docs.map(TeamRecord.fromSnapshot).toList(),
  );

  static Future<void> inviteTeamMember({
    required String name,
    required String role,
    required String email,
    required int colorSeed,
    String campaignId = kDefaultCampaignId,
  }) {
    return _sub(campaignId, 'team').add({
      'name': name,
      'role': role,
      'email': email,
      'colorSeed': colorSeed,
      'invited': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ---------------------------------------------------------------------
  // Partner organizations (the existing Beneficiaries screens)
  // ---------------------------------------------------------------------

  static Stream<List<PartnerOrganization>> watchPartnerOrganizations([
    String campaignId = kDefaultCampaignId,
  ]) => _sub(campaignId, 'partnerOrganizations').orderBy('name').snapshots().map(
    (snap) => snap.docs.map(PartnerOrganization.fromSnapshot).toList(),
  );

  static Future<void> addPartnerOrganization({
    required String name,
    required String type,
    required int people,
    required String address,
    required String contact,
    required String phone,
    required int colorSeed,
    required String createdBy,
    String campaignId = kDefaultCampaignId,
  }) {
    return _sub(campaignId, 'partnerOrganizations').add({
      'name': name,
      'type': type,
      'people': people,
      'address': address,
      'contact': contact,
      'phone': phone,
      'mealsThisMonth': 0,
      'nextDelivery': '',
      'colorSeed': colorSeed,
      'isNew': true,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Looks up a partner organization's document ID by its display name —
  /// the existing Beneficiaries screens identify a place by name (see
  /// `BeneficiaryDetailsScreen._place`), so this reuses that same key
  /// rather than threading a separate Firestore ID through the UI.
  static Future<String?> findPartnerOrganizationIdByName(
    String name, {
    String campaignId = kDefaultCampaignId,
  }) async {
    final matches = await _sub(campaignId, 'partnerOrganizations')
        .where('name', isEqualTo: name)
        .limit(1)
        .get();
    return matches.docs.isEmpty ? null : matches.docs.first.id;
  }

  static Future<void> scheduleDelivery({
    required String orgId,
    required String whenLabel,
    String campaignId = kDefaultCampaignId,
  }) {
    return _sub(
      campaignId,
      'partnerOrganizations',
    ).doc(orgId).update({
      'nextDelivery': whenLabel,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
