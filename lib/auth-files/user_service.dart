import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save user details to Firestore (secure cloud database)
  static Future<void> saveUserDetails(
    String uid,
    String firstName,
    String lastName,
    String username,
    String displayName,
    String email,
  ) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'firstName': firstName,
        'lastName': lastName,
        'username': username,
        'displayName': displayName,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving user details: $e');
      throw e;
    }
  }

  // Get user details from Firestore
  static Future<Map<String, dynamic>?> getUserDetails(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('Error getting user details: $e');
      return null;
    }
  }

  // Get current user's display name
  static Future<String?> getCurrentUserDisplayName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDetails = await getUserDetails(user.uid);
      return userDetails?['displayName'];
    }
    return null;
  }

  // Update user profile
  static Future<void> updateUserProfile(
      String uid, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('users').doc(uid).update(updates);
    } catch (e) {
      print('Error updating user profile: $e');
      throw e;
    }
  }
}
