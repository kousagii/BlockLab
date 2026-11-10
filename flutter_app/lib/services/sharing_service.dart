import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/isar_models.dart';
import '../models/scene_document.dart';

class SharingService {
  Future<void> share(BlockBuild build) async {
    final scene = SceneDocument.parse(build.sceneDataJson);
    final dir = await getTemporaryDirectory();
    final name = build.buildName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final file = File('${dir.path}/${name}_${build.id}.blocklab.json');
    await file.writeAsString(scene.encode());
    final files = [XFile(file.path, mimeType: 'application/json')];
    if (scene.thumbnail?.isNotEmpty ?? false) {
      final bytes = base64Decode(scene.thumbnail!);
      final png = bytes[0] == 137;
      final extension = png ? 'png' : 'jpg';
      final preview = File('${dir.path}/${name}_${build.id}.$extension');
      await preview.writeAsBytes(bytes);
      files.add(
        XFile(preview.path, mimeType: png ? 'image/png' : 'image/jpeg'),
      );
    }
    await SharePlus.instance.share(
      ShareParams(
        files: files,
        title: build.buildName,
        text: 'Built with BlockLab. Import the JSON file to edit this work.',
      ),
    );
  }

  Future<SceneDocument?> import() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withReadStream: true,
    );
    if (result == null) return null;
    final selected = result.files.single;
    if (selected.size > SceneDocument.maxBytes) {
      throw const FormatException('Scene exceeds 8 MB.');
    }
    final bytes = <int>[];
    final stream = selected.readStream;
    if (stream == null) {
      throw const FormatException('Could not read this file.');
    }
    await for (final chunk in stream) {
      bytes.addAll(chunk);
      if (bytes.length > SceneDocument.maxBytes) {
        throw const FormatException('Scene exceeds 8 MB.');
      }
    }
    return SceneDocument.parse(utf8.decode(bytes));
  }
}
