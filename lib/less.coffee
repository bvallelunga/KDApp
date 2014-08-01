fs    = require 'fs'
less  = require 'less'
path  = require 'path'
async = require 'async'

module.exports = (lib, cb)->
  appPath   = lib.path
  manifest  = lib.getManifest()
  files     =
    less: manifest?.source?.less
    stylesheets: manifest?.source?.stylesheets
  parser  = new(less.Parser)
    paths: [appPath, "#{appPath}/resources"]

  for type, content in files
    unless content
      return cb "The object in the manifest, 'source.#{type}' was not found"

    unless Array.isArray content
      return cb "The object in the manifest, 'source.#{type}' must be array"

    if content.length is 0
      return cb "The object in the manifest, 'source.#{type}' must have at least one file"

  if files.less and files.less.length != 0
    async.reduce files.less, "", (css, file, next)->
      file = path.normalize (path.join appPath, file) if appPath

      if /\.less/.test file
        if fs.existsSync file
          next null, css + fs.readFileSync file, 'utf-8'
        else
          next "The required file not found: #{file}"
    , (err, less)->
      if err
        return cb err

      parser.parse less, (err, tree)->
        if err
          return cb "Failed to compile LESS"

        compiledCss = tree.toCSS()
        fs.writeFileSync path.normalize(path.join appPath, "./resources/style.css"), compiledCss
        cb()
