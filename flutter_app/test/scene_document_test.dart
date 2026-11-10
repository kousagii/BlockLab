import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:unity_flutter/models/scene_document.dart';

Map<String, dynamic> legacyBlock(int shape) => {
  'blockName': 'Custom name $shape',
  'shapeType': shape,
  'position': {'x': shape * 2, 'y': 1, 'z': -3},
  'color': {'r': .2, 'g': .4, 'b': .6, 'a': 1},
  'widthOrRadius': 2,
  'height': 3,
  'length': 4,
};
String fixture() => jsonEncode({
  'messageType': 'SAVE_BUILD',
  'blocks': [for (var i = 0; i < 5; i++) legacyBlock(i)],
});

void main() {
  test(
    'legacy five-shape scene migrates with prefab half-cylinder orientation',
    () {
      final scene = SceneDocument.parse(fixture());
      expect(scene.blockCount, 5);
      expect(scene.data['schemaVersion'], 2);
      final blocks = scene.data['blocks'] as List;
      expect(blocks[0]['blockName'], 'Custom name 0');
      expect(blocks[4]['rotation']['x'], closeTo(.7071068, .000001));
      expect(blocks.map((dynamic b) => b['blockId']).toSet().length, 5);
      expect(SceneDocument.parse(scene.encode()).encode(), scene.encode());
    },
  );
  test('invalid dimensions, shape and nonunit rotation are rejected', () {
    for (final entry in [
      {'height': -1},
      {'shapeType': 5},
      {'length': 101},
      {
        'rotation': {'x': 0, 'y': 0, 'z': 0, 'w': 0},
      },
    ]) {
      final block = legacyBlock(0)..addAll(entry);
      expect(
        () => SceneDocument.parse(
          jsonEncode({
            'blocks': [block],
          }),
        ),
        throwsFormatException,
      );
    }
  });
  test('future schemas, duplicate IDs and corrupt thumbnail rejected', () {
    for (final scene in [
      {'schemaVersion': 3, 'blocks': []},
      {
        'blocks': [
          legacyBlock(0)..['blockId'] = 'same',
          legacyBlock(1)..['blockId'] = 'same',
        ],
      },
      {'blocks': [], 'imageBase64': 'invalid base64!'},
      {
        'blocks': [for (var i = 0; i < 2001; i++) legacyBlock(0)],
      },
    ]) {
      expect(
        () => SceneDocument.parse(jsonEncode(scene)),
        throwsFormatException,
      );
    }
  });
  test('version 2 requires rotation and preserves exact IDs', () {
    expect(
      () => SceneDocument.parse(
        jsonEncode({
          'schemaVersion': 2,
          'blocks': [legacyBlock(0)],
        }),
      ),
      throwsFormatException,
    );
    final scene = SceneDocument.parse(fixture());
    expect(
      SceneDocument.parse(scene.encode()).data['blocks'],
      scene.data['blocks'],
    );
  });
}
