(function() {
  'use strict';
  var CND, DB, INTERSHOP, PATH, RMDSKS, alert, badge, debug, echo, help, info, log, parallel, rpr, shop, urge, warn, whisper;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'REFRESH-MIRAGE-DATASOURCES';

  log = CND.get_logger('plain', badge);

  debug = CND.get_logger('debug', badge);

  info = CND.get_logger('info', badge);

  warn = CND.get_logger('warn', badge);

  alert = CND.get_logger('alert', badge);

  help = CND.get_logger('help', badge);

  urge = CND.get_logger('urge', badge);

  whisper = CND.get_logger('whisper', badge);

  echo = CND.echo.bind(CND);

  //...........................................................................................................
  PATH = require('path');

  //...........................................................................................................
  parallel = require('./parallel-promise');

  DB = require('./db');

  //...........................................................................................................
  // INTERSHOP                 = require '..'
  // O                         = INTERSHOP.settings
  // PTVR                      = INTERSHOP.PTV_READER
  INTERSHOP = require('../lib/intershop');

  shop = INTERSHOP.new_intershop(process.env['intershop_host_path']);

  // for k of process.env
  //   continue if k.startsWith '_'
  //   continue if /^[A-Z]/.test k
  //   debug '^37778^', ( CND.yellow k ), ( CND.blue process.env[ k ] )
  // # debug shop.settings
  // process.exit 11
  /* TAINT PTV reader should cast values */
  /* TAINT need API (proxy?) so we get error for non-existant names */
  //===========================================================================================================

  //-----------------------------------------------------------------------------------------------------------
  this.get_dsk_definitions = function() {
    var R, _, dsk, i, idx, intershop_host_path, len, match, mode, path, ref, settings_path, type, value;
    R = {};
    intershop_host_path = shop.settings['intershop/host/path'].value;
    ref = shop.PTV_READER.match(shop.settings, 'intershop/mirage/dsk/**');
    //.........................................................................................................
    for (i = 0, len = ref.length; i < len; i++) {
      [settings_path, {type, value}] = ref[i];
      dsk = settings_path.replace(/^intershop\/mirage\/dsk\//g, '');
      //.......................................................................................................
      if (type !== 'url') {
        throw new Error(`expected type 'url', got type ${rpr(type)}`);
      }
      //.......................................................................................................
      if ((match = value.match(/^([^:]+):(.*$)/)) == null) {
        throw new Error(`expected value like 'mode:/path/to/source...', got ${rpr(value)}`);
      }
      [_, mode, path] = match;
      path = PATH.resolve(intershop_host_path, path);
      //.......................................................................................................
      if ((match = dsk.match(/-([0-9]+)$/)) != null) {
        [_, idx] = match;
        idx = (parseInt(idx, 10)) - 1;
        dsk = dsk.slice(0, match.index);
        (R[dsk] != null ? R[dsk] : R[dsk] = [])[idx] = {mode, path};
      } else {
        //.......................................................................................................
        (R[dsk] != null ? R[dsk] : R[dsk] = []).push({path, mode});
      }
    }
    //.........................................................................................................
    return R;
  };

  //-----------------------------------------------------------------------------------------------------------
  this._walk_dsk_pathmodes = function*(dsk_definitions) {
    var dsk, mode, path, pathmodes, results;
    results = [];
    for (dsk in dsk_definitions) {
      pathmodes = dsk_definitions[dsk];
      results.push((yield* (function*() {
        var i, len, results1;
        results1 = [];
        for (i = 0, len = pathmodes.length; i < len; i++) {
          ({path, mode} = pathmodes[i]);
          results1.push((yield {dsk, path, mode}));
        }
        return results1;
      })()));
    }
    return results;
  };

  //-----------------------------------------------------------------------------------------------------------
  this.procure_mirage_datasources = async function(dsk_definitions) {
    var dsk, mode, path, ref, tasks, x;
    tasks = [];
    ref = this._walk_dsk_pathmodes(dsk_definitions);
    for (x of ref) {
      ({dsk, path, mode} = x);
      (function(dsk, path, mode) {
        return tasks.push(async function() {
          var q;
          q = ['select MIRAGE.procure_dsk_pathmode( $1, $2, $3 )', dsk, path, mode];
          whisper(`^447^ procuring DSK ${rpr(dsk)}`);
          return (await DB.query_single(q));
        });
      })(dsk, path, mode);
    }
    return (await parallel(tasks, 1));
  };

  //-----------------------------------------------------------------------------------------------------------
  this.clear_mirage_cache = async function() {
    return (await DB.query('select MIRAGE.clear_cache()'));
  };

  //-----------------------------------------------------------------------------------------------------------
  this.vacuum_mirage_cache = async function() {
    return (await DB.query('vacuum analyze MIRAGE.cache'));
  };

  //-----------------------------------------------------------------------------------------------------------
  this.refresh_dsks = async function(dsk_definitions, parallel_limit = 1) {
    var dsk, finished_count, mode, path, ref, running_count, t_count, task_count, tasks, waiting_count, x;
    tasks = [];
    waiting_count = 0;
    running_count = 0;
    finished_count = 0;
    task_count = 0;
    ref = this._walk_dsk_pathmodes(dsk_definitions);
    for (x of ref) {
      ({dsk, path, mode} = x);
      (function(dsk, path, mode) {
        return tasks.push(async function() {
          var result;
          waiting_count += -1;
          running_count += +1;
          // whisper "(w: #{waiting_count}, r: #{running_count}, f: #{finished_count} / #{t_count}) refreshing (#{mode}) #{path}"
          result = (await DB.query_single(['select MIRAGE.refresh( $1, $2 )', path, mode]));
          running_count += -1;
          return finished_count += +1;
        });
      })(dsk, path, mode);
    }
    // help    "(w: #{waiting_count}, r: #{running_count}, f: #{finished_count} / #{t_count}) refreshed (#{mode}) #{path}"
    waiting_count = tasks.length;
    t_count = tasks.length;
    await parallel(tasks, parallel_limit);
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this._show_dsk_definitions = function(dsk_definitions) {
    var cwd, dsk, dsk_txt, i, idx, len, mode, modepath_txt, modepaths, nr_txt, path;
    cwd = process.cwd();
    echo(CND.steel(CND.reverse(CND.bold(" Mirage Data Sources "))));
    echo(CND.grey("DSK                                 DSNR  path"));
    echo(CND.grey("——————————————————————————————————— ————— —————————————————————————————————————"));
    for (dsk in dsk_definitions) {
      modepaths = dsk_definitions[dsk];
      dsk_txt = (CND.white(dsk)).padEnd(50);
      for (idx = i = 0, len = modepaths.length; i < len; idx = ++i) {
        ({mode, path} = modepaths[idx]);
        if (path.startsWith(cwd)) {
          path = PATH.relative(cwd, path);
        }
        modepath_txt = (CND.yellow(mode)) + (CND.grey(':')) + (CND.lime(path));
        nr_txt = (`${idx + 1}`.padStart(2)) + '    ';
        echo(dsk_txt, nr_txt, modepath_txt);
      }
    }
    return null;
  };

  //###########################################################################################################
  if (module.parent == null) {
    RMDSKS = this;
    (async function() {
      var dsk_definitions, dsk_parallel_limit;
      dsk_definitions = RMDSKS.get_dsk_definitions();
      RMDSKS._show_dsk_definitions(dsk_definitions);
      await RMDSKS.procure_mirage_datasources(dsk_definitions);
      // await RMDSKS.clear_mirage_cache()
      dsk_parallel_limit = parseInt(shop.settings['intershop/mirage/parallel-limit'].value, 10);
      await RMDSKS.refresh_dsks(dsk_definitions, dsk_parallel_limit);
      await RMDSKS.vacuum_mirage_cache();
      return process.exit(0);
    })();
  }

  //  1 node lib/experiments/refresh-mirage-datasources.js  0.41s user 0.06s system 0% cpu 1:00.76 total
//  2 node lib/experiments/refresh-mirage-datasources.js  0.41s user 0.06s system 1% cpu 32.242 total
//  3 node lib/experiments/refresh-mirage-datasources.js  0.42s user 0.05s system 1% cpu 25.222 total
//  4 node lib/experiments/refresh-mirage-datasources.js  0.44s user 0.03s system 1% cpu 24.629 total
//  5 node lib/experiments/refresh-mirage-datasources.js  0.43s user 0.05s system 1% cpu 24.931 total
// 15 node lib/experiments/refresh-mirage-datasources.js  0.45s user 0.04s system 1% cpu 25.691 total

}).call(this);

//# sourceMappingURL=refresh-mirage-datasources.js.map