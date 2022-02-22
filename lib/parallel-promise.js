(function() {
  'use strict';
  var _parallel, parallel;

  ({
    parallel: _parallel
  } = require('forever-parallel'));

  //-----------------------------------------------------------------------------------------------------------
  module.exports = parallel = function(tasks, limit = 1) {
    var _tasks, i, len, task;
    _tasks = [];
//.........................................................................................................
    for (i = 0, len = tasks.length; i < len; i++) {
      task = tasks[i];
      (function(task) {
        return _tasks.push(async function(handler) {
          var error, result;
          try {
            result = (await task());
          } catch (error1) {
            error = error1;
            return handler(error);
          }
          return handler(null, result);
        });
      })(task);
    }
    //.........................................................................................................
    return new Promise(function(resolve, reject) {
      _parallel(_tasks, limit, function(error, result) {
        if (error != null) {
          return reject(error);
        }
        return resolve(result);
      });
      return null;
    });
  };

}).call(this);

//# sourceMappingURL=parallel-promise.js.map