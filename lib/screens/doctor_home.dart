import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  int _currentNavIndex = 0;
  final String _currentDoctorId = 'doc_001';
  final String _currentDoctorName = 'Dr. Jane Doe';

  @override
  Widget build(BuildContext context) {
    final List<Widget> doctorViews = [
      _buildDoctorDashboardTab(),
      _buildDoctorInboxTab(),
      _buildDoctorProfileTab(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFA),
      body: SafeArea(child: doctorViews[_currentNavIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        selectedItemColor: const Color(0xFF008080),
        unselectedItemColor: Colors.grey.shade400,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentNavIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.analytics_rounded), label: 'Appointments'),
          BottomNavigationBarItem(icon: Icon(Icons.question_answer_rounded), label: 'Inbox Board'),
          BottomNavigationBarItem(icon: Icon(Icons.badge_rounded), label: 'My Panel'),
        ],
      ),
    );
  }

  Widget _buildDoctorDashboardTab() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_currentDoctorName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('appointments')
                  .where('doctorId', isEqualTo: _currentDoctorId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var appt = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text('Patient: ${appt['patientId']}'),
                      subtitle: Text('${appt['date']} • ${appt['time']}'),
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

  Widget _buildDoctorInboxTab() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: _currentDoctorId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var chat = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return ListTile(
                title: const Text('Patient Session'),
                subtitle: Text(chat['lastMessage'] ?? ''),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        chatRoomId: snapshot.data!.docs[index].id,
                        currentUserId: _currentDoctorId,
                        receiverId: 'patient123',
                        receiverName: 'Patient Profile',
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDoctorProfileTab() {
    return Center(
      child: ElevatedButton(
        onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
        child: const Text('Log Out'),
      ),
    );
  }
}