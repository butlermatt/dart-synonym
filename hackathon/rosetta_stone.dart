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

  toHTML() {
    if( code == "" ) {
      return "<div class=\"span6\"></div>";
    } else {
      return "<div class=\"span6\"><pre>${ code }</pre></div>";
    }
  }
}

class Row {
  String title = "&nbsp;";

  Kode dart;
  Kode js;
  Note note;

  Row() {
    dart = new Kode();
    js   = new Kode();
    note = new Note();
  }

  toHTML() {
    String out = "<div class=\"row\"><div class=\"span1\"><strong>${ title }</strong></div><div class=\"row\">";

    out += js.toHTML() + dart.toHTML() + note.toHTML();

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

      // Get the column
      String t = row['title']['\$t'];
      String r = (new RegExp(@"^(\w)")).firstMatch( t )[0];

      String c = row['content']['\$t'];

      if( i != '1' ) {
        if( r == "A" ) {
          currentSection = new Section();
          out.add( currentSection );
        }

        if( i != currentIndex ) {
          currentRow = new Row();
          // print(currentSection.toString());
          // print(currentSection.rows.toString());
          currentSection.rows.add( currentRow );
          currentIndex = i;
        }

        // fill in the content
        if( r == "A") {
          currentSection.title = c;
        } else if( r == "B" ) {
          // create a new Row
          currentRow.title = c;
        } else if( r == "C" ) {
          // create a new JS code bit
          currentRow.js.code = c;
        } else if( r == "D" ) {
          // create a new Dart code bit
          currentRow.dart.code = c;
        } else {
          // create a note
          currentRow.note.note = c;
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

  var j = new Jsonp();
  j.run( feed );
}