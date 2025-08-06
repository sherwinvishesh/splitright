// splitright/lib/services/contacts_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

class ContactsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static Map<String, List<Map<String, dynamic>>> _contactsCache = {};

  // Generate a unique friend ID for the user (longer and more unique)
  static String generateFriendId() {
    const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random random = Random();
    String timestamp =
        DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    String randomPart =
        List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
    return randomPart + timestamp;
  }

  // Create or get user's friend ID
  static Future<String?> getUserFriendId(String userUid) async {
    try {
      if (defaultTargetPlatform == TargetPlatform.macOS) {
        // For macOS development - create a unique ID based on userUid
        return 'TEST${userUid.substring(0, 6)}';
      }

      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userUid).get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        // If user already has a friend ID, return it
        if (userData.containsKey('friendId')) {
          return userData['friendId'];
        } else {
          // Generate new friend ID and save it
          String friendId = generateFriendId();

          // Make sure the friend ID is unique
          while (await _friendIdExists(friendId)) {
            friendId = generateFriendId();
          }

          // Save the friend ID to user document
          await _firestore.collection('users').doc(userUid).update({
            'friendId': friendId,
          });

          print('Generated new friend ID: $friendId for user: $userUid');
          return friendId;
        }
      }
      return null;
    } catch (e) {
      print('Error getting friend ID: $e');
      return null;
    }
  }

  // Check if friend ID already exists
  static Future<bool> _friendIdExists(String friendId) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('users')
          .where('friendId', isEqualTo: friendId)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      print('Error checking friend ID: $e');
      return false;
    }
  }

  // Search user by friend ID
  static Future<Map<String, dynamic>?> searchUserByFriendId(
      String friendId) async {
    try {
      print('Searching for user with friend ID: $friendId');

      if (defaultTargetPlatform == TargetPlatform.macOS) {
        // For macOS development - simulate finding different users
        if (friendId.startsWith('TEST') && friendId.length > 4) {
          return {
            'uid': 'mock-${friendId.substring(4)}',
            'displayName': 'Test User',
            'email': 'test@example.com',
            'username': 'testuser',
            'firstName': 'Test',
            'lastName': 'User',
            'friendId': friendId,
          };
        }
        return null;
      }

      QuerySnapshot query = await _firestore
          .collection('users')
          .where('friendId', isEqualTo: friendId.toUpperCase())
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        print('Found user by friend ID: ${doc.data()}');
        return {
          'uid': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }

      print('No user found with friend ID: $friendId');
      return null;
    } catch (e) {
      print('Error searching by friend ID: $e');
      return null;
    }
  }

  // Main search function (only supports friend ID now)
  static Future<Map<String, dynamic>?> searchUser(String searchQuery) async {
    // Clean up the search query
    String cleanQuery = searchQuery.trim().toUpperCase();

    // Search by friend ID
    return await searchUserByFriendId(cleanQuery);
  }

  // Add contact connection (bidirectional)
  static Future<bool> addContact(String currentUserUid, String targetUserUid,
      Map<String, dynamic> targetUserData) async {
    try {
      if (defaultTargetPlatform == TargetPlatform.macOS) {
        // For macOS, use memory storage
        if (_contactsCache[currentUserUid] == null) {
          _contactsCache[currentUserUid] = [];
        }

        // Check if contact already exists
        bool exists = _contactsCache[currentUserUid]!
            .any((contact) => contact['uid'] == targetUserUid);
        if (!exists) {
          _contactsCache[currentUserUid]!.add({
            'uid': targetUserUid,
            'displayName': targetUserData['displayName'],
            'email': targetUserData['email'],
            'username': targetUserData['username'],
            'firstName': targetUserData['firstName'],
            'lastName': targetUserData['lastName'],
            'friendId': targetUserData['friendId'],
            'status': 'accepted',
            'addedAt': DateTime.now().toIso8601String(),
            'lastMessage': '',
            'lastMessageTime': DateTime.now().toIso8601String(),
          });

          // Add reverse connection
          print('Adding reverse connection for target user: $targetUserUid');
          try {
            // Get current user's data from Firestore
            DocumentSnapshot currentUserDoc =
                await _firestore.collection('users').doc(currentUserUid).get();

            if (currentUserDoc.exists) {
              final currentUserData =
                  currentUserDoc.data() as Map<String, dynamic>;

              if (_contactsCache[targetUserUid] == null) {
                _contactsCache[targetUserUid] = [];
              }

              _contactsCache[targetUserUid]!.add({
                'uid': currentUserUid,
                'displayName': currentUserData['displayName'] ?? 'User',
                'email': currentUserData['email'] ?? '',
                'username': currentUserData['username'] ?? 'user',
                'firstName': currentUserData['firstName'] ?? '',
                'lastName': currentUserData['lastName'] ?? '',
                'friendId': currentUserData['friendId'] ?? '',
                'status': 'accepted',
                'addedAt': DateTime.now().toIso8601String(),
                'lastMessage': '',
                'lastMessageTime': DateTime.now().toIso8601String(),
              });

              print('Successfully added reverse connection in memory');
            }
          } catch (e) {
            print('Error getting current user data for reverse connection: $e');
          }
        }
        return true;
      } else {
        // Use Firestore for other platforms
        print('Adding contact using Firestore batch operation');
        final batch = _firestore.batch();

        // Add to current user's contacts
        final currentUserContactRef = _firestore
            .collection('users')
            .doc(currentUserUid)
            .collection('contacts')
            .doc(targetUserUid);

        batch.set(currentUserContactRef, {
          'uid': targetUserUid,
          'displayName': targetUserData['displayName'],
          'email': targetUserData['email'],
          'username': targetUserData['username'],
          'firstName': targetUserData['firstName'] ?? '',
          'lastName': targetUserData['lastName'] ?? '',
          'friendId': targetUserData['friendId'] ?? '',
          'status': 'accepted',
          'addedAt': FieldValue.serverTimestamp(),
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
        });

        // Get current user's data for reverse connection
        DocumentSnapshot currentUserDoc =
            await _firestore.collection('users').doc(currentUserUid).get();

        if (currentUserDoc.exists) {
          final currentUserData = currentUserDoc.data() as Map<String, dynamic>;

          // Add to target user's contacts (reverse connection)
          final targetUserContactRef = _firestore
              .collection('users')
              .doc(targetUserUid)
              .collection('contacts')
              .doc(currentUserUid);

          batch.set(targetUserContactRef, {
            'uid': currentUserUid,
            'displayName': currentUserData['displayName'] ?? 'User',
            'email': currentUserData['email'] ?? '',
            'username': currentUserData['username'] ?? 'user',
            'firstName': currentUserData['firstName'] ?? '',
            'lastName': currentUserData['lastName'] ?? '',
            'friendId': currentUserData['friendId'] ?? '',
            'status': 'accepted',
            'addedAt': FieldValue.serverTimestamp(),
            'lastMessage': '',
            'lastMessageTime': FieldValue.serverTimestamp(),
          });

          await batch.commit();
          print('Firestore: Added bidirectional contact successfully');
          return true;
        } else {
          print('Error: Current user document not found');
          return false;
        }
      }
    } catch (e) {
      print('Error adding contact: $e');
      return false;
    }
  }

  // Get user's contacts
  static Future<List<Map<String, dynamic>>> getUserContacts(
      String userUid) async {
    try {
      if (defaultTargetPlatform == TargetPlatform.macOS) {
        return _contactsCache[userUid] ?? [];
      } else {
        QuerySnapshot snapshot = await _firestore
            .collection('users')
            .doc(userUid)
            .collection('contacts')
            .orderBy('lastMessageTime', descending: true)
            .get();

        List<Map<String, dynamic>> contacts = [];
        for (QueryDocumentSnapshot doc in snapshot.docs) {
          contacts.add({
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          });
        }

        // Cache the results
        _contactsCache[userUid] = contacts;
        return contacts;
      }
    } catch (e) {
      print('Error getting contacts: $e');
      return _contactsCache[userUid] ?? [];
    }
  }

  // Update last message for contact
  static Future<void> updateLastMessage(
      String userUid, String contactUid, String message) async {
    try {
      if (defaultTargetPlatform == TargetPlatform.macOS) {
        // Update in memory cache
        if (_contactsCache[userUid] != null) {
          for (int i = 0; i < _contactsCache[userUid]!.length; i++) {
            if (_contactsCache[userUid]![i]['uid'] == contactUid) {
              _contactsCache[userUid]![i]['lastMessage'] = message;
              _contactsCache[userUid]![i]['lastMessageTime'] =
                  DateTime.now().toIso8601String();
              break;
            }
          }
        }
      } else {
        await _firestore
            .collection('users')
            .doc(userUid)
            .collection('contacts')
            .doc(contactUid)
            .update({
          'lastMessage': message,
          'lastMessageTime': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error updating last message: $e');
    }
  }

  // Clear contacts cache (useful for logout)
  static void clearCache() {
    _contactsCache.clear();
  }
}
