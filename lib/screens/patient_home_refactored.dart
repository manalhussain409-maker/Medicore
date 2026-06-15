import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/doctor_model.dart';
import '../models/appointment_model.dart';
import '../services/doctor_service.dart';
import '../services/appointment_service.dart';
import '../services/user_service.dart';
import '../services/chat_service.dart';
import '../components/buttons.dart';
import '../components/cards.dart';
import '../components/loading.dart';
import 'chat_screen.dart';

class PatientHomeScreenRefactored extends StatefulWidget {
  const PatientHomeScreenRefactored({super.key});

  @override
  State<PatientHomeScreenRefactored> createState() =>
      _PatientHomeScreenRefactoredState();
}

class _PatientHomeScreenRefactoredState
    extends State<PatientHomeScreenRefactored> {
  int _currentNavIndex = 0;
  final DoctorService _doctorService = DoctorService();
  final AppointmentService _appointmentService = AppointmentService();
  final ChatService _chatService = ChatService();
  final UserService _userService = UserService();
  String? _currentUserId;
  String? _currentUserName;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _loadCurrentUser();
  }

  void _loadCurrentUser() async {
    if (_currentUserId != null) {
      try {
        final user = await _userService.getUserById(_currentUserId!);
        setState(() {
          _currentUserName = user?.name ?? 'Patient';
        });
      } catch (e) {
        setState(() {
          _currentUserName = 'Patient';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> patientViews = [
      _buildHomeDashboardTab(),
      _buildAppointmentsTab(),
      _buildPharmacyTab(),
      _buildProfileTab(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFA),
      body: SafeArea(child: patientViews[_currentNavIndex]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentNavIndex,
          selectedItemColor: const Color(0xFF008080),
          unselectedItemColor: Colors.grey.shade400,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          onTap: (index) => setState(() => _currentNavIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_rounded),
              label: 'Appointments',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.medical_information_rounded),
              label: 'Pharmacy',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  // ==================== HOME TAB ====================
  Widget _buildHomeDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 20),

          // Search Bar
          _buildSearchBar(),
          const SizedBox(height: 24),

          // Upcoming Appointments Quick View
          _buildUpcomingAppointments(),
          const SizedBox(height: 24),

          // Doctors List
          _buildDoctorsSection(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome Back 👋',
              style: TextStyle(
                color: Colors.black45,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Find Your Doctor',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A1931),
              ),
            ),
          ],
        ),
        CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFF008080).withOpacity(0.1),
          child: const Icon(
            Icons.person_outline_rounded,
            color: Color(0xFF008080),
            size: 28,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search doctors or specialties...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          icon: const Icon(Icons.search_rounded, color: Color(0xFF008080)),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildUpcomingAppointments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upcoming Appointments',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0A1931),
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<AppointmentModel>>(
          stream: _currentUserId != null
              ? _appointmentService.getUpcomingAppointments(_currentUserId!)
              : Stream.empty(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AppointmentCardShimmer();
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 40,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No upcoming appointments',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              );
            }

            final appointment = snapshot.data!.first;
            return AppointmentCard(
              appointment: appointment,
              onDetails: () {
                _showAppointmentDetails(appointment);
              },
              onCancel: () {
                _cancelAppointment(appointment.id);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildDoctorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available Specialists',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0A1931),
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<DoctorModel>>(
          stream: _doctorService.getAllDoctors(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Column(
                children: List.generate(
                  3,
                  (index) => const DoctorCardShimmer(),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.person_off_rounded,
                      size: 40,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No doctors available',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final doctor = snapshot.data![index];
                return DoctorCard(
                  doctor: doctor,
                  onBook: () {
                    _openBookingBottomSheet(doctor);
                  },
                  onChat: () {
                    _navigateToChat(doctor);
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }

  // ==================== APPOINTMENTS TAB ====================
  Widget _buildAppointmentsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Appointments',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A1931),
            ),
          ),
          const SizedBox(height: 20),
          StreamBuilder<List<AppointmentModel>>(
            stream: _currentUserId != null
                ? _appointmentService.getPatientAppointments(_currentUserId!)
                : Stream.empty(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Column(
                  children: List.generate(
                    3,
                    (index) => const AppointmentCardShimmer(),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No appointments yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final appointment = snapshot.data![index];
                  return AppointmentCard(
                    appointment: appointment,
                    onDetails: () {
                      _showAppointmentDetails(appointment);
                    },
                    onCancel:
                        appointment.status != 'Completed' &&
                            appointment.status != 'Cancelled'
                        ? () {
                            _cancelAppointment(appointment.id);
                          }
                        : null,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ==================== PHARMACY TAB ====================
  Widget _buildPharmacyTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medical_services_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Pharmacy Coming Soon',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // ==================== PROFILE TAB ====================
  Widget _buildProfileTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline_rounded,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Profile Coming Soon',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // ==================== HELPER METHODS ====================
  void _openBookingBottomSheet(DoctorModel doctor) {
    String selectedDay = doctor.availableDays.isNotEmpty
        ? doctor.availableDays[0]
        : 'Monday';
    String selectedSlot = doctor.availableSlots.isNotEmpty
        ? doctor.availableSlots[0]
        : '10:00 AM';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Book Appointment',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A1931),
                    ),
                  ),
                  Text(
                    'with ${doctor.name}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF008080),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Select Day',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children:
                        (doctor.availableDays.isEmpty
                                ? ['Mon', 'Wed', 'Fri']
                                : doctor.availableDays)
                            .map((d) {
                              bool isSelected = selectedDay == d;
                              return ChoiceChip(
                                label: Text(d),
                                selected: isSelected,
                                selectedColor: const Color(0xFF008080),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                                onSelected: (val) =>
                                    setModalState(() => selectedDay = d),
                              );
                            })
                            .toList(),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Select Time Slot',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children:
                        (doctor.availableSlots.isEmpty
                                ? ['10:00 AM', '02:00 PM', '06:00 PM']
                                : doctor.availableSlots)
                            .map((slot) {
                              bool isSelected = selectedSlot == slot;
                              return ChoiceChip(
                                label: Text(slot),
                                selected: isSelected,
                                selectedColor: const Color(0xFF008080),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                                onSelected: (val) =>
                                    setModalState(() => selectedSlot = slot),
                              );
                            })
                            .toList(),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Confirm Booking',
                    onPressed: () {
                      _bookAppointment(doctor, selectedDay, selectedSlot);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _bookAppointment(DoctorModel doctor, String day, String slot) async {
    try {
      await _appointmentService.bookAppointment(
        patientId: _currentUserId!,
        doctorId: doctor.id,
        patientName: _currentUserName ?? 'Patient',
        doctorName: doctor.name,
        appointmentDate: DateTime.now(),
        timeSlot: slot,
        consultationFee: double.tryParse(doctor.fee) ?? 0,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment booked successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _cancelAppointment(String appointmentId) async {
    try {
      await _appointmentService.cancelAppointment(appointmentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment cancelled'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showAppointmentDetails(AppointmentModel appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Appointment Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Doctor', appointment.doctorName),
              _detailRow(
                'Date',
                '${appointment.appointmentDate.day}/${appointment.appointmentDate.month}/${appointment.appointmentDate.year}',
              ),
              _detailRow('Time', appointment.timeSlot),
              _detailRow('Status', appointment.status),
              _detailRow('Fee', 'Rs. ${appointment.consultationFee}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value, style: TextStyle(color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  void _navigateToChat(DoctorModel doctor) async {
    try {
      final chatRoomId = await _chatService.createOrGetChatRoom(
        participant1Id: _currentUserId!,
        participant2Id: doctor.id,
        participant1Name: _currentUserName ?? 'Patient',
        participant2Name: doctor.name,
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatRoomId: chatRoomId,
            currentUserId: _currentUserId!,
            receiverId: doctor.id,
            receiverName: doctor.name,
            receiverImage: doctor.imageUrl,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error opening chat: $e')));
      }
    }
  }
}
