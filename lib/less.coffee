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
          contents = fs.readFileSync file, 'utf-8'
          
          parser.parse contents, (err, tree)->
            compiledCss = tree.toCSS()
            
            if !err and "" not in [compiledCss, contents]
              callback null, css + compiledCss
            else
              callback "Failed to compile #{file}"
              
        else if force
          callback "The required file not found: #{file}"
    , (err, css)->
      unless err
        fs.writeFileSync path.normalize(path.join appPath, files.stylesheets[0]), css
      else
        console.log err if force