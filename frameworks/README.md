Used libraries

* http://jashkenas.github.com/coffee-script/extras/coffee-script.js
* http://code.jquery.com/jquery-1.4.4.min.js

awk command:

    awk '/^\*/ { system("curl -O " $2) }' README.md
