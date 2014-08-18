read      = require 'read'
async     = require 'async'
request   = require 'request'
path      = require 'path'
Exec      = require 'child_process'

class Remove
  constructor: (lib, github)->
    @lib       = lib
    @github    = github
    @manifest  = lib.getManifest()

  app: ->
    if @github
      # Get Github Credentials
      async.series
        user: (next)->
          Exec.exec "git config --global user.username", (err, username)->
            if not err and username
              next err, [username.replace("\n", "")]
            else
              read prompt:
                "Github username: "
              , next
        pass: (next)->
          read
            prompt: "Github password: "
            silent: true
            replace: "*"
          , next
        , (err, credentials)=>
          if not err and credentials
            # Create Empty Github Repo
            request
              url: "https://api.github.com/repos/#{credentials.user[0]}/#{@lib.path.split("/").slice(-1)[0]}"
              method: "DELETE"
              headers:
                "User-Agent": "Koding KDApp CLI"
              auth:
                user: credentials.user[0]
                pass: credentials.pass[0]
            , (err, res, body)=>
              if body.message is "Bad credentials"
                console.log "Invalid Github credentials"
                return @app()
              else if err or body.errors?
                return @failed err || body.errors
              else
                @directory()
    else
      @directory()

  directory: ->
    Exec.exec "sudo rm -r #{@lib.path}", ->
      console.log """
      Successfully removed kdapp!
      Please cd out of directory: cd ../;
      """

module.exports = Remove
