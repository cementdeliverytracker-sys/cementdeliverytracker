// Basic guardrail to prevent direct Firebase access from presentation/entry layers.
// Run with: dart run tool/architecture_check.dart

import 'dart:io';

const disallowedImports = <String>{
  "package:cloud_firestore/cloud_firestore.dart",
  "package:firebase_storage/firebase_storage.dart",
};

const guardPaths = <String>{
  'lib/main.dart',
  'lib/features/auth/presentation/providers',
};

void main() {
  final violations = <String>[];

  for (final path in guardPaths) {
    final entity = FileSystemEntity.isDirectorySync(path)
        ? Directory(path)
        : File(path);

    if (entity is File) {
      _scanFile(entity, violations);
    } else if (entity is Directory) {
      for (final entry in entity.listSync(recursive: true)) {
        if (entry is File && entry.path.endsWith('.dart')) {
          _scanFile(entry, violations);
        }
      }
    }
  }

  if (violations.isNotEmpty) {
    stderr.writeln(
      'Architecture guard failed: direct Firebase imports detected',
    );
    for (final v in violations) {
      stderr.writeln(' - $v');
    }
    exitCode = 1;
  }
}

void _scanFile(File file, List<String> violations) {
  final content = file.readAsStringSync();
  for (final banned in disallowedImports) {
    if (content.contains("import '$banned';") ||
        content.contains('import "$banned";')) {
      violations.add('${file.path} -> $banned');
    }
  }
}
