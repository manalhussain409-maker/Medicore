import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class ImageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  Future<Uint8List?> pickImageBytes(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (pickedFile != null) {
        return await pickedFile.readAsBytes();
      }
      return null;
    } catch (e) {
      throw Exception('Error picking image: $e');
    }
  }

  Future<String> uploadProfileImageBytes(String userId, Uint8List imageBytes) async {
    try {
      final base64Image = base64Encode(imageBytes);
      final dataUri = 'data:image/jpeg;base64,$base64Image';

      await _firestore.collection('users').doc(userId).update({
        'profileImageUrl': dataUri,
        'imageUrl': dataUri,
      });

      return dataUri;
    } catch (e) {
      throw Exception('Error saving image: $e');
    }
  }

  Future<void> deleteProfileImage(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'profileImageUrl': FieldValue.delete(),
        'imageUrl': FieldValue.delete(),
      });
    } catch (e) {}
  }

  Future<String?> pickAndUploadImage(String userId, ImageSource source) async {
    final bytes = await pickImageBytes(source);
    if (bytes == null) return null;

    final url = await uploadProfileImageBytes(userId, bytes);
    return url;
  }
}
