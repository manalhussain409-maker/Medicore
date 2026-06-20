import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../models/appointment_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/appointment_service.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../services/pharmacy_service.dart';
import '../services/doctor_service.dart';
import '../services/image_service.dart';
import '../components/cards.dart';
import '../components/loading.dart';
import 'chat_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  final String? loggedInDoctorId;
  final String? loggedInDoctorName;
  final String userRole;

  const AdminHomeScreen({
    super.key,
    this.loggedInDoctorId,
    this.loggedInDoctorName,
    this.userRole = 'Admin',
  });

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentNavIndex = 0;
  late String _currentUserId;
  late String _currentUserName;
  late bool _isAdmin;

  final AuthService _authService = AuthService();
  final AppointmentService _appointmentService = AppointmentService();
  final ChatService _chatService = ChatService();
  final UserService _userService = UserService();
  final PharmacyService _pharmacyService = PharmacyService();
  final DoctorService _doctorService = DoctorService();
  final ImageService _imageService = ImageService();
  bool _isUploadingImage = false;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _expController = TextEditingController();
  final _feeController = TextEditingController();
  final _docImageUrlController = TextEditingController();
  Uint8List? _selectedDoctorImage;
  bool _isUploadingDoctorImage = false;
  bool _isAddingDoctor = false;

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

  final List<String> _allDays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];
  final Set<String> _selectedDays = {};
  final Map<String, List<TextEditingController>> _slotControllers = {};

  final _pharmaFormKey = GlobalKey<FormState>();
  final _medNameController = TextEditingController();
  final _medStockController = TextEditingController();
  final _medPriceController = TextEditingController();

  final Map<String, String> _patientNameCache = {};

  @override
  void initState() {
    super.initState();
    _currentUserId =
        widget.loggedInDoctorId ?? FirebaseAuth.instance.currentUser?.uid ?? '';
    _currentUserName = widget.loggedInDoctorName ?? 'User';
    _isAdmin = widget.userRole == 'Admin';
    _userService.setUserOnlineStatus(_currentUserId, true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _expController.dispose();
    _feeController.dispose();
    _docImageUrlController.dispose();
    _medNameController.dispose();
    _medStockController.dispose();
    _medPriceController.dispose();
    for (final controllers in _slotControllers.values) {
      for (final c in controllers) {
        c.dispose();
      }
    }
    super.dispose();
  }

  List<Widget> get _tabs {
    if (_isAdmin) {
      return [
        _buildAddDoctorTab(),
        _buildPharmacyTab(),
        _buildProfileTab(),
      ];
    }
    return [
      _buildAppointmentsTab(),
      _buildInboxTab(),
      _buildProfileTab(),
    ];
  }

  List<BottomNavigationBarItem> get _navItems {
    if (_isAdmin) {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.person_add_rounded),
          label: 'Doctors',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_pharmacy_rounded),
          label: 'Pharmacy',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.badge_rounded),
          label: 'Profile',
        ),
      ];
    }
    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.calendar_month_rounded),
        label: 'Appointments',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.chat_bubble_rounded),
        label: 'Chats',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.badge_rounded),
        label: 'Profile',
      ),
    ];
  }

  Map<String, List<String>> _buildAvailability() {
    final Map<String, List<String>> availability = {};
    for (final day in _selectedDays) {
      final controllers = _slotControllers[day];
      if (controllers != null) {
        final slots = controllers
            .map((c) => c.text.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        if (slots.isNotEmpty) {
          availability[day] = slots;
        }
      }
    }
    return availability;
  }

  Future<void> _addNewDoctor() async {
    if (_isAddingDoctor) return;

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_selectedSpecialty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a specialty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isAddingDoctor = true);

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    String? imageUrl = _docImageUrlController.text.trim().isEmpty
        ? null
        : _docImageUrlController.text.trim();

    if (_selectedDoctorImage != null) {
      try {
        final pendingUid = 'pending_${email.replaceAll(RegExp(r'[@.]'), '_')}';
        imageUrl = await _imageService
            .uploadProfileImageBytes(pendingUid, _selectedDoctorImage!)
            .timeout(const Duration(seconds: 10));
      } catch (e) {
        imageUrl = null;
      }
    }

    final availability = _buildAvailability();

    try {
      await _doctorService.createPendingDoctor(
        name: name,
        email: email,
        specialty: _selectedSpecialty!,
        experience: _expController.text.trim(),
        fee: _feeController.text.trim(),
        imageUrl: imageUrl,
        availability: availability.isNotEmpty ? availability : null,
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      if (mounted) {
        setState(() => _isAddingDoctor = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding doctor: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    _nameController.clear();
    _emailController.clear();
    _expController.clear();
    _feeController.clear();
    _docImageUrlController.clear();
    setState(() {
      _selectedSpecialty = null;
      _selectedDays.clear();
      _slotControllers.clear();
      _selectedDoctorImage = null;
      _isAddingDoctor = false;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Dr. $name added. They can register with: $email'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showDoctorImagePickerOptions() {
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
                'Select Doctor Photo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF00796B)),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickDoctorImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.photo_library, color: Color(0xFF00796B)),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickDoctorImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDoctorImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedDoctorImage = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _addMedicine() async {
    if (_pharmaFormKey.currentState == null ||
        !_pharmaFormKey.currentState!.validate()) {
      return;
    }

    try {
      await _pharmacyService.addMedicine(
        name: _medNameController.text.trim(),
        stock: int.tryParse(_medStockController.text.trim()) ?? 0,
        price: double.tryParse(_medPriceController.text.trim()) ?? 0,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding medicine: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _medNameController.clear();
    _medStockController.clear();
    _medPriceController.clear();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Medicine added to inventory'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<String> _getPatientName(String patientId) async {
    if (_patientNameCache.containsKey(patientId)) {
      return _patientNameCache[patientId]!;
    }
    final user = await _userService.getUserById(patientId);
    final name = user?.name ?? 'Patient';
    _patientNameCache[patientId] = name;
    return name;
  }

  Future<void> _logout() async {
    await _userService.setUserOnlineStatus(_currentUserId, false);
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
              ? 'Admin Dashboard'
              : _currentNavIndex == 1
                  ? 'Pharmacy'
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
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentNavIndex,
          selectedItemColor: const Color(0xFF00796B),
          unselectedItemColor: Colors.grey.shade400,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          onTap: (index) => setState(() => _currentNavIndex = index),
          items: _navItems,
        ),
      ),
    );
  }

  Widget _buildAppointmentsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Appointments',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A1931),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage patient bookings',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 20),
          StreamBuilder<List<AppointmentModel>>(
            stream: _appointmentService.getDoctorAppointments(_currentUserId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Column(
                  children:
                      List.generate(3, (_) => const AppointmentCardShimmer()),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _emptyState(
                  Icons.calendar_today_outlined,
                  'No appointments yet',
                  'Patient bookings will appear here',
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final appt = snapshot.data![index];
                  return AppointmentCard(
                    appointment: appt,
                    onDetails: () => _showAppointmentActions(appt),
                    onCancel:
                        appt.status == 'Pending' || appt.status == 'Confirmed'
                            ? () => _updateStatus(appt.id, 'Cancelled')
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
              const Color(0xFF00796B),
              () {
                Navigator.pop(ctx);
                _showPrescriptionDialog(appt.id);
              },
            ),
            _actionTile(
              'Message Patient',
              Icons.chat_outlined,
              const Color(0xFF00796B),
              () async {
                Navigator.pop(ctx);
                final chatRoomId = await _chatService.createOrGetChatRoom(
                  participant1Id: _currentUserId,
                  participant2Id: appt.patientId,
                  participant1Name: _currentUserName,
                  participant2Name: appt.patientName,
                );
                if (!mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      chatRoomId: chatRoomId,
                      currentUserId: _currentUserId,
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
              backgroundColor: const Color(0xFF00796B),
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildAddDoctorTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, $_currentUserName',
              style: const TextStyle(
                color: Color(0xFF00796B),
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Register New Doctor',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A1931),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: _inputDeco('Doctor Name', Icons.person),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDeco('Login Email', Icons.email_outlined),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedSpecialty,
              hint: const Text('Select Specialty'),
              decoration: _inputDeco('Specialty', Icons.medical_services),
              items: _specialtiesList
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedSpecialty = v),
              validator: (v) => v == null ? 'Select specialty' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _expController,
              decoration: _inputDeco('Years of Experience', Icons.timeline),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _feeController,
              keyboardType: TextInputType.number,
              decoration:
                  _inputDeco('Consultation Fee (Rs.)', Icons.attach_money),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: _showDoctorImagePickerOptions,
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2F1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF00796B),
                          width: 2,
                        ),
                      ),
                      child: _selectedDoctorImage != null
                          ? ClipOval(
                              child: Image.memory(
                                _selectedDoctorImage!,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            )
                          : _isUploadingDoctorImage
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF00796B),
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.camera_alt,
                                      color: Color(0xFF00796B),
                                      size: 36,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Add Photo',
                                      style: TextStyle(
                                        color: Color(0xFF00796B),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                    ),
                    if (_selectedDoctorImage != null)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF00796B),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Tap to add doctor photo',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2F1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.schedule, color: Color(0xFF00796B), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Availability Schedule',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0A1931),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select days and add time slots for this doctor',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _allDays.map((day) {
                      final selected = _selectedDays.contains(day);
                      return FilterChip(
                        label: Text(
                          day.substring(0, 3),
                          style: TextStyle(
                            fontSize: 12,
                            color: selected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        selected: selected,
                        selectedColor: const Color(0xFF00796B),
                        checkmarkColor: Colors.white,
                        onSelected: (isSelected) {
                          setState(() {
                            if (isSelected) {
                              _selectedDays.add(day);
                              _slotControllers[day] = [
                                TextEditingController(text: '09:00 AM'),
                              ];
                            } else {
                              _selectedDays.remove(day);
                              _slotControllers.remove(day);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  if (_selectedDays.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ..._selectedDays.map((day) => _buildDaySlots(day)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isAddingDoctor ? null : _addNewDoctor,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00796B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isAddingDoctor
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Add Doctor',
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
      ),
    );
  }

  Widget _buildDaySlots(String day) {
    final controllers = _slotControllers[day] ?? [];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                day,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF00796B),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  setState(() {
                    controllers.add(TextEditingController(text: '09:00 AM'));
                  });
                },
                child: const Row(
                  children: [
                    Icon(Icons.add_circle, color: Color(0xFF00796B), size: 18),
                    SizedBox(width: 4),
                    Text(
                      'Add Slot',
                      style: TextStyle(
                        color: Color(0xFF00796B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...List.generate(controllers.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controllers[i],
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'e.g. 09:00 AM',
                        hintStyle: TextStyle(
                            color: Colors.grey.shade400, fontSize: 12),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  if (controllers.length > 1)
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline,
                          color: Colors.redAccent, size: 20),
                      onPressed: () {
                        setState(() {
                          controllers[i].dispose();
                          controllers.removeAt(i);
                        });
                      },
                    ),
                ],
              ),
            );
          }),
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
          Text(
            _isAdmin ? 'All Conversations' : 'Patient Messages',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A1931),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder(
              stream: _chatService.getUserChatRooms(_currentUserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00796B)),
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
                      (id) => id != _currentUserId,
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
                                  color: Color(0xFF00796B),
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
                                    currentUserId: _currentUserId,
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

  Widget _buildPharmacyTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pharmacy Inventory',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A1931),
            ),
          ),
          const SizedBox(height: 16),
          Form(
            key: _pharmaFormKey,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _medNameController,
                    decoration: const InputDecoration(
                      labelText: 'Medicine',
                      hintText: 'Panadol',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _medStockController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Stock',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _medPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Price',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle,
                      color: Color(0xFF00796B), size: 36),
                  onPressed: _addMedicine,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder(
              stream: _pharmacyService.getAllMedicines(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00796B)),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _emptyState(
                    Icons.medication_outlined,
                    'Inventory empty',
                    'Add medicines using the form above',
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final med = snapshot.data![index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.medication_rounded,
                          color: Color(0xFF00796B),
                        ),
                        title: Text(
                          med.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          med.inStock
                              ? 'In stock: ${med.stock}'
                              : 'Out of stock',
                          style: TextStyle(
                            color: med.inStock ? Colors.green : Colors.red,
                          ),
                        ),
                        trailing: Text(
                          'Rs. ${med.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00796B),
                          ),
                        ),
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

  Widget _buildProfileTab() {
    return FutureBuilder<UserModel?>(
      future: _userService.getUserById(_currentUserId),
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
                          _currentUserName,
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
                _currentUserName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A1931),
                ),
              ),
              Text(
                user?.email ?? _currentUserId,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00796B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isAdmin ? 'Administrator' : 'Doctor',
                  style: const TextStyle(
                    color: Color(0xFF00796B),
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
          _profileInfoTile(Icons.phone, 'Phone', user?.phoneNumber ?? 'Not set'),
          _profileInfoTile(Icons.location_city, 'City', user?.city ?? 'Not set'),
          _profileInfoTile(Icons.home_outlined, 'Address', user?.address ?? 'Not set'),
          _profileInfoTile(
            Icons.person_outline,
            'Gender',
            user?.gender ?? 'Not set',
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showEditProfileDialog(user),
              icon: const Icon(Icons.edit, color: Color(0xFF00796B)),
              label: const Text(
                'Edit Profile',
                style: TextStyle(
                  color: Color(0xFF00796B),
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF00796B)),
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
                  userId: _currentUserId,
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
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00796B)),
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
          Icon(icon, color: const Color(0xFF00796B), size: 20),
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
      final url = await _imageService.pickAndUploadImage(_currentUserId, source);
      if (url != null) {
        await _userService.updateUserProfile(
          userId: _currentUserId,
          profileImageUrl: url,
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
      name.isNotEmpty ? name[0].toUpperCase() : 'U',
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

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF00796B)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
