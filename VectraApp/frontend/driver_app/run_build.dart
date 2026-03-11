import 'dart:io';

void main() async {
  final process = await Process.start('flutter', ['build', 'web', '--no-tree-shake-icons'], runInShell: true);
  final file = File('build_output.txt');
  final sink = file.openWrite();
  
  process.stdout.listen((data) {
    sink.add(data);
  });
  
  process.stderr.listen((data) {
    sink.add(data);
  });
  
  await process.exitCode;
  await sink.close();
}
