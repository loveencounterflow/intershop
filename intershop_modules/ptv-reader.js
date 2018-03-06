// Generated by CoffeeScript 2.2.1
(function() {
  'use strict';
  var FS, PATH, PTVR, log, rpr;

  //###########################################################################################################
  FS = require('fs');

  PATH = require('path');

  rpr = (require('util')).inspect;

  //-----------------------------------------------------------------------------------------------------------
  this.split_line = function(line) {
    /* TAINT should check that type looks like `::...=` */
    var path, type, value;
    [path, type, value] = line.trim().split(/\s+/, 3);
    type = type.replace(/^::/, '');
    type = type.replace(/=$/, '');
    return {path, type, value};
  };

  //-----------------------------------------------------------------------------------------------------------
  this.resolve = function(text, values) {
    return text.replace(/\$\{([^}]+)}/, function($0, $1, position, input) {
      var R;
      if ((position > 0) && (input[position - 1] === '\\')) {
        return $0;
      }
      if ((R = values[$1]) === void 0) {
        throw new Error(`unknown key ${rpr($1)}`);
      }
      return R.value;
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.hash_from_path = function(path) {
    return this.update_hash_from_path(path, {});
  };

  //-----------------------------------------------------------------------------------------------------------
  this.update_hash_from_path = function(path, R) {
    var i, len, line, ref, source, type, value;
    source = FS.readFileSync(path, {
      encoding: 'utf-8'
    });
    ref = source.split('\n');
    for (i = 0, len = ref.length; i < len; i++) {
      line = ref[i];
      if ((line.match(/^\s*$/)) != null) {
        continue;
      }
      if ((line.match(/^\s*#/)) != null) {
        continue;
      }
      ({path, type, value} = this.split_line(line));
      value = this.resolve(value, R);
      R[path] = {type, value};
    }
    return R;
  };

  //-----------------------------------------------------------------------------------------------------------
  this.options_as_facet_json = function(x) {
    return JSON.stringify(x);
  };

  //-----------------------------------------------------------------------------------------------------------
  this.options_as_untyped_json = function(x) {
    var R, facet, key;
    R = {};
    for (key in x) {
      facet = x[key];
      R[key] = facet.value;
    }
    return JSON.stringify(R);
  };

  //###########################################################################################################
  if (module.parent == null) {
    log = console.log;
    PTVR = this;
    log('42992', PTVR.resolve('before\\${middle}after', {}));
    log('42992', PTVR.resolve('before${middle}after', {
      middle: {
        value: '---something---'
      }
    }));
    log('42992', PTVR.hash_from_path(PATH.join(__dirname, '../intershop.ptv')));
  }

}).call(this);

//# sourceMappingURL=ptv-reader.js.map
