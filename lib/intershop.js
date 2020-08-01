(function() {
  'use strict';
  var CND, MAIN, PATH, alert, badge, debug, echo, help, info, isa, join, log, resolve, rpr, urge, validate, warn, whisper;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'INTERSHOP';

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

  join = PATH.join.bind(PATH);

  resolve = PATH.resolve.bind(PATH);

  MAIN = this;

  this.types = require('./types');

  ({validate, isa} = this.types.export());

  //-----------------------------------------------------------------------------------------------------------
  this.get = function(key) {
    var R, entry, type, value;
    if ((entry = this.settings[key]) == null) {
      throw new Error(`^intershop/get@44787^ unknown variable ${rpr(key)}`);
    }
    ({type, value} = entry);
    switch (type) {
      case 'int':
      case 'integer':
        validate.integer(R = parseInt(value, 10));
        break;
      case 'U.natural_number':
        validate.positive_integer(R = parseInt(value, 10));
        break;
      case 'text':
        R = value;
        break;
      case 'json':
        R = JSON.parse(value);
        break;
      case 'boolean':
        if (value === 'true') {
          R = true;
        } else if (value === 'false') {
          R = false;
        } else {
          throw new Error(`^intershop/get@44787^ expected a boolean literal, got ${rpr(value)}`);
        }
        break;
      default:
        R = value;
    }
    // when 'url'
    // text/path/folder
    // url
    // text/ip-address
    // unit
    // text/path/file
    return R;
  };

  //-----------------------------------------------------------------------------------------------------------
  /* TAINT consider to use Multimix */
  this.new_intershop = function(path = null) {
    var R, error, intershop_guest_configuration_path, intershop_guest_path, intershop_host_configuration_path, intershop_host_path, key, ref, ref1, value;
    R = {};
    R.PTV_READER = require('./ptv-reader');
    R.new_intershop = MAIN.new_intershop.bind(MAIN);
    R.types = MAIN.types;
    R.get = MAIN.get.bind(R);
    //.........................................................................................................
    /* TAINT validate */
    intershop_host_path = (ref = path != null ? path : process.env['intershop_host_path']) != null ? ref : process.cwd();
    intershop_guest_path = resolve(join(intershop_host_path, 'intershop'));
    intershop_host_configuration_path = resolve(join(intershop_host_path, 'intershop.ptv'));
    intershop_guest_configuration_path = resolve(join(intershop_guest_path, 'intershop.ptv'));
    //.........................................................................................................
    R.settings = {};
    R.settings['intershop/host/path'] = {
      type: 'text/path/folder',
      value: intershop_host_path
    };
    R.settings['intershop/guest/path'] = {
      type: 'text/path/folder',
      value: intershop_guest_path
    };
    R.settings['intershop/host/configuration/path'] = {
      type: 'text/path/folder',
      value: intershop_host_configuration_path
    };
    R.settings['intershop/guest/configuration/path'] = {
      type: 'text/path/folder',
      value: intershop_guest_configuration_path
    };
    ref1 = process.env;
    for (key in ref1) {
      value = ref1[key];
      R.settings[`os/env/${key}`] = {
        type: 'text',
        value
      };
    }
    try {
      //.........................................................................................................
      R.PTV_READER.update_hash_from_path(intershop_guest_configuration_path, R.settings);
    } catch (error1) {
      error = error1;
      warn(`'^intershop@334-1^'
when trying to read guest configuration from
  ${intershop_guest_configuration_path}
an error occurred:
  ${error.message}`);
    }
    try {
      // process.exit 1
      // throw error
      R.PTV_READER.update_hash_from_path(intershop_host_configuration_path, R.settings);
    } catch (error1) {
      error = error1;
      warn(`'^intershop@334-2^'
when trying to read host configuration from
  ${intershop_host_configuration_path}
an error occurred:
  ${error.message}`);
      process.exit(1);
      throw error;
    }
    //.........................................................................................................
    return R;
  };

}).call(this);

//# sourceMappingURL=intershop.js.map