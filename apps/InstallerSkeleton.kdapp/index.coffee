class @@acController extends AppController

  constructor:(options = {}, data)->
    options.view    = new @@acMainView
    options.appInfo =
      name : "@@a"
      type : "application"

    super options, data

do ->

  # In live mode you can add your App view to window's appView
  if appView?
    view = new @@acMainView
    appView.addSubView view

  else
    KD.registerAppClass @@acController,
      name     : "@@aco"
      routes   :
        "/:name?/@@aco" : null
        "/:name?/@@ul/Apps/@@aco" : null
      dockPath : "/@@ul/Apps/@@aco"
      behavior : "application"