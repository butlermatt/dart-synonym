/*
   Copyright 2012 Google Inc. All Rights Reserved.

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/

#import('dart:html');
#import('dart:json');

slugify(String title) {
  if (title == null) return '';
  return title.toLowerCase()
              .replaceAll(new RegExp(@'[^a-z0-9\s-]'), '')
              .replaceAll(new RegExp(@'\s'), '-');
}

interface HTMLable {
  String toHTML();
}

interface Hideable {
  void hide();
  void show();
}

class Article implements HTMLable {
  List<Section> sections;

  Article(List<Section> this.sections);

  String toHTML() {
    String innerHTML = "";
    sections.forEach((Section section){
      innerHTML += section.toHTML();
    });
    return innerHTML;
  }
}

class Synonym implements HTMLable, Hideable {
  String title;
  String id;
  List<Row> examples;

  Synonym(this.title) {
    examples = <Row>[];
    id = 'syn-${slugify(title)}';
  }

  String toHTML() {
    String html = '';
    html += '<section class="synonym" id="${id}">';
    examples.forEach((Row row) {
      html += row.toHTML();
    });
    html += '</section>';
    return html;
  }

  void hide() {
    document.query('#${id}').classes.add('hide');
  }

  void show() {
    document.query('#${id}').classes.remove('hide');
  }
}

class Section implements HTMLable {
  List<Synonym> synonyms;
  String title;

  Section() : synonyms = <Synonym>[];

  String toHTML() {
    String out = '<section id="sec-${slugify(title)}" class="group">';

    // add the title
    out += '<div class="row"><div class="span16"><h1>${ title }</h1></div></div>';

    // print the synonyms
    synonyms.forEach((Synonym synonym) {
      out += synonym.toHTML();
    });

    out += "</section>";
    return out;
  }

  void hide() {
    document.query('#${id}').classes.add('hide');
  }

  void show() {
    document.query('#${id}').classes.remove('hide');
  }
}

class Note implements HTMLable {
  String note;

  String toHTML() {
    return '<div class="span3">${ note }</div>';
  }
}

class Kode implements HTMLable {
  String code;
  String type;

  String toHTML() {
    if( code == null || code.trim().isEmpty() ) {
      return '<div class="span8"></div>';
    } else {
      code = code.replaceAll('<','&lt;').replaceAll('>','&gt;');
      return '<div class="span8"><pre class="prettyprint ${type}">${ code }</pre></div>';
    }
  }
}

class JSCode extends Kode {
  JSCode() {
    type = "lang-js";
  }
}

class DartCode extends Kode {
  DartCode() {
    type = "lang-java";
  }
}

class Row implements HTMLable {
  String _title;
  String id;

  DartCode dart;
  JSCode js;
  Note note;

  Row() {
    dart = new DartCode();
    js   = new JSCode();
    note = new Note();
  }

  String get title() => _title;

  void set title(title) {
    _title = title;
    id = slugify(title);
  }

  String toHTML() {
    String out = "";
    if( title != null ) {
      out += '<div class="row"><div class="span16"><h2 id="${id}" ';
      out += ' class="section">${ title }</h2></div></div>';
    }
    out += '<div class="row">';

    out += js.toHTML() + dart.toHTML(); // + note.toHTML();

    out += "</div></div>";
    return out;
  }
}

class Jsonp { 
  Future run( String url ) {
    Completer completer = new Completer();
    Future future = completer.future;
    new XMLHttpRequest.getTEMPNAME(url, (request) {
      List codeSnippets = JSON.parse(request.responseText);
      List<Section> sections = codeReceived(codeSnippets);
      completer.complete(sections);
    });
    return future;
  }

  // Example JSON row:
  /*
  {
      "id": {
          "$t": "https://spreadsheets.google.com/feeds/cells/0AnmjtuFxqXtydG5VaDFya0FXVFhCTVRZdVdtS2lwbUE/od6/public/basic/R2C1"
      },
      "updated": {
          "$t": "2012-01-03T23:06:59.696Z"
      },
      "category": [{
          "scheme": "http://schemas.google.com/spreadsheets/2006",
          "term": "http://schemas.google.com/spreadsheets/2006#cell"
      }],
      "title": {
          "type": "text",
          "$t": "A2"
      },
      "content": {
          "type": "text",
          "$t": "Getting Started"
      },
      "link": [{
          "rel": "self",
          "type": "application/atom+xml",
          "href": "https://spreadsheets.google.com/feeds/cells/0AnmjtuFxqXtydG5VaDFya0FXVFhCTVRZdVdtS2lwbUE/od6/public/basic/R2C1"
      }]
  }
  */

  // Parse the JSON that comes back from the spreadsheet
  List<Section> codeReceived(List jsonObjects) {
    List data = jsonObjects["feed"]["entry"];

    List<Section> sections = <Section>[];

    var currentIndex = "0";
    var currentRow;
    var currentSection;
    var currentSynonym;
    var currentPair = [];

    data.forEach((row) {
      // Get the row number
      String i = (new RegExp(@"(\d+)")).firstMatch( row['title']['\$t'] )[0];

      // Get the column info
      String title = row['title']['\$t'];  // looks like C3
      String match = (new RegExp(@"^(\w)")).firstMatch( title )[0];

      String content = row['content']['\$t'];

      if( i != '1' ) { // skip the headers
        if( match == "A" ) {
          // Whenever a value is in column A, create a new section
          currentSection = new Section();
          sections.add( currentSection );
        }

        if( match == 'B' ) {
          // Whenever a value is in column B, create a new Synonym
          currentSynonym = new Synonym(content);
          currentSection.synonyms.add(currentSynonym);
        }

        if( i != currentIndex ) {
          // If the current row has changed, create a new row
          currentRow = new Row();
          if (currentSynonym != null) {
            currentSynonym.examples.add( currentRow );
          }
          currentIndex = i;
        }

        // fill in the content
        if( match == "A") {
          currentSection.title = content;
        } else if( match == "B" ) {
          currentRow.title = content;
        } else if( match == "C" ) {
          // create a new JS code bit
          currentRow.js.code = content;
        } else if( match == "D" ) {
          // create a new Dart code bit
          currentRow.dart.code = content;
        } else if( match == "E" ) {
          // create a note
          currentRow.note.note = content;
        }
      }

    });

    return sections;
  }
 
} 

main() {
  String feedUrl = "/assets/rosetta_stone.json";

  var j = new Jsonp();
  j.run( feedUrl ).then((sections) {
    var article = new Article(sections);
    var html = article.toHTML();

    document.query('#meat').innerHTML = html;
    
    // signal to the main page to start syntax highlighting
    window.postMessage('code:loaded', '*');
  });
 
}