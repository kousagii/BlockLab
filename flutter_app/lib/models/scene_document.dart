import 'dart:convert';
import 'dart:math';

/// The portable, editable scene format. Legacy records are migrated on read.
class SceneDocument {
  static const maxBytes = 8 * 1024 * 1024;
  static const maxBlocks = 2000;
  final Map<String, dynamic> data;
  SceneDocument._(this.data);
  int get blockCount => (data['blocks'] as List).length;
  String? get thumbnail => data['imageBase64'] as String?;
  String encode() => jsonEncode(data);

  factory SceneDocument.parse(String text) {
    if (utf8.encode(text).length > maxBytes) {
      throw const FormatException('Scene exceeds 8 MB.');
    }
    final raw = jsonDecode(text);
    if (raw is! Map<String, dynamic>) {
      throw const FormatException('Expected a scene object.');
    }
    final version = raw['schemaVersion'] ?? 1;
    if (version is! int || version < 1 || version > 2) {
      throw const FormatException('Unsupported scene version.');
    }
    final blocks = raw['blocks'];
    if (blocks is! List || blocks.length > maxBlocks) {
      throw const FormatException('Invalid block list (maximum 2000).');
    }
    double number(dynamic value, double min, double max) {
      if (value is! num || !value.isFinite || value < min || value > max) {
        throw const FormatException('Invalid block dimensions or coordinates.');
      }
      return value.toDouble();
    }

    Map<String, double> vector(
      dynamic value,
      List<String> axes,
      double min,
      double max,
    ) {
      if (value is! Map) {
        throw const FormatException('Missing block properties.');
      }
      return {for (final axis in axes) axis: number(value[axis], min, max)};
    }

    final ids = <String>{};
    final normalized = <Map<String, dynamic>>[];
    for (var i = 0; i < blocks.length; i++) {
      final b = blocks[i];
      if (b is! Map<String, dynamic> ||
          b['shapeType'] is! int ||
          b['shapeType'] < 0 ||
          b['shapeType'] > 4) {
        throw const FormatException('Unknown block shape.');
      }
      final id = b['blockId'] ?? 'legacy-$i';
      if (id is! String || id.isEmpty || id.length > 128 || !ids.add(id)) {
        throw const FormatException('Invalid or duplicate block ID.');
      }
      final name = b['blockName'] ?? 'Block ${i + 1}';
      if (name is! String || name.length > 200) {
        throw const FormatException('Invalid block name.');
      }
      final rotation =
          b['rotation'] ??
          (version == 1
              ? (b['shapeType'] == 4
                    ? {'x': sqrt(.5), 'y': 0, 'z': 0, 'w': sqrt(.5)}
                    : {'x': 0, 'y': 0, 'z': 0, 'w': 1})
              : null);
      final q = vector(rotation, ['x', 'y', 'z', 'w'], -1, 1);
      final magnitude = q.values.fold<double>(0, (sum, n) => sum + n * n);
      if ((magnitude - 1).abs() > .01) {
        throw const FormatException('Invalid block rotation.');
      }
      normalized.add({
        'blockId': id,
        'blockName': name,
        'shapeType': b['shapeType'],
        'position': vector(b['position'], ['x', 'y', 'z'], -10000, 10000),
        'rotation': q,
        'color': vector(b['color'], ['r', 'g', 'b', 'a'], 0, 1),
        for (final key in ['widthOrRadius', 'height', 'length'])
          key: number(b[key], .1, 100),
      });
    }
    final thumbnail = raw['imageBase64'];
    if (thumbnail != null && thumbnail is! String) {
      throw const FormatException('Invalid thumbnail.');
    }
    if (thumbnail is String && thumbnail.isNotEmpty) {
      if (thumbnail.length > 2 * 1024 * 1024) {
        throw const FormatException('Thumbnail exceeds 2 MB.');
      }
      final bytes = base64Decode(thumbnail);
      final jpeg = bytes.length > 3 && bytes[0] == 255 && bytes[1] == 216;
      final png = bytes.length > 8 && bytes[0] == 137 && bytes[1] == 80;
      if (!jpeg && !png) {
        throw const FormatException('Invalid thumbnail image.');
      }
    }
    return SceneDocument._({
      'schemaVersion': 2,
      'messageType': 'SAVE_BUILD',
      if (raw['sessionId'] is String) 'sessionId': raw['sessionId'],
      'imageBase64': thumbnail,
      'blocks': normalized,
    });
  }
}
