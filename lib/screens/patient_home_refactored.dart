import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/doctor_model.dart';
import '../models/appointment_model.dart';
import '../models/user_model.dart';
import '../models/medicine_model.dart';
import '../services/doctor_service.dart';
import '../services/appointment_service.dart';
import '../services/user_service.dart';
import '../services/chat_service.dart';
import '../services/pharmacy_service.dart';
import '../services/auth_service.dart';
import '../services/image_service.dart';
import '../services/cart_service.dart';
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
  final PharmacyService _pharmacyService = PharmacyService();
  final AuthService _authService = AuthService();
  final ImageService _imageService = ImageService();
  final CartService _cartService = CartService();
  bool _isUploadingImage = false;

  String? _currentUserId;
  UserModel? _currentUser;
  String _searchQuery = '';
  String _pharmacySearch = '';

  final _searchController = TextEditingController();
  final _pharmacySearchController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _loadCurrentUser();
    _cartService.loadCart();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pharmacySearchController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    if (_currentUserId == null) return;
    await _userService.setUserOnlineStatus(_currentUserId!, true);
    final user = await _userService.getUserById(_currentUserId!);
    if (mounted) {
      setState(() {
        _currentUser = user;
        _phoneController.text = user?.phoneNumber ?? '';
        _cityController.text = user?.city ?? '';
      });
    }
  }

  Future<void> _logout() async {
    if (_currentUserId != null) {
      await _userService.setUserOnlineStatus(_currentUserId!, false);
    }
    await _authService.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  List<DoctorModel> _filterDoctors(List<DoctorModel> doctors) {
    if (_searchQuery.trim().isEmpty) return doctors;
    final q = _searchQuery.toLowerCase();
    return doctors
        .where(
          (d) =>
              d.name.toLowerCase().contains(q) ||
              d.specialty.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final views = [
      _buildHomeTab(),
      _buildAppointmentsTab(),
      _buildPharmacyTab(),
      _buildProfileTab(),
    ];

    final appBarTitles = ['Medicore', 'Appointments', 'Pharmacy', 'Profile'];

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00796B),
        title: Text(
          appBarTitles[_currentNavIndex],
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
      body: SafeArea(child: views[_currentNavIndex]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentNavIndex,
          selectedItemColor: const Color(0xFF00796B),
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
              icon: Icon(Icons.local_pharmacy_rounded),
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

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildSearchBar(),
          const SizedBox(height: 20),
          _buildQuickActions(),
          const SizedBox(height: 24),
          _buildUpcomingAppointments(),
          const SizedBox(height: 24),
          _buildDoctorsSection(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final name = _currentUser?.name ?? 'Patient';
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, $name 👋',
                style: TextStyle(
                  color: Colors.grey.shade600,
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
        ),
        GestureDetector(
          onTap: () => setState(() => _currentNavIndex = 3),
          child: CircleAvatar(
            radius: 26,
            backgroundColor: const Color(0xFF00796B).withOpacity(0.1),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'P',
              style: const TextStyle(
                color: Color(0xFF00796B),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Search doctors or specialties...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon:
              const Icon(Icons.search_rounded, color: Color(0xFF00796B)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        _quickAction(Icons.calendar_month_rounded, 'Book', () {
          setState(() => _currentNavIndex = 0);
        }),
        _quickAction(Icons.local_pharmacy_rounded, 'Pharmacy', () {
          setState(() => _currentNavIndex = 2);
        }),
        _quickAction(Icons.chat_bubble_rounded, 'Chats', () {
          setState(() => _currentNavIndex = 1);
        }),
      ],
    );
  }

  Widget _quickAction(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFF00796B), size: 28),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0A1931),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingAppointments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Upcoming',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A1931),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _currentNavIndex = 1),
              child: const Text('See all'),
            ),
          ],
        ),
        StreamBuilder<List<AppointmentModel>>(
          stream: _currentUserId != null
              ? _appointmentService.getUpcomingAppointments(_currentUserId!)
              : const Stream.empty(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AppointmentCardShimmer();
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _emptyCard(
                Icons.calendar_today_outlined,
                'No upcoming appointments',
                'Book a doctor to get started',
              );
            }
            final appt = snapshot.data!.first;
            return AppointmentCard(
              appointment: appt,
              onDetails: () => _showAppointmentDetails(appt),
              onCancel: () => _cancelAppointment(appt.id),
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
                children: List.generate(3, (_) => const DoctorCardShimmer()),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildFallbackDoctors();
            }

            final doctors = _filterDoctors(snapshot.data!);
            if (doctors.isEmpty) {
              return _emptyCard(
                Icons.search_off_rounded,
                'No results for "$_searchQuery"',
                'Try a different search term',
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: doctors.length,
              itemBuilder: (context, index) {
                final doctor = doctors[index];
                return DoctorCard(
                  doctor: doctor,
                  onBook: () => _openBookingSheet(doctor),
                  onChat: () => _navigateToChat(doctor),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildAppointmentsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
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
          const SizedBox(height: 20),
          StreamBuilder<List<AppointmentModel>>(
            stream: _currentUserId != null
                ? _appointmentService.getPatientAppointments(_currentUserId!)
                : const Stream.empty(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Column(
                  children:
                      List.generate(3, (_) => const AppointmentCardShimmer()),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _emptyCard(
                  Icons.calendar_today_outlined,
                  'No appointments yet',
                  'Book your first appointment from Home',
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
                    onDetails: () => _showAppointmentDetails(appt),
                    onCancel:
                        appt.status != 'Completed' && appt.status != 'Cancelled'
                            ? () => _cancelAppointment(appt.id)
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

  Widget _buildPharmacyTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pharmacy',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0A1931),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Browse and order medicines',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  Stack(
                    children: [
                      IconButton(
                        onPressed: _showCartSheet,
                        icon: const Icon(Icons.shopping_cart_rounded,
                            color: Color(0xFF00796B)),
                      ),
                      if (_cartService.itemCount > 0)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${_cartService.itemCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pharmacySearchController,
                onChanged: (v) => setState(() => _pharmacySearch = v),
                decoration: InputDecoration(
                  hintText: 'Search medicines...',
                  prefixIcon:
                      const Icon(Icons.search, color: Color(0xFF00796B)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<MedicineModel>>(
            stream: _pharmacyService.searchMedicines(_pharmacySearch),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF00796B)),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.medication_outlined,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        'No medicines available',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final med = snapshot.data![index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2F1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.medication_liquid,
                          color: Color(0xFF00796B),
                        ),
                      ),
                      title: Text(
                        med.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            med.inStock
                                ? '${med.stock} units available'
                                : 'Out of stock',
                            style: TextStyle(
                              color:
                                  med.inStock ? Colors.green : Colors.red,
                              fontSize: 12,
                            ),
                          ),
                          if (med.category != null)
                            Text(
                              med.category!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                        ],
                      ),
                      trailing: med.inStock
                          ? GestureDetector(
                              onTap: () => _addToCart(med),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00796B),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add_shopping_cart,
                                        color: Colors.white, size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      'Add',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Text(
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
    );
  }

  void _addToCart(MedicineModel medicine) async {
    await _cartService.addItem(medicine);
    setState(() {});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${medicine.name} added to cart'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
        action: SnackBarAction(
          label: 'View Cart',
          textColor: Colors.white,
          onPressed: _showCartSheet,
        ),
      ),
    );
  }

  void _showCartSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'My Cart (${_cartService.itemCount})',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0A1931),
                            ),
                          ),
                          if (_cartService.itemCount > 0)
                            TextButton(
                              onPressed: () async {
                                await _cartService.clearCart();
                                setModalState(() {});
                                setState(() {});
                              },
                              child: const Text('Clear All',
                                  style: TextStyle(color: Colors.redAccent)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_cartService.itemCount == 0)
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shopping_cart_outlined,
                                    size: 64,
                                    color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                Text(
                                  'Your cart is empty',
                                  style: TextStyle(
                                      color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        )
                      else ...[
                        Expanded(
                          child: ListView.builder(
                            controller: scrollController,
                            itemCount: _cartService.items.length,
                            itemBuilder: (context, index) {
                              final item = _cartService.items[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7FAFA),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.medicine.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'Rs. ${item.medicine.price.toStringAsFixed(0)} each',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color:
                                                  Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                              Icons.remove_circle_outline,
                                              size: 22),
                                          onPressed: () async {
                                            await _cartService
                                                .updateQuantity(
                                              item.medicine.id,
                                              item.quantity - 1,
                                            );
                                            setModalState(() {});
                                            setState(() {});
                                          },
                                        ),
                                        Text(
                                          '${item.quantity}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.add_circle_outline,
                                              size: 22,
                                              color:
                                                  Color(0xFF00796B)),
                                          onPressed: () async {
                                            await _cartService
                                                .updateQuantity(
                                              item.medicine.id,
                                              item.quantity + 1,
                                            );
                                            setModalState(() {});
                                            setState(() {});
                                          },
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'Rs. ${item.totalPrice.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF00796B),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Rs. ${_cartService.totalPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00796B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () => _checkoutCart(setModalState),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00796B),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Place Order',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _checkoutCart(StateSetter setModalState) async {
    if (_currentUserId == null) return;
    try {
      final orderId = await _cartService.checkout(
        _currentUserId!,
        _currentUser?.name ?? 'Patient',
      );
      if (!mounted) return;
      Navigator.pop(context);
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order placed! Order ID: $orderId'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildProfileTab() {
    return FutureBuilder<UserModel?>(
      future: _userService.getUserById(_currentUserId!),
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
                          user?.name ?? 'P',
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
                user?.name ?? 'Patient',
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
                  color: const Color(0xFF008080).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Patient',
                  style: TextStyle(
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
    if (_currentUserId == null) return;
    setState(() => _isUploadingImage = true);
    try {
      final url = await _imageService.pickAndUploadImage(_currentUserId!, source);
      if (url != null) {
        await _userService.updateUserProfile(
          userId: _currentUserId!,
          profileImageUrl: url,
        );
        await _loadCurrentUser();
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
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cityCtrl,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedGender,
                  hint: const Text('Select Gender'),
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    border: OutlineInputBorder(),
                    isDense: true,
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
                  userId: _currentUserId!,
                  name: nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : null,
                  phoneNumber: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
                  city: cityCtrl.text.trim().isNotEmpty ? cityCtrl.text.trim() : null,
                  address: addressCtrl.text.trim().isNotEmpty ? addressCtrl.text.trim() : null,
                  gender: selectedGender,
                );
                Navigator.pop(ctx);
                await _loadCurrentUser();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile updated'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00796B),
              ),
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
      name.isNotEmpty ? name[0].toUpperCase() : 'P',
      style: const TextStyle(
        fontSize: 36,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _emptyCard(IconData icon, String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 44, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text(title, style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  Widget _buildFallbackDoctors() {
    return _emptyCard(
      Icons.person_search_rounded,
      'No doctors available',
      'Doctors added by admin will appear here',
    );
  }

  void _openBookingSheet(DoctorModel doctor) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF008080),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null || !mounted) return;

    final dayName = DateFormat('EEEE').format(pickedDate);
    final slotsForDay = doctor.getSlotsForDay(dayName);

    if (slotsForDay.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Doctor is not available on $dayName'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final bookedSlots = await _appointmentService
        .getBookedSlotsForDoctorOnDate(doctor.uid, pickedDate);

    String? selectedSlot;
    for (final slot in slotsForDay) {
      if (!bookedSlots.contains(slot)) {
        selectedSlot = slot;
        break;
      }
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Book Appointment',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A1931),
                    ),
                  ),
                  Text(
                    'with ${doctor.name} - ${doctor.specialty}',
                    style: const TextStyle(
                      color: Color(0xFF008080),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Date: ${pickedDate.day}/${pickedDate.month}/${pickedDate.year} ($dayName)',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  Text(
                    'Fee: Rs. ${doctor.fee}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 20),
                  const Text('Select Time Slot',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: slotsForDay.map((slot) {
                      final isBooked = bookedSlots.contains(slot);
                      final selected = selectedSlot == slot && !isBooked;
                      return ChoiceChip(
                        label: Text(
                          isBooked ? '$slot (Booked)' : slot,
                          style: TextStyle(
                            decoration: isBooked
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        selected: selected,
                        selectedColor: const Color(0xFF008080),
                        backgroundColor:
                            isBooked ? Colors.red.shade50 : null,
                        labelStyle: TextStyle(
                          color: selected
                              ? Colors.white
                              : isBooked
                                  ? Colors.red.shade300
                                  : Colors.black87,
                          fontWeight:
                              isBooked ? FontWeight.normal : FontWeight.w500,
                        ),
                        onSelected: isBooked
                            ? null
                            : (_) => setModalState(() => selectedSlot = slot),
                      );
                    }).toList(),
                  ),
                  if (bookedSlots.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          '${bookedSlots.length} slot(s) already booked',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: selectedSlot != null
                        ? 'Confirm Booking - Rs. ${doctor.fee}'
                        : 'No Slots Available',
                    onPressed: selectedSlot != null
                        ? () {
                            Navigator.pop(context);
                            _bookAppointment(
                                doctor, pickedDate, selectedSlot!);
                          }
                        : () {},
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _bookAppointment(
    DoctorModel doctor,
    DateTime appointmentDate,
    String slot,
  ) async {
    try {
      await _appointmentService.bookAppointment(
        patientId: _currentUserId!,
        doctorId: doctor.uid,
        patientName: _currentUser?.name ?? 'Patient',
        doctorName: doctor.name,
        appointmentDate: appointmentDate,
        timeSlot: slot,
        consultationFee: double.tryParse(doctor.fee) ?? 0,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment booked successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() => _currentNavIndex = 1);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _cancelAppointment(String id) async {
    try {
      await _appointmentService.cancelAppointment(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment cancelled'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showAppointmentDetails(AppointmentModel appt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Appointment Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Doctor', appt.doctorName),
              _detailRow(
                'Date',
                '${appt.appointmentDate.day}/${appt.appointmentDate.month}/${appt.appointmentDate.year}',
              ),
              _detailRow('Time', appt.timeSlot),
              _detailRow('Status', appt.status),
              _detailRow('Fee', 'Rs. ${appt.consultationFee}'),
              if (appt.prescription != null && appt.prescription!.isNotEmpty)
                _detailRow('Prescription', appt.prescription!),
            ],
          ),
        ),
        actions: [
          if (appt.status == 'Confirmed' || appt.status == 'Completed')
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final chatRoomId = await _chatService.createOrGetChatRoom(
                  participant1Id: _currentUserId!,
                  participant2Id: appt.doctorId,
                  participant1Name: _currentUser?.name ?? 'Patient',
                  participant2Name: appt.doctorName,
                );
                if (!mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      chatRoomId: chatRoomId,
                      currentUserId: _currentUserId!,
                      receiverId: appt.doctorId,
                      receiverName: appt.doctorName,
                    ),
                  ),
                );
              },
              child: const Text('Message Doctor'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.grey.shade700)),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToChat(DoctorModel doctor) async {
    try {
      final chatRoomId = await _chatService.createOrGetChatRoom(
        participant1Id: _currentUserId!,
        participant2Id: doctor.uid,
        participant1Name: _currentUser?.name ?? 'Patient',
        participant2Name: doctor.name,
        participant2Image: doctor.imageUrl,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatRoomId: chatRoomId,
            currentUserId: _currentUserId!,
            receiverId: doctor.uid,
            receiverName: doctor.name,
            receiverImage: doctor.imageUrl,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening chat: $e')),
      );
    }
  }
}
