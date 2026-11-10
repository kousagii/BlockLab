import 'dart:convert';

typedef UnitySender = void Function(String object, String method, String data);

/// A session is initialized once, even when ready messages or focus repeat.
class UnityBridge {
  final String sessionId;
  final String? scene;
  final UnitySender send;
  bool started = false;
  UnityBridge({required this.sessionId, required this.send, this.scene});

  void requestReady() {
    if (!started) send('SaveLoadSystem', 'RequestReady', sessionId);
  }

  Map<String, dynamic>? receive(String message) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(message);
    } on FormatException {
      return null;
    }
    if (decoded is! Map<String, dynamic>) return null;
    if (decoded['messageType'] == 'ERROR') return decoded;
    if (decoded['sessionId'] != sessionId) return null;
    if (decoded['messageType'] == 'UNITY_READY' && !started) {
      send(
        'SaveLoadSystem',
        'BeginSession',
        jsonEncode({'sessionId': sessionId, 'sceneDataJson': scene ?? ''}),
      );
    }
    if (decoded['messageType'] == 'SESSION_STARTED') started = true;
    return decoded;
  }
}
