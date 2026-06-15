import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. REGISTER METHOD (Saves role to Firestore)
  Future<User?> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      // Create user in Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        // Create user model instance
        UserModel newUser = UserModel(
          uid: user.uid,
          name: name,
          email: email,
          role: role,
        );

        // Save user role data into Firestore under 'users' collection
        await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
        return user;
      }
      return null;
    } catch (e) {
      print("Registration Error: ${e.toString()}");
      return null;
    }
  }

  // 2. LOGIN METHOD (Validates user credentials)
  Future<User?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print("Login Error: ${e.toString()}");
      return null;
    }
  }

  // 3. GET USER ROLE METHOD (Fetches role from Firestore)
  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return data['role'] as String;
      }
      return null;
    } catch (e) {
      print("Error fetching user role: ${e.toString()}");
      return null;
    }
  }

  // 4. SIGNOUT METHOD
  Future<void> signOut() async {
    await _auth.signOut();
  }
}