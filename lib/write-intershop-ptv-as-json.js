(function() {
  'use strict';
  var FS, PATH, comma, echo, i, idx, key, keys, last_idx, ref, settings, value;

  //###########################################################################################################
  FS = require('fs');

  PATH = require('path');

  echo = console.log;

  ({settings} = (require('./intershop')).new_intershop());

  keys = (Object.keys(settings)).sort();

  last_idx = keys.length - 1;

  echo('{');

  for (idx = i = 0, ref = last_idx; (0 <= ref ? i <= ref : i >= ref); idx = 0 <= ref ? ++i : --i) {
    key = keys[idx];
    value = settings[key];
    comma = idx === last_idx ? '' : ',';
    echo((JSON.stringify(key)) + ': ' + (JSON.stringify(value)) + comma);
  }

  echo('}');

}).call(this);

//# sourceMappingURL=write-intershop-ptv-as-json.js.map