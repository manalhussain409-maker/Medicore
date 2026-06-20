import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medicine_model.dart';

class CartItem {
  final MedicineModel medicine;
  int quantity;

  CartItem({required this.medicine, this.quantity = 1});

  double get totalPrice => medicine.price * quantity;

  Map<String, dynamic> toMap() => {
        'medicineId': medicine.id,
        'name': medicine.name,
        'price': medicine.price,
        'quantity': quantity,
      };

  factory CartItem.fromMap(Map<String, dynamic> map, MedicineModel medicine) {
    return CartItem(medicine: medicine, quantity: map['quantity'] ?? 1);
  }
}

class CartService {
  static const String _cartKey = 'pharmacy_cart';
  List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.length;
  double get totalPrice =>
      _items.fold(0.0, (prev, item) => prev + item.totalPrice);
  int get totalQuantity =>
      _items.fold(0, (prev, item) => prev + item.quantity);

  Future<void> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartData = prefs.getString(_cartKey);
    if (cartData != null) {
      try {
        final List<dynamic> decoded = jsonDecode(cartData);
        _items = decoded.map((e) {
          final map = e as Map<String, dynamic>;
          return CartItem(
            medicine: MedicineModel(
              id: map['medicineId'] ?? '',
              name: map['name'] ?? '',
              stock: 999,
              price: (map['price'] ?? 0).toDouble(),
            ),
            quantity: map['quantity'] ?? 1,
          );
        }).toList();
      } catch (_) {
        _items = [];
      }
    }
  }

  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartData = jsonEncode(_items.map((e) => e.toMap()).toList());
    await prefs.setString(_cartKey, cartData);
  }

  Future<void> addItem(MedicineModel medicine) async {
    final existing = _items.indexWhere((i) => i.medicine.id == medicine.id);
    if (existing >= 0) {
      _items[existing].quantity++;
    } else {
      _items.add(CartItem(medicine: medicine));
    }
    await _saveCart();
  }

  Future<void> removeItem(String medicineId) async {
    _items.removeWhere((i) => i.medicine.id == medicineId);
    await _saveCart();
  }

  Future<void> updateQuantity(String medicineId, int quantity) async {
    final index = _items.indexWhere((i) => i.medicine.id == medicineId);
    if (index >= 0) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = quantity;
      }
      await _saveCart();
    }
  }

  Future<void> clearCart() async {
    _items.clear();
    await _saveCart();
  }

  Future<String> checkout(String patientId, String patientName) async {
    if (_items.isEmpty) throw Exception('Cart is empty');

    final orderId = 'ORD_${DateTime.now().millisecondsSinceEpoch}';
    await FirebaseFirestore.instance.collection('orders').doc(orderId).set({
      'orderId': orderId,
      'patientId': patientId,
      'patientName': patientName,
      'items': _items.map((e) => e.toMap()).toList(),
      'totalAmount': totalPrice,
      'totalItems': totalQuantity,
      'status': 'Pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    for (final item in _items) {
      final medRef = FirebaseFirestore.instance
          .collection('pharmacy')
          .doc(item.medicine.id);
      final doc = await medRef.get();
      if (doc.exists) {
        final currentStock = (doc.data()?['stock'] ?? 0) as int;
        final newStock = currentStock - item.quantity;
        if (newStock >= 0) {
          await medRef.update({'stock': newStock});
        }
      }
    }

    await clearCart();
    return orderId;
  }
}
