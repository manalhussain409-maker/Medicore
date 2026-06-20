import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_room_model.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create or get chat room
  Future<String> createOrGetChatRoom({
    required String participant1Id,
    required String participant2Id,
    required String participant1Name,
    required String participant2Name,
    String? participant2Image,
  }) async {
    try {
      // Create a unique chat room ID
      List<String> participants = [participant1Id, participant2Id]..sort();
      String chatRoomId = participants.join('_');

      DocumentSnapshot docSnap = await _firestore
          .collection('chats')
          .doc(chatRoomId)
          .get();

      if (!docSnap.exists) {
        // Create new chat room
        await _firestore.collection('chats').doc(chatRoomId).set({
          'id': chatRoomId,
          'participants': participants,
          'participantNames': '$participant1Name • $participant2Name',
          'participantImageUrl': participant2Image,
          'lastMessage': 'Chat started',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'unreadCount': 0,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return chatRoomId;
    } catch (e) {
      throw Exception('Error creating chat room: $e');
    }
  }

  // Send message
  Future<void> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String senderName,
    required String senderImage,
    required String message,
    String? fileUrl,
    String? fileType,
  }) async {
    try {
      final messageId = _firestore.collection('temp').doc().id;

      await _firestore
          .collection('chats')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .set({
            'id': messageId,
            'chatRoomId': chatRoomId,
            'senderId': senderId,
            'senderName': senderName,
            'senderImage': senderImage,
            'message': message,
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
            if (fileUrl != null) 'fileUrl': fileUrl,
            if (fileType != null) 'fileType': fileType,
          });

      await _firestore.collection('chats').doc(chatRoomId).update({
        'lastMessage': message,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error sending message: $e');
    }
  }

  // Get chat rooms for user
  Stream<List<ChatRoomModel>> getUserChatRooms(String userId) {
    try {
      return _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .snapshots()
          .map((snapshot) {
            final rooms = snapshot.docs
                .map((doc) => ChatRoomModel.fromMap(doc.data(), docId: doc.id))
                .toList();
            rooms.sort(
              (a, b) => b.lastMessageTime.compareTo(a.lastMessageTime),
            );
            return rooms;
          });
    } catch (e) {
      throw Exception('Error fetching chat rooms: $e');
    }
  }

  // Get messages for a chat room
  Stream<List<MessageModel>> getChatMessages(String chatRoomId) {
    try {
      return _firestore
          .collection('chats')
          .doc(chatRoomId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => MessageModel.fromMap(doc.data(), docId: doc.id))
                .toList();
          });
    } catch (e) {
      throw Exception('Error fetching messages: $e');
    }
  }

  // Mark message as read
  Future<void> markMessageAsRead(String chatRoomId, String messageId) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .update({'isRead': true});
    } catch (e) {
      throw Exception('Error marking message as read: $e');
    }
  }

  // Delete message
  Future<void> deleteMessage(String chatRoomId, String messageId) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      throw Exception('Error deleting message: $e');
    }
  }

  // Get unread count
  Future<int> getUnreadCount(String chatRoomId, String userId) async {
    try {
      final snapshot = await _firestore
          .collection('chats')
          .doc(chatRoomId)
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .where('senderId', isNotEqualTo: userId)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Error getting unread count: $e');
    }
  }
}
