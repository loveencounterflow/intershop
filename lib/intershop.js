(function() {
  'use strict';
  var CND, INTERSHOP, PATH, alert, badge, debug, echo, error, help, info, intershop_guest_configuration_path, intershop_guest_path, intershop_host_configuration_path, intershop_host_path, join, key, log, ref, resolve, rpr, urge, value, warn, whisper;

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

  this.PTV_READER = require('./ptv-reader');

  //-----------------------------------------------------------------------------------------------------------
  intershop_host_path = process.cwd();

  intershop_guest_path = resolve(join(intershop_host_path, 'intershop'));

  intershop_host_configuration_path = resolve(join(intershop_host_path, 'intershop.ptv'));

  intershop_guest_configuration_path = resolve(join(intershop_guest_path, 'intershop.ptv'));

  //...........................................................................................................
  this.settings = {};

  this.settings['intershop/host/path'] = {
    type: 'text/path/folder',
    value: intershop_host_path
  };

  this.settings['intershop/guest/path'] = {
    type: 'text/path/folder',
    value: intershop_guest_path
  };

  this.settings['intershop/host/configuration/path'] = {
    type: 'text/path/folder',
    value: intershop_host_configuration_path
  };

  this.settings['intershop/guest/configuration/path'] = {
    type: 'text/path/folder',
    value: intershop_guest_configuration_path
  };

  ref = process.env;
  for (key in ref) {
    value = ref[key];
    this.settings[`os/env/${key}`] = {
      type: 'text',
      value
    };
  }

  try {
    //...........................................................................................................
    this.PTV_READER.update_hash_from_path(intershop_guest_configuration_path, this.settings);
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
    this.PTV_READER.update_hash_from_path(intershop_host_configuration_path, this.settings);
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

  //###########################################################################################################
  if (module.parent == null) {
    INTERSHOP = this;
  }

  // INTERSHOP.helo()

}).call(this);

//# sourceMappingURL=intershop.js.map