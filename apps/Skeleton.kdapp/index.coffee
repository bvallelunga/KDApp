class @@acMainView extends KDView

  constructor:(options = {}, data)->
    options.cssClass = '@@al main-view'
    super options, data

  viewAppended:->
    @addSubView new KDView
      partial  : "Welcome to @@a app!"
      cssClass : "welcome-view"

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
    
  else if appPreview?
    view = new @@acMainView
    appPreview.addSubView view

  else
    KD.registerAppClass @@acController,
      name     : "@@ac"
      routes   :
        "/:name?/@@ac" : null
        "/:name?/@@ul/Apps/@@ac" : null
      dockPath : "/@@ul/Apps/@@ac"
      behavior : "application"