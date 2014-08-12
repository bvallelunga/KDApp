class {{ appCap }}MainView extends KDView

  constructor:(options = {}, data)->
    options.cssClass = "#{appCSS} main-view"
    @Installer = new {{ appCap }}InstallerController
    super options, data

  viewAppended: ->
    @addSubView @container = new KDCustomHTMLView
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

    @progress.updateBar = (percentage, unit, status)->
      if percentage is 100
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
      @Installer.isConfigured()
        .then (configured)=>
          url = unless configured then configureURL else launchURL

          if url
            @link.updatePartial """
              Click here to launch #{appName}:
              <a target='_blank' href='#{url}'>#{url}</a>
            """
            @link.show()
        .catch (error)=>
          @link.updatePartial "Failed to check if #{appName} is configured."
          @link.show()
          console.error error

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
      @Installer.on "status-update", @bound "statusUpdate"
      @Installer.init()

  statusUpdate: (message, percentage)->
    percentage ?= 100

    if percentage is 100
      if @Installer.state in [NOT_INSTALLED, INSTALLED, FAILED]
        element.hide() for element in [
          @installButton, @reinstallButton, @uninstallButton
        ]

    switch @Installer.state
      when NOT_INSTALLED
        @link.hide()
        @installButton.show()
        @updateProgress message, percentage
      when INSTALLED
        @link.show()
        @reinstallButton.show()
        @uninstallButton.show()
        @link.setSession()
        @updateProgress message, percentage
      when WORKING
        @link.hide()
        @Installer.state = @Installer.lastState
        @updateProgress message, percentage
      when FAILED
        @Installer.state = @Installer.lastState
        @statusUpdate message, percentage
      when WRONG_PASSWORD
        @Installer.state = @Installer.lastState
        @passwordModal yes, (password)=>
          @Installer.command @Installer.lastCommand, password if password?
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
          @Installer.command command, password
    else
      @Installer.command command

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

  updateProgress: (status, percentage)->
    @progress.updateBar percentage, '%', status
