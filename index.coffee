#!/usr/bin/env coffee

config          = require './package.json'
program         = require 'commander'
program._name   = config.name
lib             = require('./lib') config, program

program
  .version config.version
  .option '-q, --quite', 'Disable Logging'

program
  .command 'create [type] [name]'
  .description 'Create a new <basic> or <installer> KDApp (default: basic)'
  .action lib.create.bind lib

program
  .command 'compile'
  .description 'Compile all assets of app, making it ready to be published'

program
  .command 'compile [type]'
  .description 'Compile specific assest: coffee, less'
  .action lib.compile.bind lib

program
  .command 'preview'
  .option '-a, --watch', 'Enable watching for file changes and then compile (default: true)'
  .option '-n, --no-watch', 'Disable watching for file changes'
  .description 'Preview the application on a local web server'
  .action lib.preview.bind lib

program
  .command 'publish [env]'
  .description 'Publish to <sandbox> or <store> enviroment'
  .action lib.publish.bind lib

program
  .command 'help'
  .description 'Output help information'
  .action lib.help.bind lib

program.parse process.argv
program.help() unless program.args.length
module.exports = lib
