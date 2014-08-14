# DO NOT TOUCH
[NOT_INSTALLED, INSTALLED, WORKING,
FAILED, WRONG_PASSWORD, INSTALL, ABORT
REINSTALL, UNINSTALL]   = [0..7]
user                    = KD.nick()
domain                  = "#{user}.kd.io"
vmHostname              = "#{user}.koding.kd.io"
getSession              = -> (Math.random() + 1).toString(36).substring 7

# Configure App Here
app                     = "{{ appLower }}"                                             # App name used for variables
appName                 = "{{ app }}"                                                  # App name used for titles and statuses
appCSS                  = "{{ appCap }}-installer"                                     # App name used for css
github                  = "https://rest.kd.io/{{ github }}/{{ appCap }}.kdapp/master"  # Git repository on the master branch
logo                    = "#{github}/resources/logo.png"                               # The main logo centered at the top of the app
launchURL               = "/#{app}"                                                    # The relative url used after the app is configured (can be set to "false")
configureURL            = "/#{app}/install"                                            # The relative url used to configure app (can be set to "false")
installChecker          = "/home/#{user}/Web/#{app}/"                                  # Path to check if the app is instaled
configuredChecker       = "/home/#{user}/Web/#{app}/config.inc.php"                    # Path to check if configured after install (can be set to "false")
logger                  = "/tmp/_{{ appCap }}.#{getSession()}.out"                     # Path to log installer progress
scripts                 =                                                              # Scripts with url and if sudo access required
  install   :
    url     : "#{github}/scripts/install.sh"
    sudo    : true
  reinstall :
    url     : "#{github}/scripts/reinstall.sh"
    sudo    : true
  uninstall :
    url     : "#{github}/scripts/uninstall.sh"
    sudo    : true
description             =                                                              # The main description centered under the progress bar
"""
<p>
  <div class="center bold">Welcome to {{ app }} Installer App!</div>
</p>
"""


# Addition Configuration Variables Here
