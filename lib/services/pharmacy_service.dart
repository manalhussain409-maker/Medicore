import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/medicine_model.dart';

class PharmacyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<MedicineModel>> getAllMedicines() {
    return _firestore.collection('pharmacy').snapshots().map((snapshot) {
      final medicines = snapshot.docs
          .map((doc) => MedicineModel.fromMap(doc.data(), docId: doc.id))
          .toList();
      medicines.sort((a, b) => a.name.compareTo(b.name));
      return medicines;
    });
  }

  Stream<List<MedicineModel>> searchMedicines(String query) {
    return getAllMedicines().map((medicines) {
      if (query.trim().isEmpty) return medicines;
      final lower = query.toLowerCase();
      return medicines
          .where((m) => m.name.toLowerCase().contains(lower))
          .toList();
    });
  }

  Future<void> addMedicine({
    required String name,
    required int stock,
    required double price,
    String? category,
    String? description,
  }) async {
    await _firestore.collection('pharmacy').add({
      'name': name,
      'stock': stock,
      'price': price,
      'category': category ?? 'General',
      'description': description,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateStock(String medicineId, int stock) async {
    await _firestore.collection('pharmacy').doc(medicineId).update({
      'stock': stock,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteMedicine(String medicineId) async {
    await _firestore.collection('pharmacy').doc(medicineId).delete();
  }
}
