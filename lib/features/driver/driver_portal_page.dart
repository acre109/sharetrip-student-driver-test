import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/driver_notification_service.dart';
import '../../../core/services/driver_safety_service.dart';
import '../shared/driver_chat_page.dart';
import '../../core/services/sharetrip_local_store.dart';

class DriverLoginPage extends StatefulWidget {
  const DriverLoginPage({super.key});

  @override
  State<DriverLoginPage> createState() => _DriverLoginPageState();
}

class _DriverLoginPageState extends State<DriverLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _showPassword = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver Portal')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 390),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.directions_car_filled_rounded,
                        size: 58, color: AppColors.primary),
                    const SizedBox(height: 16),
                    const Text('ShareTrip Drive',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 7),
                    const Text('Sign in to manage your rides and passengers.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 30),
                    const Text('School Email'),
                    const SizedBox(height: 7),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'Enter your school email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || !value.contains('@')) {
                          return 'Enter a valid school email.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    const Text('Password'),
                    const SizedBox(height: 7),
                    TextFormField(
                      controller: _password,
                      obscureText: !_showPassword,
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _showPassword = !_showPassword),
                          icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                        ),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Enter your password.' : null,
                    ),
                    const SizedBox(height: 25),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          Navigator.pushReplacement(context,
                            MaterialPageRoute(builder: (_) => const DriverPortalPage()));
                        }
                      },
                      child: const Text('Log In to Driver Portal'),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Prototype access: this screen currently validates the form only. '
                      'Connect real driver authentication before deployment.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DriverPortalPage extends StatefulWidget {
  const DriverPortalPage({super.key});

  @override
  State<DriverPortalPage> createState() => _DriverPortalPageState();
}

class _DriverPortalPageState extends State<DriverPortalPage> {
  int _tab = 0;
  int _availableSeats = 3;
  String _tripFilter = 'Active';
  bool _online = true;
  bool _checkedIn = true;
  final List<String> _requests = ['Andrea Jimenez', 'Paolo Reyes'];
  final List<String> _requestStatus = ['Pending', 'Pending'];
  final List<String> _rides = ['Bitin Junction → CMDI Main Campus'];
  final List<String> _documents = ['School ID', "Driver's License", 'OR/CR Registration'];
  final List<String> _notifications = ['Driver portal ready. Device alerts are enabled when permitted.'];
  final DriverSafetyService _safety = DriverSafetyService();

  @override
  void initState() {
    super.initState();
    DriverNotificationService.instance.initialize();
  }

  Future<void> _notify(String title, String body) async {
    if (!mounted) return;
    setState(() => _notifications.insert(0, '$title — $body'));
    try {
      await DriverNotificationService.instance.show(title, body, id: DateTime.now().millisecondsSinceEpoch ~/ 1000);
    } catch (_) {
      // In-app notification remains available if OS notification permission is denied.
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _open(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _home(),
      _requestsPage(),
      _tripsPage(),
      _contributionsPage(),
      _profilePage(),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text('ShareTrip Drive', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Student messages',
            onPressed: () => _open(const DriverMessagesInboxPage()),
            icon: const Icon(Icons.chat_bubble_outline),
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => _open(_notificationsPage()),
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.inbox_outlined), selectedIcon: Icon(Icons.inbox), label: 'Requests'),
          NavigationDestination(icon: Icon(Icons.route_outlined), selectedIcon: Icon(Icons.route), label: 'Trips'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Earnings'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _home() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _card(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('DRIVER STATUS', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: Text(_online ? 'Online & available' : 'Currently offline', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
              Switch(value: _online, onChanged: (value) => setState(() => _online = value)),
            ]),
            Text(_online ? 'Students can request seats on your posted rides.' : 'You will not receive new ride requests.', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ]),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _stat('Pending requests', '${_requestStatus.where((s) => s == 'Pending').length}', Icons.people_outline)),
          const SizedBox(width: 10),
          Expanded(child: _stat('Upcoming trips', '${_rides.length}', Icons.directions_car_outlined)),
        ]),
        const SizedBox(height: 16),
        SizedBox(height: 48, child: ElevatedButton.icon(
          onPressed: () => _open(_postRidePage()),
          icon: const Icon(Icons.add),
          label: const Text('Post a Ride'),
        )),
        const SizedBox(height: 18),
        _sectionTitle('Current Trip', action: 'View trip', onAction: () => _open(_tripDetailPage())),
        _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: const [Expanded(child: Text('Bitin → CMDI Main Campus', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))), _StatusTag('Active')]),
          const SizedBox(height: 12),
          Row(children: const [
            Expanded(child: _MiniStat(label: 'Departure', value: '6:30 AM')),
            Expanded(child: _MiniStat(label: 'Seats filled', value: '3 / 4')),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => _open(_tripDetailPage()), child: const Text('Manage trip'))),
            const SizedBox(width: 8),
            Expanded(child: ElevatedButton(onPressed: () => _open(_tripStatusPage()), child: const Text('Start trip'))),
          ]),
        ])),
        const SizedBox(height: 18),
        _sectionTitle('Pending Requests', action: 'See all', onAction: () => setState(() => _tab = 1)),
        ..._requests.asMap().entries.where((e) => _requestStatus[e.key] == 'Pending').map((entry) =>
          _card(child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(child: Icon(Icons.person_outline)),
            title: Text(entry.value, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(entry.key == 0 ? 'Bitin Junction · 2 seats' : 'Maitim Junction · 1 seat'),
            trailing: const _StatusTag('Pending'),
            onTap: () => setState(() => _tab = 1),
          ))),
        _card(child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.shield_outlined, color: AppColors.primary, size: 30),
          title: const Text('Driver Safety Center', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('Safety tools, reports, and guidelines'),
          onTap: () => _open(_safetyPage()),
        )),
      ],
    );
  }

  Widget _requestsPage() {
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Ride Requests', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 5),
      const Text('Review ride requests from verified students.', style: TextStyle(color: AppColors.textSecondary)),
      const SizedBox(height: 16),
      ..._requests.asMap().entries.map((entry) => _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const CircleAvatar(child: Icon(Icons.person_outline)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(entry.value, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(entry.key == 0 ? 'BSIT · 3rd Year' : 'BS Education · 2nd Year', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ])),
          _StatusTag(_requestStatus[entry.key]),
        ]),
        const SizedBox(height: 12),
        Text(entry.key == 0 ? 'Pickup: Bitin Junction  ·  Seats: 2' : 'Pickup: Maitim Junction  ·  Seats: 1'),
        const SizedBox(height: 12),
        if (_requestStatus[entry.key] == 'Pending') Row(children: [
          Expanded(child: OutlinedButton(onPressed: () { setState(() => _requestStatus[entry.key] = 'Declined'); _notify('Request declined', 'You declined ${entry.value}.'); }, child: const Text('Decline'))),
          const SizedBox(width: 8),
          Expanded(child: ElevatedButton(onPressed: () { setState(() => _requestStatus[entry.key] = 'Accepted'); _notify('Request accepted', 'You accepted ${entry.value}.'); }, child: const Text('Accept'))),
        ]),
        OutlinedButton.icon(
          onPressed: () => _open(DriverChatPage(
            conversationId: 'driver_jd', title: 'Message ${entry.value}', senderRole: 'Driver')),
          icon: const Icon(Icons.chat_bubble_outline), label: const Text('Message student'),
        ),
      ]))),
      if (_requests.isEmpty) const _EmptyState(icon: Icons.inbox_outlined, title: 'No ride requests', body: 'New student requests will appear here.'),
    ]);
  }

  Widget _tripsPage() {
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('My Trips', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 14),
      SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'Active', label: Text('Active')),
          ButtonSegment(value: 'Upcoming', label: Text('Upcoming')),
          ButtonSegment(value: 'Completed', label: Text('Completed')),
        ],
        selected: {_tripFilter},
        onSelectionChanged: (value) => setState(() => _tripFilter = value.first),
      ),
      const SizedBox(height: 14),
      _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: const [Expanded(child: Text('Bitin → CMDI Main Campus', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))), _StatusTag('Active')]),
        const SizedBox(height: 5),
        const Text('Today · 6:30 AM · 3 passengers', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => _open(_tripDetailPage()), child: const Text('View passengers'))),
          const SizedBox(width: 8),
          Expanded(child: ElevatedButton(onPressed: () => _open(_tripStatusPage()), child: const Text('Trip status'))),
        ]),
        const SizedBox(height: 5),
        TextButton.icon(onPressed: () => _message('Trip cancellation request recorded in this prototype.'), icon: const Icon(Icons.cancel_outlined, color: AppColors.danger), label: const Text('Cancel trip', style: TextStyle(color: AppColors.danger))),
      ])),
      if (_tripFilter == 'Upcoming') _card(child: const ListTile(title: Text('Maitim Junction → CMDI Bay 2'), subtitle: Text('Tomorrow · 7:00 AM'), trailing: _StatusTag('Scheduled'))),
      if (_tripFilter == 'Completed') _card(child: const ListTile(title: Text('Bitin Junction → CMDI'), subtitle: Text('Yesterday · 6:30 AM'), trailing: _StatusTag('Completed'))),
    ]);
  }

  Widget _contributionsPage() {
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Fare Contributions', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 5),
      const Text('A record of suggested transportation contributions.', style: TextStyle(color: AppColors.textSecondary)),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(gradient: AppColors.headerGradient, borderRadius: BorderRadius.circular(20)),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('TOTAL COLLECTED', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('₱150', style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold)),
          Text('3 completed rides · Cash collection records', style: TextStyle(color: Colors.white70, fontSize: 12)),
        ]),
      ),
      const SizedBox(height: 16),
      _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
        Text('Recent contributions', style: TextStyle(fontWeight: FontWeight.bold)),
        ListTile(contentPadding: EdgeInsets.zero, title: Text('Bitin → CMDI'), subtitle: Text('Today · 3 passengers'), trailing: Text('₱75', style: TextStyle(fontWeight: FontWeight.bold))),
        Divider(height: 1),
        ListTile(contentPadding: EdgeInsets.zero, title: Text('Maitim → CMDI'), subtitle: Text('Yesterday · 3 passengers'), trailing: Text('₱75', style: TextStyle(fontWeight: FontWeight.bold))),
      ])),
    ]);
  }

  Widget _profilePage() {
    return ListView(padding: const EdgeInsets.all(16), children: [
      _card(child: FutureBuilder<Map<String, dynamic>?>(
        future: ShareTripLocalStore.getDriverProfile(),
        builder: (context, snapshot) {
          final profile = snapshot.data;
          final name = profile?['name']?.toString() ?? 'Juan Dela Cruz';
          final email = profile?['email']?.toString() ?? 'juan.delacruz@cmdi.edu.ph';
          return Row(children: [
            CircleAvatar(radius: 30, child: Text(name.trim().isEmpty ? 'D' : name.trim().substring(0, 1).toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold))),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(email, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 5),
              const _StatusTag('Driver'),
            ])),
            IconButton(onPressed: () => _open(_driverSettingsPage()), icon: const Icon(Icons.settings_outlined)),
          ]);
        },
      )),
      const SizedBox(height: 14),
      _card(child: Column(children: [
        _menuRow(Icons.directions_car_outlined, 'My Vehicles', () => _open(_vehiclesPage())),
        _menuRow(Icons.folder_open_outlined, 'Documents & Verification', () => _open(_documentsPage())),
        _menuRow(Icons.star_outline, 'Passenger Reviews', () => _open(_simplePage('Passenger Reviews', ['★★★★★  Andrea Jimenez', '★★★★★  Paolo Reyes']))),
        _menuRow(Icons.schedule, 'Schedule & Notifications', () => _open(_driverSettingsPage())),
        _menuRow(Icons.shield_outlined, 'Privacy, Safety & About', () => _open(_safetyPage())),
      ])),
      const SizedBox(height: 12),
      _card(child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Available to drive', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('Allow students to request seats'),
        value: _online,
        onChanged: (value) => setState(() => _online = value),
      )),
      const SizedBox(height: 10),
      OutlinedButton.icon(
        onPressed: () => showDialog(context: context, builder: (ctx) => AlertDialog(
          title: const Text('Sign out?'),
          content: const Text('You will return to the ShareTrip welcome page.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Stay')),
            TextButton(onPressed: () {
              Navigator.pop(ctx);
              Navigator.popUntil(context, (route) => route.isFirst);
            }, child: const Text('Sign out')),
          ],
        )),
        icon: const Icon(Icons.logout, color: AppColors.danger),
        label: const Text('Sign Out', style: TextStyle(color: AppColors.danger)),
      ),
    ]);
  }

  Widget _postRidePage() {
    final pickup = TextEditingController(text: 'Bitin Junction');
    final destination = TextEditingController(text: 'CMDI Main Campus');
    final fare = TextEditingController(text: '25');
    String vehicleType = 'Shuttle';
    return StatefulBuilder(builder: (context, setLocal) => Scaffold(
      appBar: AppBar(title: const Text('Post a Ride')),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        const Text('Offer available seats to students.', style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 18),
        _field('Pickup', pickup),
        _field('Destination / Route', destination),
        _field('Date', TextEditingController(text: 'Select date'), readOnly: true),
        _field('Departure time', TextEditingController(text: '6:30 AM'), readOnly: true),
        _card(child: Row(children: [
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Seats available', style: TextStyle(fontWeight: FontWeight.bold)), Text('Vehicle capacity: 4', style: TextStyle(fontSize: 12, color: AppColors.textSecondary))])),
          IconButton(onPressed: () => setLocal(() => _availableSeats = (_availableSeats - 1).clamp(1, 4).toInt()), icon: const Icon(Icons.remove_circle_outline)),
          Text('$_availableSeats', style: const TextStyle(fontWeight: FontWeight.bold)),
          IconButton(onPressed: () => setLocal(() => _availableSeats = (_availableSeats + 1).clamp(1, 4).toInt()), icon: const Icon(Icons.add_circle, color: AppColors.primary)),
        ])),
        _field('Fare per seat (₱)', fare, keyboard: TextInputType.number),
        const SizedBox(height: 8),
        const Text('Vehicle'),
        const SizedBox(height: 7),
        DropdownButtonFormField<String>(
          value: vehicleType,
          items: const [
            DropdownMenuItem(value: 'Shuttle', child: Text('Shuttle')),
            DropdownMenuItem(value: 'Motorcycle', child: Text('Motorcycle')),
            DropdownMenuItem(value: 'Tricycle', child: Text('Tricycle')),
          ],
          onChanged: (value) => setLocal(() => vehicleType = value ?? 'Shuttle'),
        ),
        const SizedBox(height: 14),
        TextFormField(maxLines: 3, decoration: const InputDecoration(labelText: 'Optional notes', hintText: 'Pickup landmark or reminders...')),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: () {
          this.setState(() => _rides.add('${pickup.text} → ${destination.text} · $vehicleType'));
          Navigator.pop(context);
          _notify('Ride posted', '${pickup.text} to ${destination.text} ($vehicleType) is now listed with $_availableSeats seats.');
          _message('Ride posted with $_availableSeats available seats.');
        }, child: const Text('Post Ride')),
      ]),
    ));
  }

  Widget _tripDetailPage() => _simplePage('Trip Details', [
    'Route: Bitin Junction → CMDI Main Campus',
    'Departure: 6:30 AM',
    'Vehicle: Passenger Tricycle · ABC 1234',
    'Passengers: Andrea Jimenez, Paolo Reyes, Mika Santos',
    'Available seats: 1',
  ], actions: [
    ('View trip status', () => _open(_tripStatusPage())),
    ('Cancel trip', () => _message('Trip cancellation recorded.')),
  ]);

  Widget _tripStatusPage() => _DriverLiveTripScreen(
    onSos: () => _open(_sosPage()),
    onReport: () => _open(_reportPage()),
    onStatusChanged: (status) => _notify('Trip update', status),
  );

  Widget _notificationsPage() => Scaffold(
    appBar: AppBar(title: const Text('Notifications')),
    body: _notifications.isEmpty
        ? const Center(child: Text('You are all caught up.'))
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _notifications.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) => ListTile(
              leading: const CircleAvatar(child: Icon(Icons.notifications_active_outlined)),
              title: Text(_notifications[index]),
              subtitle: const Text('This device'),
            ),
          ),
  );

  Widget _safetyPage() => Scaffold(
    appBar: AppBar(title: const Text('Driver Safety Center')),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      _card(child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Location privacy', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 6),
        Text('Live location is requested only when you open trip tracking. Stop tracking or leave the screen to end the stream.'),
      ])),
      _card(child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Emergency guidance', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 6),
        Text('For immediate danger, call local emergency services. SOS prepares an SMS with your current coordinates; you must review and send it.'),
      ])),
      OutlinedButton.icon(
        onPressed: () => _open(_locationTrackingPage()),
        icon: const Icon(Icons.my_location),
        label: const Text('Test live location'),
      ),
      ElevatedButton.icon(
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
        onPressed: () => _open(_sosPage()),
        icon: const Icon(Icons.sos),
        label: const Text('Emergency SOS'),
      ),
      TextButton(onPressed: () => _open(_reportPage()), child: const Text('Report a safety concern')),
    ]),
  );

  Widget _locationTrackingPage() => _DriverLocationScreen();

  Widget _sosPage() => _DriverSosScreen(safety: _safety);

  Widget _vehiclesPage() => _simplePage('My Vehicles', [
    'Allowed vehicle types: Shuttle, Motorcycle, Tricycle',
    'Register your vehicle details during driver registration.',
  ], actions: [
    ('Add Vehicle', () => _message('Vehicle type options: Shuttle, Motorcycle, Tricycle.')),
  ]);

  Widget _documentsPage() => _simplePage('Documents & Verification', [
    ..._documents.map((d) => '$d · Submitted for review'),
    'Vehicle inspection · Not submitted',
    'Barangay clearance · Not submitted',
  ], actions: [
    ('Upload document', () => _message('Choose a document file to upload.')),
    ('Refresh status', () => _message('Document statuses refreshed.')),
  ]);

  Widget _driverSettingsPage() => _settingsPage();

  Widget _settingsPage() => _DriverSettingsScreen(
    onSave: () => _message('Driver settings saved in this prototype.'),
  );

  Widget _reportPage() {
    final details = TextEditingController();
    String category = 'Safety concern';
    return StatefulBuilder(builder: (context, setLocal) => Scaffold(
      appBar: AppBar(title: const Text('Report a Problem')),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        const Text('Tell the ShareTrip team what happened.'),
        const SizedBox(height: 15),
        DropdownButtonFormField<String>(
          value: category,
          items: const ['Safety concern', 'Incorrect details', 'Inappropriate behaviour', 'Other'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: (v) => setLocal(() => category = v ?? category),
          decoration: const InputDecoration(labelText: 'Report category'),
        ),
        const SizedBox(height: 12),
        TextField(controller: details, maxLines: 5, decoration: const InputDecoration(labelText: 'Details', hintText: 'Describe the issue...')),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: () {
          Navigator.pop(context);
          _message('Your report has been recorded in this prototype.');
        }, child: const Text('Submit Report')),
      ]),
    ));
  }

  Widget _simplePage(String title, List<String> lines, {List<(String, VoidCallback)> actions = const []}) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: lines.map((line) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Text(line, style: const TextStyle(fontSize: 14)),
        )).toList())),
        const SizedBox(height: 14),
        ...actions.map((action) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: OutlinedButton(onPressed: action.$2, child: Text(action.$1)),
        )),
      ]),
    );
  }

  Widget _field(String label, TextEditingController controller, {TextInputType? keyboard, bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 7),
        TextField(controller: controller, keyboardType: keyboard, readOnly: readOnly, decoration: InputDecoration(hintText: label)),
      ]),
    );
  }

  Widget _sectionTitle(String title, {String? action, VoidCallback? onAction}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Expanded(child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
      if (action != null) TextButton(onPressed: onAction, child: Text(action)),
    ]),
  );

  Widget _stat(String label, String value, IconData icon) => _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(icon, color: AppColors.primary),
    const SizedBox(height: 8),
    Text(value, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
    Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
  ]));

  Widget _menuRow(IconData icon, String title, VoidCallback onTap) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, color: AppColors.primary),
    title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17), border: Border.all(color: AppColors.border)),
    child: child,
  );
}


class _DriverLocationScreen extends StatefulWidget {
  @override
  State<_DriverLocationScreen> createState() => _DriverLocationScreenState();
}

class _DriverLocationScreenState extends State<_DriverLocationScreen> {
  final LocationService _location = LocationService();
  Stream<Position>? _positions;
  String? _error;

  void _start() {
    setState(() {
      _error = null;
      _positions = _location.getLocationStream().handleError((Object e) {
        if (mounted) setState(() => _error = e.toString());
      });
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Live Trip Location')),
    body: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Your device location updates while this screen is open. Keep the app in the foreground for reliable tracking.'),
        const SizedBox(height: 16),
        ElevatedButton.icon(onPressed: _start, icon: const Icon(Icons.my_location), label: const Text('Start location tracking')),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: const TextStyle(color: Colors.red))),
        const SizedBox(height: 12),
        Expanded(child: _positions == null
          ? const Center(child: Text('Location tracking is stopped.'))
          : StreamBuilder<Position>(
              stream: _positions,
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Location error: ${snapshot.error}'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final p = snapshot.data!;
                return Card(child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.gps_fixed, size: 42),
                    const SizedBox(height: 12),
                    Text('${p.latitude.toStringAsFixed(6)}, ${p.longitude.toStringAsFixed(6)}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Accuracy: ${p.accuracy.toStringAsFixed(1)} m'),
                    Text('Speed: ${(p.speed * 3.6).toStringAsFixed(1)} km/h'),
                    Text('Updated: ${p.timestamp.toLocal()}'),
                  ]),
                ));
              },
            )),
      ]),
    ),
  );
}

class _DriverSosScreen extends StatefulWidget {
  final DriverSafetyService safety;
  const _DriverSosScreen({required this.safety});

  @override
  State<_DriverSosScreen> createState() => _DriverSosScreenState();
}

class _DriverSosScreenState extends State<_DriverSosScreen> {
  final _contact = TextEditingController();
  bool _loading = true;
  String? _message;

  @override
  void initState() {
    super.initState();
    widget.safety.getEmergencyContact().then((value) {
      if (mounted) setState(() { _contact.text = value; _loading = false; });
    });
  }

  @override
  void dispose() { _contact.dispose(); super.dispose(); }

  Future<void> _sendSos() async {
    final contact = _contact.text.trim();
    if (contact.isEmpty) {
      setState(() => _message = 'Enter an emergency contact number first.');
      return;
    }
    setState(() { _loading = true; _message = null; });
    try {
      await widget.safety.saveEmergencyContact(contact);
      final opened = await widget.safety.composeSos(contact: contact);
      setState(() => _message = opened
          ? 'SMS composer opened with your current coordinates. Review the message and press Send.'
          : 'Could not open the SMS app. Call emergency services directly if needed.');
    } catch (e) {
      setState(() => _message = 'Could not get your location: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Emergency SOS')),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      const Icon(Icons.sos, size: 58, color: Colors.red),
      const Text('Send your location to your emergency contact', textAlign: TextAlign.center, style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      const Text('This opens your phone’s SMS app with a message containing your current GPS coordinates. You must press Send. It does not alert ShareTrip staff or emergency responders automatically.', textAlign: TextAlign.center),
      const SizedBox(height: 20),
      TextField(controller: _contact, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Emergency contact phone number', hintText: '+63...')),
      const SizedBox(height: 14),
      ElevatedButton.icon(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
        onPressed: _loading ? null : _sendSos,
        icon: const Icon(Icons.sms),
        label: Text(_loading ? 'Please wait…' : 'Prepare SOS SMS with location'),
      ),
      OutlinedButton.icon(onPressed: () async {
        final ok = await widget.safety.callEmergencyServices();
        if (!ok && mounted) setState(() => _message = 'Unable to open the phone app. Dial 911 manually.');
      }, icon: const Icon(Icons.call), label: const Text('Call 911')),
      if (_message != null) Padding(padding: const EdgeInsets.only(top: 14), child: Text(_message!, textAlign: TextAlign.center)),
    ]),
  );
}

class _DriverLiveTripScreen extends StatefulWidget {
  final VoidCallback onSos;
  final VoidCallback onReport;
  final ValueChanged<String> onStatusChanged;
  const _DriverLiveTripScreen({required this.onSos, required this.onReport, required this.onStatusChanged});

  @override
  State<_DriverLiveTripScreen> createState() => _DriverLiveTripScreenState();
}

class _DriverLiveTripScreenState extends State<_DriverLiveTripScreen> {
  final LocationService _location = LocationService();
  final MapController _mapController = MapController();
  final TextEditingController _pickupController = TextEditingController(text: 'Bitin Junction, Bay, Laguna, Philippines');
  final TextEditingController _destinationController = TextEditingController(text: 'CMDI Main Campus, Pila, Laguna, Philippines');
  StreamSubscription<Position>? _positionSubscription;
  Position? _latestPosition;
  LatLng? _pickupPoint;
  LatLng? _destinationPoint;
  List<LatLng> _routePoints = [];
  bool _tracking = false;
  bool _loadingLocation = false;
  bool _routeLoading = false;
  bool _mapReady = false;
  bool _followDriver = true;
  bool _checkedIn = true;
  bool _isResolvingAddresses = false;
  String _stage = 'Heading to pickup';
  String? _gpsError;
  String? _routeError;
  double? _remainingKm;
  double? _etaMinutes;
  LatLng? _lastRoutedFrom;
  DateTime? _lastRouteTime;

  LatLng get _driverPoint => LatLng(_latestPosition!.latitude, _latestPosition!.longitude);
  LatLng? get _activeTarget => _stage == 'Heading to pickup' ? _pickupPoint : _destinationPoint;

  Future<LatLng> _geocode(String address) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {'q': address, 'format': 'jsonv2', 'limit': '1'});
    final response = await http.get(uri, headers: {'User-Agent': 'ShareTrip/1.0 (driver navigation)'}).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) throw Exception('Could not find "$address". Check the place name and try again.');
    final rows = jsonDecode(response.body) as List;
    if (rows.isEmpty) throw Exception('No map result for "$address". Try a more complete address.');
    return LatLng(double.parse(rows.first['lat'].toString()), double.parse(rows.first['lon'].toString()));
  }

  Future<void> _resolveTripAddresses() async {
    setState(() { _isResolvingAddresses = true; _routeError = null; });
    try {
      final pickup = await _geocode(_pickupController.text.trim());
      final destination = await _geocode(_destinationController.text.trim());
      if (!mounted) return;
      setState(() { _pickupPoint = pickup; _destinationPoint = destination; });
      if (_latestPosition != null) await _loadRoadRoute(_driverPoint, _activeTarget!, force: true);
      if (_mapReady) _fitRouteOrDriver();
    } catch (e) {
      if (mounted) setState(() => _routeError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isResolvingAddresses = false);
    }
  }

  Future<void> _loadRoadRoute(LatLng start, LatLng target, {bool force = false}) async {
    if (_routeLoading) return;
    if (!force && _lastRoutedFrom != null) {
      final moved = const Distance().as(LengthUnit.Meter, _lastRoutedFrom!, start);
      final elapsed = DateTime.now().difference(_lastRouteTime ?? DateTime.fromMillisecondsSinceEpoch(0));
      if (moved < 40 && elapsed.inSeconds < 20) return;
    }
    setState(() { _routeLoading = true; _routeError = null; });
    try {
      final coordinates = '${start.longitude},${start.latitude};${target.longitude},${target.latitude}';
      final uri = Uri.parse('https://router.project-osrm.org/route/v1/driving/$coordinates?overview=full&geometries=geojson');
      final response = await http.get(uri, headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) throw Exception('Routing service is unavailable.');
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['code'] != 'Ok' || (data['routes'] as List).isEmpty) throw Exception('No drivable road route found between these locations.');
      final route = (data['routes'] as List).first as Map<String, dynamic>;
      final coords = (route['geometry']['coordinates'] as List);
      final points = coords.map<LatLng>((v) => LatLng((v[1] as num).toDouble(), (v[0] as num).toDouble())).toList();
      if (!mounted) return;
      setState(() {
        _routePoints = points;
        _remainingKm = (route['distance'] as num).toDouble() / 1000;
        _etaMinutes = (route['duration'] as num).toDouble() / 60;
        _lastRoutedFrom = start;
        _lastRouteTime = DateTime.now();
      });
      if (_mapReady && _routePoints.isNotEmpty) _fitRouteOrDriver();
    } catch (e) {
      if (mounted) setState(() => _routeError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _routeLoading = false);
    }
  }

  Future<void> _startTracking() async {
    await _positionSubscription?.cancel();
    setState(() { _loadingLocation = true; _gpsError = null; });
    try {
      final firstFix = await _location.getCurrentLocation();
      if (!mounted) return;
      setState(() { _latestPosition = firstFix; _loadingLocation = false; _tracking = true; });
      _moveToDriver();
      if (_pickupPoint == null || _destinationPoint == null) await _resolveTripAddresses();
      if (_activeTarget != null) await _loadRoadRoute(_driverPoint, _activeTarget!, force: true);
      _positionSubscription = _location.getLocationStream().listen((position) {
        if (!mounted) return;
        final previous = _latestPosition;
        setState(() => _latestPosition = position);
        if (_followDriver) _moveToDriver();
        if (_activeTarget != null) _loadRoadRoute(LatLng(position.latitude, position.longitude), _activeTarget!);
        if (previous != null && _stage == 'Heading to pickup' && _pickupPoint != null) {
          final distance = const Distance().as(LengthUnit.Meter, _driverPoint, _pickupPoint!);
          if (distance <= 35) _setStage('Passenger picked up');
        }
      }, onError: (Object error) {
        if (mounted) setState(() { _gpsError = _friendlyGpsError(error); _tracking = false; });
      });
    } catch (error) {
      if (!mounted) return;
      setState(() { _loadingLocation = false; _tracking = false; _gpsError = _friendlyGpsError(error); });
    }
  }

  String _friendlyGpsError(Object error) {
    final value = error.toString();
    if (value.toLowerCase().contains('permission')) return 'Location permission is blocked. Allow location access in browser/device settings, then try again.';
    if (value.toLowerCase().contains('disabled')) return 'Turn on device location services and try again.';
    return 'Could not get a GPS fix: $value';
  }

  void _setStage(String value) {
    setState(() => _stage = value);
    widget.onStatusChanged(value);
    if (_latestPosition != null && _activeTarget != null) _loadRoadRoute(_driverPoint, _activeTarget!, force: true);
  }

  Future<void> _stopTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    if (mounted) setState(() => _tracking = false);
  }

  void _moveToDriver() {
    if (!_mapReady || _latestPosition == null) return;
    _mapController.move(_driverPoint, 16.5);
  }

  void _fitRouteOrDriver() {
    if (!_mapReady) return;
    final points = <LatLng>[..._routePoints];
    if (_latestPosition != null) points.add(_driverPoint);
    if (points.length >= 2) {
      _mapController.fitCamera(CameraFit.coordinates(coordinates: points, padding: const EdgeInsets.all(55), maxZoom: 16));
    } else if (points.isNotEmpty) {
      _mapController.move(points.first, 15);
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _pickupController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Widget _mapMarker(IconData icon, Color color) => Icon(icon, color: color, size: 42, shadows: const [Shadow(color: Colors.white, blurRadius: 4)]);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Live Driver Navigation')),
    body: Column(children: [
      Expanded(flex: 6, child: Stack(children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: const LatLng(14.1775, 121.2830), initialZoom: 14,
            onMapReady: () { _mapReady = true; if (_latestPosition != null) _moveToDriver(); else _fitRouteOrDriver(); },
            onPositionChanged: (camera, gesture) { if (gesture && _followDriver) setState(() => _followDriver = false); },
          ),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.sharetrip.app'),
            if (_routePoints.isNotEmpty) PolylineLayer(polylines: [Polyline(points: _routePoints, strokeWidth: 7, color: AppColors.primary, borderStrokeWidth: 2, borderColor: Colors.white)]),
            MarkerLayer(markers: [
              if (_pickupPoint != null) Marker(point: _pickupPoint!, width: 44, height: 48, child: _mapMarker(Icons.location_on, Colors.green)),
              if (_destinationPoint != null) Marker(point: _destinationPoint!, width: 44, height: 48, child: _mapMarker(Icons.location_on, Colors.red)),
              if (_latestPosition != null) Marker(point: _driverPoint, width: 50, height: 50, child: Container(decoration: BoxDecoration(color: Colors.blue.withOpacity(.18), shape: BoxShape.circle, border: Border.all(color: Colors.blue, width: 2)), child: const Center(child: Icon(Icons.navigation, color: Colors.blue, size: 28)))),
            ]),
            RichAttributionWidget(attributions: [TextSourceAttribution('OpenStreetMap contributors')]),
          ],
        ),
        Positioned(top: 12, left: 12, right: 12, child: Card(child: Padding(padding: const EdgeInsets.all(13), child: Row(children: [
          Icon(_gpsError != null ? Icons.location_disabled : (_tracking ? Icons.navigation : Icons.gps_fixed), color: AppColors.primary),
          const SizedBox(width: 10), Expanded(child: Text(_gpsError ?? (_loadingLocation ? 'Acquiring GPS location…' : _tracking ? (_routeLoading ? 'GPS active · Updating road route…' : 'Live navigation is active') : 'Start live GPS to show your location and road route'), style: const TextStyle(fontWeight: FontWeight.w600))),
          if (_routeLoading) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
        ])))),
        Positioned(right: 14, bottom: 14, child: FloatingActionButton.small(heroTag: 'driver_recenter', backgroundColor: Colors.white, foregroundColor: AppColors.primary, onPressed: () { _followDriver = true; _moveToDriver(); }, child: const Icon(Icons.my_location))),
      ])),
      Expanded(flex: 5, child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 18), children: [
        Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('TRIP ROUTE', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(controller: _pickupController, decoration: const InputDecoration(labelText: 'Pickup location', prefixIcon: Icon(Icons.trip_origin))),
          const SizedBox(height: 8),
          TextField(controller: _destinationController, decoration: const InputDecoration(labelText: 'Destination', prefixIcon: Icon(Icons.flag_outlined))),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: _isResolvingAddresses ? null : _resolveTripAddresses, icon: const Icon(Icons.route), label: Text(_isResolvingAddresses ? 'Finding locations…' : 'Update route on map')),
          if (_routeError != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(_routeError!, style: const TextStyle(color: Colors.red, fontSize: 12))),
          const SizedBox(height: 8),
          Row(children: [Expanded(child: ElevatedButton.icon(onPressed: _tracking || _loadingLocation ? null : _startTracking, icon: const Icon(Icons.gps_fixed), label: Text(_loadingLocation ? 'Getting GPS…' : 'Start live GPS'))), const SizedBox(width: 8), OutlinedButton(onPressed: _tracking ? _stopTracking : null, child: const Text('Stop'))]),
          if (_latestPosition != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text('GPS ${_latestPosition!.latitude.toStringAsFixed(6)}, ${_latestPosition!.longitude.toStringAsFixed(6)}  ·  ±${_latestPosition!.accuracy.toStringAsFixed(0)} m  ·  ${(_latestPosition!.speed * 3.6).toStringAsFixed(1)} km/h', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
          const SizedBox(height: 4),
          const Text('Allow location permission and run Chrome/Edge on localhost or HTTPS. The map uses OpenStreetMap tiles and OSRM road routing.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ]))),
        Card(child: Column(children: [
          ListTile(title: const Text('Trip progress'), subtitle: Text(_stage)),
          for (final stage in ['Heading to pickup', 'Passenger picked up', 'In transit', 'Arrived']) RadioListTile<String>(dense: true, value: stage, groupValue: _stage, title: Text(stage), onChanged: (v) { if (v != null) _setStage(v); }),
        ])),
        if (_remainingKm != null || _etaMinutes != null) Card(child: Padding(padding: const EdgeInsets.all(14), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [Column(children: [const Text('Route distance'), Text(_remainingKm == null ? '--' : '${_remainingKm!.toStringAsFixed(2)} km', style: const TextStyle(fontWeight: FontWeight.bold))]), Column(children: [const Text('Estimated time'), Text(_etaMinutes == null ? '--' : '${_etaMinutes!.round()} min', style: const TextStyle(fontWeight: FontWeight.bold))])]))),
        Card(child: SwitchListTile(title: const Text('Passenger check-in'), subtitle: Text(_checkedIn ? 'Passenger checked in' : 'Waiting for passenger'), value: _checkedIn, onChanged: (v) => setState(() => _checkedIn = v))),
        OutlinedButton(onPressed: widget.onReport, child: const Text('Report a problem')),
        ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), onPressed: widget.onSos, icon: const Icon(Icons.sos), label: const Text('Emergency SOS')),
      ])),
    ]),
  );
}

class _DriverSettingsScreen extends StatefulWidget {
  final VoidCallback onSave;
  const _DriverSettingsScreen({required this.onSave});

  @override
  State<_DriverSettingsScreen> createState() => _DriverSettingsScreenState();
}

class _DriverSettingsScreenState extends State<_DriverSettingsScreen> {
  final Map<String, bool> _days = {'Monday': true, 'Tuesday': true, 'Wednesday': true, 'Thursday': true, 'Friday': true, 'Saturday': false, 'Sunday': false};
  bool _rideRequests = true;
  bool _rideUpdates = true;
  bool _contributions = true;
  bool _alerts = true;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Driver Settings')),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      const Text('Driving availability', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const Text('Choose the days and regular hours students can expect you to drive.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      const SizedBox(height: 12),
      ..._days.keys.map((day) => CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(day),
        value: _days[day],
        onChanged: (value) => setState(() => _days[day] = value ?? false),
      )),
      Row(children: const [
        Expanded(child: TextField(decoration: InputDecoration(labelText: 'From', hintText: '4:00 PM'))),
        SizedBox(width: 12),
        Expanded(child: TextField(decoration: InputDecoration(labelText: 'Until', hintText: '8:00 PM'))),
      ]),
      const SizedBox(height: 22),
      const Text('Notification preferences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Ride requests'), value: _rideRequests, onChanged: (v) => setState(() => _rideRequests = v)),
      SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Ride updates'), value: _rideUpdates, onChanged: (v) => setState(() => _rideUpdates = v)),
      SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Fare contributions'), value: _contributions, onChanged: (v) => setState(() => _contributions = v)),
      SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Safety & system alerts'), value: _alerts, onChanged: (v) => setState(() => _alerts = v)),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: widget.onSave, child: const Text('Save Settings')),
    ]),
  );
}

class _StatusTag extends StatelessWidget {
  final String text;
  const _StatusTag(this.text);

  @override
  Widget build(BuildContext context) {
    Color color = text.toLowerCase() == 'active' || text.toLowerCase() == 'accepted' || text.toLowerCase() == 'verified driver' || text.toLowerCase() == 'completed'
        ? AppColors.success
        : text.toLowerCase() == 'declined' || text.toLowerCase() == 'cancelled'
            ? AppColors.danger
            : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(.1), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(right: 8),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(11)),
    child: Column(children: [
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
    ]),
  );
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _EmptyState({required this.icon, required this.title, required this.body});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(children: [
      Icon(icon, size: 42, color: AppColors.textSecondary),
      const SizedBox(height: 10),
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 5),
      Text(body, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
    ]),
  );
}
