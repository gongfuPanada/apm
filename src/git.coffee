{spawn} = require 'child_process'
path = require 'path'
_ = require 'underscore-plus'
npm = require 'npm'
config = require './apm'
fs = require './fs'

addPortableGitToEnv = (env) ->
  localAppData = env.LOCALAPPDATA
  return unless localAppData

  try
    children = fs.readdirSync(path.join(localAppData, 'GitHub'))
  catch error
    return

  for child in children when child.indexOf('PortableGit_') is 0
    cmdPath = path.join(localAppData, 'GitHub', child, 'cmd')
    binPath = path.join(localAppData, 'GitHub', child, 'bin')
    if env.Path
      env.Path += "#{path.delimiter}#{cmdPath}#{path.delimiter}#{binPath}"
    else
      env.Path = "#{cmdPath}#{path.delimiter}#{binPath}"
    break

  return

addGitBashToEnv = (env) ->
  if env.ProgramFiles
    gitPath = path.join(env.ProgramFiles, 'Git')

  unless fs.isDirectorySync(gitPath)
    if env['ProgramFiles(x86)']
      gitPath = path.join(env['ProgramFiles(x86)'], 'Git')

  return unless fs.isDirectorySync(gitPath)

  cmdPath = path.join(gitPath, 'cmd')
  binPath = path.join(gitPath, 'bin')
  if env.Path
    env.Path += "#{path.delimiter}#{cmdPath}#{path.delimiter}#{binPath}"
  else
    env.Path = "#{cmdPath}#{path.delimiter}#{binPath}"

exports.addGitToEnv = (env) ->
  addPortableGitToEnv(env)
  addGitBashToEnv(env)

exports.getGitVersion = (callback) ->
  npmOptions =
    userconfig: config.getUserConfigPath()
    globalconfig: config.getGlobalConfigPath()
  npm.load npmOptions, ->
    git = npm.config.get('git') ? 'git'
    env = _.extend({}, process.env)
    exports.addGitToEnv(env) if process.platform is 'win32'
    spawned = spawn(git, ['--version'], {env})
    outputChunks = []
    spawned.stderr.on 'data', (chunk) -> outputChunks.push(chunk)
    spawned.stdout.on 'data', (chunk) -> outputChunks.push(chunk)
    spawned.on 'error', ->
    spawned.on 'close', (code) ->
      if code is 0
        [gitName, versionName, version] = Buffer.concat(outputChunks).toString().split(' ')
        version = version?.trim()
      callback(version)
