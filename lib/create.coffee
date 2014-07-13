fs        = require 'fs-extra'
Applause  = require 'applause'

class Create
  constructor: (user, app, path, root) ->
    @user      = user 
    @path      = path
    @root      = root
    @appName   = app
    
  capitalize: (string)->
    return (string.split(' ').map (word) -> 
      word[0].toUpperCase() + word[1..-1].toLowerCase()
    ).join ' '
    
  nameify: (string)->
    return string.replace(' ', '')
  
  app: ->
    app       = @capitalize @appName
    appLower  = @nameify @appName.toLowerCase()
    appCap    = @nameify @capitalize @appName
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

module.exports = Create