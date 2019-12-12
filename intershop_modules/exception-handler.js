(function() {
  'use strict';
  var CND, FS, PATH, alert, badge, bold, cyan, debug, echo, get_context, gold, green, grey, help, info, isa_text, log, red, reverse, rpr, show_error_with_source_context, stackman, steel, urge, warn, whisper, white, yellow;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'nodexh';

  log = CND.get_logger('plain', badge);

  debug = CND.get_logger('debug', badge);

  info = CND.get_logger('info', badge);

  warn = CND.get_logger('warn', badge);

  alert = CND.get_logger('alert', badge);

  help = CND.get_logger('help', badge);

  urge = CND.get_logger('urge', badge);

  whisper = CND.get_logger('whisper', badge);

  echo = CND.echo.bind(CND);

  stackman = (require('stackman'))();

  FS = require('fs');

  PATH = require('path');

  ({isa_text, red, green, steel, grey, cyan, bold, gold, reverse, white, yellow, reverse} = CND);

  //-----------------------------------------------------------------------------------------------------------
  get_context = function(path, linenr) {
    /* TAINT use stackman.sourceContexts() instead */
    var R, delta, error, first_idx, i, idx, last_idx, len, line, lines, lnr, ref, this_linenr;
    try {
      lines = (FS.readFileSync(path, {
        encoding: 'utf-8'
      })).split('\n');
      delta = 1;
      first_idx = Math.max(0, linenr - 1 - delta);
      last_idx = Math.min(lines.length - 1, linenr - 1 + delta);
      R = [];
      ref = lines.slice(first_idx, +last_idx + 1 || 9e9);
      for (idx = i = 0, len = ref.length; i < len; idx = ++i) {
        line = ref[idx];
        this_linenr = first_idx + idx + 1;
        lnr = (this_linenr.toString().padStart(4)) + '│ ';
        if (this_linenr === linenr) {
          R.push(`${grey(lnr)}${cyan(line)}`);
        } else {
          R.push(`${grey(lnr)}${grey(line)}`);
        }
      }
    } catch (error1) {
      // R = R.join '\n'
      error = error1;
      if (error.code !== 'ENOENT') {
        throw error;
      }
      return [grey('./.')];
    }
    return R;
  };

  //-----------------------------------------------------------------------------------------------------------
  show_error_with_source_context = function(error) {
    stackman.callsites(error, function(error, callsites) {
      if (error != null) {
        throw error;
      }
      callsites.forEach(function(callsite) {
        var i, len, line, linenr, path, relpath, source;
        if (!isa_text((path = callsite.getFileName()))) {
          alert(grey('—'.repeat(108)));
          return null;
        }
        relpath = PATH.relative(process.cwd(), path);
        linenr = callsite.getLineNumber();
        if (path.startsWith('internal/')) {
          alert(grey(`${relpath} #${linenr}`));
          return null;
        }
        alert();
        // alert steel bold reverse ( "#{relpath} ##{linenr}:" ).padEnd 108
        alert(gold(`${bold(relpath)} #${linenr}:`.padEnd(108)));
        source = get_context(path, linenr);
        for (i = 0, len = source.length; i < len; i++) {
          line = source[i];
          alert(line);
        }
        return null;
      });
      return null;
    });
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this.exit_handler = function(exception) {
    var head, i, len, line, message, print, ref, ref1, tail;
    print = alert;
    message = ' EXCEPTION: ' + ((ref = exception != null ? exception.message : void 0) != null ? ref : "an unrecoverable condition occurred");
    if ((exception != null ? exception.where : void 0) != null) {
      message += '\n--------------------\n' + exception.where + '\n--------------------';
    }
    [head, ...tail] = message.split('\n');
    print(reverse(' ' + head + ' '));
    for (i = 0, len = tail.length; i < len; i++) {
      line = tail[i];
      warn(line);
    }
    if ((exception != null ? exception.stack : void 0) != null) {
      show_error_with_source_context(exception);
    } else {
      whisper((ref1 = exception != null ? exception.stack : void 0) != null ? ref1 : "(exception undefined, no stack)");
    }
    return process.exitCode = 1;
  };

  this.exit_handler = this.exit_handler.bind(this);

  //###########################################################################################################
  if (global[Symbol.for('cnd-exception-handler')] == null) {
    global[Symbol.for('cnd-exception-handler')] = true;
    if (process.type === 'renderer') {
      window.addEventListener('error', (event) => {
        var message, ref, ref1, ref2, ref3;
        // event.preventDefault()
        message = ((ref = (ref1 = event.error) != null ? ref1.message : void 0) != null ? ref : "(error without message)") + '\n' + ((ref2 = (ref3 = event.error) != null ? ref3.stack : void 0) != null ? ref2 : '').slice(0, 500);
        OPS.log(message);
        // @exit_handler event.error
        OPS.open_devtools();
        return true;
      });
      window.addEventListener('unhandledrejection', (event) => {
        var message, ref, ref1, ref2, ref3;
        // event.preventDefault()
        message = ((ref = (ref1 = event.reason) != null ? ref1.message : void 0) != null ? ref : "(error without message)") + '\n' + ((ref2 = (ref3 = event.reason) != null ? ref3.stack : void 0) != null ? ref2 : '').slice(0, 500);
        OPS.log(message);
        // @exit_handler event.reason
        OPS.open_devtools();
        return true;
      });
    } else {
      process.on('uncaughtException', this.exit_handler);
      process.on('unhandledRejection', this.exit_handler);
    }
  }

}).call(this);
