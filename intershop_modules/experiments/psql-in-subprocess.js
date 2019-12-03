// Generated by CoffeeScript 2.4.1
(function() {
  'use strict';
  var CND, CP, alert, badge, debug, help, info, jr, rpr, urge, warn, whisper;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'INTERSHOP/PSQL-IN-SUBPROCESS';

  debug = CND.get_logger('debug', badge);

  alert = CND.get_logger('alert', badge);

  whisper = CND.get_logger('whisper', badge);

  warn = CND.get_logger('warn', badge);

  help = CND.get_logger('help', badge);

  urge = CND.get_logger('urge', badge);

  info = CND.get_logger('info', badge);

  CP = require('child_process');

  ({jr} = CND);

  //-----------------------------------------------------------------------------------------------------------
  this.demo = function() {
    var cmd, cp, env, shell;
    cmd = 'psql -U intershop -d intershop -p 5432 --set=intershop_db_user=intershop --set=intershop_db_name=intershop --set=out=/tmp/intershop-intershop/psql-output --set QUIET=on --set ON_ERROR_STOP=1 -c "select name from CATALOG.catalog order by schema, name;"';
    // cmd = 'ls'
    env = {
      PAGER: 'pspg -s17'
    };
    shell = true;
    cp = CP.spawn(cmd, {shell, env});
    cp.stdout.setEncoding('utf-8');
    cp.stderr.setEncoding('utf-8');
    cp.stdout.on('data', function(data) {
      return info(jr(data));
    });
    cp.stdout.on('close', function() {
      return whisper('close');
    });
    cp.stdout.on('end', function() {
      return whisper('end');
    });
    cp.stderr.on('data', function(data) {
      return warn(data);
    });
    return null;
  };

  //###########################################################################################################
  if (module === require.main) {
    (() => {
      this.demo();
      return setTimeout((function() {}), 1000);
    })();
  }

}).call(this);

//# sourceMappingURL=psql-in-subprocess.js.map
