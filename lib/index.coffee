fs        = require 'fs-extra'
path      = require 'path'
Applause  = require 'applause'
coffee    = require './coffee'
less      = require './less'
Exec      = require('child_process');

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
        when "coffee" then coffee manifest, @path
        when "less" then less manifest, @path, true
    else 
      coffee manifest, @path
      less manifest, @path
  
  publish: console.log
  
  serve: (options)->
    manifest  = @getManifest()
    webFolder = "/home/#{@user}/Web"
    appFolder = "#{webFolder}/#{manifest.name}.kdapp"
    @compile()
    
    Exec.exec """
      mkdir -p #{webFolder}
      mkdir -p #{appFolder}
      ln -s --force #{@path}/index.js #{appFolder}/index.js
      ln -s --force #{@path}/resources/style.css #{appFolder}/style.css
    """, (err)->
      unless err
        message = """
          
          Starting app server...
          Listening on https://koding.com/bvallelunga/Apps/Preview?app=#{manifest.name}
          
          ctrl-c to stop the server
          
        """
        
        stdin = process.stdin
        stdin.setRawMode true
        stdin.resume()
        stdin.setEncoding( 'utf8' );
        
        stdin.on 'data', (key)->
          if key is '\u0003'
            Exec.exec "rm -r --force #{appFolder}", process.exit
          process.stdout.write key

      else
        message = "Failed to start app server"
      
      console.log message
  
  help: ()->
    @program.help()
  
module.exports = (options) -> new Lib options