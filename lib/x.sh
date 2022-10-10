#!/usr/bin/env zsh

source ~/.x/etc/data_env.sh

bt_single_app(){
  # ------------- define  local funcs --------------------    
  app=${PWD##/*/}
  # msg
  headerprefix="# ------ ${app} ----"
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
  
  # ------------- single setup --------------------    
  bt_setup_one() {
      echo "root=${CENVROOT}"
      root=${CENVROOT}
      [[ ! "$PWD" =~ "$root/app" ]]  && bt_usage  
      FUNC=${1:-info}
      # for all individual app
      if [[ "$2" == "" ]]; then
          DIR=$PWD
      else
          DIR=$root/app/$2
      fi
      ( 
          cd $DIR  
          zsh_call_check_defined "$FUNC"
      )
  }
  # ------------- single main --------------------    
  [[ -f ./setup.sh ]] && source ./setup.sh 
  bt_setup_one "$@"

  # ------------- undefine  local funcs --------------------    
  unset -f  header
  unset -f  bresetenv
  unset -f  brew_install  
  unset -f  brew_uninstall
  unset -f  brew_reinstall
  unset -f  pipenv
  unset -f  pip_install
  unset -f  pip_uninstall
  unset -f  pip_reinstall
  unset -f  noop_install
  unset -f  noop_reinstall
  unset -f  noop_uninstall
  unset -f  bash_call_check_defined
  unset -f  zsh_call_check_defined
  unset -f  setenv

}

################################## all ###################################
bt_all_app(){
  
  # ------------- define  local funcs --------------------    

  bt_init_rc(){
      echo 'export PATH=~/.e/bin:$PATH'>$CRC
  }

  bt_all_install(){
      bt_init_rc
      for x in $apps 
      do 
          (cd $1/app/$x; 
          $W_APP_EXE install           
          $W_APP_EXE config 
          $W_APP_EXE setenv 
          )
      done
  }

  bt_all_uninstall(){
      for x in $apps 
      do 
          (cd $1/app/$x; $W_APP_EXE uninstall )           
      done
  }

  bt_all_reinstall(){
      #init_rc
      for x in $apps 
      do 
          (cd $1/app/$x; 
          $W_APP_EXE reinstall            
          $W_APP_EXE config  
          $W_APP_EXE setenv  
          )
      done
  }

  bt_all_setenv(){
      bt_init_rc
      for x in $apps 
      do 
          (cd $1/app/$x; $W_APP_EXE setenv  )
      done
  }


  bt_all_init_rc(){
    bt_init_rc
    bt_all $*

  }

  bt_all(){
      root=$1
      func=$2
      for x in $apps 
      do 
          (cd $root/app/$x; $W_APP_EXE $func)           
      done
  }

  # ------------- all main --------------------    
  bt_setup_all(){
    (
      
      . ${CENVROOT}/etc/config.sh
      #source ~/.e/lib/all_app.sh
      FUNC=$1
      root=$2 
      #echo "$FUNC $root"

      if typeset -f  bt_all_$FUNC > /dev/null; then
        bt_all_$FUNC $root
      else
        echo "OP not predefined for all, try all!"
        bt_all $root $FUNC
      fi
    )
  }


  # ------------- all main --------------------    
  W_APP_EXE=bt_env_app    
  #if [[ -z "${apps+x}" ]]; then apps=(x); fi   
   
  bt_setup_all "$@" 
  #
  # ------------- unset local funcs --------------------    
  unset -f  bt_init_rc
  unset -f  bt_all_install
  unset -f  bt_all_uninstall
  unset -f  bt_all_reinstall
  unset -f  bt_all_setenv
  unset -f  bt_all_init_rc
  unset -f  bt_all
  unset -f  bt_setup_all

}


################### funcs ################################

bt_usage(){ 
  echo "usage: e p w"
  #exit 1
  return 0 # to use  && on return 
}


bt_is_in_env(){
  [[ $PWD =~ $EROOT[$1] ]]
}

bt_get_curenv(){
  for e in ${(k)EROOT} 
  do
    if [[ $PWD =~ $EROOT[$e] ]] ; then echo "$e"; fi
  done
  echo ""
}

################### go to app dir ################################
bt_to_app_or_root() {
  eroot=$1
  app=$2
  #echo "\$EROOT[$eroot]=$EROOT[$eroot]"
  # to root
  if [[ -d $EROOT[$eroot] ]] && [[ "$app" == "" ]];  then
    cd $EROOT[$eroot]
  # to app
  else 
    # find unique dir path in each eroot 
    declare -A apppath 
    for k v in ${(kv)EROOT} 
    do
      DIRS=($([[ -d $v/app ]] && find $v/app -type d -name $app))
      count=${#DIRS[@]} 
      #echo "$DIRS[@] : $count"
      if [[ $(($count)) -gt 1 ]]; then
        echo "$k: $count ducplicates: "
        for d in "${DIRS[@]}"; do
          echo "   $d"
        done
      elif [[ $(($count)) -lt 1 ]]; then
        #echo "$k: None" 
        :;
      elif [[ $(($count)) -eq 1 ]]; then
        #echo "$k: ${DIRS[@]}" 
        apppath[$k]=${DIRS[1]} 
      fi  
    done
    # to app
    #echo "found:${(kv)apppath}"
    if [[ -d "$apppath[$eroot]" ]]; then
      #echo "cd $apppath[$eroot]"
      cd $apppath[$eroot]
    else
      echo "no matching app in $eroot"
    fi
  fi
  
}

################### rename symbol in a root dir ################################
# rename_all e old new
bt_rename_all() {
  envroot=$1 
  old=$2
  new=$3
  dirs=($(find $EROOT[envroot] -type d |grep -v "\.git"))
  for d in "${dirs[@]}"
  do
    files=($(find $d  -type f -name "*.sh")) 
    for f in  "${files[@]}" 
    do
      echo $f
      sed -i '' -e "s/$old/$new/g" "$f"  
    done
  done
}

bt_env_app(){
  export CENV=$(bt_get_curenv)

  if [[ $CENV  == "" ]]; then 
    bt_usage && return
  else
    export CENVROOT=$EROOT[$CENV]
    export CRC=~/.${CENV}envrc 
  fi

  if [[ "$PWD" == "$CENVROOT" ]]; then
    bt_all_app $1 $CENVROOT 
  elif [[ "$PWD" =~ "$CENVROOT/app/*/" ]]; then
     bt_single_app "$@" 
  else
    bt_usage
  fi
}
