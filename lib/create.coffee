fs        = require 'fs-extra'
cons      = require 'consolidate'
read      = require 'read'
async     = require 'async'
request   = require 'request'
Exec      = require 'child_process'

class Create
  constructor: (user, type, app, path, root) ->
    @user      = user
    @path      = path
    @root      = root
    @appName   = app
    @type      = type

  capitalize: (string, once=false)->
    unless once
      string = (string.split(' ').map (word) ->
        word[0].toUpperCase() + word[1..-1].toLowerCase()
      ).join ' '
    else
      string = string[0].toUpperCase() + string[1..-1].toLowerCase()

    return string

  nameify: (string)->
    return string.replace(' ', '')

  inApplicationsFolder: ->
    pathArray = @path.split("/")
    return pathArray[pathArray.length - 1] is "Applications"

  app: ->
    unless @inApplicationsFolder()
      return console.log """
      Apps can only be created in the Applications folder!

      To fix: cd ~/Applications
      """

    switch @type
      when "basic" then skelAppName = "Skeleton"
      when "installer" then skelAppName = "InstallerSkeleton"
      else return console.log """
      Unknown template type: #{@type}

      To fix, choose one of the following: basic or installer
      Then run command: kdapp create <type> #{@appName}
      """

    app       = @capitalize @appName
    appLower  = @nameify @appName.toLowerCase()
    appCap    = @nameify @capitalize @appName
    appCapOne = @nameify @capitalize @appName, yes
    userLower = @user.toLowerCase()
    userCap   = @capitalize @user
    skelApp   = "#{@root}/apps/#{skelAppName}.kdapp"
    tempApp   = "/tmp/#{appCap}.kdapp"
    destApp   = "#{@path}/#{appCap}.kdapp"

    # Get Github Credentials
    async.series
      user: (next)->
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

        # Create Empty Github Repo
        request
          url: "https://api.github.com/user/repos"
          method: "POST"
          headers:
            "User-Agent": "Koding KDApp CLI"
          json:
            name: "#{appCap}.kdapp"
          auth:
            user: credentials.user[0]
            pass: credentials.pass[0]
        , (err, res, body)=>
          if body.message is "Bad credentials"
            console.log "Invalid Github credentials"
            return @app()
          else if err
            return console.log "Failed to create #{appCap}.kdapp"

          # Copy Template to Temp
          fs.copy skelApp, tempApp, (err)=>
            if err
              return console.log "Failed to create #{appCap}.kdapp"

            files = [
              "ChangeLog", "README.md", "index.coffee",
              "manifest.json", "resources/style.css"
            ]

            if @type is "installer"
              files = files.concat [
                "config.coffee", "views/index.coffee",
                "less/style.less", "controllers/installer.coffee"
              ]

            # Apply Variables to Template
            async.each files, (file, next)=>
              cons.swig "#{tempApp}/#{file}",
                'app'       : app
                'appLower'  : appLower
                'appCap'    : appCap
                'appCapOne' : appCapOne
                'user'      : @user
                'userLower' : userLower
                'userCap'   : userCap
              , (err, result)->
                fs.writeFile "#{tempApp}/#{file}", result, next
            , (err)->
              if err
                console.log "Failed to create #{appCap}.kdapp"
                return fs.removeSync tempApp

              # Move Template to Destination
              fs.move tempApp, destApp, (err)->
                if err
                  console.log "Failed to create #{appCap}.kdapp"
                  return fs.removeSync tempApp

                # Init Repo and Make First Commit
                Exec.exec """
                  cd #{destApp};
                  git init;
                  git add .;
                  git commit -m "First Commit";
                  git remote add origin #{body.ssh_url};
                  git push origin master;
                """, ->
                    console.log """

                    Your new project is called: #{appCap}.kdapp

                    A repository on github has been created and your
                    files have been pushed to the remote repo.
                  """

module.exports = Create
