// splitright/lib/services/messaging_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'contacts_service.dart';

class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime timestamp;
  final bool isRead;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    this.isRead = false,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': isRead,
    };
  }
}

class MessagingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static Map<String, List<Message>> _messagesCache = {};

  // Generate chat ID from two user IDs (always same order)
  static String generateChatId(String userId1, String userId2) {
    List<String> users = [userId1, userId2]..sort();
    return '${users[0]}_${users[1]}';
  }

  // Send a message
  static Future<bool> sendMessage(String receiverId, String text) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;

      final senderId = currentUser.uid;
      final chatId = generateChatId(senderId, receiverId);

      if (defaultTargetPlatform == TargetPlatform.macOS) {
        // For macOS development - store in memory
        final message = Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          senderId: senderId,
          receiverId: receiverId,
          text: text,
          timestamp: DateTime.now(),
        );

        if (_messagesCache[chatId] == null) {
          _messagesCache[chatId] = [];
        }
        _messagesCache[chatId]!.add(message);

        print('macOS: Message sent successfully');

        // Update last message for both users
        await ContactsService.updateLastMessage(senderId, receiverId, text);
        await ContactsService.updateLastMessage(receiverId, senderId, text);

        return true;
      } else {
        // Store in Firestore
        final messageRef = _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .doc();

        final message = Message(
          id: messageRef.id,
          senderId: senderId,
          receiverId: receiverId,
          text: text,
          timestamp: DateTime.now(),
        );

        await messageRef.set(message.toFirestore());

        // Update last message for both users
        await ContactsService.updateLastMessage(senderId, receiverId, text);
        await ContactsService.updateLastMessage(receiverId, senderId, text);

        print('Firestore: Message sent successfully');
        return true;
      }
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  // Get messages for a chat
  static Stream<List<Message>> getMessages(String otherUserId) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    final chatId = generateChatId(currentUser.uid, otherUserId);

    if (defaultTargetPlatform == TargetPlatform.macOS) {
      // For macOS development - return cached messages as stream
      return Stream.periodic(Duration(milliseconds: 500), (count) {
        return _messagesCache[chatId] ?? [];
      });
    } else {
      // Return Firestore stream
      return _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList();
      });
    }
  }

  // Mark messages as read
  static Future<void> markMessagesAsRead(String otherUserId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final chatId = generateChatId(currentUser.uid, otherUserId);

      if (defaultTargetPlatform == TargetPlatform.macOS) {
        // For macOS development - mark in memory
        if (_messagesCache[chatId] != null) {
          for (var message in _messagesCache[chatId]!) {
            if (message.receiverId == currentUser.uid) {
              // Create new message with isRead = true (since Message is immutable)
              final updatedMessage = Message(
                id: message.id,
                senderId: message.senderId,
                receiverId: message.receiverId,
                text: message.text,
                timestamp: message.timestamp,
                isRead: true,
              );
              // Replace in list
              final index = _messagesCache[chatId]!.indexOf(message);
              _messagesCache[chatId]![index] = updatedMessage;
            }
          }
        }
      } else {
        // Mark as read in Firestore
        final batch = _firestore.batch();
        final messagesQuery = await _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .where('receiverId', isEqualTo: currentUser.uid)
            .where('isRead', isEqualTo: false)
            .get();

        for (var doc in messagesQuery.docs) {
          batch.update(doc.reference, {'isRead': true});
        }

        await batch.commit();
      }
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // Get unread message count for a user
  static Future<int> getUnreadCount(String otherUserId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return 0;

      final chatId = generateChatId(currentUser.uid, otherUserId);

      if (defaultTargetPlatform == TargetPlatform.macOS) {
        // For macOS development - count unread in memory
        if (_messagesCache[chatId] == null) return 0;
        return _messagesCache[chatId]!
            .where((message) =>
                message.receiverId == currentUser.uid && !message.isRead)
            .length;
      } else {
        // Count unread in Firestore
        final unreadQuery = await _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .where('receiverId', isEqualTo: currentUser.uid)
            .where('isRead', isEqualTo: false)
            .get();

        return unreadQuery.docs.length;
      }
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  // Clear messages cache (useful for logout)
  static void clearCache() {
    _messagesCache.clear();
  }

  // Delete a message
  static Future<bool> deleteMessage(
      String messageId, String otherUserId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;

      final chatId = generateChatId(currentUser.uid, otherUserId);

      if (defaultTargetPlatform == TargetPlatform.macOS) {
        // For macOS development - remove from memory
        if (_messagesCache[chatId] != null) {
          _messagesCache[chatId]!
              .removeWhere((message) => message.id == messageId);
        }
        return true;
      } else {
        // Delete from Firestore
        await _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .doc(messageId)
            .delete();
        return true;
      }
    } catch (e) {
      print('Error deleting message: $e');
      return false;
    }
  }
}
