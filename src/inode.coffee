###
Flexcache

Copyright (c) 2011 Daniel Poelzleithner

BSD License
###

async = require 'async'
quack = require 'quack-array'
assert = require 'assert'
colors = require 'colors'
eyes = require 'eyes'
fs = require 'fs'
{ EventEmitter } = require('events')

net = require "net"
repl = require "repl"
path = require "path"
mkdirp = require "mkdirp"
vm = require 'vm'
config_base = path.join(process.env.HOME, ".config", "inode")
history_file = path.join(config_base, "history")
history = null
util = require 'util'

log = eyes.inspector()

old_history = []

command_nr = 0


nice_error = (err) ->
    return if not err
    self.outputStream.write('\n')
    self.outputStream.write('Caught exception: '.red.bold + err.message.red + "\n")
    self.outputStream.write(String(err.stack) + "\n")
    self.rli.prompt()


process.on 'uncaughtException', nice_error

shell = repl.start("> ")

# fix the most annoying default sigint handler
shell.rli.removeAllListeners('SIGINT')

self = shell

mkdirp config_base, 0755, (err) ->
    fs.open history_file, "a+", (err, fd) ->
        history = fd

    fs.readFile history_file, "utf-8", (err, data) ->
        if not data
            return
        dat = data.split("\n")
        for line in dat
            self.rli.history.unshift String(line)
        self.rli.history_index = -1

shell.rli.write("inode".yellow.bold + " type ".grey + ".help".white.bold + " for help".grey + "\n")
shell.rli.bufferedCommand = ""

shell.eval ?= (code, context, file, cb) ->
    try
        [err, result] = vm.runInContext(code, context, file)
    catch e
      err = e
    cb(err, result)


shell.rli.on 'SIGINT', () ->
    if self.bufferedCommand.length == 0
        self.outputStream.write('\n(^C abort command. Press ^D to exit.)'.red)
    
    self.rli.line = ''
    self.rli.write('\n')
    self.bufferedCommand = ''
    self.displayPrompt()

shell.rli.on 'line', (line) ->
    if line.trim() == ""
        self.bufferedCommand = self.bufferedCommand.trimRight()
    else
        command_nr += 1
        if history
            buf = new Buffer(line + "\n")
            fs.write(history, buf, 0, buf.length, null)

shell.displayPrompt = () ->
    if self.bufferedCommand.length
        self.rli.setPrompt('... '.white, 4)
    else
        pure = 'In [' + command_nr + ']: '
        self.rli.setPrompt('In ['.cyan + String(command_nr).cyan.bold + ']: '.cyan, pure.length)
    self.rli.prompt()

shell.context["_shell"] = shell
shell.context["log"] = log

shell.defineCommand 'req',
    help: 'requires a module: ARG = require("ARG")  or  ARG1 = require("ARG2")',
    action: (args) ->
        args = args.split(" ")
        if args.length == 1
            self.eval args[0] + " = require('" + args[0] + "');", self.context, 'repl', (e, ret) ->
                nice_error(e)
        else if args.length == 2
            self.eval args[0] + " = require('" + args[1] + "');", self.context, 'repl', (e, ret) ->
                nice_error(e)
