import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:unity_flutter/models/isar_models.dart';
import 'package:unity_flutter/models/scene_document.dart';
import 'package:unity_flutter/services/sharing_service.dart';
import 'scene_document_test.dart' show fixture;

void main() {
  test(
    'editable export and picture share attach separate file types',
    () async {
      final dir = await Directory.systemTemp.createTemp('blocklab-sharing-');
      addTearDown(() => dir.delete(recursive: true));
      final shared = <ShareParams>[];
      final service = SharingService(
        temporaryDirectory: () async => dir,
        shareFiles: (params) async {
          shared.add(params);
          return const ShareResult('', ShareResultStatus.dismissed);
        },
      );
      final original = fixture();
      final build = BlockBuild()
        ..id = 8
        ..buildName = 'A / colorful build'
        ..sceneDataJson = original;
      await service.exportBuild(build);
      expect(shared.single.files, hasLength(1));
      final exported = shared.single.files!.single;
      expect(exported.mimeType, 'application/json');
      expect(exported.path, endsWith('.blocklab.json'));
      expect(
        SceneDocument.parse(
          await File(exported.path).readAsString(),
        ).blockCount,
        5,
      );
      final bytes = [0xff, 0xd8, 0xff, 0xe0, 0, 16, 0xff, 0xd9];
      await service.sharePicture(build.buildName, base64Encode(bytes));
      expect(shared.last.files, hasLength(1));
      final picture = shared.last.files!.single;
      expect(picture.mimeType, 'image/jpeg');
      expect(await File(picture.path).readAsBytes(), bytes);
      expect(shared.last.text, isNull);
      expect(build.sceneDataJson, original);
      expect(build.id, 8);
      await expectLater(
        service.sharePicture('bad', 'broken'),
        throwsFormatException,
      );
      expect(shared, hasLength(2));
    },
  );
}
