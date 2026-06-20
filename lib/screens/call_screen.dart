import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/call_service.dart';

class CallScreen extends StatefulWidget {
  final String callId;
  final String chatRoomId;
  final String currentUserId;
  final String currentUserName;
  final String receiverId;
  final String receiverName;
  final String type;
  final bool isOutgoing;

  const CallScreen({
    super.key,
    required this.callId,
    required this.chatRoomId,
    required this.currentUserId,
    required this.currentUserName,
    required this.receiverId,
    required this.receiverName,
    required this.type,
    required this.isOutgoing,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final CallService _callService = CallService();
  int? _remoteUid;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isCameraOff = false;
  bool _isConnected = false;
  int _callDuration = 0;
  Timer? _timer;
  StreamSubscription? _callDocSub;

  @override
  void initState() {
    super.initState();
    _initCall();
    _listenToCallDocument();
  }

  Future<void> _initCall() async {
    final hasPermission = await _callService.requestPermissions();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Camera and microphone permissions are required for calls.')),
        );
        Navigator.pop(context);
      }
      return;
    }

    await _callService.initialize();

    final channelName = widget.chatRoomId;
    final uid = CallService.generateUid(widget.currentUserId);

    await _callService.joinChannel(
      channelName: channelName,
      uid: uid,
      eventHandler: RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          if (mounted) {
            if (widget.isOutgoing) {
              _updateCallStatus('ringing');
            }
          }
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          if (mounted) {
            setState(() {
              _remoteUid = remoteUid;
              _isConnected = true;
            });
            _startTimer();
            if (widget.isOutgoing) {
              _updateCallStatus('active');
            }
          }
        },
        onUserOffline:
            (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          if (mounted) {
            setState(() {
              _remoteUid = null;
              _isConnected = false;
            });
            _endCall();
          }
        },
        onRtcStats: (RtcConnection connection, RtcStats stats) {},
      ),
    );
  }

  void _listenToCallDocument() {
    _callDocSub = FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.callId)
        .snapshots()
        .listen((doc) {
      if (!doc.exists || !mounted) return;
      final data = doc.data()!;
      if (data['status'] == 'ended') {
        _cleanupAndPop();
      }
      if (!widget.isOutgoing && data['status'] == 'ringing') {
        _updateCallStatus('active');
      }
    });
  }

  void _updateCallStatus(String status) {
    FirebaseFirestore.instance.collection('calls').doc(widget.callId).update({
      'status': status,
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _callDuration++);
      }
    });
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _endCall() async {
    _timer?.cancel();
    _callDocSub?.cancel();
    _updateCallStatus('ended');
    await _callService.leaveChannel();
    await _callService.dispose();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _cleanupAndPop() {
    _timer?.cancel();
    _callDocSub?.cancel();
    _callService.dispose();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _callDocSub?.cancel();
    _callService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  if (_remoteUid != null && widget.type == 'video')
                    AgoraVideoView(
                      controller: VideoViewController.remote(
                        rtcEngine: _callService.engine!,
                        canvas: VideoCanvas(uid: _remoteUid!),
                        connection: RtcConnection(channelId: widget.chatRoomId),
                      ),
                    )
                  else
                    _buildCallerView(),
                  if (widget.type == 'video' && !_isCameraOff)
                    Positioned(
                      top: 16,
                      right: 16,
                      width: 120,
                      height: 160,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AgoraVideoView(
                          controller: VideoViewController(
                            rtcEngine: _callService.engine!,
                            canvas: const VideoCanvas(uid: 0),
                          ),
                        ),
                      ),
                    ),
                  if (widget.type == 'video' && _isCameraOff)
                    Positioned(
                      top: 16,
                      right: 16,
                      width: 120,
                      height: 160,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.videocam_off,
                            color: Colors.white54, size: 32),
                      ),
                    ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isConnected
                              ? widget.receiverName
                              : widget.isOutgoing
                                  ? widget.receiverName
                                  : widget.currentUserName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isConnected
                              ? _formatDuration(_callDuration)
                              : widget.isOutgoing
                                  ? 'Calling...'
                                  : 'Incoming call...',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildCallerView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF00796B),
            ),
            child: Center(
              child: Text(
                widget.receiverName.isNotEmpty
                    ? widget.receiverName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.receiverName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isConnected
                ? _formatDuration(_callDuration)
                : widget.isOutgoing
                    ? 'Calling...'
                    : 'Incoming call...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: _isMuted ? Icons.mic_off : Icons.mic,
            label: _isMuted ? 'Unmute' : 'Mute',
            onTap: () async {
              setState(() => _isMuted = !_isMuted);
              await _callService.toggleMute(_isMuted);
            },
          ),
          if (widget.type == 'video')
            _buildControlButton(
              icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
              label: _isCameraOff ? 'Camera On' : 'Camera Off',
              onTap: () async {
                setState(() => _isCameraOff = !_isCameraOff);
                await _callService.toggleCamera(!_isCameraOff);
              },
            ),
          _buildControlButton(
            icon: Icons.call_end,
            label: 'End',
            onTap: _endCall,
            isEnd: true,
          ),
          _buildControlButton(
            icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
            label: 'Speaker',
            onTap: () async {
              setState(() => _isSpeakerOn = !_isSpeakerOn);
              await _callService.toggleSpeakerphone(_isSpeakerOn);
            },
          ),
          if (widget.type == 'video')
            _buildControlButton(
              icon: Icons.cameraswitch,
              label: 'Switch',
              onTap: () => _callService.switchCamera(),
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isEnd = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  isEnd ? Colors.red : Colors.white.withValues(alpha: 0.2),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
