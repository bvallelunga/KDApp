fs        = require 'fs-extra'
path      = require 'path'
os        = require 'os'
googl     = require 'goo.gl'
Coffee    = require './coffee'
Less      = require './less'
Serve     = require './serve'
Create    = require './create'

class Lib
  constructor: (config, program) ->
    @program  = program
    @path     = process.env.PWD
    @user     = process.env.LOGNAME
    @root     = path.resolve __dirname, '..'
    @hostname = os.hostname()
    
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
      
  create: (app, options) ->
    return @help() unless app
    
    create = new Create @user, app, @path, @root
    create.app()
  
  compile: (type)->
    manifest = @getManifest()
    
    if type
      switch type
        when "coffee" then Coffee manifest, @path
        when "less" then Less manifest, @path, true
    else 
      Coffee manifest, @path
      Less manifest, @path
  
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
 
  serve: (options)->
    manifest = @getManifest()
    serve    = new Serve manifest, @user, @path, @previewUrl
    
    @compile()
    serve.start =>
      serve.watch() if options.watch
      serve.on "compile", @compile.bind @ 
  
  help: ()->
    @program.help()
  
module.exports = (options) -> new Lib options