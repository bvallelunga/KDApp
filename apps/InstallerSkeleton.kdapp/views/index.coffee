class {{ appCap }}MainView extends KDView

  constructor:(options = {}, data)->
    @kiteHelper = new KiteHelper

    @installer = new {{ appCap }}InstallerController
        kiteHelper: @kiteHelper

    @selectVm = new {{ appCap }}SelectVm
        kiteHelper: @kiteHelper
        installer : @installer

    options.cssClass = "#{appCSS} main-view"
    super options, data

  viewAppended: ->
    @addSubView @wrapper = new KDCustomHTMLView
      tagName       : 'div'
      cssClass      : 'wrapper'

    @wrapper.addSubView @selectVm

    @wrapper.addSubView @container = new KDCustomHTMLView
      tagName       : 'div'
      cssClass      : 'container'

    @container.addSubView new KDCustomHTMLView
      tagName       : 'img'
      cssClass      : 'logo'
      attributes    :
        src         : logo

    @container.addSubView @progress = new KDCustomHTMLView
      tagName       : 'div'
      cssClass      : 'progress-container'

    @progress.updateBar = (percentage, unit, status, override)->
      if percentage is 100 and not override
        @loader.hide()
      else
        @loader.show()

      @title.updatePartial(status)
      @bar.setWidth(percentage, unit)

    @progress.addSubView @progress.title = new KDCustomHTMLView
      tagName       : 'div'
      cssClass      : 'title'
      partial       : 'Checking VM State...'

    @progress.addSubView @progress.bar = new KDCustomHTMLView
      tagName       : 'div'
      cssClass      : 'bar'

    @progress.addSubView @progress.loader = new KDLoaderView
      showLoader    : yes
      size          :
        width       : 20
      cssClass      : "spinner"

    @container.addSubView @link = new KDCustomHTMLView
      cssClass : 'hidden running-link'

    @link.setSession = =>
      @installer.isConfigured()
        .then (configured)=>
          url = unless configured then configureURL else launchURL

          if url
            url = "http://#{@kiteHelper.getVm()}#{url}"

            @link.updatePartial """
              Click here to launch #{appName}:
              <a target='_blank' href='#{url}'>#{url}</a>
            """
            @link.show()
        .catch (error)=>
          console.error error
          @updateProgress "Failed to check if #{appName} is configured."

    @container.addSubView @buttonContainer = new KDCustomHTMLView
      tagName       : 'div'
      cssClass      : 'button-container'

    @buttonContainer.addSubView @installButton = new KDButtonView
      title         : "Install #{appName}"
      cssClass      : 'button green solid hidden'
      callback      : => @commitCommand INSTALL

    @buttonContainer.addSubView @reinstallButton = new KDButtonView
      title         : "Reinstall"
      cssClass      : 'button solid hidden'
      callback      : => @commitCommand REINSTALL

    @buttonContainer.addSubView @uninstallButton = new KDButtonView
      title         : "Uninstall"
      cssClass      : 'button red solid hidden'
      callback      : => @commitCommand UNINSTALL

    @container.addSubView new KDCustomHTMLView
      cssClass : "description"
      partial  : description

    KD.utils.defer =>
      @installer.on "status-update", @bound "statusUpdate"
      @installer.init()

  statusUpdate: (message, percentage)->
    percentage ?= 100

    element.hide() for element in [
      @installButton, @reinstallButton, @uninstallButton, @link
    ]

    switch @installer.state
      when NOT_INSTALLED
        if percentage is 100
          @installButton.show()
          @selectVm.disabled false
        @updateProgress message, percentage
      when INSTALLED
        if percentage is 100
          @reinstallButton.show()
          @uninstallButton.show()
          @link.setSession()
          @selectVm.disabled false
        @updateProgress message, percentage
      when WORKING
        @selectVm.disabled true
        @installer.state = @installer.lastState
        @updateProgress message, percentage, true
      when FAILED
        @installer.state = @installer.lastState
        @statusUpdate message, percentage
      when ABORT
        @selectVm.turnOffVmModal()
        @updateProgress message, percentage
      when WRONG_PASSWORD
        @installer.state = @installer.lastState
        @passwordModal yes, (password)=>
          if password?
            @installer.command @installer.lastCommand, password
      else
        @updateProgress message, percentage

  commitCommand: (command)->
    switch command
      when INSTALL then name = "install"
      when REINSTALL then name = "reinstall"
      when UNINSTALL then name = "uninstall"
      else return throw "Command not registered."

    if scripts[name].sudo
      @passwordModal no, (password)=>
        if password?
          @installer.command command, password
    else
      @installer.command command

  passwordModal: (error, cb)->
    unless @modal
      unless error
        title = "#{appName} needs sudo access to continue"
      else
        title = "Incorrect password, please try again"

      @modal = new KDModalViewWithForms
        title         : title
        overlay       : yes
        overlayClick  : no
        width         : 550
        height        : "auto"
        cssClass      : "new-kdmodal"
        cancel        : =>
          @modal.destroy()
          delete @modal
          cb()
        tabs                    :
          navigable             : yes
          callback              : (form)=>
            @modal.destroy()
            delete @modal
            cb form.password
          forms                 :
            "Sudo Password"     :
              buttons           :
                Next            :
                  title         : "Submit"
                  style         : "modal-clean-green"
                  type          : "submit"
              fields            :
                password        :
                  type          : "password"
                  placeholder   : "sudo password..."
                  validate      :
                    rules       :
                      required  : yes
                    messages    :
                      required  : "password is required!"

  updateProgress: (status, percentage, override)->
    percentage ?= 100
    @progress.updateBar percentage, '%', status, override
