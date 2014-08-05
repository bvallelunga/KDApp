class {{ appCap }}MainView extends KDView

  constructor:(options = {}, data)->
    options.cssClass = '{{ appCap }} main-view'
    super options, data

  viewAppended:->
    @addSubView new KDView
      partial  : "Welcome to {{ app }} app!"
      cssClass : "welcome-view"

class {{ appCap }}Controller extends AppController

  constructor:(options = {}, data)->
    options.view    = new {{ appCap }}MainView
    options.appInfo =
      name : "{{ app }}"
      type : "application"

    super options, data

do ->

  # In live mode you can add your App view to window's appView
  if appView?
    view = new {{ appCap }}MainView
    appView.addSubView view

  else
    KD.registerAppClass {{ appCap }}Controller,
      name     : "{{ appCapOne }}"
      routes   :
        "/:name?/{{ appCapOne }}" : null
        "/:name?/{{ userLower }}/Apps/{{ appCapOne }}" : null
      dockPath : "/{{ userLower }}/Apps/{{ appCapOne }}"
      behavior : "application"