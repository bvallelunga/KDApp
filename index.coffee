#!/usr/bin/env coffee

config          = require './package.json'
program         = require 'commander'
program._name   = config.name
lib             = require('./lib') program

program
  .version config.version
  .option '-l, --log', 'Enable Logging'

program 
  .command 'create [name]'
  .description 'Create a new KDApp project'
  .action lib.create.bind lib

program 
  .command 'compile'
  .description 'Compile all assets of app, making it ready to be published'

program 
  .command 'compile [type]'
  .description 'Compile specific assest: coffee, less'
  .action lib.compile.bind lib
  
program 
  .command 'serve'
  .option '-p, --port', 'Port for web server (default: 4000)', 4000
  .option '-a, --autoreload', 'Enable app refresh on file changes (default: true)'
  .option '-n, --no-autoreload', 'Disable app refresh on file changes'
  .description 'Serves the application on a local web server'
  .action lib.serve.bind lib
  
program
  .command 'publish [env]'
  .description 'Publish to <sandbox> or <production> enviroment'
  .action lib.publish.bind lib
  
program
  .command 'help'
  .description 'Output help information'
  .action lib.help.bind lib

program.parse process.argv
program.help() unless program.args.length