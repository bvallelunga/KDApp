class {{ appCap }}InstallerController extends KDController

  constructor:(options = {}, data)->

    { {{ appLower }}InstallerController } = KD.singletons
    return {{ appLower }}InstallerController if {{ appLower }}InstallerController

    @kiteHelper = options.kiteHelper
    @registerSingleton "{{ appLower }}InstallerController", this, yes
    super options, data

  announce:(message, state, percentage)->
    @updateState state if state?
    @emit "status-update", message, percentage

  error: (err, override)->
    message = err.details?.message or err.message
    state = FAILED

    switch message
      when "Permissiond denied. Wrong password"
        message = "Your password was incorrect, please try again"
        state = WRONG_PASSWORD
      when "CPU limit reached"
        message = "To use another vm with your plan, please turn off one of your vms"
        state = ABORT
      else
        message = override

    console.log err
    @announce message, state

  init: ->
    @announce "Checking your vm's status...", WORKING, 0
    @kiteHelper.getKite().then (kite)=>
      @watcherDirectory()

      kite.fsExists(path: installChecker).then (state)=>
        unless state
          @announce "#{appName} not installed", NOT_INSTALLED
        else
          @announce "#{appName} is installed", INSTALLED
      .catch (err)=>
          @error err
    .catch (err)=>
      @error err

  command: (command, password, retry)->
    switch command
      when INSTALL then name = "install"
      when REINSTALL then name = "reinstall"
      when UNINSTALL then name = "uninstall"
      else return @error message: "Command not registered."

    @lastCommand = command
    @announce "#{@namify name}ing #{appName}...", null, 0
    session = getSession()

    @configureWatcher(session).then (watcher)=>
      @kiteHelper.run
        command: "curl -sL #{scripts[name].url} | bash -s #{user} #{logger}/#{session}/ #{@mysqlPassword} > #{logger}/#{name}.out"
        password: if scripts[name].sudo then password else null
      , (err, res)=>
        watcher.stopWatching()

        # Usually script have some output. If no output, retry command
        if not retry? and not err? and not res.stdout and not res.stderr
          return @command @lastCommand, password, true
        else if err? or res.exitStatus != 0
          @error err or message: res.stderr, "Failed to #{name} #{appName}, please contact support if the issue continues"
        else
          @init()

    .catch (err) =>
      @error err

  configureWatcher: (session, cb)->
    new Promise (resolve, reject) =>
      @kiteHelper.run
        command : "mkdir -p #{logger}/#{session}"
      , (err)=>
        unless err
          watcher = new FSWatcher
            path : "#{logger}/#{session}"
            recursive : no
            vmName: @kiteHelper.getVm()
          watcher.fileAdded = (change)=>
            {name} = change.file
            [percentage, status] = name.split '-'
            @announce status, WORKING, percentage if percentage? and status?

          watcher.watch()
          resolve watcher
        else
          reject err

  watcherDirectory: ->
    @kiteHelper.run
        command : "mkdir -p #{logger}/"
    , (err)=>
      @error err if err?

  updateState: (state)->
    @lastState = @state
    @state = state

  namify: (name)->
    return (name.split(/\s+/).map (word) -> word[0].toUpperCase() + word[1..-1].toLowerCase()).join ' '

  isConfigured: ->
    new Promise (resolve, reject)=>
      unless configuredChecker
        return resolve yes

      @kiteHelper.getKite().then (kite)=>
        kite.fsExists(path: configuredChecker)
          .then(resolve)
          .catch(reject)
