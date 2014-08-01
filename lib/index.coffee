fs        = require 'fs-extra'
path      = require 'path'
os        = require 'os'
googl     = require 'goo.gl'
winston   = require 'winston'
Coffee    = require './coffee'
Less      = require './less'
Preview   = require './preview'
Create    = require './create'

class Lib
  constructor: (config, program)->
    @program  = program
    @path     = process.env.PWD
    @user     = process.env.LOGNAME
    @root     = path.resolve __dirname, '..'
    @hostname = os.hostname()
    @winston  = winston

    @winston.add @winston.transports.File, filename: "/tmp/kdapp.log"
    @winston.remove @winston.transports.Console

    if config.production
      @previewUrl  = "https://koding.com/Preview"
    else
      @previewUrl  = "https://koding.com/bvallelunga/Apps/Preview"

  getManifest: ->
    manifestPath = "#{@path}/manifest.json"

    try
      return JSON.parse fs.readFileSync manifestPath
    catch error
      if error.errno is 34
        console.log "Manifest file does not exists: #{manifestPath}"
      else
        console.log "Manifest file seems corrupted: #{manifestPath}"
      process.exit error.errno or 3

  create: (type, app, options)->
    if not app and type
      [app, type] = [type, 'basic']
    else unless app and type
      return @help()

    create = new Create @, type, app
    create.app()

  compile: (type)->
    if type
      switch type
        when "coffee" then Coffee @
        when "less" then Less @ yes
    else
      Coffee @
      Less @

  publish: (env, options)->
    # Use to check if app exists
    @getManifest()

    if env is "store"
      publishMode = "production"
      console.log """
      Please make sure all changes have been pushed to github.

      """
    else
      publishMode = "test"

    googl.shorten "#{@previewUrl}?publish=#{publishMode}&hostname=#{@hostname}&path=#{@path}"
      .then (shortUrl)->
        console.log "To finish publishing: #{shortUrl}"

      .catch (err)->
        console.error err.message

  preview: (options)->
    preview  = new Preview @

    @compile()
    preview.start =>
      preview.watch() if options.watch
      preview.on "compile", @compile.bind @

  help: ->
    @program.help()

module.exports = (options) -> new Lib options
