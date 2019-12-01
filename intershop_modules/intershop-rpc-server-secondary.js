// Generated by CoffeeScript 2.4.1
(function() {
  'use strict';
  var $, $async, CND, FS, NET, O, PATH, PS, RPCS, alert, badge, debug, echo, help, info, rpr, urge, warn, whisper;

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
  PS = require('pipestreams');

  ({$, $async} = PS);

  //...........................................................................................................
  O = require('./options');

  // debug '84874', '⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖'
  // for key, value of process.env
  //   continue unless ( key.match /mojikura|intershop/ )?
  //   debug key, value

  //-----------------------------------------------------------------------------------------------------------
  this._acquire_host_rpc_routines = function() {
    var error, host_rpc, host_rpc_module_path, intershop_host_modules_path, key, value;
    intershop_host_modules_path = process.env['intershop_host_modules_path'];
    if (intershop_host_modules_path != null) {
      host_rpc_module_path = PATH.join(intershop_host_modules_path, 'rpc.js');
      host_rpc = null;
      try {
        host_rpc = require(host_rpc_module_path);
      } catch (error1) {
        error = error1;
        if (error.code !== 'MODULE_NOT_FOUND') {
          throw error;
        }
        warn(`no host RPC code at ${rpr(host_rpc_module_path)}`);
      }
      if (host_rpc != null) {
// Object.assign @, host_rpc
        for (key in host_rpc) {
          value = host_rpc[key];
          info('33829', `add host RPC attribute ${rpr(key)}`);
          this[key] = value;
        }
      }
    }
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this._socket_listen_on_all = function(socket) {
    socket.on('close', function() {
      return help('socket', 'close');
    });
    socket.on('connect', function() {
      return help('socket', 'connect');
    });
    socket.on('data', function() {
      return help('socket', 'data');
    });
    socket.on('drain', function() {
      return help('socket', 'drain');
    });
    socket.on('end', function() {
      return help('socket', 'end');
    });
    socket.on('error', function() {
      return help('socket', 'error');
    });
    socket.on('lookup', function() {
      return help('socket', 'lookup');
    });
    socket.on('timeout', function() {
      return help('socket', 'timeout');
    });
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this._server_listen_on_all = function(server) {
    server.on('close', function() {
      return help('server', 'close');
    });
    server.on('connection', function() {
      return help('server', 'connection');
    });
    server.on('error', function() {
      return help('server', 'error');
    });
    server.on('listening', function() {
      return help('server', 'listening');
    });
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this.listen = function(handler = null) {
    var server;
    //.........................................................................................................
    server = NET.createServer((socket) => {
      var S, counts, on_stop, pipeline, source;
      socket.on('error', (error) => {
        return warn(`socket error: ${error.message}`);
      });
      //.......................................................................................................
      source = PS._nodejs_input_to_pull_source(socket);
      counts = {
        requests: 0,
        rpcs: 0,
        hits: 0,
        fails: 0,
        errors: 0
      };
      S = {socket, counts};
      pipeline = [];
      on_stop = PS.new_event_collector('stop', () => {
        return socket.end();
      });
      //.......................................................................................................
      pipeline.push(source);
      pipeline.push(PS.$split());
      // pipeline.push PS.$show()
      pipeline.push(this.$show_counts(S));
      pipeline.push(this.$dispatch(S));
      pipeline.push(on_stop.add(PS.$drain()));
      //.......................................................................................................
      PS.pull(...pipeline);
      return null;
    });
    //.........................................................................................................
    if (handler == null) {
      handler = () => {
        var family, host, port;
        ({
          address: host,
          port,
          family
        } = server.address());
        return help(`${O.app.name} RPC server listening on ${family} ${host}:${port}`);
      };
    }
    //.........................................................................................................
    // ### !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! ###
    // try FS.unlinkSync O.rpc.path catch error then warn error
    // server.listen O.rpc.path, handler
    // ### !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! ###
    server.listen(O.rpc.port, O.rpc.host, handler);
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$show_counts = function(S) {
    return PS.$watch(function(event) {
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
      var error, event, method, parameters;
      try {
        event = JSON.parse(line);
        [method, parameters] = event;
      } catch (error1) {
        error = error1;
        method = 'error';
        parameters = `An error occurred while trying to parse ${rpr(event)}:\n${error.message}`;
      }
      // debug '27211', ( rpr method ), ( rpr parameters )
      //.......................................................................................................
      switch (method) {
        case 'error':
          this.send_error(S, parameters);
          break;
        //.....................................................................................................
        /* Send `stop` signal to primary and exit secondary: */
        case 'stop':
          process.send('stop');
          process.exit();
          break;
        //.....................................................................................................
        /* exit and have primary restart secondary: */
        case 'restart':
          process.exit();
          break;
        default:
          //.....................................................................................................
          this.do_rpc(S, method, parameters);
      }
      //.......................................................................................................
      return send(event);
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.do_rpc = function(S, method_name, parameters) {
    var error, error_2, message, method, result;
    S.counts.rpcs += +1;
    method = this[`rpc_${method_name}`];
    if (method == null) {
      return this.send_error(S, `no such method: ${rpr(method_name)}`);
    }
    try {
      //.........................................................................................................
      result = method.call(this, S, parameters);
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
    return this._write(S, method_name, result);
  };

  //-----------------------------------------------------------------------------------------------------------
  this.send_error = function(S, message) {
    return this._write(S, 'error', message);
  };

  //-----------------------------------------------------------------------------------------------------------
  this._write = function(S, method, parameters) {
    S.socket.write((JSON.stringify([method, parameters])) + '\n');
    return null;
  };

  //===========================================================================================================
  // RPC METHODS
  //-----------------------------------------------------------------------------------------------------------
  // { IDL, IDLX, }            = require 'mojikura-idl'

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

  // #-----------------------------------------------------------------------------------------------------------
  // @rpc_normalize_formula = ( S, P ) ->
  //   unless ( CND.isa_list P ) and ( P.length is 2 )
  //     throw new Error "expected a list with two texts, got #{rpr P}"
  //   [ glyph, original_formula, ] = P
  //   unless ( CND.isa_text glyph ) and ( CND.isa_text original_formula )
  //     throw new Error "expected a list with two texts, got #{rpr P}"
  //   #.........................................................................................................
  //   normalized_formula  = IDLX.minimize_formula original_formula
  //   if normalized_formula is original_formula then  S.counts.fails += +1
  //   else                                            S.counts.hits  += +1
  //   # debug '44432', rpr normalized_formula
  //   # if normalized_formula? and normalized_formula isnt original_formula
  //   #   debug '66672', glyph, original_formula, '->', normalized_formula if ( original_formula.match /∅/ )?
  //   #   event.data.row.formula = MKNCR.chrs_from_text normalized_formula
  //   return [ glyph, normalized_formula, ]

  // #-----------------------------------------------------------------------------------------------------------
  // @rpc_get_relational_bigrams = ( S, P ) ->
  //   unless ( CND.isa_list P ) and ( P.length is 1 )
  //     throw new Error "expected a list with one text, got #{rpr P}"
  //   [ formula, ] = P
  //   return null if formula is null
  //   unless ( CND.isa_text formula )
  //     throw new Error "expected a list with one text, got #{rpr P}"
  //   #.........................................................................................................
  //   return IDLX.get_relational_bigrams formula

  // #-----------------------------------------------------------------------------------------------------------
  // @rpc_get_relational_bigrams_as_indices = ( S, P ) ->
  //   unless ( CND.isa_list P ) and ( P.length is 1 )
  //     throw new Error "expected a list with one text, got #{rpr P}"
  //   [ formula, ] = P
  //   return null if formula is null
  //   unless ( CND.isa_text formula )
  //     throw new Error "expected a list with one text, got #{rpr P}"
  //   #.........................................................................................................
  //   return IDLX.get_relational_bigrams_as_indices formula

  // #-----------------------------------------------------------------------------------------------------------
  // @rpc_XCTO_demo = ( S, P ) ->
  //   debug '33344', P
  //   # unless ( CND.isa_list P ) and ( P.length is 1 )
  //   #   throw new Error "expected a list with one text, got #{rpr P}"
  //   # [ formula, ] = P
  //   # return null if formula is null
  //   # unless ( CND.isa_text formula )
  //   #   throw new Error "expected a list with one text, got #{rpr P}"
  //   #.........................................................................................................
  //   return rpr P

  // ############################################################################################################
  // do ( L = @ ) ->
  //   for name, method of L
  //     continue unless name.startsWith 'rpc_'
  //     L[ name ] = method.bind L

  //###########################################################################################################
  if (module.parent == null) {
    RPCS = this;
    this._acquire_host_rpc_routines();
    RPCS.listen();
  }

}).call(this);

//# sourceMappingURL=intershop-rpc-server-secondary.js.map
