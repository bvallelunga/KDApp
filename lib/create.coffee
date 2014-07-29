fs        = require 'fs-extra'
Applause  = require 'applause'
async     = require 'async'

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
    
    fs.copy skelApp, tempApp, (err)=>
      unless err
        applause = Applause.create
          variables:
            'a'   : app
            'al'  : appLower
            'ac'  : appCap
            'aco' : appCapOne
            'u'   : @user
            'ul'  : userLower
            'uc'  : userCap
        
        files = [
          "ChangeLog", "README.md", "index.coffee", 
          "manifest.json", "resources/style.css"
        ]
        
        if @type is "installer"
          files = files.concat [
            "config.coffee", "views/index.coffee",
            "less/style.less", "controllers/installer.coffee"
          ]
        
        async.each files, (file, next)->
          contents = fs.readFileSync "#{tempApp}/#{file}", 'utf8'
          result = applause.replace contents
          fs.writeFile "#{tempApp}/#{file}", result, next
        , (err)->
          if err
            fs.removeSync tempApp
            console.log "Failed to create #{appCap}.kdapp"
          else
            fs.move tempApp, destApp, (err)->
              unless err
                console.log """
                Your new project is called: #{appCap}.kdapp
                
                Please commit your files before testing. Koding apps pull
                the assets (images and scripts) from your repository.
                """
              else
                fs.removeSync tempApp
                console.log "Failed to create #{appCap}.kdapp"
      else
        console.log "Failed to create #{appCap}.kdapp"

module.exports = Create