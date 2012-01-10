#import('dart:html');
#import('dart:json');

class Section {
  List rows;
  String foo;
  String title = "Title";

  Section() {
    rows = [];
  }

  toHTML() {
    String out = "<section>";

    // add the title
    out += "<div class=\"page-header\"><h1>${ title }</h1></div>";

    // print the rows
    rows.forEach((row){
      out += row.toHTML();
    });

    out += "</section>";
    return out;
  }
}

class Note {
  String note = "";

  toHTML() {
    return "<div class=\"span3\">${ note }</div>";
  }
}

class Kode {
  String code = "";
  String type = "";

  toHTML() {
    if( code == "" || code == " " ) {
      return "<div class=\"span8\"></div>";
    } else {
      code = code.replaceAll('<','&lt;').replaceAll('>','&gt;');
      return "<div class=\"span8\"><pre class=\"prettyprint ${type}\">${ code }</pre></div>";
    }
  }
}

class JSCode extends Kode {
  JSCode() {
    type = "lang-js";
  }
  //String type = "lang-js";
}

class DartCode extends Kode {
  DartCode() {
    type = "lang-java";
  }
  //String type = "lang-java";
}

class Row {
  String title = "";

  DartCode dart;
  JSCode js;
  Note note;

  Row() {
    dart = new DartCode();
    js   = new JSCode();
    note = new Note();
  }

  toHTML() {
    String out = "";
    if( title != '' ) {
      print( title );
      out += "<div class=\"row\"><h2 class=\"section\">${ title }</h2></div>";
    }
    out += "<div class=\"row\">";

    out += js.toHTML() + dart.toHTML(); // + note.toHTML();

    out += "</div></div>";
    return out;
  }
}

class Jsonp { 
  void run( String url ) { 
    window.on.message.add(codeReceived, false); 
    ScriptElement s = new Element.tag('script');

    // // Jsonp call 
    s.src = url;

    document.nodes.add(s); 
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
  void codeReceived(MessageEvent e) {
    List data = JSON.parse(e.data);
    data = data["feed"]["entry"];

    List out = [];

    var currentIndex = "0";
    var currentRow = null;
    var currentSection = null;
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
          out.add( currentSection );
        }

        if( i != currentIndex ) {
          // If the current row has changed, create a new row
          currentRow = new Row();
          currentSection.rows.add( currentRow );
          currentIndex = i;
        }

        // fill in the content
        if( match == "A") {
          currentSection.title = content;
        } else if( match == "B" ) {
          // create a new Row
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

    String innerHTML = "";
    out.forEach((o){
      innerHTML += o.toHTML();
    });

    document.query('#meat').innerHTML = innerHTML;
  }
}

main() {
  String key = "0AnmjtuFxqXtydG5VaDFya0FXVFhCTVRZdVdtS2lwbUE";
  String worksheet = "od6";
  String feed = "https://spreadsheets.google.com/feeds/cells/${key}/${worksheet}/public/basic?alt=json-in-script&callback=printStone";

  // String feed = "/assets/rosetta_stone.json";

  var j = new Jsonp();
  j.run( feed );
}