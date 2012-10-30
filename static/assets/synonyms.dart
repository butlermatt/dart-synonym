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
  'csharp': 'assets/csharp-samples.xml'
};

final Map<String, Document> synonymXmls = new Map<String, Document>();
final Map<String, DocumentFragment> synonymHtmls = new Map<String, DocumentFragment>();

const String transformUrl = "assets/transform.xslt";
Document xsltContents;

getUrl(String url, OnSuccess onSuccess) {
  var get = new HttpRequest();
  get.open('GET', url);
  get.on.readyStateChange.add((event) {
    if (get.readyState == 4 && get.status == 200) {
      onSuccess(get.responseXML);
    }
  });
  get.send();
}

processXml() {
  if (synonymXmls.length != 3 || xsltContents == null) return;
  
  var processor = new XSLTProcessor();
  processor.importStylesheet(xsltContents);

  for (String key in synonymXmls.keys) {
    Document synonym = synonymXmls[key];
    synonymHtmls[key] = processor.transformToFragment(synonym, document);
  }
  
  print("all done");
  
  displaySynonyms();
  
//  var destination = query('#meat');
//  destination.innerHTML = '';
//  destination.nodes.add(result);
//  window.postMessage('code:loaded', '*');
}

displaySynonyms() {
  var destination = query('#meat');
  var dartSynonyms = synonymHtmls['dart'];
  var jsSynonyms = synonymHtmls['js'];
  var dartSyns = dartSynonyms.queryAll('.synonym');
  for (var syn in dartSyns) {
    var id = syn.attributes['id'];
    var code = jsSynonyms.query('.synonym[id="${id}"] .codes .span8');
    if (code != null) {
      syn.query('.codes').nodes.add(code);
    } else {
      print("did not find syn for $id");
    }
  }
  
  destination.innerHTML = '';
  destination.nodes.add(dartSynonyms);
  
  print("done here");
  
  window.postMessage('code:loaded', '*');
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
}