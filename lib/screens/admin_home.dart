import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  // Pass the logged-in doctor's unique Firestore document ID or Auth UID dynamically when navigating to this screen
  final String? loggedInDoctorId;
  final String? loggedInDoctorName;

  const AdminHomeScreen({
    super.key,
    this.loggedInDoctorId, // e.g., Passed from Auth screen selection or successful login
    this.loggedInDoctorName,
  });

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentNavIndex = 0;

  // DYNAMIC FALLBACKS: Uses the authenticated doctor's credentials if available; defaults to a testing profile otherwise
  late String _currentDoctorId;
  late String _currentDoctorName;

  // Form Field Controllers (Add Doctor)
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _expController = TextEditingController();
  final _feeController = TextEditingController();
  final _docImageUrlController = TextEditingController();

  // Specialty Dropdown States
  String? _selectedSpecialty;
  final List<String> _specialtiesList = [
    'Cardiologist',
    'Dermatologist',
    'Neurologist',
    'Pediatrician',
    'General Physician',
    'Orthopedic',
    'Gynecologist',
  ];

  // Pharmacy Field Controllers
  final _pharmaFormKey = GlobalKey<FormState>();
  final _medNameController = TextEditingController();
  final _medStockController = TextEditingController();
  final _medPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Dynamically assign identity based on who logged in
    _currentDoctorId = widget.loggedInDoctorId ?? 'doc_001';
    _currentDoctorName = widget.loggedInDoctorName ?? 'Admin Panel';
  }

  void _addNewDoctorToDatabase() async {
    if (_formKey.currentState!.validate() && _selectedSpecialty != null) {
      await FirebaseFirestore.instance.collection('doctors').add({
        'name': _nameController.text.trim(),
        'specialty': _selectedSpecialty,
        'experience': _expController.text.trim(),
        'fee': _feeController.text.trim(),
        'imageUrl': _docImageUrlController.text.trim().isEmpty
            ? 'https://cdn-icons-png.flaticon.com/512/387/387561.png'
            : _docImageUrlController.text.trim(),
        'availableDays': ['Mon', 'Wed', 'Fri'],
        'availableSlots': ['09:00 AM', '11:00 AM', '03:00 PM'],
      });

      _nameController.clear();
      _expController.clear();
      _feeController.clear();
      _docImageUrlController.clear();

      setState(() {
        _selectedSpecialty = null;
      });

      if (!mounted) return; // Guarding BuildContext across async gaps
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Practitioner profile added successfully!')),
      );
    }
  }

  void _addMedicineToInventory() async {
    if (_pharmaFormKey.currentState!.validate()) {
      await FirebaseFirestore.instance.collection('pharmacy').add({
        'name': _medNameController.text.trim(),
        'stock': int.tryParse(_medStockController.text.trim()) ?? 0,
        'price': double.tryParse(_medPriceController.text.trim()) ?? 0.0,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      _medNameController.clear();
      _medStockController.clear();
      _medPriceController.clear();

      if (!mounted) return; // Guarding BuildContext across async gaps
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inventory stock added successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> adminTabs = [
      _buildAddDoctorTab(),
      _buildDoctorInboxTab(),
      _buildPharmacyTab(),
      _buildDoctorProfileTab(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFA),
      body: SafeArea(child: adminTabs[_currentNavIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        selectedItemColor: const Color(0xFF00796B),
        unselectedItemColor: Colors.grey.shade400,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentNavIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person_add_rounded), label: 'Add Doctor'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: 'Patient Chats'),
          BottomNavigationBarItem(icon: Icon(Icons.local_pharmacy_rounded), label: 'Pharmacy'),
          BottomNavigationBarItem(icon: Icon(Icons.badge_rounded), label: 'Profile'),
        ],
      ),
    );
  }

  // ================= TAB 1: ADD DOCTOR =================
  Widget _buildAddDoctorTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Admin Dashboard', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
            Text('Welcome, $_currentDoctorName', style: const TextStyle(fontSize: 14, color: Color(0xFF00796B), fontWeight: FontWeight.bold)),
            const Text('Register New Practitioner', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0A1931))),
            const SizedBox(height: 24),

            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Doctor Name', prefixIcon: const Icon(Icons.person), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              validator: (val) => val!.isEmpty ? 'Please enter a name' : null,
            ),
            const SizedBox(height: 16),

            // Dropdown Menu Field for Specialties
            DropdownButtonFormField<String>(
              value: _selectedSpecialty,
              hint: const Text('Select Specialty'),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.medical_services, color: Color(0xFF00796B)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: _specialtiesList.map((String specialty) {
                return DropdownMenuItem<String>(
                  value: specialty,
                  child: Text(specialty),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedSpecialty = newValue;
                });
              },
              validator: (val) => val == null ? 'Please select a specialty' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _expController,
              decoration: InputDecoration(labelText: 'Years of Experience', prefixIcon: const Icon(Icons.timeline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              validator: (val) => val!.isEmpty ? 'Please enter experience value' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _feeController,
              decoration: InputDecoration(labelText: 'Consultation Fee (Rs.)', prefixIcon: const Icon(Icons.attach_money), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              validator: (val) => val!.isEmpty ? 'Please input entry fee' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _docImageUrlController,
              decoration: InputDecoration(labelText: 'Doctor Profile Image URL', hintText: 'Paste web image link address here', prefixIcon: const Icon(Icons.link_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _addNewDoctorToDatabase,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00796B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Save Practitioner to System', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= TAB 2: ACTIVE PATIENT CHATS (FILTERED BY LOGGED-IN DOCTOR) =================
  Widget _buildDoctorInboxTab() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$_currentDoctorName\'s Inbox', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0A1931))),
          const Text('Secure channels showing only chats assigned to you.', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // This is where the magic happens: filtering chats where 'participants' contains this specific logged-in doctor's unique ID
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .where('participants', arrayContains: _currentDoctorId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                if (snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No active conversation lines found for your profile.', style: TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var chatRoom = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    String chatRoomId = snapshot.data!.docs[index].id;
                    String lastMsg = chatRoom['lastMessage'] ?? 'No inquiries sent yet...';

                    List participants = chatRoom['participants'] ?? [];
                    // Using orElse closure mapping strategy
                    String targetedPatientId = participants.firstWhere(
                            (id) => id != _currentDoctorId,
                        orElse: () => 'patient123'
                    );

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: Color(0xFFE0F2F1), child: Icon(Icons.person, color: Color(0xFF00796B))),
                        title: Text('Patient ID: $targetedPatientId'),
                        subtitle: Text(lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                chatRoomId: chatRoomId,
                                currentUserId: _currentDoctorId,
                                receiverId: targetedPatientId,
                                receiverName: 'Patient ($targetedPatientId)',
                              ),
                            ),
                          );
                        },
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

  // ================= TAB 3: PHARMACY TRACKER =================
  Widget _buildPharmacyTab() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pharmacy Operations', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0A1931))),
          const Text('Add items and check live stock levels.', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 16),

          Form(
            key: _pharmaFormKey,
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _medNameController,
                    decoration: const InputDecoration(labelText: 'Medicine', hintText: 'Panadol'),
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _medStockController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Stock Qty', hintText: '100'),
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _medPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Price (Rs.)', hintText: '20'),
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Color(0xFF00796B), size: 36),
                  onPressed: _addMedicineToInventory,
                )
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Current Available Inventory stock', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('pharmacy').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                if (snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Inventory layout is currently empty.', style: TextStyle(color: Colors.grey)));
                }
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var med = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    return Card(
                        child: ListTile(
                          leading: const Icon(Icons.medication_rounded, color: Color(0xFF00796B)),
                          title: Text(med['name'] ?? 'Unknown Item', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('In-Stock Units: ${med['stock']}'),
                          trailing: Text('Rs. ${med['price']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
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

  // ================= TAB 4: PROFILE INFO =================
  Widget _buildDoctorProfileTab() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const SizedBox(height: 30),
          const CircleAvatar(radius: 46, backgroundColor: Color(0xFF00796B), child: Icon(Icons.admin_panel_settings, size: 44, color: Colors.white)),
          const SizedBox(height: 16),
          Text(_currentDoctorName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0A1931))),
          const Text('System Administrator Mode', style: TextStyle(color: Color(0xFF00796B), fontWeight: FontWeight.w600)),
          const SizedBox(height: 40),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Log Out System Instance', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onTap: () => Navigator.pushReplacementNamed(context, '/login'),
          )
        ],
      ),
    );
  }
}