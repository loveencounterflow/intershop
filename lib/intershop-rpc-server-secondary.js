(function() {
  'use strict';
  var $, $async, $drain, $watch, CND, DATOM, FS, NET, O, PATH, SP, alert, badge, cast, debug, echo, help, info, isa, jr, new_datom, process_is_managed, rpr, select, type_of, urge, validate, warn, whisper;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'INTERSHOP/RPC/SECONDARY';

  debug = CND.get_logger('debug', badge);

  alert = CND.get_logger('alert', badge);

  whisper = CND.get_logger('whisper', badge);

  warn = CND.get_logger('warn', badge);

  help = CND.get_logger('help', badge);

  urge = CND.get_logger('urge', badge);

  info = CND.get_logger('info', badge);

  echo = CND.echo.bind(CND);

  //...........................................................................................................
  FS = require('fs');

  PATH = require('path');

  NET = require('net');

  //...........................................................................................................
  SP = require('steampipes');

  ({$, $async, $watch, $drain} = SP.export());

  //...........................................................................................................
  DATOM = require('datom');

  ({new_datom, select} = DATOM.export());

  //...........................................................................................................
  this.types = require('./types');

  ({isa, validate, cast, type_of} = this.types);

  //...........................................................................................................
  O = require('./options');

  process_is_managed = module === require.main;

  ({jr} = CND);

  // debug '84874', '⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖'
  // for key, value of process.env
  //   continue unless ( key.match /mojikura|intershop/ )?
  //   debug key, value

  //-----------------------------------------------------------------------------------------------------------
  this._acquire_host_rpc_routines = function() {
    /* TAINT test for name collisions */
    /* TAINT do not require `rpc_` prefix? */
    /* TAINT use dedicated namespace (object) to keep RPC methods */
    /* TAINT make compatible with xemitter conventions */
    var error, host_rpc, host_rpc_module_path, intershop_host_modules_path, key, value;
    intershop_host_modules_path = process.env['intershop_host_modules_path'];
    help('^3334^', `trying to acquire RPC routines from ${rpr(intershop_host_modules_path)}`);
    if (intershop_host_modules_path != null) {
      host_rpc_module_path = PATH.join(intershop_host_modules_path, 'rpc.js');
      host_rpc = null;
      try {
        /* Make sure to accept missing `rpc.js` module without swallowing errors occurring during import: */
        require.resolve(host_rpc_module_path);
      } catch (error1) {
        error = error1;
        if (error.code !== 'MODULE_NOT_FOUND') {
          throw error;
        }
        warn(`no such module: ${rpr(host_rpc_module_path)}`);
        return null;
      }
      host_rpc = require(host_rpc_module_path);
      for (key in host_rpc) {
        value = host_rpc[key];
        info('^3389^', `add host RPC attribute ${rpr(key)}`);
        this[key] = value;
      }
    }
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this.contract = function(key, method) {
    var rpc_key;
    /* TAINT use dedicated namespace (object) to keep RPC methods */
    /* TAINT make compatible with xemitter conventions */
    validate.nonempty_text(key);
    validate.callable(method);
    rpc_key = `rpc_${key}`;
    if (this[rpc_key] != null) {
      throw new Error(`^rpc-secondary/contract@55777^ method already exists: ${rpr(key)} (${rpr(rpc_key)})`);
    }
    this[rpc_key] = method;
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this._socket_listen_on_all = function(socket) {
    socket.on('close', function() {
      return whisper('^rpc-4432-1^', 'socket', 'close');
    });
    socket.on('connect', function() {
      return whisper('^rpc-4432-2^', 'socket', 'connect');
    });
    socket.on('data', function() {
      return whisper('^rpc-4432-3^', 'socket', 'data');
    });
    socket.on('drain', function() {
      return whisper('^rpc-4432-4^', 'socket', 'drain');
    });
    socket.on('end', function() {
      return whisper('^rpc-4432-5^', 'socket', 'end');
    });
    socket.on('error', function() {
      return whisper('^rpc-4432-6^', 'socket', 'error');
    });
    socket.on('lookup', function() {
      return whisper('^rpc-4432-7^', 'socket', 'lookup');
    });
    socket.on('timeout', function() {
      return whisper('^rpc-4432-8^', 'socket', 'timeout');
    });
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this._server_listen_on_all = function(server) {
    server.on('close', function() {
      return whisper('^rpc-4432-9^', 'server', 'close');
    });
    server.on('connection', function() {
      return whisper('^rpc-4432-10^', 'server', 'connection');
    });
    server.on('error', function() {
      return whisper('^rpc-4432-11^', 'server', 'error');
    });
    server.on('listening', function() {
      return whisper('^rpc-4432-12^', 'server', 'listening');
    });
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this.listen = function(handler = null) {
    var server;
    this._acquire_host_rpc_routines();
    //.........................................................................................................
    server = NET.createServer((socket) => {
      var S, counts, pipeline, source;
      //.......................................................................................................
      // @_socket_listen_on_all socket
      source = SP.new_push_source();
      socket.on('data', (data) => {
        if (data !== '') {
          return source.send(data);
        }
      });
      socket.on('error', (error) => {
        return warn(`socket error: ${error.message}`);
      });
      // socket.on 'error',  ( error ) => throw error
      // socket.on 'end',              => source.end()
      counts = {
        requests: 0,
        rpcs: 0,
        hits: 0,
        fails: 0,
        errors: 0
      };
      S = {socket, counts};
      pipeline = [];
      //.......................................................................................................
      pipeline.push(source);
      pipeline.push(SP.$split());
      // pipeline.push $watch ( d ) => urge '^3398^', jr d
      pipeline.push(this.$show_counts(S));
      pipeline.push(this.$dispatch(S));
      pipeline.push($drain());
      //.......................................................................................................
      SP.pull(...pipeline);
      return null;
    });
    //.........................................................................................................
    if (handler == null) {
      handler = () => {
        var app_name, family, host, port, ref, ref1;
        ({
          address: host,
          port,
          family
        } = server.address());
        app_name = (ref = (ref1 = O.app.name) != null ? ref1 : process.env['intershop_db_name']) != null ? ref : 'intershop';
        return help(`RPC server for ${app_name} listening on ${family} ${host}:${port}`);
      };
    }
    //.........................................................................................................
    // ### !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! ###
    // try FS.unlinkSync O.rpc.path catch error then warn error
    // server.listen O.rpc.path, handler
    // ### !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! ###
    // @_server_listen_on_all server
    server.listen(O.rpc.port, O.rpc.host, handler);
    this.stop = function() {
      return server.close();
    };
    // debug '^899555^', ( k for k of server)
    // process.on 'uncaughtException',   -> warn "^8876^ uncaughtException";   server.close -> whisper "RPC server closed"
    // process.on 'unhandledRejection',  -> warn "^8876^ unhandledRejection";  server.close -> whisper "RPC server closed"
    // process.on 'exit',                -> warn "^8876^ exit";                server.close -> whisper "RPC server closed"
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$show_counts = function(S) {
    return $watch(function(event) {
      S.counts.requests += +1;
      if ((S.counts.requests % 1000) === 0) {
        urge(JSON.stringify(S.counts));
      }
      return null;
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$dispatch = function(S) {
    return $((line, send) => {
      var $rsvp, error, event, method, parameters, type;
      if (line === '') {
        return null;
      }
      event = null;
      method = null;
      parameters = null;
      $rsvp = false;
      while (true) {
        try {
          //.......................................................................................................
          event = JSON.parse(line);
        } catch (error1) {
          error = error1;
          this.send_error(S, `^rpc-secondary/$dispatch@5564^
An error occurred while trying to parse ${rpr(line)}:
${error.message}`);
          break;
        }
        //.....................................................................................................
        switch (type = type_of(event)) {
          // when 'list'
          //   warn "^rpc-secondary/$dispatch@5564^ using list instead of object in RPC calls is deprecated"
          //   [ method, parameters, ] = event
          //   $rsvp                   = true
          case 'object':
            ({
              $key: method,
              $value: parameters,
              $rsvp
            } = event);
            if ($rsvp == null) {
              $rsvp = false;
            }
            break;
          default:
            this.send_error(S, `^rpc-secondary/$dispatch@5565^ expected object, got a ${type}: ${rpr(event)}`);
            break;
        }
        //.....................................................................................................
        switch (method) {
          case 'error':
            this.send_error(S, parameters);
            break;
          //...................................................................................................
          /* Send `stop` signal to primary and exit secondary: */
          case 'stop':
            if (process_is_managed) {
              process.send('stop');
            }
            process.exit();
            break;
          //...................................................................................................
          /* exit and have primary restart secondary: */
          case 'restart':
            if (!process_is_managed) {
              warn("received restart signal but standalone process can't restart");
            } else {
              process.exit();
            }
            break;
          default:
            //...................................................................................................
            if ($rsvp === true) {
              this.do_rpc(S, method, parameters);
            }
        }
        //.....................................................................................................
        break;
      }
      //.......................................................................................................
      /* TAINT sending on failed lines w/out marking them as such? */
      send(event != null ? event : line);
      return null;
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.do_rpc = async function(S, method_name, parameters) {
    var error, error_2, message, method, method_type, result;
    S.counts.rpcs += +1;
    method = this[`rpc_${method_name}`];
    method_type = type_of(method);
    if (method == null) {
      return this.send_error(S, `no such method: ${rpr(method_name)}`);
    }
    try {
      //.........................................................................................................
      switch (method_type) {
        case 'function':
          result = method.call(this, S, parameters);
          break;
        case 'asyncfunction':
          result = (await method.call(this, S, parameters));
          break;
        default:
          throw new Error(`unknown method type ${rpr(method_type)}`);
      }
    } catch (error1) {
      error = error1;
      S.counts.errors += +1;
      try {
        ({message} = error);
      } catch (error1) {
        error_2 = error1;
        null;
      }
      if (message == null) {
        message = '(UNKNOWN ERROR MESSAGE)';
      }
      return this.send_error(S, error.message);
    }
    if (isa.promise(result)) {
      result.then((result) => {
        return this._write(S, method_name, result);
      });
    } else {
      this._write(S, method_name, result);
    }
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this.send_error = function(S, message) {
    return this._write(S, 'error', message);
  };

  //-----------------------------------------------------------------------------------------------------------
  this._write = function(S, $method, parameters) {
    var d;
    // debug '^intershop-rpc-server-secondary.coffee@3332^', ( rpr method_name ), ( rpr parameters )
    // if isa.object parameters  then  d = new_datom '^rpc-result', { $method, parameters..., }
    // else                            d = new_datom '^rpc-result', { $method, $value: parameters, }
    d = new_datom('^rpc-result', {
      $method,
      $value: parameters
    });
    S.socket.write((JSON.stringify(d)) + '\n');
    return null;
  };

  //===========================================================================================================
  // RPC METHODS
  //-----------------------------------------------------------------------------------------------------------
  this.rpc_has_rpc_method = function(S, P) {
    /* TAINT don't do ad-hoc name mangling, use dedicated namespace */
    validate.nonempty_text(P);
    return this[`rpc_${P}`] != null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this.rpc_helo = function(S, P) {
    return `helo ${rpr(P)}`;
  };

  //-----------------------------------------------------------------------------------------------------------
  this.rpc_add = function(S, P) {
    var a, b;
    if (!((CND.isa_list(P)) && (P.length === 2))) {
      throw new Error(`expected a list with two numbers, got ${rpr(P)}`);
    }
    [a, b] = P;
    if (!((CND.isa_number(a)) && (CND.isa_number(b)))) {
      throw new Error(`expected a list with two numbers, got ${rpr(P)}`);
    }
    return a + b;
  };

  //-----------------------------------------------------------------------------------------------------------
  this.rpc_add_integers_only = function(S, P) {
    var a, b;
    if (!((CND.isa_list(P)) && (P.length === 2))) {
      throw new Error(`expected a list with two numbers, got ${rpr(P)}`);
    }
    [a, b] = P;
    if (!((CND.isa_number(a)) && (CND.isa_number(b)))) {
      throw new Error(`expected a list with two numbers, got ${rpr(P)}`);
    }
    if (!(a === Math.floor(a))) {
      throw new Error(`expected an integer, got ${rpr(a)}`);
    }
    if (!(b === Math.floor(b))) {
      throw new Error(`expected an integer, got ${rpr(b)}`);
    }
    return a + b;
  };

  //###########################################################################################################
  if (module === require.main) {
    (() => {
      var RPCS;
      RPCS = this;
      return RPCS.listen();
    })();
  }

  // curl --silent --show-error localhost:23001/
// curl --silent --show-error localhost:23001
// curl --show-error localhost:23001
// grep -r --color=always -P '23001' db src bin tex-inputs | sort | less -SRN
// grep -r --color=always -P '23001' . | sort | less -SRN
// grep -r --color=always -P '23001|8910|rpc' . | sort | less -SRN

}).call(this);

//# sourceMappingURL=intershop-rpc-server-secondary.js.map