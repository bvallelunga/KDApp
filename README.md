# KDApp CLI
> KDApp command-line interface for Koding.com

## Requirements

- [Install node.js](http://nodejs.org/) version `>=0.10.x`

## Install

```
$ sudo npm install -g kdapp
```

## Getting Started

```
$ kdapp create "First App" # create KDApp project
$ cd FirstApp.kdapp        # change to project directory
$ kdapp preview            # compile and prview app
```

## Usage

```
Usage: kdapp [options] [command]

Commands:

  create [name]          Create a new KDApp project
  compile                Compile all assets of app, making it ready to be published
  compile [type]         Compile specific assest: coffee, less
  preview [options]      Preview the application on a local web server
  publish [env]          Publish to <sandbox> or <store> enviroment
  help                   Output help information

Options:

  -h, --help     output usage information
  -V, --version  output the version number
  -q, --quite    Disable Logging
```
