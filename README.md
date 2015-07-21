# glg-name-match
A polymer component that provides a declarative way to drop in a fuzzy name matcher based on a cerca index using ngrams
and custom scoring/sorting designed to provide results for typeahead.

To see the events, attributes, and methods of the glg-name-match polymer
component, take a look at the [literate coffeescript source files](src/glg-name-match.litcoffee).

## usage
Include the glg-name-match polymer component in your package.json.

    "glg-name-match":"git://github.com/custom-elements/glg-name-match#master"

Import the glg-name-match.html in your HTML.

    <link rel="import" href="node_modules/glg-name-match/src/glg-name-match.html">

## polyfills
Using the glg-name-match polymer component of course presumes that the
browsers in use will support:
* custom elements
* HTML imports
* templates
* shadow dom

If older browsers need to be supported, you should include the
webcomponents polyfill in your HTML.

`<script src="node_modules/webcomponents.js/webcomponents.js"></script>`
