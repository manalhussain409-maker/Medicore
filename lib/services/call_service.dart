import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class CallService {
  static const String _appId = 'YOUR_AGORA_APP_ID';

  RtcEngine? _engine;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _engine = createAgoraRtcEngine();
    await _engine!.initialize(RtcEngineContext(
      appId: _appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    _isInitialized = true;
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    final statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    return statuses[Permission.camera]!.isGranted &&
        statuses[Permission.microphone]!.isGranted;
  }

  Future<void> joinChannel({
    required String channelName,
    required int uid,
    required RtcEngineEventHandler eventHandler,
  }) async {
    _engine!.registerEventHandler(eventHandler);

    _engine!.enableVideo();
    _engine!.enableAudio();

    await _engine!.joinChannel(
      token: '',
      channelId: channelName,
      uid: uid,
      options: const ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileCommunication,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
  }

  Future<void> leaveChannel() async {
    await _engine?.leaveChannel();
  }

  Future<void> toggleMute(bool muted) async {
    await _engine?.muteLocalAudioStream(muted);
  }

  Future<void> toggleSpeakerphone(bool enabled) async {
    await _engine?.setEnableSpeakerphone(enabled);
  }

  Future<void> toggleCamera(bool enabled) async {
    await _engine?.muteLocalVideoStream(!enabled);
  }

  Future<void> switchCamera() async {
    await _engine?.switchCamera();
  }

  RtcEngine? get engine => _engine;

  Future<void> dispose() async {
    await _engine?.release();
    _engine = null;
    _isInitialized = false;
  }

  static int generateUid(String userId) {
    int hash = 0;
    for (int i = 0; i < userId.length; i++) {
      hash = (hash * 31 + userId.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return hash % 100000000;
  }
}
