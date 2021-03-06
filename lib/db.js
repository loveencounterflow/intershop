(function() {
  'use strict';
  var $, $async, $drain, $show, $watch, CND, Cursor, INTERSHOP, O, SP, alert, assign, badge, db, debug, echo, has_duplicates, help, info, isa, keys_of, last_of, log, pluck, pool, pool_settings, rpr, shop, type_of, types, urge, validate, warn, whisper;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'INTERSHOP/DB';

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
  // ### TAINT due to the way that intershop determines the locations of `intershop.ptv` configuration files,
  // we have to intermittently `cd` to the app directory: ###
  // PATH                      = require 'path'
  // prv_path                  = process.cwd()
  // process.chdir PATH.join __dirname, '../..'
  // whisper '33622', "working directory temporarily changed to #{process.cwd()}"
  INTERSHOP = require('../lib/intershop');

  shop = INTERSHOP.new_intershop();

  O = shop.settings;

  // process.chdir prv_path
  // whisper '33622', "working directory changed to #{prv_path}"
  //...........................................................................................................
  db = {
    /* TAINT value should be cast by PTV reader */
    database: O['intershop/db/name'].value,
    port: parseInt(O['intershop/db/port'].value, 10),
    user: O['intershop/db/user'].value
  };

  //...........................................................................................................
  pool_settings = {
    // database:                 'postgres',
    // user:                     'brianc',
    // password:                 'secret!',
    // port:                     5432,
    // ssl:                      true,
    // max:                      20, # set pool max size to 20
    idleTimeoutMillis: 1000, // close idle clients after 1 second
    connectionTimeoutMillis: 1000 // return an error after 1 second if connection could not be established
  };

  pool = new (require('pg')).Pool(db);

  Cursor = require('pg-cursor');

  SP = require('steampipes');

  ({$, $async, $watch, $show, $drain} = SP.export());

  //...........................................................................................................
  assign = Object.assign;

  has_duplicates = function(x) {
    return (new Set(x)).size !== x.length;
  };

  last_of = function(x) {
    return x[x.length - 1];
  };

  keys_of = Object.keys;

  types = require('./types');

  ({isa, type_of, validate} = types);

  //-----------------------------------------------------------------------------------------------------------
  pluck = function(x, k) {
    var R;
    R = x[k];
    delete x[k];
    return R;
  };

  //-----------------------------------------------------------------------------------------------------------
  this._get_query_object = function(q, ...settings) {
    var text, type, values;
    switch (type = type_of(q)) {
      case 'pod':
        return assign({}, q, ...settings);
      case 'text':
        text = q;
        values = null;
        break;
      case 'list':
        [text, ...values] = q;
        break;
      default:
        throw new Error(`expected a text or a list, got a ${type}`);
    }
    return assign({text, values}, ...settings);
  };

  //-----------------------------------------------------------------------------------------------------------
  this.query = async function(q, ...settings) {
    var R, error, field, keys, result, row;
    try {
      /* TAINT since this method uses `pool.query`, transactions across more than a single call will fail.
       See https://node-postgres.com/features/transactions. */
      //.........................................................................................................
      /* `result` is a single object with some added data or a list of such objects in the case of a multiple
       query; we reduce the latter to the last item: */
      result = (await pool.query(this._get_query_object(q, ...settings)));
    } catch (error1) {
      error = error1;
      error.message = `^intershop/db/query@4453^ an exception occurred when trying to query ${rpr(db)} using ${rpr(q)}: ${rpr(error.message)}`;
      throw error;
    }
    //.........................................................................................................
    /* acc. to https://node-postgres.com/features/connecting we have to wait here: */
    // await pool.end()
    result = isa.list(result) ? last_of(result) : result;
    //.........................................................................................................
    /* We return an empty list in case the query didn't return anything: */
    if (result == null) {
      return [];
    }
    //.........................................................................................................
    /* We're only interested in the list of rows; again, if that list is empty, or it's a list of lists
     (when `rowMode: 'array'` was set), we're done: */
    R = result.rows;
    if (R.length === 0) {
      return [];
    }
    if (isa.list(R[0])) {
      return R;
    }
    //.........................................................................................................
    /* Otherwise, we've got a non-empty list of row objects. If the query specified non-unique field names,
     field names will clobber each other. To avoid silent failure, we check for duplicates and
     matching lengths of metadata and actual rows: */
    keys = (function() {
      var i, len, ref, results;
      ref = result.fields;
      results = [];
      for (i = 0, len = ref.length; i < len; i++) {
        field = ref[i];
        results.push(field.name);
      }
      return results;
    })();
    //.........................................................................................................
    if ((has_duplicates(keys)) || (keys.length !== (keys_of(R[0])).length)) {
      error = new Error(`detected duplicate fieldnames: ${rpr(keys)}`);
      error.code = 'fieldcount mismatch';
      throw error;
    }
    return (function() {
      var i, len, results;
      results = [];
      for (i = 0, len = R.length; i < len; i++) {
        row = R[i];
        //.........................................................................................................
        results.push({...row});
      }
      return results;
    })();
  };

  //-----------------------------------------------------------------------------------------------------------
  this.query_lists = async function(q, ...settings) {
    return (await this.query(q, {
      rowMode: 'array'
    }, ...settings));
  };

  //-----------------------------------------------------------------------------------------------------------
  this.query_one = async function(q, ...settings) {
    var rows;
    rows = (await this.query(q, ...settings));
    if (rows.length !== 1) {
      throw new Error(`expected exactly one result row, got ${rows.length}`);
    }
    return rows[0];
  };

  //-----------------------------------------------------------------------------------------------------------
  this.query_one_list = async function(q, ...settings) {
    return (await this.query_one(q, {
      rowMode: 'array'
    }, ...settings));
  };

  //-----------------------------------------------------------------------------------------------------------
  this.query_single = async function(q, ...settings) {
    var R;
    R = (await this.query_one_list(q, ...settings));
    if (R.length !== 1) {
      throw new Error(`expected row with single value, got on with ${rows.length} values`);
    }
    return R[0];
  };

  //-----------------------------------------------------------------------------------------------------------
  this.perform = async function(q, ...settings) {
    var lego, text, values;
    ({text, values} = this._get_query_object(q));
    lego = '';
    while ((text.indexOf(lego)) >= 0) {
      lego += 'ð';
    }
    if (!text.endsWith(';')) {
      text += ';';
    }
    text = `do $${lego}$ begin perform ${text} end; $${lego}$;`;
    return (await this.query({text, values}, ...settings));
  };

  //-----------------------------------------------------------------------------------------------------------
  this.query_as_readstream = function(q, ...settings) {
    return new Promise(async(resolve, reject) => {
      /* NOTE options include batchSize, highWaterMark; see
         https://github.com/brianc/node-postgres/blob/master/packages/pg-query-stream/index.js */
      var QueryStream, R, client, options, pg, query, release_client, text, values;
      pg = require('pg');
      QueryStream = require('pg-query-stream');
      client = (await pool.connect());
      release_client = function() {
        release_client = (function() {});
        return client.release();
      };
      try {
        //.........................................................................................................
        options = this._get_query_object(q, ...settings);
        text = pluck(options, 'text');
        values = pluck(options, 'values');
        query = new QueryStream(text, values, options);
        R = client.query(query);
        R.on('end', function() {
          return release_client();
        });
      } finally {
        release_client();
      }
      resolve(R);
      return null;
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.query_as_json_readstream = async function(q, ...settings) {
    var JSONStream, readstream;
    readstream = (await this.new_nodejs_readstream_raw(q, ...settings));
    JSONStream = require('jsonstream2');
    return readstream.pipe(JSONStream.stringify());
  };

  //-----------------------------------------------------------------------------------------------------------
  this.new_query_source = function(q, ...settings) {
    return new Promise(async(resolve, reject) => {
      var client, client_released, cursor, error, on_end, on_error, options, read, source, text, values;
      client_released = false;
      client = null;
      cursor = null;
      source = null;
      //.........................................................................................................
      on_end = function() {
        return cursor.close(() => {
          source.end();
          if (!client_released) {
            client.release();
          }
          client_released = true;
          return resolve();
        });
      };
      //.........................................................................................................
      on_error = (error) => {
        /* NOTE obligatory error handling, absolutely must do this or app will hang, swallow errors: */
        cursor.close(async() => {
          if (!client_released) {
            client.release();
          }
          client_released = true;
          if (!pool.ended) {
            await pool.end();
          }
          return reject(error);
        });
        return null;
      };
      try {
        //.........................................................................................................
        client = (await pool.connect());
        options = this._get_query_object(q, ...settings);
        text = pluck(options, 'text');
        values = pluck(options, 'values');
        cursor = client.query(new Cursor(text, values, options));
        source = SP.new_push_source();
        //.......................................................................................................
        read = function() {
          return new Promise((resolve, reject) => {
            return cursor.read(100, (error, rows) => {
              if (error != null) {
                on_error(error);
                return reject();
              }
              if (rows.length === 0) {
                return on_end();
              }
              return resolve(rows);
            });
          });
        };
        //.......................................................................................................
        source.start = function() {
          return (async()/* Note: must be function, not asyncfunction */ => {
            var i, len, row, rows;
            while (true) {
              rows = (await read());
              for (i = 0, len = rows.length; i < len; i++) {
                row = rows[i];
                source.send(row);
              }
            }
            return null;
          })();
        };
        return resolve(source);
      } catch (error1) {
        //.........................................................................................................
        error = error1;
        if (cursor == null) {
          throw error;
        }
        on_error(error);
      }
      //.........................................................................................................
      return null;
    });
  };

  // # previously we used pg-query-stream:
  // QueryStream               = require 'pg-query-stream'
  //   #-----------------------------------------------------------------------------------------------------------
  //   @fetch_query_source = ( q, settings... ) ->
  //     ### TAINT when an error occurs that does not lead to process termination, the client may not be returned to the pool ###
  //     # debug '44453', Object.assign settings...
  //     on_stop = ->
  //       client.end() unless has_ended
  //       has_ended = yes
  //     #.......................................................................................................
  //     has_ended                   = no
  //     client                      = await pool.connect()
  //     { text, values, options, }  = @_get_query_object q, settings...
  //     submittable                 = new QueryStream text,values, options
  //     readstream                  = client.query submittable
  //     source                      = PS._nodejs_input_to_pull_source readstream
  //     #.......................................................................................................
  //     submittable.on  'error', ( error ) -> on_stop(); throw error
  //     readstream.on   'error', ( error ) -> on_stop(); throw error
  //     #.......................................................................................................
  //     pipeline      = []
  //     pipeline.push source
  //     pipeline.push PS.map_stop on_stop
  //     return PS.pull pipeline...

  //###########################################################################################################
  if (require.main === module) {
    (async() => {
      var DB, demo_stream, error, relpath;
      try {
        //.........................................................................................................
        DB = this;
        info('01', (await DB.query('select 42 as a, 108 as b;')));
        info('02', (await DB.query_one('select 42 as a, 108 as b;')));
        info('03', (await DB.query_lists('select 42 as a, 108 as b;')));
        help('------------------------------------------------------------------------------------------');
        try {
          info('04', (await DB.query('select 42, 108;')));
        } catch (error1) {
          error = error1;
          if (error.code !== 'fieldcount mismatch') {
            throw error;
          }
          warn(error.message);
        }
        help('------------------------------------------------------------------------------------------');
        info('05', (await DB.query('select 42, 108;', {
          rowMode: 'array'
        })));
        info('06', (await DB.query_lists('select 42, 108;')));
        info('07', (await DB.query_one_list('select 42, 108;')));
        info('08', (await DB.query_single('select 42;')));
        help('------------------------------------------------------------------------------------------');
        info('09', (await DB.query('select 42; select 108;')));
        try {
          info('10', (await DB.query('do $$ begin perform log( $a$helo$a$ ); end; $$;')));
          info('11', (await DB.perform('log( $$helo$$ );')));
          info('12', (await DB.perform('log( $ððð$helo$ððð$ );')));
        } catch (error1) {
          error = error1;
          relpath = (require('path')).relative(process.cwd(), __filename);
          warn('^2298^', "demos with SQL `log()` only work when run in intershop process, e.g.");
          warn('^2298^', `  intershop node ${relpath}`);
          warn(`terminated with ${error.message}`);
          process.exit(1);
        }
        //-----------------------------------------------------------------------------------------------------------
        demo_stream = function(q, ...settings) {
          return new Promise(async(resolve, reject) => {
            var pipeline, source;
            source = (await DB.new_query_source(q, ...settings));
            pipeline = [];
            pipeline.push(source);
            pipeline.push(SP.$show());
            pipeline.push($drain(function() {
              help('ok');
              return resolve();
            }));
            SP.pull(...pipeline);
            // source.end()
            return null;
          });
        };
        // demo_stream "select * from STROKEORDERS.strokeordersXXX limit x10"
        await demo_stream("select * from generate_series( 100, 110 ) as count;");
        await demo_stream("select * from generate_series( 100, 110 ) as count;", {
          rowMode: 'array'
        });
      } finally {
        if (!pool.ended) {
          /* NOTE always call `pool.end()` to keep app from waiting for timeout: */
          //.........................................................................................................
          await pool.end();
        }
      }
      //.........................................................................................................
      return null;
    })();
  }

  this._db = db;

  this._pool = pool;

}).call(this);

//# sourceMappingURL=db.js.map