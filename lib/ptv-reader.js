(function() {
  'use strict';
  var FS, PATH, PTVR, log, minimatch, rpr;

  //###########################################################################################################
  FS = require('fs');

  PATH = require('path');

  rpr = (require('util')).inspect;

  minimatch = require('minimatch');

  //-----------------------------------------------------------------------------------------------------------
  this.split_line = function(line) {
    var _, match, path, type, value;
    /* TAINT should check that type looks like `::...=` */
    if ((match = line.trim().match(/^(\S+)\s+::([^=]+)=\s*$/)) != null) {
      [_, path, type] = match;
      value = '';
    } else if ((match = line.trim().match(/^(\S+)\s+::([^=]+)=\s+(.*)$/))) {
      [_, path, type, value] = match;
    } else {
      throw new Error(`not a legal PTV line: ${rpr(line)}`);
    }
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
  this.hash_from_paths = function(...paths) {
    var R, i, len, path;
    R = {};
    for (i = 0, len = paths.length; i < len; i++) {
      path = paths[i];
      this.update_hash_from_path(path, R);
    }
    return R;
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

  //-----------------------------------------------------------------------------------------------------------
  this.match = function(facets, pattern, settings) {
    var R, key, matcher, value;
    R = [];
    matcher = new minimatch.Minimatch(pattern, settings);
    return (function() {
      var results;
      results = [];
      for (key in facets) {
        value = facets[key];
        if (matcher.match(key)) {
          results.push([key, value]);
        }
      }
      return results;
    })();
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
    log('42992', PTVR.hash_from_paths(PATH.join(__dirname, '../intershop.ptv')));
  }

}).call(this);

//# sourceMappingURL=ptv-reader.js.map