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

import 'dart:html';

typedef void OnSuccess(Document xmlContents);

final Map<String, String> synonymsUrls = const {
  'dart': 'assets/dart-samples.xml',
  'js': 'assets/js-samples.xml',
  'csharp': 'assets/csharp-samples.xml',
  'python': 'assets/python-samples.xml'
};

final Map<String, Document> synonymXmls = new Map<String, Document>();
final Map<String, DocumentFragment> synonymHtmls = new Map<String, DocumentFragment>();

const String transformUrl = "assets/transform.xslt";
Document xsltContents;

getUrl(String url, OnSuccess onSuccess) {
  var request = new HttpRequest();
  request.open('GET', url);
  request.onReadyStateChange.listen((_) {
    if (request.readyState == HttpRequest.DONE &&
        (request.status == 200 || request.status == 0)) {
      onSuccess(request.responseXml);
    }
  });
  request.overrideMimeType('text/xml');
  request.send();
}

processXml([String defaultLang = 'js']) {
  if (synonymXmls.length != synonymsUrls.length || xsltContents == null) return;

  var processor = new XsltProcessor();
  processor.importStylesheet(xsltContents);

  for (String key in synonymXmls.keys) {
    Document synonym = synonymXmls[key];
    synonymHtmls[key] = processor.transformToFragment(synonym, document);
  }

  displaySynonyms(defaultLang);
}

displaySynonyms(String lang) {
  var destination = query('#meat');
  var dartSynonyms = synonymHtmls['dart'];
  var otherSynonyms = synonymHtmls[lang];
  var dartSyns = dartSynonyms.queryAll('.synonym');
  for (var syn in dartSyns) {
    var destination = syn.query('.codes');
    var id = syn.attributes['id'];
    var code = otherSynonyms.query('.synonym[id="${id}"] .codes .span8');
    if (code != null) {
      destination.nodes.add(code);
    } else {
      var span8 = new DivElement()..classes.add('span8');
      var pre = new PreElement();
      pre.text = '// No equivalent synonym found.';
      span8.nodes.add(pre);
      destination.nodes.add(span8);
    }
  }

  destination.innerHtml = '';
  destination.nodes.add(dartSynonyms);

  window.postMessage('code:loaded', '*');
}

switchLanguage(Event e) {
  var lang = (e.target as SelectElement).value;
  processXml(lang);
}

main() {
  for (var lang in synonymsUrls.keys) {
    getUrl(synonymsUrls[lang], (Document contents) {
      synonymXmls[lang] = contents;
      processXml();
    });
  }

  getUrl(transformUrl, (contents) {
    xsltContents = contents;
    processXml();
  });

  var select = query('.language-choice select');
  if (select == null) {
    print("did not find language choice");
  } else {
    select.onChange.listen(switchLanguage);
  }
}