(function() {
  'use strict';
  var CND, FS, PATH, alert, badge, cast, check, debug, declare, declare_check, echo, help, info, is_sad, isa, jr, rpr, squel, type_of, types, urge, validate, warn, whisper;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'INTERSHOP/INTERSHOP-WRITE-ADDONS-BUILDSCRIPT';

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

  // resolve_pkg               = require 'resolve-pkg'
  // package_json              = require PATH.resolve PATH.join process.env.intershop_host_path, 'package.json'
  //...........................................................................................................
  types = new (require('intertype')).Intertype();

  ({isa, validate, cast, check, declare, declare_check, is_sad, type_of} = types.export());

  //...........................................................................................................
  ({jr} = CND);

  squel = (require('squel')).useFlavour('postgres');

  //-----------------------------------------------------------------------------------------------------------
  this.as_line = function(sql) {
    return sql.toString() + ';';
  };

  //-----------------------------------------------------------------------------------------------------------
  this.add_addon = function(aoid, path, relpath) {
    var sql;
    sql = squel.insert().into('ADDONS.addons').set('aoid', aoid).set('path', path).set('relpath', relpath);
    return this.as_line(sql);
  };

  //-----------------------------------------------------------------------------------------------------------
  this.add_file = function(aoid, target, path, relpath) {
    var sql;
    sql = squel.insert().into('ADDONS.files').set('aoid', aoid).set('target', target).set('path', path).set('relpath', relpath);
    return this.as_line(sql);
  };

  //-----------------------------------------------------------------------------------------------------------
  this.write_buildscript = function(addons) {
    var addon, aoid, file, file_id, path, ref, ref1, relpath, target;
    validate.object(addons);
    ref = addons.addons;
    for (aoid in ref) {
      addon = ref[aoid];
      echo();
      echo(`# ${'-'.repeat(108)}`);
      echo(`# Addon: ${addon.aoid}`);
      echo(`# ${addon.path}`);
      ref1 = addon.files;
      // echo """postgres_unpaged -c "select generate_series( 1, 9 );" """
      for (file_id in ref1) {
        file = ref1[file_id];
        ({target, relpath, path} = file);
        switch (target) {
          case 'rebuild':
            /* TAINT must escape critical characters */
            echo(`echo -e $orange$reverse $reset$orange '${path}'$reset`);
            echo(`postgres_unpaged -f ${path}`);
        }
      }
    }
    // else
    //   echo "# skipping #{target} file #{path}"
    echo(`echo -e $orange$reverse $reset$orange '${addons.populate_sql_path}'$reset`);
    echo(`postgres_unpaged -f ${addons.populate_sql_path}`);
    // echo "postgres_unpaged -c 'select ADDONS.import_python_addons();'" # not necessary, done by `U.py_init()`
    echo(`# ${'-'.repeat(108)}`);
    echo("# (end of addons)");
    echo();
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this.write_summary = function(addons) {
    var bin_path, mod_path;
    validate.object(addons);
    validate.nonempty_text(bin_path = process.env.intershop_guest_bin_path);
    validate.nonempty_text(mod_path = process.env.intershop_guest_modules_path);
    echo();
    // echo "#{bin_path}/intershop-nodexh #{mod_path}/intershop-find-addons.js"
    echo(`echo -e "$steel$reverse" 'ADDONS.files' "$reset\"`);
    echo(`postgres_unpaged -c 'select aoid, target, relpath from ADDONS.files order by aoid, target, relpath;'`);
    echo();
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this.write_sql_inserts = function(addons) {
    var addon, aoid, file, file_id, path, ref, ref1, relpath, target, write;
    validate.object(addons);
    FS.writeFileSync(addons.populate_sql_path, '');
    //.........................................................................................................
    write = function(x = '') {
      validate.text(x);
      FS.appendFileSync(addons.populate_sql_path, x + '\n');
      return null;
    };
    //.........................................................................................................
    write(`-- generated by ${__filename}`);
    write(`-- generated on ${(new Date()).toString()}`);
    write();
    ref = addons.addons;
    for (aoid in ref) {
      addon = ref[aoid];
      write();
      write('-- ' + '_'.repeat(105));
      write(`-- Addon: ${addon.aoid}`);
      write(this.add_addon(addon.aoid, addon.path, addon.relpath));
      ref1 = addon.files;
      for (file_id in ref1) {
        file = ref1[file_id];
        ({target, relpath, path} = file);
        write(this.add_file(addon.aoid, target, path, relpath));
      }
    }
    write();
    write('-- EOF');
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this.generate_scripts = function() {
    var addons;
    addons = (require('./intershop-find-addons')).find_addons();
    this.write_buildscript(addons);
    this.write_sql_inserts(addons);
    this.write_summary(addons);
    return null;
  };

  //###########################################################################################################
  if (module === require.main) {
    (() => {
      return this.generate_scripts();
    })();
  }

}).call(this);

//# sourceMappingURL=intershop-write-addons-buildscript.js.map