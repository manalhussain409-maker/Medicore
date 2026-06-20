import '../utils/firestore_utils.dart';

class ChatRoomModel {
  final String id;
  final List<String> participants;
  final String participantNames;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final String? participantImageUrl;
  final bool isActive;

  ChatRoomModel({
    required this.id,
    required this.participants,
    required this.participantNames,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.participantImageUrl,
    this.isActive = true,
  });

  factory ChatRoomModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return ChatRoomModel(
      id: map['id'] ?? docId ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      participantNames: map['participantNames'] ?? 'Unknown User',
      lastMessage: map['lastMessage'] ?? 'No messages yet',
      lastMessageTime: parseFirestoreDateOrNow(map['lastMessageTime']),
      unreadCount: map['unreadCount'] ?? 0,
      participantImageUrl: map['participantImageUrl'],
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participants': participants,
      'participantNames': participantNames,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'unreadCount': unreadCount,
      'participantImageUrl': participantImageUrl,
      'isActive': isActive,
    };
  }

  ChatRoomModel copyWith({
    String? id,
    List<String>? participants,
    String? participantNames,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    String? participantImageUrl,
    bool? isActive,
  }) {
    return ChatRoomModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      participantNames: participantNames ?? this.participantNames,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      participantImageUrl: participantImageUrl ?? this.participantImageUrl,
      isActive: isActive ?? this.isActive,
    );
  }
}
