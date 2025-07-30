// splitright/lib/auth-files/user_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  // In-memory storage for macOS (to avoid keychain issues)
  static Map<String, Map<String, String>> _userDetails = {};
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> saveUserDetails(
    String uid,
    String firstName,
    String lastName,
    String username,
    String displayName,
    String email,
  ) async {
    final userInfo = {
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
      'displayName': displayName,
      'email': email,
    };

    if (defaultTargetPlatform == TargetPlatform.macOS) {
      // Use memory storage for macOS
      _userDetails[uid] = userInfo;
      print('macOS: Saved user details in memory for $displayName');
    } else {
      try {
        // Use Firestore for other platforms
        await _firestore.collection('users').doc(uid).set({
          ...userInfo,
          'createdAt': FieldValue.serverTimestamp(),
        });
        // Also cache in memory as backup
        _userDetails[uid] = userInfo;
      } catch (e) {
        print('Firestore error, using memory storage: $e');
        _userDetails[uid] = userInfo;
      }
    }
  }

  static Future<Map<String, dynamic>?> getUserDetails(String uid) async {
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      return _userDetails[uid];
    } else {
      try {
        DocumentSnapshot doc =
            await _firestore.collection('users').doc(uid).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>?;
          // Cache in memory
          if (data != null) {
            _userDetails[uid] =
                data.map((key, value) => MapEntry(key, value.toString()));
          }
          return data;
        }
        return _userDetails[uid]; // Fallback to memory
      } catch (e) {
        print('Firestore error, using memory storage: $e');
        return _userDetails[uid];
      }
    }
  }

  static Future<String?> getCurrentUserDisplayName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (defaultTargetPlatform == TargetPlatform.macOS) {
        return _userDetails[user.uid]?['displayName'];
      } else {
        final userDetails = await getUserDetails(user.uid);
        return userDetails?['displayName'];
      }
    }
    return null;
  }

  static String? getUserDisplayName(String uid) {
    return _userDetails[uid]?['displayName'];
  }
}
