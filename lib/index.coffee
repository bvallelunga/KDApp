fs        = require 'fs-extra'
path      = require 'path'
Applause  = require 'applause'
coffee    = require './coffee'
less      = require './less'

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
  
  create: (app, options) ->
    return @help() unless app
    
    appLower  = app.toLowerCase()
    appCap    = @capitalize app
    userLower = @user.toLowerCase()
    userCap   = @capitalize @user
    tempApp   = "/tmp/#{appCap}.kdapp"
    destApp   = "#{@path}/#{appCap}.kdapp"
    
    fs.copy "#{@root}/skeleton", tempApp, (err)=>
      unless err
        applause = Applause.create
          variables:
            'a' : app
            'al': appLower
            'ac': appCap
            'u' : @user
            'ul': userLower
            'uc': userCap
            'p' : destApp
        
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
    manifestPath = "#{@path}/manifest.json"

    try
      manifest = JSON.parse fs.readFileSync manifestPath
    catch error
      if error.errno is 34
        console.log "Manifest file does not exists: #{manifestPath}"
      else
        console.log "Manifest file seems corrupted: #{manifestPath}"
      process.exit error.errno or 3
    
    if type
      switch type
        when "coffee" then coffee manifest, @path
        when "less" then less manifest, @path, true
    else 
      coffee manifest, @path
      less manifest, @path
  
  publish: console.log
  serve: console.log
  
  help: ()->
    @program.help()
  
module.exports = (options) -> new Lib options