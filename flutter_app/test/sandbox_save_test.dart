import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_embed_unity/flutter_embed_unity.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unity_flutter/models/lesson.dart';
import 'package:unity_flutter/services/profile_service.dart';
import 'package:unity_flutter/design/app_theme.dart';
import 'package:unity_flutter/screens/sandbox_screen.dart';
import 'package:unity_flutter/services/isar_service.dart';
import 'package:unity_flutter/services/sharing_service.dart';
import 'scene_document_test.dart' show fixture;

class ControlledStore extends IsarService {
  ControlledStore() : super(database: Completer<Isar>().future);
  Completer<int> create = Completer<int>();
  int creates = 0, updates = 0;
  int? updatedId;
  @override
  Future<int> saveNewBuild(String name, String json, String? image) {
    creates++;
    return create.future;
  }

  @override
  Future<void> updateBuild(int id, String json, String? image) async {
    updates++;
    updatedId = id;
  }
}

class ControlledSharing extends SharingService {
  int pictures = 0;
  Completer<void>? pending;
  @override
  Future<void> sharePicture(String name, String imageBase64) async {
    pictures++;
    await pending?.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'save errors retry, concurrent responses do not duplicate, later saves update',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      const channel = MethodChannel('com.learntoflutter/flutter_embed_unity');
      final calls = <List<dynamic>>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'sendToUnity') {
          calls.add(call.arguments as List<dynamic>);
        }
        return null;
      });
      messenger.setMockMethodCallHandler(SystemChannels.platform_views, (
        call,
      ) async {
        if (call.method == 'create') return 1;
        if (call.method == 'resize') {
          final args = call.arguments as Map;
          return {'width': args['width'], 'height': args['height']};
        }
        return null;
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(channel, null);
        messenger.setMockMethodCallHandler(SystemChannels.platform_views, null);
      });
      final store = ControlledStore();
      final sharing = ControlledSharing();
      SharedPreferences.setMockInitialValues({});
      final profile = ProfileService(await SharedPreferences.getInstance());
      final lesson = Lesson({
        'id': 'sandbox-test',
        'title': 'Test lesson',
        'difficulty': 'Beginner',
        'source': 'Synthetic test',
        'steps': [
          {'text': 'Place a cube.'},
          {'text': 'Change its height.'},
        ],
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.build(Brightness.light),
          home: SandboxScreen(
            isarService: store,
            lesson: lesson,
            profile: profile,
            sharingService: sharing,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));
      final session =
          calls.firstWhere((c) => c[1] == 'RequestReady')[2] as String;
      Future<void> emit(Map<String, dynamic> data) async {
        final callback = tester
            .widget<EmbedUnity>(find.byType(EmbedUnity))
            .onMessageFromUnity!;
        callback(jsonEncode({...data, 'sessionId': session}));
        await tester.pump();
      }

      await emit({'messageType': 'UNITY_READY'});
      await emit({'messageType': 'SESSION_STARTED'});
      await emit({
        'messageType': 'WORKSPACE_STATE',
        'dirty': true,
        'canUndo': true,
        'revision': 3,
      });
      expect(find.text('Unsaved changes'), findsOneWidget);
      final runtime = tester.state(find.byType(EmbedUnity));
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(profile.stepForLesson('sandbox-test'), 1);
      expect(tester.state(find.byType(EmbedUnity)), same(runtime));
      expect(calls.where((c) => c[1] == 'BeginSession').length, 1);
      await tester.tap(find.byTooltip('Collapse lesson'));
      await tester.pumpAndSettle();
      expect(tester.state(find.byType(EmbedUnity)), same(runtime));
      final save = {
        ...jsonDecode(fixture()) as Map<String, dynamic>,
        'messageType': 'SAVE_BUILD',
        'revision': 3,
      };
      await tester.tap(find.byTooltip('Save build'));
      await tester.pump();
      await emit(save);
      await emit(save);
      expect(store.creates, 1);
      expect(calls.where((c) => c[1] == 'AcknowledgeSave'), isEmpty);
      store.create.completeError(StateError('Disk full'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Could not save your build.'), findsOneWidget);
      expect(find.text('Unsaved changes'), findsOneWidget);
      expect(calls.where((c) => c[1] == 'AcknowledgeSave'), isEmpty);
      store.create = Completer<int>();
      await tester.tap(find.byTooltip('Save build'));
      await tester.pump();
      await emit(save);
      store.create.complete(12);
      await tester.pumpAndSettle();
      expect(calls.where((c) => c[1] == 'AcknowledgeSave').length, 1);
      expect(
        jsonDecode(
          calls.lastWhere((c) => c[1] == 'AcknowledgeSave')[2] as String,
        )['revision'],
        3,
      );
      await tester.tap(find.byTooltip('Save build'));
      await tester.pump();
      await emit(save);
      await tester.pumpAndSettle();
      expect(store.creates, 2);
      expect(store.updates, 1);
      expect(store.updatedId, 12);

      await tester.tap(find.byTooltip('More workspace options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Share picture'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Save build'), findsNothing);
      expect(tester.state(find.byType(EmbedUnity)), same(runtime));
      expect(calls.where((c) => c[1] == 'BeginSession').length, 1);
      expect(calls.lastWhere((c) => c[1] == 'SetPictureMode')[2], 'true');
      sharing.pending = Completer<void>();
      await tester.tap(find.widgetWithText(FilledButton, 'Share picture'));
      await tester.pump();
      final request = calls.lastWhere((c) => c[1] == 'RequestPicture')[2];
      await emit({'messageType': 'PICTURE_READY', 'requestId': 'stale'});
      expect(sharing.pictures, 0);
      final picture = {
        'messageType': 'PICTURE_READY',
        'requestId': request,
        'imageBase64': 'test image',
      };
      await emit(picture);
      await emit(picture);
      expect(sharing.pictures, 1);
      sharing.pending!.complete();
      await tester.pumpAndSettle();
      expect(store.creates, 2);
      expect(store.updates, 1);
      expect(calls.where((c) => c[1] == 'AcknowledgeSave').length, 2);
      await tester.tap(find.widgetWithText(FilledButton, 'Share picture'));
      await tester.pump();
      final failedRequest = calls.lastWhere((c) => c[1] == 'RequestPicture')[2];
      await emit({'messageType': 'PICTURE_ERROR', 'requestId': failedRequest});
      await tester.pumpAndSettle();
      expect(
        find.text('Could not share the picture. Please retry.'),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Share picture'));
      await tester.pump(const Duration(seconds: 16));
      await tester.pumpAndSettle();
      expect(
        find.text('Could not take the picture. Please retry.'),
        findsOneWidget,
      );
      expect(calls.lastWhere((c) => c[1] == 'SetUiBlocked')[2], 'false');
      await tester.tap(find.text('Keep building'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Save build'), findsOneWidget);
      expect(find.text('Unsaved changes'), findsOneWidget);
      expect(profile.stepForLesson('sandbox-test'), 1);
      expect(tester.state(find.byType(EmbedUnity)), same(runtime));
      expect(calls.lastWhere((c) => c[1] == 'SetPictureMode')[2], 'false');
      await tester.pumpWidget(const SizedBox());
      debugDefaultTargetPlatformOverride = null;
    },
  );
}
