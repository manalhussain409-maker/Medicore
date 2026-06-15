import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  int _currentNavIndex = 0;
  // Mock current user session ID (In production, swap with FirebaseAuth.instance.currentUser!.uid)
  final String _currentPatientId = 'patient123';

  @override
  Widget build(BuildContext context) {
    final List<Widget> patientViews = [
      _buildHomeDashboardTab(),
      _buildAppointmentsCalendarTab(),
      _buildPharmacyTab(),
      _buildProfileTab(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFA),
      body: SafeArea(child: patientViews[_currentNavIndex]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, -4))
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentNavIndex,
          selectedItemColor: const Color(0xFF008080),
          unselectedItemColor: Colors.grey.shade400,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          onTap: (index) => setState(() => _currentNavIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.bubble_chart_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: 'Schedules'),
            BottomNavigationBarItem(icon: Icon(Icons.medical_information_rounded), label: 'Pharmacy'),
            BottomNavigationBarItem(icon: Icon(Icons.face_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  // ================= TAB 1: MASTER USER FRIENDLY DASHBOARD =================
  Widget _buildHomeDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome Back 👋', style: TextStyle(color: Colors.black45, fontWeight: FontWeight.w500, fontSize: 14)),
                  SizedBox(height: 2),
                  Text('Find Your Specialist', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0A1931))),
                ],
              ),
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFF008080).withValues(alpha: 0.1),
                child: const Icon(Icons.person_outline_rounded, color: Color(0xFF008080)),
              )
            ],
          ),
          const SizedBox(height: 20),

          // Custom Search Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search doctors or specialties...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                icon: const Icon(Icons.search_rounded, color: Color(0xFF008080)),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 24),

          const Text('Available Live Consultants', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0A1931))),
          const SizedBox(height: 12),

          // Real-time Doctors Stream
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('doctors').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Center(child: Text('Error loading files.'));
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF008080)));
              }
              if (snapshot.data!.docs.isEmpty) {
                return _buildEmptyStatePlaceholder(Icons.person_off_rounded, 'No active practitioners found.');
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;

                  // Safe explicit String conversions to avoid type mismatch crashes
                  String docId = data['id']?.toString() ?? snapshot.data!.docs[index].id;
                  String docName = data['name']?.toString() ?? 'Doctor Specialist';
                  String specialty = data['specialty']?.toString() ?? 'General Medicine';
                  String experience = data['experience']?.toString() ?? '0';
                  String fee = data['fee']?.toString() ?? '0';
                  String imageUrl = data['imageUrl']?.toString() ?? '';
                  List<String> days = List<String>.from(data['availableDays'] ?? []);
                  List<String> slots = List<String>.from(data['availableSlots'] ?? ['10:00 AM', '02:00 PM', '06:00 PM']);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 10)],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Row(
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(color: const Color(0xFFF0F5F5), borderRadius: BorderRadius.circular(14)),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: (imageUrl.isNotEmpty && imageUrl != 'placeholder')
                                  ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (c, o, s) => const Icon(Icons.person, color: Color(0xFF008080)))
                                  : const Icon(Icons.person, color: Color(0xFF008080)),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(docName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0A1931))),
                                Text(specialty, style: const TextStyle(color: Color(0xFF008080), fontSize: 13, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text(fee.contains('Rs') ? '$fee • $experience Yrs Exp' : 'Rs. $fee • $experience Yrs Exp',
                                    style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              ElevatedButton(
                                onPressed: () => _openBookingBottomSheet(docId, docName, specialty, days, slots),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF008080),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  elevation: 0,
                                ),
                                child: const Text('Book', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(height: 4),

                              // Real-Time Conditional Chat/Lock Button Integration
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('appointments')
                                    .where('patientId', isEqualTo: _currentPatientId)
                                    .where('doctorId', isEqualTo: docId)
                                    .where('status', isEqualTo: 'Confirmed')
                                    .snapshots(),
                                builder: (context, appointmentSnapshot) {
                                  bool hasActiveAppointment = appointmentSnapshot.hasData &&
                                      appointmentSnapshot.data!.docs.isNotEmpty;

                                  return IconButton(
                                    onPressed: () {
                                      if (hasActiveAppointment) {
                                        _navigateToChat(docId, docName);
                                      } else {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                            title: const Row(
                                              children: [
                                                Icon(Icons.lock_outline_rounded, color: Color(0xFF008080)),
                                                SizedBox(width: 10),
                                                Text('Chat Locked', style: TextStyle(fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                            content: Text(
                                              'To clear your diagnostic inquiry with $docName, you must secure an active slot reservation first.',
                                              style: const TextStyle(color: Colors.black87),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF008080),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                ),
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  _openBookingBottomSheet(docId, docName, specialty, days, slots);
                                                },
                                                child: const Text('Book Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                    },
                                    style: IconButton.styleFrom(
                                      backgroundColor: hasActiveAppointment
                                          ? const Color(0xFF008080).withValues(alpha: 0.1)
                                          : Colors.grey.shade100,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      padding: const EdgeInsets.all(12),
                                    ),
                                    icon: Icon(
                                      hasActiveAppointment ? Icons.chat_bubble_rounded : Icons.lock_rounded,
                                      color: hasActiveAppointment ? const Color(0xFF008080) : Colors.grey.shade400,
                                      size: 20,
                                    ),
                                  );
                                },
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ================= INTERACTIVE BOOKING BOTTOM SHEET =================
  void _openBookingBottomSheet(String docId, String name, String specialty, List<String> days, List<String> slots) {
    String selectedDay = days.isNotEmpty ? days[0] : 'Monday';
    String selectedSlot = slots.isNotEmpty ? slots[0] : '10:00 AM';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Book Appointment with $name', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0A1931))),
                  Text(specialty, style: const TextStyle(color: Color(0xFF008080), fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 20),

                  const Text('Select Working Day', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: (days.isEmpty ? ['Mon', 'Wed', 'Fri'] : days).map((d) {
                      bool isSelected = selectedDay == d;
                      return ChoiceChip(
                        label: Text(d),
                        selected: isSelected,
                        selectedColor: const Color(0xFF008080),
                        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                        onSelected: (val) => setModalState(() => selectedDay = d),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  const Text('Select Time Window', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: slots.map((s) {
                      bool isSelected = selectedSlot == s;
                      return ChoiceChip(
                        label: Text(s),
                        selected: isSelected,
                        selectedColor: const Color(0xFF008080),
                        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                        onSelected: (val) => setModalState(() => selectedSlot = s),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF008080), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () async {
                        // Creates appointment record confirming unlock requirements instantly
                        await FirebaseFirestore.instance.collection('appointments').add({
                          'patientId': _currentPatientId,
                          'doctorId': docId,
                          'doctorName': name,
                          'specialty': specialty,
                          'date': selectedDay,
                          'time': selectedSlot,
                          'status': 'Confirmed',
                          'timestamp': FieldValue.serverTimestamp(),
                        });
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Appointment Reserved for $selectedDay! Chat Unlocked.'), backgroundColor: const Color(0xFF008080)),
                          );
                        }
                      },
                      child: const Text('Confirm Appointment Booking', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ================= TAB 2: LIVE CALENDAR SCHEDULE MANAGEMENT =================
  Widget _buildAppointmentsCalendarTab() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Consultation Schedules', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0A1931))),
          const SizedBox(height: 4),
          const Text('Real-time tracking of your verified doctor visits.', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 16),

          SizedBox(
            height: 70,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _buildCalendarStripDays(),
            ),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('appointments')
                  .where('patientId', isEqualTo: _currentPatientId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                if (snapshot.data!.docs.isEmpty) {
                  return _buildEmptyStatePlaceholder(Icons.calendar_today_outlined, 'No active consultation bookings scheduled.');
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var appt = snapshot.data!.docs[index].data() as Map<String, dynamic>;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFF008080).withValues(alpha: 0.1),
                            child: const Icon(Icons.event_available_rounded, color: Color(0xFF008080)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(appt['doctorName'] ?? 'Doctor Specialist', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                Text(appt['specialty'] ?? 'Specialty', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                const SizedBox(height: 4),
                                Text('${appt['date']} at ${appt['time']}', style: const TextStyle(color: Color(0xFF008080), fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                            child: Text(appt['status'] ?? 'Confirmed', style: TextStyle(color: Colors.green.shade700, fontSize: 11, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
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

  // ================= CHAT ROUTE DISPATCH NAVIGATION PIPELINE =================
  void _navigateToChat(String docId, String docName) async {
    String chatRoomId = '${_currentPatientId}_$docId';
    await FirebaseFirestore.instance.collection('chats').doc(chatRoomId).set({
      'participants': [_currentPatientId, docId],
      'lastMessage': 'Conversation initiated...',
      'lastMessageTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatRoomId: chatRoomId,
            currentUserId: _currentPatientId,
            receiverId: docId,
            receiverName: docName,
          ),
        ),
      );
    }
  }

  List<Widget> _buildCalendarStripDays() {
    List<Map<String, String>> days = [
      {'day': 'Mon', 'num': '15'}, {'day': 'Tue', 'num': '16'},
      {'day': 'Wed', 'num': '17'}, {'day': 'Thu', 'num': '18'},
      {'day': 'Fri', 'num': '19'}, {'day': 'Sat', 'num': '20'}
    ];
    return days.map((d) {
      bool active = d['num'] == '15';
      return Container(
        width: 55,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF008080) : Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(d['day']!, style: TextStyle(fontSize: 11, color: active ? Colors.white70 : Colors.grey)),
            Text(d['num']!, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: active ? Colors.white : const Color(0xFF0A1931))),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildPharmacyTab() => const Center(child: Text('E-Pharmacy Prescription Interface.'));
  Widget _buildProfileTab() => const Center(child: Text('Patient Command Center Settings.'));

  Widget _buildEmptyStatePlaceholder(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}