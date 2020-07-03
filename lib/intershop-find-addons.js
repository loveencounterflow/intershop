(function() {
  'use strict';
  var CND, DATOM, FS, PATH, alert, badge, cast, check, debug, declare, declare_check, echo, help, info, is_sad, isa, jr, new_datom, resolve_pkg, rpr, type_of, types, urge, validate, warn, whisper;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'INTERSHOP/FIND-ADDONS';

  debug = CND.get_logger('debug', badge);

  alert = CND.get_logger('alert', badge);

  whisper = CND.get_logger('whisper', badge);

  warn = CND.get_logger('warn', badge);

  help = CND.get_logger('help', badge);

  urge = CND.get_logger('urge', badge);

  info = CND.get_logger('info', badge);

  echo = CND.echo.bind(CND);

  //...........................................................................................................
  PATH = require('path');

  FS = require('fs');

  resolve_pkg = require('resolve-pkg');

  //...........................................................................................................
  types = require('./types');

  ({isa, validate, cast, check, declare, declare_check, is_sad, type_of} = types.export());

  DATOM = require('datom');

  ({new_datom} = DATOM.export());

  //...........................................................................................................
  ({jr} = CND);

  //-----------------------------------------------------------------------------------------------------------
  declare('ishop_addon_target', function(x) {
    return x === 'app' || x === 'ignore' || x === 'support' || x === 'rebuild';
  });

  //-----------------------------------------------------------------------------------------------------------
  this.validate_ipj_targets = function(addon) {
    var file_id, path, ref, relpath, target, type;
    //.........................................................................................................
    if ((type = type_of(addon.files)) !== 'object') {
      throw new Error(`^intershop/find-addons@478^ expected ${addon.ipj.relpath}#targets to be an object, found ${type}`);
    }
    //.........................................................................................................
    if (isa.empty(Object.keys(addon.files))) {
      throw new Error(`^intershop/find-addons@478^ ${addon.ipj.relpath}#targets has no keys`);
    }
    ref = addon.files;
    //.........................................................................................................
    for (file_id in ref) {
      ({path, relpath, target} = ref[file_id]);
      if (is_sad(check.is_file(path))) {
        throw new Error(`^intershop/find-addons@478^
file ${rpr(path)}
referred to in targets[ ${rpr(file_id)} ]
of ${addon.ipj.relpath}
does not exist`);
      }
      if (!isa.ishop_addon_target(target)) {
        throw new Error(`^intershop/find-addons@478^ unknown target ${rpr(target)} in ${addon.ipj.relpath}#targets[ ${rpr(file_id)} ]`);
      }
    }
    //.........................................................................................................
    return true;
  };

  //-----------------------------------------------------------------------------------------------------------
  this.find_addons = function() {
    var R, addons;
    validate.nonempty_text(process.env.intershop_host_path);
    addons = {};
    R = {addons};
    R = this._find_addons(R, 'guest', process.env.intershop_guest_path);
    R = this._find_addons(R, 'host', process.env.intershop_host_path);
    return new_datom('^intershop-addons', R);
  };

  //-----------------------------------------------------------------------------------------------------------
  this._find_addons = function(R, location, XXX_path) {
    var addon, aoid, cwd, error, file_id, ipj, package_json, path, ref, ref1, relpath, target, type, version;
    validate.intershop_addon_location(location);
    validate.nonempty_text(process.env.intershop_tmp_path);
    R.populate_sql_path = PATH.join(process.env.intershop_tmp_path, 'populate-addons-table.sql');
    R.host_path = XXX_path;
    package_json = require(PATH.join(R.host_path, 'package.json'));
//.........................................................................................................
    for (aoid in (ref = package_json.dependencies) != null ? ref : {}) {
      if (!aoid.startsWith('intershop-')) {
        continue;
      }
      //.......................................................................................................
      cwd = location === 'guest' ? process.env.intershop_guest_path : R.host_path;
      addon = {
        aoid,
        path: resolve_pkg(aoid, {cwd})
      };
      //.......................................................................................................
      if (addon.path == null) {
        warn(`^intershop/find-addons@478^ unable to locate ${aoid}; skipping`);
        continue;
      }
      addon.relpath = PATH.relative(process.cwd(), addon.path);
      //.......................................................................................................
      /* `ipj`: Intershop Package Json */
      addon.ipj = {};
      addon.ipj.path = PATH.join(addon.path, 'intershop-package.json');
      addon.ipj.relpath = PATH.relative(process.cwd(), addon.ipj.path);
      try {
        //.......................................................................................................
        ipj = require(addon.ipj.path);
      } catch (error1) {
        error = error1;
        if (error.code !== 'MODULE_NOT_FOUND') {
          throw error;
        }
        warn(`^intershop/find-addons@478^ unable to locate ${addon.ipj.relpath}; skipping`);
        continue;
      }
      //.......................................................................................................
      if ((type = type_of(ipj)) !== 'object') {
        throw new Error(`^intershop/find-addons@478^ expected ${addon.ipj.relpath} to contain type object, found ${type}`);
      }
      //.......................................................................................................
      if ((type = type_of(ipj['intershop-package-version'])) !== 'text') {
        throw new Error(`^intershop/find-addons@478^ expected ${addon.ipj.relpath}#version to be a text, found ${type}`);
      }
      //.......................................................................................................
      if ((version = ipj['intershop-package-version']) !== '1.0.0') {
        throw new Error(`^intershop/find-addons@478^ expected InterShop Package version 1.0.0, found ${ipj.version} in ${addon.ipj.relpath}#version to be a text, found ${type}`);
      }
      //.......................................................................................................
      addon.ipj.version = ipj['intershop-package-version'];
      addon.files = {};
      ref1 = ipj.files;
      for (file_id in ref1) {
        target = ref1[file_id];
        path = PATH.resolve(PATH.join(addon.path, file_id));
        relpath = PATH.relative(process.cwd(), path);
        addon.files[file_id] = {path, relpath, target};
      }
      //.......................................................................................................
      this.validate_ipj_targets(addon);
      R.addons[addon.aoid] = addon;
    }
    //.........................................................................................................
    return R;
  };

  //###########################################################################################################
  if (module === require.main) {
    (() => {
      var addon, addons, color, file, file_id, i, len, ref, ref1, relpath, results, target;
      addons = this.find_addons();
      ref = addons.addons;
      results = [];
      for (i = 0, len = ref.length; i < len; i++) {
        addon = ref[i];
        echo();
        echo(CND.white(`Addon: ${addon.aoid}`));
        echo(CND.grey(`  ${addon.path}`));
        ref1 = addon.files;
        for (file_id in ref1) {
          file = ref1[file_id];
          ({target, relpath} = file);
          color = (function() {
            switch (target) {
              case 'app':
                return CND.green;
              case 'ignore':
                return CND.grey;
              case 'support':
                return CND.gold;
              case 'rebuild':
                return CND.red;
              default:
                return CND.grey;
            }
          })();
          target = ((target + ' ').padEnd(10, '—')) + '>';
          echo(`  ${color(target)} ${CND.lime(relpath)}`);
        }
        results.push(echo());
      }
      return results;
    })();
  }

  // debug @find_addons()

}).call(this);

//# sourceMappingURL=intershop-find-addons.js.map