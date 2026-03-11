import 'dart:io';

void main() async {
  final process = await Process.start('flutter', ['analyze', '--no-pub'], runInShell: true);
  final file = File('analyze_output.txt');
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
