fs        = require 'fs-extra'
path      = require 'path'
Applause  = require 'applause'
kdc       = require './kdc'

util = require('util');

class Lib
  constructor: (program) ->
    @program = program
    @path    = process.env.PWD
    @user    = process.env.LOGNAME
    @root    = path.resolve __dirname, '..'
  
  create: (app, options) ->
    return @help() unless app
    return console.log "App name can not contain spaces" if " " in app
    
    appLower  = app.toLowerCase()
    appCap    = app[0].toUpperCase() + app[1..-1].toLowerCase()
    userLower = @user.toLowerCase()
    userCap   = @user[0].toUpperCase() + @user[1..-1].toLowerCase()
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
    if type
      switch type
        when "coffee" then kdc @path
    else 
      kdc @path
  
  publish: console.log
  serve: console.log
  
  help: ()->
    @program.help()
  
module.exports = (options) -> new Lib options