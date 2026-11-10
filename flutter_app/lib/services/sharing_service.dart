import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/isar_models.dart';
import '../models/scene_document.dart';

class SharingService {
  final Future<Directory> Function() _temporaryDirectory;
  final Future<ShareResult> Function(ShareParams) _shareFiles;

  SharingService({
    Future<Directory> Function()? temporaryDirectory,
    Future<ShareResult> Function(ShareParams)? shareFiles,
  }) : _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory,
       _shareFiles = shareFiles ?? SharePlus.instance.share;

  Future<void> exportBuild(BlockBuild build) async {
    final scene = SceneDocument.parse(build.sceneDataJson);
    final dir = await _temporaryDirectory();
    final name = build.buildName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final file = File('${dir.path}/${name}_${build.id}.blocklab.json');
    await file.writeAsString(scene.encode());
    await _shareFiles(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        title: build.buildName,
        text: 'Import this file into BlockLab to edit the build.',
      ),
    );
  }

  Future<void> sharePicture(String name, String imageBase64) async {
    if (imageBase64.length > 16 * 1024 * 1024) {
      throw const FormatException('Picture is too large.');
    }
    final bytes = base64Decode(imageBase64);
    if (bytes.length < 4 || bytes[0] != 0xff || bytes[1] != 0xd8) {
      throw const FormatException('Could not read the picture. Please retry.');
    }
    final dir = await _temporaryDirectory();
    final safeName = name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final file = File(
      '${dir.path}/${safeName}_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await file.writeAsBytes(bytes, flush: true);
    await _shareFiles(
      ShareParams(
        files: [XFile(file.path, mimeType: 'image/jpeg')],
        title: name,
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
