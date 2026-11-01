import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('No screen view file in views/ folders exceeds 300 lines of code', () {
    final libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue, reason: 'lib directory must exist');

    final dartFiles = libDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) {
          final normalized = file.path.replaceAll(r'\', '/');
          return normalized.endsWith('.dart') &&
              !normalized.endsWith('.g.dart') &&
              normalized.contains('/presentation/views/') &&
              !normalized.contains('/presentation/views/widgets/');
        })
        .toList();

    final allViewStats = <String, int>{};
    final violatingFiles = <String, int>{};

    for (final file in dartFiles) {
      final lines = file.readAsLinesSync();
      final relativePath = file.path.replaceAll(r'\', '/');
      allViewStats[relativePath] = lines.length;
      if (lines.length > 300) {
        violatingFiles[relativePath] = lines.length;
      }
    }

    // Print summary of all views
    final sortedAll = allViewStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    // ignore: avoid_print
    print('Scanned ${sortedAll.length} screen view files in views/:');
    for (final entry in sortedAll) {
      // ignore: avoid_print
      print('  ${entry.value.toString().padLeft(4)} lines : ${entry.key}');
    }

    if (violatingFiles.isNotEmpty) {
      final buffer = StringBuffer(
        'The following ${violatingFiles.length} screen file(s) in views/ exceed 300 lines of code:\n',
      );
      final sortedEntries = violatingFiles.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final entry in sortedEntries) {
        buffer.writeln('  - ${entry.key}: ${entry.value} lines (exceeds 300 limit)');
      }
      fail(buffer.toString());
    }
  });
}
