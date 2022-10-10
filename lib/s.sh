###################################
#  single app  
#
###################################
app=${PWD##/*/}
# msg
headerprefix="
# ------ ${app} --"
# concatenate
header(){ echo "$headerprefix $1"; } 

## brew
bresetenv(){
# apple m1 differ from intel
! [ -L /usr/local/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
export HOMEBREW_NO_INSTALL_CLEANUP=true #  unset to cancel
export HOMEBREW_NO_ENV_HINTS=true # unset to concel
}
brew_install()  { bresetenv;  brew install $app; }
brew_uninstall(){ bresetenv;  brew uninstall $app; }
brew_reinstall(){ bresetenv;  brew install -f $app; }

## pip 
pipenv(){
    #echo "pip current used global pyenv setting"
    echo ""
}
pip_install(){ pipenv; pip install $app; }
pip_uninstall(){ pipenv; pip unintall $app; }
pip_reinstall(){ pipenv; echo " pip has no reinstall!" }


## noop 
noop_install(){ echo "no op!"; }
noop_reinstall(){ echo "no op!"; }
noop_uninstall(){ echo "no op!"; }

#default but overridden by app by reassign pkgmgr 
pkgmgr=${WPKGMGR:-noop}

bash_call_check_defined(){
  fun=$1
  defaultfun=${pkgmgr}_$fun 
  if [[ $(type -t $fun) == function ]] ; then 
    $fun 
  elif [[ $(type -t $defaultfun) == function ]] ; then 
    $defaultfun
  fi
}

zsh_call_check_defined(){
  fun=$1
  defaultfun=${pkgmgr}_$fun 
  # this check function also avoid invoke base unix command accidently such as install
  if typeset -f  $fun > /dev/null; then 
    header $fun
    $fun 
  elif typeset -f  $defaultfun > /dev/null; then 
    $defaultfun
  else
    # sh.e variable of same name defined  
    #echo "${!1}" # for bash   
    header $fun
    echo "${(P)fun}" # P indicates to interpret as further paramete 
  fi
}

## variable to be overrided by child
setenv="" 
cheatsheet=""
##
setenv(){
  echo "$headerprefix">>$CRC; 
  echo "$setenv">>$CRC; 
  #echo "appended to $CRC:  $setenv";  
  eval "$setenv";  
}
