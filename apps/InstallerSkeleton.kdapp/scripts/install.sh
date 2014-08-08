#       Setup - DO NOT TOUCH        #
# --------------------------------- #
if [ $# -lt 2 ]
  then
  echo "Please provide a username and log output"
  echo "bash install.sh <user> <log output>"
  echo ""
  exit 0
else
  USER=$1
  OUT=$2
  mkdir -p $OUT
fi

#       Start Coding Here...        #
# --------------------------------- #
touch $OUT/"10-Starting Install"
# Code install commands

touch $OUT/"100-Finishing Install"
# Code last touches commands
