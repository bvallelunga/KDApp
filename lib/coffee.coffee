fs      = require "fs"
os      = require "os"
coffee  = require "coffee-script"
path    = require "path"

fs.existsSync ?= path.existsSync

pistachios = /\{(\w*)?(\#\w*)?((?:\.\w*)*)(\[(?:\b\w*\b)(?:\=[\"|\']?.*[\"|\']?)\])*\{([^{}]*)\}\s*\}/g

compileDebug = (path, source, error)->
  data = source.toString()
  if error.location
    {first_line, last_line, first_column, last_column} = error.location
    lines = data.split os.EOL
    trace = lines.slice(first_line, last_line+1).join os.EOL
    point = ""
    for i in [0..last_column]
      if i < first_column then point+=" " else point+="^"
    point+= " #{error.message}"

  first_line++; last_line++;
  spaces = Array((first_line+"").length+1).join " "
  curr = first_line
  prev = first_line - 1
  next = first_line + 1

  previous_line = if first_line > 1 then "#{prev}   #{lines[prev-1]}" else ""
  next_line = if lines.length > next then "#{next}  #{lines[next-1]}" else ""
  """
  at #{path} line #{first_line}:#{last_line} column #{first_column}:#{last_column}

  #{previous_line}
  #{curr}   #{trace}
  #{spaces}   #{point}
  #{next_line}
  """

module.exports = (lib, cb)->
  appPath     = lib.path
  manifest    = lib.getManifest()
  [bin, file] = process.argv
  files       = manifest?.source?.blocks?.app?.files
  source      = ""

  unless files
    return cb "The object in the manifest, 'source.blocks.app.files' was not found"

  unless Array.isArray files
    return cb "The object in the manifest, 'source.blocks.app.files' must be an array"

  for file in files
    file = path.normalize (path.join appPath, file)  if appPath

    if /\.coffee/.test file
      if fs.existsSync file
        data = fs.readFileSync file
      else
        return cb "The required file was not found: #{file}"
      try
        compiled = coffee.compile data.toString(), bare: true
      catch error
        return cb """
        Compile Error: #{error.message}
        #{compileDebug file, data, error}
        """
    else if /\.js/.test file
      if fs.existsSync file
        compiled = fs.readFileSync(file).toString()
      else
        return cb "The required file was not found: #{file}"

    block = """
    /* BLOCK STARTS: #{file} */
    #{compiled}
    """
    block = block.replace pistachios, (pistachio)-> pistachio.replace /\@/g, 'this.'
    source += block

  mainSource = """
  /* Compiled by kdc on #{(new Date()).toString()} */
  (function() {
  /* KDAPP STARTS */
  if (typeof window.appPreview !== "undefined" && window.appPreview !== null) {
    var appView = window.appPreview
  }
  #{source}
  /* KDAPP ENDS */
  }).call();
  """
  fs.writeFileSync (path.join appPath, "index.js"), mainSource
  cb()
