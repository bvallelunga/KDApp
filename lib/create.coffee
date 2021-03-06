fs        = require 'fs-extra'
cons      = require 'consolidate'
read      = require 'read'
async     = require 'async'
request   = require 'request'
util      = require 'util'
Exec      = require 'child_process'

class Create
  constructor: (lib, type, app)->
    @lib       = lib
    @appName   = app
    @type      = type

  capitalize: (string, once=false)->
    unless once
      string = (string.split(' ').map (word) ->
        word[0].toUpperCase() + word[1..-1].toLowerCase()
      ).join ' '
    else
      string = string[0].toUpperCase() + string[1..-1].toLowerCase()

  nameify: (string)->
    string.replace /\ /g, ''

  inApplicationsFolder: ->
    pathArray = @lib.path.split("/")
    pathArray[pathArray.length - 1] is "Applications"

  failed: (err)->
    @lib.winston.error err
    return console.log """
    Failed to create #{@nameify @capitalize @appName, yes}
    #{util.inspect err}
    """

  app: ->
    unless @inApplicationsFolder()
      return console.log """
      Apps can only be created in the Applications folder!

      To fix: cd ~/Applications
      """

    switch @type
      when "basic" then skelAppName = "Skeleton"
      when "installer"
        skelAppName = "InstallerSkeleton"
        additionalFiles = [
          "config.coffee", "views/index.coffee", "views/selectVm.coffee",
          "less/style.less", "less/dropdown.less",
          "controllers/installer.coffee"
        ]

      else return console.log """
      Unknown template type: #{@type}

      To fix, choose one of the following: basic or installer
      Then run command: kdapp create <type> #{@appName}
      """

    app       = @capitalize @appName
    appLower  = @nameify @appName.toLowerCase()
    appCap    = @nameify @capitalize @appName
    appCapOne = @nameify @capitalize @appName, yes
    user      = @lib.user
    userLower = @lib.user.toLowerCase()
    userCap   = @capitalize @lib.user
    github    = ""
    skelApp   = "#{@lib.root}/apps/#{skelAppName}.kdapp"
    tempApp   = "/tmp/#{appCapOne}.kdapp"
    destApp   = "#{@lib.path}/#{appCapOne}.kdapp"

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
            url: "https://api.github.com/user/repos"
            method: "POST"
            headers:
              "User-Agent": "Koding KDApp CLI"
            json:
              name        : "#{appCapOne}.kdapp"
              description : "Koding app created from a template."
              homepage    : "https://koding.com/Apps/#{user}/#{appCapOne}"
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
              github = credentials.user[0]

            # Copy Template to Temp
            fs.copy skelApp, tempApp, (err)=>
              return @failed err if err

              files = [
                "ChangeLog", "README.md", "index.coffee",
                "manifest.json", "resources/style.css"
              ]

              if additionalFiles?
                files = files.concat additionalFiles

              # Apply Variables to Template
              async.each files, (file, next)->
                cons.swig "#{tempApp}/#{file}",
                  'app'       : app
                  'appLower'  : appLower
                  'appCap'    : appCap
                  'appCapOne' : appCapOne
                  'user'      : user
                  'userLower' : userLower
                  'userCap'   : userCap,
                  'github'    : github
                , (err, result)->
                  return next err if err?
                  fs.writeFile "#{tempApp}/#{file}", result, next
              , (err)=>
                if err
                  @failed(err)
                  return fs.removeSync tempApp

                # Move Template to Destination
                fs.move tempApp, destApp, (err)=>
                  if err
                    @failed err
                    return fs.removeSync tempApp

                  # Init Repo and Make First Commit
                  Exec.exec """
                    git config --global user.username #{credentials.user[0]}
                    cd #{destApp};
                    git init;
                    git add .;
                    git commit -m "First Commit";
                    git remote add origin #{body.ssh_url};
                    git push origin master;
                  """, (err)=>
                      return @failed err if err

                      console.log """

                      Your new project is called: #{appCapOne}.kdapp

                      A repository on github has been created and your
                      files have been pushed to the remote repo.
                    """
        else
          # Move prompt to new line
          console.log ""

module.exports = Create
