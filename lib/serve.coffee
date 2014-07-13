Applause  = require 'applause'
Exec      = require('child_process');
fs        = require 'fs-extra'
path      = require 'path'

class Serve
  constructor: (manifest, user, path) ->
    @manifest  = manifest
    @user      = user 
    @path      = path
    @webFolder = "/home/#{@user}/Web"
    @appFolder = "#{@webFolder}/#{manifest.name}.kdapp"
    
  start: ->
    Exec.exec """
      mkdir -p #{@webFolder}
      mkdir -p #{@appFolder}
      ln -s --force #{@path}/index.js #{@appFolder}/index.js
      ln -s --force #{@path}/resources/style.css #{@appFolder}/style.css
    """, (err)=>
      unless err
        message = """
          
          Starting app server...
          Listening on https://koding.com/bvallelunga/Apps/Preview?app=#{@manifest.name}
          
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

      else
        message = "Failed to start app server"
      
      console.log message

module.exports = Serve