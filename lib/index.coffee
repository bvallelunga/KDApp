fs        = require 'fs-extra'
path      = require 'path'
Coffee    = require './coffee'
Less      = require './less'
Serve     = require './serve'

class Lib
  constructor: (program) ->
    @program = program
    @path    = process.env.PWD
    @user    = process.env.LOGNAME
    @root    = path.resolve __dirname, '..'
    
  capitalize: (string)->
    return (string.split(' ').map (word) -> 
      word[0].toUpperCase() + word[1..-1].toLowerCase()
    ).join ' '
    
  nameify: (string)->
    return string.replace(' ', '')
    
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
    
    app       = @capitalize app
    appLower  = @nameify app.toLowerCase()
    appCap    = @nameify @capitalize app
    userLower = @user.toLowerCase()
    userCap   = @capitalize @user
    skelApp   = "#{@root}/apps/Skeleton.kdapp"
    tempApp   = "/tmp/#{appCap}.kdapp"
    destApp   = "#{@path}/#{appCap}.kdapp"
    
    fs.copy skelApp, tempApp, (err)=>
      unless err
        applause = Applause.create
          variables:
            'a' : app
            'al': appLower
            'ac': appCap
            'u' : @user
            'ul': userLower
            'uc': userCap
        
        files = [
          "ChangeLog", "README.md", "index.coffee", 
          "manifest.json", "resources/style.css"
        ]
        
        for file in files
          contents = fs.readFileSync "#{tempApp}/#{file}", 'utf8'
          result = applause.replace contents
          fs.writeFileSync "#{tempApp}/#{file}", result
          
        fs.move tempApp, destApp, (err)->
          if err
            fs.removeSync tempApp
            console.log "Failed to create #{appCap}.kdapp"
          
      else
        console.log "Failed to create #{appCap}.kdapp"
  
  compile: (type)=>
    manifest = @getManifest()
    
    if type
      switch type
        when "coffee" then Coffee manifest, @path
        when "less" then Less manifest, @path, true
    else 
      Coffee manifest, @path
      Less manifest, @path
  
  publish: console.log
  
  serve: (options)->
    manifest  = @getManifest()
    serve     = new Serve manifest, @user, @path
    
    @compile()
    serve.start()
    
  
  help: ()->
    @program.help()
  
module.exports = (options) -> new Lib options