import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:unity_flutter/services/unity_bridge.dart';

void main() {
  test(
    'cold or warm readiness initializes once after session acknowledgement',
    () {
      final calls = <List<String>>[];
      final bridge = UnityBridge(
        sessionId: 'session-a',
        scene: 'saved scene',
        send: (object, method, data) => calls.add([object, method, data]),
      );
      bridge.requestReady();
      expect(calls.single[1], 'RequestReady');
      bridge.receive(
        jsonEncode({'messageType': 'UNITY_READY', 'sessionId': 'session-a'}),
      );
      expect(calls.last[1], 'BeginSession');
      expect(jsonDecode(calls.last[2])['sceneDataJson'], 'saved scene');
      bridge.receive(
        jsonEncode({
          'messageType': 'SESSION_STARTED',
          'sessionId': 'session-a',
        }),
      );
      final count = calls.length;
      bridge.receive(
        jsonEncode({'messageType': 'UNITY_READY', 'sessionId': 'session-a'}),
      );
      bridge.requestReady();
      expect(calls.length, count);
      expect(bridge.started, isTrue);
    },
  );
  test('stale sessions and unstructured messages cannot load or save', () {
    final calls = <String>[];
    final bridge = UnityBridge(
      sessionId: 'new',
      send: (_, method, data) => calls.add(method),
    );
    expect(bridge.receive('UNITY_READY'), isNull);
    expect(bridge.receive('[]'), isNull);
    expect(
      bridge.receive('{"messageType":"SAVE_BUILD","sessionId":"old"}'),
      isNull,
    );
    bridge.receive('{"messageType":"UNITY_READY","sessionId":"old"}');
    expect(calls, isEmpty);
  });
}
