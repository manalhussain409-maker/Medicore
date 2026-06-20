import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import 'call_screen.dart';

class ChatScreen extends StatefulWidget {
  final String chatRoomId;
  final String currentUserId;
  final String receiverId;
  final String receiverName;
  final String? receiverImage;

  const ChatScreen({
    super.key,
    required this.chatRoomId,
    required this.currentUserId,
    required this.receiverId,
    required this.receiverName,
    this.receiverImage,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final UserService _userService = UserService();
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isReceiverOnline = false;
  DateTime? _lastSeen;
  bool _hasText = false;
  bool _isRecording = false;
  Duration _recordDuration = Duration.zero;
  bool _isRecordingSupported = true;

  @override
  void initState() {
    super.initState();
    _checkMicSupport();
    _checkReceiverStatus();
    _checkActiveCalls();
    _messageController.addListener(() {
      setState(() {
        _hasText = _messageController.text.isNotEmpty;
      });
    });
  }

  Future<void> _checkMicSupport() async {
    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission && mounted) {
        setState(() => _isRecordingSupported = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRecordingSupported = false);
      }
    }
  }

  void _checkReceiverStatus() {
    _userService.getUserStream(widget.receiverId).listen((user) {
      if (user != null && mounted) {
        setState(() {
          _isReceiverOnline = user.isOnline;
          _lastSeen = user.lastSeen;
        });
      }
    });
  }

  void _checkActiveCalls() {
    FirebaseFirestore.instance
        .collection('calls')
        .where('participants', arrayContains: widget.currentUserId)
        .where('status', isEqualTo: 'ringing')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty && mounted) {
        final callDoc = snapshot.docs.first;
        final callData = callDoc.data();
        if (callData['chatRoomId'] == widget.chatRoomId &&
            callData['callerId'] != widget.currentUserId) {
          _showCallScreen(
            callDoc.id,
            callData['type'] ?? 'voice',
            false,
            userName: callData['callerName'] ?? 'Unknown',
          );
        }
      }
    });
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    try {
      final message = _messageController.text.trim();
      _messageController.clear();

      final currentUser = await _userService.getCurrentUser();
      if (currentUser == null) return;

      await _chatService.sendMessage(
        chatRoomId: widget.chatRoomId,
        senderId: widget.currentUserId,
        senderName: currentUser.name,
        senderImage: currentUser.profileImageUrl ?? '',
        message: message,
      );

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    }
  }

  Future<void> _toggleRecording() async {
    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voice recording is not available on web. Please use a mobile device.')),
        );
      }
      return;
    }
    if (_isRecording) {
      try {
        final path = await _audioRecorder.stop();
        if (mounted) {
          setState(() {
            _isRecording = false;
            _recordDuration = Duration.zero;
          });
        }
        if (path != null) {
          await _sendVoiceMessage(path);
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isRecording = false;
            _recordDuration = Duration.zero;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error stopping recording: $e')),
          );
        }
      }
    } else {
      try {
        final hasPermission = await _audioRecorder.hasPermission();
        if (!hasPermission) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Microphone permission required. Please enable it in Settings.')),
            );
          }
          return;
        }

        final dir = await getApplicationDocumentsDirectory();
        final filePath =
            '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(),
          path: filePath,
        );

        if (mounted) {
          setState(() => _isRecording = true);
          _startRecordingTimer();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error starting recording: $e')),
          );
        }
      }
    }
  }

  void _startRecordingTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted && _isRecording) {
        setState(() => _recordDuration += const Duration(seconds: 1));
        return true;
      }
      return false;
    });
  }

  String _formatRecordingDuration() {
    final m = _recordDuration.inMinutes.toString().padLeft(2, '0');
    final s = (_recordDuration.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _sendVoiceMessage(String filePath) async {
    try {
      final currentUser = await _userService.getCurrentUser();
      if (currentUser == null) return;

      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final base64Data = base64Encode(bytes);

      await _chatService.sendMessage(
        chatRoomId: widget.chatRoomId,
        senderId: widget.currentUserId,
        senderName: currentUser.name,
        senderImage: currentUser.profileImageUrl ?? '',
        message: '🎤 Voice message',
        fileUrl: 'data:audio/aac;base64,$base64Data',
        fileType: 'audio',
      );

      try {
        await file.delete();
      } catch (_) {}
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending voice: $e')),
        );
      }
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Send Attachment',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _attachmentOption(
                    Icons.photo_camera,
                    'Camera',
                    Colors.blue,
                    () {
                      Navigator.pop(ctx);
                      _pickAndSendImage(ImageSource.camera);
                    },
                  ),
                  _attachmentOption(
                    Icons.photo_library,
                    'Gallery',
                    Colors.purple,
                    () {
                      Navigator.pop(ctx);
                      _pickAndSendImage(ImageSource.gallery);
                    },
                  ),
                  _attachmentOption(
                    Icons.insert_drive_file,
                    'Document',
                    Colors.orange,
                    () {
                      Navigator.pop(ctx);
                      _pickAndSendDocument();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _attachmentOption(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 75,
      );
      if (pickedFile == null) return;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sending image...'),
          duration: Duration(seconds: 1),
        ),
      );

      final currentUser = await _userService.getCurrentUser();
      if (currentUser == null) return;

      final file = File(pickedFile.path);
      final bytes = await file.readAsBytes();
      final base64Data = base64Encode(bytes);

      await _chatService.sendMessage(
        chatRoomId: widget.chatRoomId,
        senderId: widget.currentUserId,
        senderName: currentUser.name,
        senderImage: currentUser.profileImageUrl ?? '',
        message: '📷 Photo',
        fileUrl: 'data:image/jpeg;base64,$base64Data',
        fileType: 'image',
      );

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending image: $e')),
        );
      }
    }
  }

  Future<void> _pickAndSendDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx'],
      );
      if (result == null || result.files.isEmpty) return;

      final pickedFile = result.files.first;
      if (pickedFile.path == null) return;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sending document...'),
          duration: Duration(seconds: 1),
        ),
      );

      final currentUser = await _userService.getCurrentUser();
      if (currentUser == null) return;

      final file = File(pickedFile.path!);
      final ext = pickedFile.extension ?? 'pdf';
      final bytes = await file.readAsBytes();
      final base64Data = base64Encode(bytes);

      await _chatService.sendMessage(
        chatRoomId: widget.chatRoomId,
        senderId: widget.currentUserId,
        senderName: currentUser.name,
        senderImage: currentUser.profileImageUrl ?? '',
        message: '📎 ${pickedFile.name}',
        fileUrl: 'data:application/$ext;base64,$base64Data',
        fileType: 'document',
      );

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending document: $e')),
        );
      }
    }
  }

  Future<void> _startCall(String type) async {
    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Calls are not available on web. Please use a mobile device.')),
        );
      }
      return;
    }
    final currentUser = await _userService.getCurrentUser();
    if (currentUser == null) return;

    try {
      final callId =
          '${widget.currentUserId}_${widget.receiverId}_${DateTime.now().millisecondsSinceEpoch}';
      await FirebaseFirestore.instance.collection('calls').doc(callId).set({
        'callId': callId,
        'chatRoomId': widget.chatRoomId,
        'callerId': widget.currentUserId,
        'callerName': currentUser.name,
        'receiverId': widget.receiverId,
        'receiverName': widget.receiverName,
        'type': type,
        'status': 'ringing',
        'participants': [widget.currentUserId, widget.receiverId],
        'startedAt': FieldValue.serverTimestamp(),
      });

      await _chatService.sendMessage(
        chatRoomId: widget.chatRoomId,
        senderId: widget.currentUserId,
        senderName: currentUser.name,
        senderImage: currentUser.profileImageUrl ?? '',
        message: '📞 ${type == 'video' ? 'Video' : 'Voice'} call started',
      );

      if (!mounted) return;
      _showCallScreen(callId, type, true, userName: currentUser.name);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting call: $e')),
        );
      }
    }
  }

  void _showCallScreen(String callId, String type, bool isOutgoing, {String? userName}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CallScreen(
          callId: callId,
          chatRoomId: widget.chatRoomId,
          currentUserId: widget.currentUserId,
          currentUserName: userName ?? '',
          receiverId: widget.receiverId,
          receiverName: widget.receiverName,
          type: type,
          isOutgoing: isOutgoing,
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate =
        DateTime(timestamp.year, timestamp.month, timestamp.day);

    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute';

    if (messageDate == today) {
      return timeStr;
    } else if (messageDate == yesterday) {
      return 'Yesterday $timeStr';
    } else {
      final month = timestamp.month.toString().padLeft(2, '0');
      final day = timestamp.day.toString().padLeft(2, '0');
      return '$month/$day $timeStr';
    }
  }

  String _getLastSeenText() {
    if (_isReceiverOnline) return 'Online';
    if (_lastSeen != null) {
      final diff = DateTime.now().difference(_lastSeen!);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    }
    return 'Offline';
  }

  Future<void> _logout() async {
    await _userService.setUserOnlineStatus(widget.currentUserId, false);
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe) {
    final fileUrl = msg['fileUrl'] as String?;
    final fileType = msg['fileType'] as String?;
    final message = msg['message'] ?? '';
    final isCallMessage = message.startsWith('📞');

    if (fileType == 'image' && fileUrl != null) {
      return Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          color: isMe ? const Color(0xFF1A237E) : const Color(0xFFE8E8E8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Image.network(
                fileUrl,
                width: 250,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 250,
                    height: 200,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF00796B),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 250,
                    height: 150,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image,
                        color: Colors.grey, size: 40),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                message,
                style: TextStyle(
                  color: isMe ? Colors.white70 : Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (fileType == 'audio' && fileUrl != null) {
      return Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF1A237E) : const Color(0xFFE8E8E8),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mic,
              color: isMe ? Colors.white : const Color(0xFF00796B),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: isMe
                          ? Colors.white.withOpacity(0.3)
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      widthFactor: 0.6,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isMe
                              ? Colors.white
                              : const Color(0xFF00796B),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Voice message',
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (fileType == 'document' && fileUrl != null) {
      return Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF1A237E) : const Color(0xFFE8E8E8),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isMe
                    ? Colors.white.withOpacity(0.2)
                    : const Color(0xFF00796B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.insert_drive_file,
                color: isMe ? Colors.white : const Color(0xFF00796B),
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message.replaceFirst('📎 ', ''),
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isCallMessage
            ? const Color(0xFF00796B).withValues(alpha: 0.1)
            : isMe
                ? const Color(0xFF1A237E)
                : const Color(0xFFE8E8E8),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: isCallMessage
              ? const Color(0xFF00796B)
              : isMe
                  ? Colors.white
                  : const Color(0xFF333333),
          fontSize: 15,
          height: 1.4,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00796B),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: Text(
                widget.receiverName.isNotEmpty
                    ? widget.receiverName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.receiverName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    _getLastSeenText(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _startCall('voice'),
            icon: const Icon(Icons.call, color: Colors.white, size: 22),
            tooltip: 'Voice Call',
          ),
          IconButton(
            onPressed: () => _startCall('video'),
            icon: const Icon(Icons.videocam, color: Colors.white, size: 22),
            tooltip: 'Video Call',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'logout') _logout();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF00796B)),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE8EAF6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 48,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Start a new conversation!',
                          style: TextStyle(
                            color: Color(0xFF1A237E),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Send a message to begin chatting',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildCallPromptButton(
                              Icons.videocam,
                              'Video Call',
                              () => _startCall('video'),
                            ),
                            const SizedBox(width: 16),
                            _buildCallPromptButton(
                              Icons.call,
                              'Voice Call',
                              () => _startCall('voice'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 16,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageDoc = messages[index];
                    final msg =
                        messageDoc.data() as Map<String, dynamic>;
                    final isMe =
                        msg['senderId'] == widget.currentUserId;

                    final timestamp =
                        (msg['timestamp'] as Timestamp).toDate();
                    final timeStr = _formatTime(timestamp);

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            _buildMessageBubble(msg, isMe),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              child: Text(
                                timeStr,
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_isRecording)
            Container(
              color: Colors.red.shade50,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Recording... ${_formatRecordingDuration()}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _toggleRecording,
                    icon: const Icon(Icons.stop_circle,
                        color: Colors.red, size: 32),
                  ),
                ],
              ),
            ),
          Container(
            color: Colors.white,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 8,
              right: 8,
              top: 8,
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    onPressed: _showAttachmentOptions,
                    icon: const Icon(Icons.attach_file,
                        color: Color(0xFF00796B), size: 26),
                    tooltip: 'Attach',
                  ),
                  Expanded(
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _messageController,
                        maxLines: 1,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle:
                              TextStyle(color: Colors.grey.shade400),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                        ),
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (_hasText)
                    Material(
                      color: const Color(0xFF00796B),
                      borderRadius: BorderRadius.circular(50),
                      child: InkWell(
                        onTap: _sendMessage,
                        borderRadius: BorderRadius.circular(50),
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    )
                  else if (_isRecordingSupported)
                    Material(
                      color: _isRecording
                          ? Colors.red
                          : const Color(0xFF00796B),
                      borderRadius: BorderRadius.circular(50),
                      child: InkWell(
                        onTap: _toggleRecording,
                        borderRadius: BorderRadius.circular(50),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            _isRecording ? Icons.stop : Icons.mic,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallPromptButton(
      IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF00796B).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF00796B).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF00796B), size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF00796B),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }
}
