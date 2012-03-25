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

#import('dart:dom');

getUrl(String url, Function onSuccess) {
  var get = new XMLHttpRequest();
  get.open('GET', url);
  get.addEventListener('readystatechange', (event) {
    if (get.readyState == 4 && get.status == 200) {
      onSuccess(get);
    }
  });
  get.send();
}

main() {
  var synonymsUrl = "/assets/synonyms.xml";
  var transformUrl = "/assets/transform.xslt";

  var xmlContents;
  var xsltContents;

  processXML() {
    if (xmlContents == null || xsltContents == null) return;

    var processor = new XSLTProcessor();
    processor.importStylesheet(xsltContents);
    var result = processor.transformToFragment(xmlContents, document);
    var destination = document.getElementById('meat');
    destination.innerHTML = '';
    destination.appendChild(result);
    window.postMessage('code:loaded', '*');
  }

  getUrl(synonymsUrl, (xhr) {
    xmlContents = xhr.responseXML; 
    processXML();
  });

  getUrl(transformUrl, (xhr) {
    xsltContents = xhr.responseXML; 
    processXML();
  });
}