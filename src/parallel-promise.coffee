

'use strict'

{ parallel: _parallel, }  = require 'forever-parallel'

#-----------------------------------------------------------------------------------------------------------
module.exports = parallel = ( tasks, limit = 1 ) ->
  _tasks = []
  #.........................................................................................................
  for task in tasks
    do ( task ) -> _tasks.push ( handler ) ->
      try result = await task() catch error then return handler error
      handler null, result
  #.........................................................................................................
  return new Promise ( resolve, reject ) ->
    _parallel _tasks, limit, ( error, result ) ->
      return reject error if error?
      resolve result
    return null


