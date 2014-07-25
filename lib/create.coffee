fs        = require 'fs-extra'
Applause  = require 'applause'

class Create
  constructor: (user, app, path, root) ->
    @user      = user 
    @path      = path
    @root      = root
    @appName   = app
    
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
    
    app       = @capitalize @appName
    appLower  = @nameify @appName.toLowerCase()
    appCap    = @nameify @capitalize @appName
    appCapOne = @nameify @capitalize @appName, true
    userLower = @user.toLowerCase()
    userCap   = @capitalize @user
    skelApp   = "#{@root}/apps/Skeleton.kdapp"
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
          unless err
            console.log "Your new project is called: #{appCap}.kdapp"
          else
            fs.removeSync tempApp
            console.log "Failed to create #{appCap}.kdapp"
      else
        console.log "Failed to create #{appCap}.kdapp"

module.exports = Create