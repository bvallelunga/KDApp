class {{ appCap }}SelectVm extends KDView

  constructor: (options = {}, data)->
    @kiteHelper = options.kiteHelper
    @installer = options.installer

    options.cssClass = "#{appName}-dropdown"
    super options, data

  viewAppended: ->
    @kiteHelper.getReady().then =>
      @addSubView @header = new KDCustomHTMLView
        tagName       : 'div'
        cssClass      : 'header'
        partial       : @namify(@kiteHelper.getVm())

      @addSubView @selection = new KDCustomHTMLView
        tagName       : 'div'
        cssClass      : 'selection'

      @updateList()

  namify: (hostname)->
    return hostname.split(".")[0]

  updateList: ->
    @selection.updatePartial ""
    {vmController} = KD.singletons

    @kiteHelper.getVms().forEach (vm)=>
      @selection.addSubView vmItem = new KDCustomHTMLView
        tagName       : 'div'
        cssClass      : "item"
        click         : =>
          @chooseVm vm.hostnameAlias if !@hasClass "disabled"

      if vm.hostnameAlias is @kiteHelper.getVm()
        vmItem.setClass "active"

      vmItem.addSubView new KDCustomHTMLView
        tagName       : 'span'
        cssClass      : "bubble"

      vmItem.addSubView new KDCustomHTMLView
        tagName       : 'span'
        cssClass      : "name"
        partial       : @namify vm.hostnameAlias

      vmController.info vm.hostnameAlias, (err, vmn, info)=>
        vmItem.setClass info?.state.toLowerCase()

  chooseVm: (vm)->
    @kiteHelper.setDefaultVm vm
    @installer.init()
    @header.updatePartial @namify vm
    @updateList()

  turnOffVm: (vm)->
    @installer.announce "Please wait while we turn off #{@namify vm}...", WORKING, 0

    @kiteHelper.turnOffVm(vm).then =>
      # Wait for Koding to register other vm is off
      KD.utils.wait 10000, =>
        @installer.init()
        @updateList()
    .catch (err)=>
      @installer.error err

  turnOffVmModal: ->
    if @modal
      retun @modal

    {vmController} = KD.singletons
    @addSubView container = new KDCustomHTMLView
        tagName         : 'div'

    container.addSubView new KDCustomHTMLView
        tagName       : 'div'
        cssClass      : "description"
        partial       : """
          Your plan's vm quota requires that you turn off one of your vms to use another
        """

    @kiteHelper.getVms().forEach (vm)=>
      container.addSubView vmItem = new KDCustomHTMLView
        tagName       : 'div'
        cssClass      : "item"
        partial       : """
          <div class="bubble"></div>
          #{vm.hostnameAlias}
        """
        click         : (event)=>
          @turnOffVm vm.hostnameAlias
          @removeModal()

      vmController.info vm.hostnameAlias, (err, vmn, info)=>
        if info?.state != "RUNNING"
          vmItem.destroy()

    @modal = new KDModalView
      title           : "Choose VM To Turn Off"
      overlay         : yes
      overlayClick    : no
      width           : 400
      height          : "auto"
      cssClass        : "new-kdmodal"
      view            : container
      cancel          : => @removeModal()

  removeModal: ->
    @modal.destroy()
    delete @modal

  disabled: (disabled)->
    if disabled
      @setClass "disabled"
    else
      @unsetClass "disabled"
