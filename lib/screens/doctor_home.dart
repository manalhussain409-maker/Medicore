import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../models/appointment_model.dart';
import '../models/doctor_model.dart';
import '../models/user_model.dart';
import '../services/appointment_service.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../services/doctor_service.dart';
import '../services/image_service.dart';
import '../components/cards.dart';
import '../components/loading.dart';
import 'chat_screen.dart';

class DoctorHomeScreen extends StatefulWidget {
  final String? loggedInDoctorId;
  final String? loggedInDoctorName;

  const DoctorHomeScreen({
    super.key,
    this.loggedInDoctorId,
    this.loggedInDoctorName,
  });

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  int _currentNavIndex = 0;
  late String _currentDoctorId;
  late String _currentDoctorName;

  final AuthService _authService = AuthService();
  final AppointmentService _appointmentService = AppointmentService();
  final ChatService _chatService = ChatService();
  final UserService _userService = UserService();
  final DoctorService _doctorService = DoctorService();
  final ImageService _imageService = ImageService();
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _currentDoctorId =
        widget.loggedInDoctorId ?? FirebaseAuth.instance.currentUser?.uid ?? '';
    _currentDoctorName = widget.loggedInDoctorName ?? 'Doctor';
    _userService.setUserOnlineStatus(_currentDoctorId, true);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _logout() async {
    await _userService.setUserOnlineStatus(_currentDoctorId, false);
    await _authService.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00796B),
        title: Text(
          _currentNavIndex == 0
              ? 'Doctor Dashboard'
              : _currentNavIndex == 1
                  ? 'Patient Messages'
                  : 'Profile',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Sign Out',
                          style: TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                ),
              );
              if (confirmed == true) _logout();
            },
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ],
        elevation: 0,
      ),
      body: SafeArea(child: _tabs[_currentNavIndex]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentNavIndex,
          selectedItemColor: const Color(0xFF008080),
          unselectedItemColor: Colors.grey.shade400,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          onTap: (index) => setState(() => _currentNavIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_rounded),
              label: 'Appointments',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.question_answer_rounded),
              label: 'Inbox',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_rounded),
              label: 'Schedule',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.badge_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> get _tabs => [
        _buildAppointmentsTab(),
        _buildInboxTab(),
        _buildAvailabilityTab(),
        _buildProfileTab(),
      ];

  Widget _buildAppointmentsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dr. $_currentDoctorName',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A1931),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage your practice',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 20),
          StreamBuilder<List<AppointmentModel>>(
            stream: _appointmentService.getDoctorAppointments(_currentDoctorId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Column(
                  children: List.generate(
                    3,
                    (_) => const AppointmentCardShimmer(),
                  ),
                );
              }
              if (snapshot.hasError) {
                return _emptyState(
                  Icons.error_outline,
                  'Something went wrong',
                  'Unable to load appointments. Pull to refresh.',
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _emptyState(
                  Icons.calendar_today_outlined,
                  'No appointments yet',
                  'Patient bookings will appear here',
                );
              }

              final allAppointments = snapshot.data!;
              final today = DateTime.now();
              final todayAppointments = allAppointments
                  .where(
                    (a) =>
                        a.appointmentDate.year == today.year &&
                        a.appointmentDate.month == today.month &&
                        a.appointmentDate.day == today.day,
                  )
                  .toList();
              final patientQueue = allAppointments
                  .where((a) => a.status == 'Pending')
                  .toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader(
                    Icons.today_rounded,
                    "Today's Appointments",
                    '${todayAppointments.length} scheduled',
                  ),
                  const SizedBox(height: 10),
                  if (todayAppointments.isEmpty)
                    _compactEmptyCard(
                      Icons.event_available_outlined,
                      'No appointments today',
                    )
                  else
                    ...todayAppointments.map(
                      (appt) => AppointmentCard(
                        appointment: appt,
                        onDetails: () => _showAppointmentActions(appt),
                        onCancel: appt.status == 'Pending' ||
                                appt.status == 'Confirmed'
                            ? () => _updateStatus(appt.id, 'Cancelled')
                            : null,
                      ),
                    ),
                  const SizedBox(height: 24),
                  _sectionHeader(
                    Icons.people_alt_rounded,
                    'Patient Queue',
                    '${patientQueue.length} waiting',
                  ),
                  const SizedBox(height: 10),
                  if (patientQueue.isEmpty)
                    _compactEmptyCard(
                      Icons.check_circle_outline,
                      'No patients waiting',
                    )
                  else
                    ...patientQueue.map(
                      (appt) => AppointmentCard(
                        appointment: appt,
                        onDetails: () => _showAppointmentActions(appt),
                        onCancel: () => _updateStatus(appt.id, 'Cancelled'),
                      ),
                    ),
                  if (allAppointments
                      .where((a) => a.status != 'Pending')
                      .isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _sectionHeader(
                      Icons.history_rounded,
                      'Recent Activity',
                      '',
                    ),
                    const SizedBox(height: 10),
                    ...allAppointments
                        .where((a) => a.status != 'Pending')
                        .take(5)
                        .map(
                          (appt) => AppointmentCard(
                            appointment: appt,
                            onDetails: () => _showAppointmentActions(appt),
                          ),
                        ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2F1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF008080), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A1931),
                ),
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _compactEmptyCard(IconData icon, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade400),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _showAppointmentActions(AppointmentModel appt) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              appt.patientName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '${appt.appointmentDate.day}/${appt.appointmentDate.month}/${appt.appointmentDate.year} - ${appt.timeSlot}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            if (appt.status == 'Pending')
              _actionTile(
                'Confirm Appointment',
                Icons.check_circle_outline,
                Colors.green,
                () {
                  _updateStatus(appt.id, 'Confirmed');
                  Navigator.pop(ctx);
                },
              ),
            if (appt.status == 'Confirmed')
              _actionTile(
                'Mark as Completed',
                Icons.task_alt,
                Colors.blue,
                () {
                  _updateStatus(appt.id, 'Completed');
                  Navigator.pop(ctx);
                },
              ),
            _actionTile(
              'Add Prescription',
              Icons.note_add_outlined,
              const Color(0xFF008080),
              () {
                Navigator.pop(ctx);
                _showPrescriptionDialog(appt.id);
              },
            ),
            _actionTile(
              'Message Patient',
              Icons.chat_outlined,
              const Color(0xFF008080),
              () async {
                Navigator.pop(ctx);
                final chatRoomId = await _chatService.createOrGetChatRoom(
                  participant1Id: _currentDoctorId,
                  participant2Id: appt.patientId,
                  participant1Name: _currentDoctorName,
                  participant2Name: appt.patientName,
                );
                if (!mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      chatRoomId: chatRoomId,
                      currentUserId: _currentDoctorId,
                      receiverId: appt.patientId,
                      receiverName: appt.patientName,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionTile(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }

  Future<void> _updateStatus(String id, String status) async {
    await _appointmentService.updateAppointmentStatus(id, status);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Appointment $status')),
    );
  }

  void _showPrescriptionDialog(String appointmentId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Prescription'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Enter medicines and dosage...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await _appointmentService.addPrescription(
                appointmentId,
                controller.text.trim(),
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF008080),
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildInboxTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Patient Messages',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A1931),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder(
              stream: _chatService.getUserChatRooms(_currentDoctorId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF008080)),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _emptyState(
                    Icons.chat_bubble_outline,
                    'No conversations yet',
                    'Messages from patients will appear here',
                  );
                }

                final rooms = snapshot.data!;
                return ListView.builder(
                  itemCount: rooms.length,
                  itemBuilder: (context, index) {
                    final room = rooms[index];
                    final otherId = room.participants.firstWhere(
                      (id) => id != _currentDoctorId,
                      orElse: () => '',
                    );

                    return FutureBuilder<String>(
                      future: _getPatientName(otherId),
                      builder: (context, nameSnap) {
                        final displayName = nameSnap.data ?? 'Loading...';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFE0F2F1),
                              child: Text(
                                displayName.isNotEmpty
                                    ? displayName[0].toUpperCase()
                                    : 'P',
                                style: const TextStyle(
                                  color: Color(0xFF008080),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              displayName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              room.lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    chatRoomId: room.id,
                                    currentUserId: _currentDoctorId,
                                    receiverId: otherId,
                                    receiverName: displayName,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  final Map<String, String> _patientNameCache = {};

  Future<String> _getPatientName(String patientId) async {
    if (_patientNameCache.containsKey(patientId)) {
      return _patientNameCache[patientId]!;
    }
    final user = await _userService.getUserById(patientId);
    final name = user?.name ?? 'Patient';
    _patientNameCache[patientId] = name;
    return name;
  }

  Widget _buildAvailabilityTab() {
    return FutureBuilder<DoctorModel?>(
      future: _doctorService.getDoctorById(_currentDoctorId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF008080)));
        }

        final doctor = snapshot.data;

        Map<String, List<String>> availability = {};
        if (doctor != null) {
          availability = Map<String, List<String>>.from(doctor.availability);
        }

        final allDays = [
          'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
        ];

        return StatefulBuilder(
          builder: (context, setTabState) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Set Your Schedule',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A1931),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Configure which days you are available and your time slots',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  ...allDays.map((day) {
                    final isWorking = availability.containsKey(day) &&
                        (availability[day]?.isNotEmpty ?? false);
                    final slots = availability[day] ?? [];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                day,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF0A1931),
                                ),
                              ),
                              Switch(
                                value: isWorking,
                                activeColor: const Color(0xFF008080),
                                onChanged: (val) {
                                  setTabState(() {
                                    if (val) {
                                      availability[day] = ['09:00 AM', '11:00 AM'];
                                    } else {
                                      availability.remove(day);
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                          if (isWorking) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ...slots.map((slot) => Chip(
                                      label: Text(slot),
                                      deleteIcon: const Icon(Icons.close, size: 16),
                                      onDeleted: () {
                                        setTabState(() {
                                          slots.remove(slot);
                                          if (slots.isEmpty) {
                                            availability.remove(day);
                                          }
                                        });
                                      },
                                      backgroundColor: const Color(0xFFE0F2F1),
                                      labelStyle: const TextStyle(
                                        color: Color(0xFF008080),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    )),
                                ActionChip(
                                  avatar: const Icon(Icons.add, size: 16, color: Color(0xFF008080)),
                                  label: const Text('Add Slot',
                                      style: TextStyle(color: Color(0xFF008080))),
                                  onPressed: () => _showAddSlotDialog(
                                    context,
                                    day,
                                    availability,
                                    setTabState,
                                  ),
                                  backgroundColor: Colors.white,
                                  side: const BorderSide(color: Color(0xFF008080)),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () async {
                        await _doctorService.updateDoctorAvailabilitySettings(
                          _currentDoctorId,
                          availability,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Schedule updated successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF008080),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save Schedule',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddSlotDialog(
    BuildContext context,
    String day,
    Map<String, List<String>> availability,
    StateSetter setTabState,
  ) {
    final timeController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Add Time Slot for $day'),
        content: TextField(
          controller: timeController,
          decoration: InputDecoration(
            hintText: 'e.g. 09:00 AM',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.access_time, color: Color(0xFF008080)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final slot = timeController.text.trim();
              if (slot.isNotEmpty) {
                setTabState(() {
                  availability[day] ??= [];
                  availability[day]!.add(slot);
                });
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF008080)),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return FutureBuilder<UserModel?>(
      future: _userService.getUserById(_currentDoctorId),
      builder: (context, snapshot) {
        final user = snapshot.data;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFF008080),
                    child: ClipOval(
                      child: SizedBox(
                        width: 100,
                        height: 100,
                        child: _buildProfileImage(
                          user?.profileImageUrl,
                          _currentDoctorName,
                        ),
                      ),
                    ),
                  ),
                  if (_isUploadingImage)
                    const Positioned.fill(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _showImagePickerOptions,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 18,
                          color: Color(0xFF008080),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Dr. $_currentDoctorName',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A1931),
                ),
              ),
              Text(
                user?.email ?? '',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF008080).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  user?.specialty ?? 'Doctor',
                  style: const TextStyle(
                    color: Color(0xFF008080),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _infoCard(user),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                  label: const Text(
                    'Sign Out',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoCard(UserModel? user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          _profileInfoTile(Icons.email_outlined, 'Email', user?.email ?? 'N/A'),
          _profileInfoTile(
              Icons.phone, 'Phone', user?.phoneNumber ?? 'Not set'),
          _profileInfoTile(
              Icons.location_city, 'City', user?.city ?? 'Not set'),
          _profileInfoTile(
              Icons.home_outlined, 'Address', user?.address ?? 'Not set'),
          _profileInfoTile(
            Icons.person_outline,
            'Gender',
            user?.gender ?? 'Not set',
          ),
          _profileInfoTile(
            Icons.star_outline,
            'Specialty',
            user?.specialty ?? 'Not set',
          ),
          _profileInfoTile(
            Icons.work_outline,
            'Experience',
            '${user?.experience ?? "N/A"} years',
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showEditProfileDialog(user),
              icon: const Icon(Icons.edit, color: Color(0xFF008080)),
              label: const Text(
                'Edit Profile',
                style: TextStyle(
                  color: Color(0xFF008080),
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF008080)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(UserModel? user) {
    final nameCtrl = TextEditingController(text: user?.name ?? '');
    final phoneCtrl = TextEditingController(text: user?.phoneNumber ?? '');
    final cityCtrl = TextEditingController(text: user?.city ?? '');
    final addressCtrl = TextEditingController(text: user?.address ?? '');
    String? selectedGender = user?.gender;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Name', border: OutlineInputBorder(), isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Phone', border: OutlineInputBorder(), isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cityCtrl,
                  decoration: const InputDecoration(
                    labelText: 'City', border: OutlineInputBorder(), isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Address', border: OutlineInputBorder(), isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedGender,
                  hint: const Text('Select Gender'),
                  decoration: const InputDecoration(
                    labelText: 'Gender', border: OutlineInputBorder(), isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (v) => setDialogState(() => selectedGender = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _userService.updateUserProfile(
                  userId: _currentDoctorId,
                  name: nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : null,
                  phoneNumber: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
                  city: cityCtrl.text.trim().isNotEmpty ? cityCtrl.text.trim() : null,
                  address: addressCtrl.text.trim().isNotEmpty ? addressCtrl.text.trim() : null,
                  gender: selectedGender,
                );
                Navigator.pop(ctx);
                setState(() {});
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile updated'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF008080)),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF008080), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Change Profile Photo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF008080)),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _uploadProfileImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF008080)),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _uploadProfileImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _uploadProfileImage(ImageSource source) async {
    setState(() => _isUploadingImage = true);
    try {
      final url = await _imageService.pickAndUploadImage(_currentDoctorId, source);
      if (url != null) {
        await _doctorService.updateDoctorProfile(
          doctorId: _currentDoctorId,
          imageUrl: url,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo updated'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Widget _buildProfileImage(String? imageUrl, String name) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('data:image')) {
        try {
          final base64Str = imageUrl.split(',').last;
          return Image.memory(
            base64Decode(base64Str),
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          );
        } catch (e) {
          return _buildInitials(name);
        }
      }
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        ),
        errorWidget: (context, url, error) => _buildInitials(name),
      );
    }
    return _buildInitials(name);
  }

  Widget _buildInitials(String name) {
    return Text(
      name.isNotEmpty ? name[0].toUpperCase() : 'D',
      style: const TextStyle(
        fontSize: 36,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _emptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(title,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}
