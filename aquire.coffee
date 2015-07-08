npmModule = require 'npm'
path = require 'path'

MODULE_DIR = 'aquire_modules'

# Some helpers

nodeify = (o, k) -> ->
  args = (x for x in arguments)
  new Promise (resolve, reject) =>
    args.push (err, result) -> if err then reject err else resolve result
    o[k].apply(o, args)

fin = (p, f) ->
  p.catch (e) -> f(); throw e
  p.then (x) -> f(); x

# npm actually just ignores whatever you say and outputs stuff to console.log anyway
withNoConsoleLog = (p) ->
  [oldlog, console.log] = [console.log, ->]
  fin p, -> console.log = oldlog


load = nodeify npmModule, 'load'
install = nodeify npmModule.commands, 'install'


npm = load
  prefix: MODULE_DIR
  loglevel: 'silent'
  silent: true
  production: true

makePath = (name) -> path.resolve(MODULE_DIR, 'node_modules', name.split('@')[0])

localRequire = (names) -> require makePath name for name in names

remoteRequire = (names) ->
  npm
  .then -> withNoConsoleLog(install names)
  .then -> localRequire names

simplify = (modules) -> if modules.length is 1 then modules[0] else modules

aquire = (names...) ->
  Promise.resolve()
  .then -> localRequire names
  .catch -> remoteRequire names
  .then simplify

module.exports = aquire
