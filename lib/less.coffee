fs    = require 'fs'
less  = require 'less'
path  = require 'path'
async = require 'async'

module.exports = (manifest, appPath, force)->
  files = 
    less: manifest?.source?.less
    stylesheets: manifest?.source?.stylesheets
  
  for type, content in files
    unless content
      console.log "The object 'source.#{type}' is not found in manifest file." if force
      return
  
    unless Array.isArray content
      console.log "The object 'source.#{type}' must be array in manifest file." if force
      return
    
    if content.length is 0
      console.log "The object 'source.#{type}' must have at least one file." if force
      return
  
  parser = new(less.Parser)
    paths: [appPath, "#{appPath}/resources"]
  
  if files.less and files.less.length != 0
    async.reduce files.less, "", (css, file, callback)-> 
      file = path.normalize (path.join appPath, file) if appPath
      
      if /\.less/.test file
        if fs.existsSync file
          callback null, css + fs.readFileSync file, 'utf-8'
        else if force
          callback "The required file not found: #{file}"
    , (err, less)->
      unless err
        parser.parse less, (err, tree)->
          return console.log "Failed to compile LESS" if err
          
          compiledCss = tree.toCSS()
          fs.writeFileSync path.normalize(path.join appPath, "./resources/style.css"), compiledCss
      else
        console.log err if force