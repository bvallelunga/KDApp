fs            = require 'fs-extra'
googl         = require 'goo.gl'
watch         = require 'node-watch'
Exec          = require('child_process')
EventEmitter  = require('events').EventEmitter

class Preview extends EventEmitter
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
        
        googl.shorten "#{@previewUrl}?app=#{@manifest.name}"
          .then (shortUrl)->
            console.log """
            
            Starting app server...
            Listening on #{shortUrl}
            
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
        console.log "Failed to start app server"
      
  watch: (compile)->
    excludeFiles = ["#{@path}/index.js", "#{@path}/resources/style.css"]
  
    watch @path, 
      recursive: true
      followSymLinks: true
    , (filename)=>
      if filename not in excludeFiles
        @emit "compile"
    
    console.log "Started watching for changes"

module.exports = Preview