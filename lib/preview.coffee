fs            = require 'fs-extra'
googl         = require 'goo.gl'
watch         = require 'node-watch'
Exec          = require 'child_process'
EventEmitter  = require('events').EventEmitter

class Preview extends EventEmitter
  constructor: (lib) ->
    @lib        = lib
    @manifest   = lib.getManifest()
    @webFolder  = "/home/#{@lib.user}/Web"
    @appFolder  = "#{@webFolder}/#{@manifest.name}.kdapp"

  start: (cb)->
    Exec.exec """
      mkdir -p #{@webFolder}
      mkdir -p #{@appFolder}
      cp --force #{@lib.root}/apps/redirect.html #{@appFolder}/index.html
      ln -s --force #{@lib.path}/index.js #{@appFolder}/index.js
      ln -s --force #{@lib.path}/resources/style.css #{@appFolder}/style.css
    """, (err)=>
      if err
        @lib.winston.error err
        return console.log "Failed to start app server"

      @emit "compile"
      previewUrl = encodeURIComponent "#{@lib.previewUrl}?app=#{@manifest.name}"
      redirectUrl = "https://#{@lib.user}.kd.io/#{@manifest.name}.kdapp/?next=#{previewUrl}"

      googl.shorten redirectUrl
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

  watch: (compile)->
    excludeFiles = [
      "#{@lib.path}/index.js", "#{@lib.path}/resources/style.css"
    ]

    watch @lib.path,
      recursive: true
      followSymLinks: true
    , (filename)=>
      if filename not in excludeFiles
        @emit "compile"

    console.log "Started watching for changes"

module.exports = Preview
