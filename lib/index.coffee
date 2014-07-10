kdc = require './kdc'

class Lib

  constructor: (program) ->
    @program = program
    @path    = process.env.PWD
  
  create: (name, options) ->
    return @help() unless name
  
  compile: (type)=>
    if type
      switch type
        when "coffee" then kdc @path
    else 
      kdc @path
  
  publish: console.log
  serve: console.log
  
  help: ()->
    @program.help()
  
module.exports = (options) -> new Lib options