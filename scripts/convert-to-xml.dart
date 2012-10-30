import 'dart:json';
import 'dart:io';

Future readFile(String name) {
  var completer = new Completer();
  var future = completer.future;
  var file = new File(name);
  var inputStream = new StringInputStream(file.openInputStream());
  var buffer = new StringBuffer();
  inputStream.lineHandler = () {
  	buffer.add(inputStream.readLine());
  };
  inputStream.closeHandler = () => completer.complete(buffer.toString());
  return future;
}

String slugify(String title) {
  if (title == null) return '';
  // because string.replaceAll(regex) doesn't work in VM yet
  final numOrLetter = new RegExp(r'[a-z0-9-]');
  final space = new RegExp(r'\s');
  var buffer = new StringBuffer();
  var lower = title.toLowerCase();
  for (var i = 0; i < lower.length; i++) {
  	var char = lower[i];
  	if (char.contains(numOrLetter)) {
  	  buffer.add(char);
  	} else if (char.contains(space)) {
  	  buffer.add('-');
  	}
  }

  return buffer.toString();
}

String entityEscape(String content) {
	return content.replaceAll('&', '&amp;')
	              .replaceAll('<', '&lt;')
	              .replaceAll('>', '&gt;')
	              .replaceAll("'", '&apos;')
	              .replaceAll('"', '&quot;');
}

String code(String language, String content) {
  return '<code language="$language"><![CDATA[\n$content\n]]></code>';
}

void main() {
  readFile('/Users/sethladd/Code/dart-rosetta-stone/static/assets/rosetta_stone.json').then((contents) {
  	final obj = JSON.parse(contents);
  	final data = obj['feed']['entry'];
  	final rowNumRE = new RegExp(r'\d+');
  	final columnLetterRE = new RegExp(r'^(\w)');

  	var firstTheme = true;
  	var firstSynonym = true;

  	print('<?xml version="1.0"?>');
  	print('<synonyms>');

  	data.forEach((row) {
  	  var cellId = row['title']['\$t'];
  	  var rowNum = int.parseInt(rowNumRE.firstMatch(cellId)[0]);
  	  var columnLetter = columnLetterRE.firstMatch(cellId)[0];
  	  var content = row['content']['\$t'];

  	  if (rowNum == 1) return;

  	  if (columnLetter == 'A') {
  	  	if (!firstTheme) {
  	  		print('  </synonym>');
  	  		print('</theme>');
  	  	}
  	  	print('<theme id="theme-${slugify(content)}">');
  	  	print('  <title>${entityEscape(content)}</title>');
  	  	firstTheme = false;
  	  	firstSynonym = true;
  	  }

  	  if (columnLetter == 'B') {
  	  	if (!firstSynonym) {
  	  		print('  </synonym>');
  	  	}
  	  	print('  <synonym id="syn-${slugify(content)}">');
  	  	print('    <title>${entityEscape(content)}</title>');
  	  	firstSynonym = false;
  	  }

  	  if (columnLetter == 'C') {
  	  	print('    ${code('javascript', content)}');
  	  }

  	  if (columnLetter == 'D') {
  	  	print('    ${code('dart', content)}');
  	  }
  	});

  	print('  </synonym>');
  	print('</theme>');
  	print('</synonyms>');
  });
}
