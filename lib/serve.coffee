fs            = require 'fs-extra'
watch         = require 'node-watch'
Exec          = require('child_process')
EventEmitter  = require('events').EventEmitter

class Serve extends EventEmitter
  constructor: (manifest, user, path, previewUrl) ->
    @manifest   = manifest
    @user       = user 
    @path       = path
    @previewUrl = previewUrl 
    @webFolder  = "/home/#{@user}/Web"
    @appFolder  = "#{@webFolder}/#{manifest.name}.kdapp"
    
  start: (cb)->
    Exec.exec """
      mkdir -p #{@webFolder}
      mkdir -p #{@appFolder}
      ln -s --force #{@path}/index.js #{@appFolder}/index.js
      ln -s --force #{@path}/resources/style.css #{@appFolder}/style.css
    """, (err)=>
      unless err
        @emit "compile"
        
        message = """
        
        Starting app server...
        Listening on #{@previewUrl}?app=#{@manifest.name}
        
        ctrl-c to stop the server
          
        """
        
        stdin = process.stdin
        stdin.setRawMode true
        stdin.resume()
        stdin.setEncoding( 'utf8' );
        
        stdin.on 'data', (key)=>
          if key is '\u0003'
            Exec.exec "rm -r --force #{@appFolder}", process.exit
          process.stdout.write key
        
        cb()
      else
        message = "Failed to start app server"
      
      console.log message
      
  watch: (compile)->
    excludeFiles = ["#{@path}/index.js", "#{@path}/resources/style.css"]
  
    watch @path, 
      recursive: true
      followSymLinks: true
    , (filename)=>
      if filename not in excludeFiles
        @emit "compile"
    
    console.log "Started watching for changes"

module.exports = Serve