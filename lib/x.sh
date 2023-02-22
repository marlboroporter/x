#!/usr/bin/env zsh

source ${XENV_ROOT}/etc/data_env.sh

#log "hi"
log(){
  [[ "${XENV_DEBUG}" = true ]] && echo "$1"  
}




bt_single_app(){
  # ------------- define  local variable and funcs --------------------    
  app=${PWD##/*/}
  ## variable to be overrided by child in each xapp dir
  appdef=""
  setenv="" 
  cheatsheet=""
  # msg
  header(){ echo "# ------ $1: ${app} -- ${appdef} "; } 

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
      shift
      $fun "$@"
    elif typeset -f  $defaultfun > /dev/null; then 
      shift
      $defaultfun "$@" 
    else
      #echo "${!1}" # for bash   
      header $fun
      echo "${(P)fun}" # P indicates to interpret as further paramete 
    fi
  }

  ##
  setenv(){
    header $1 >>$CRC 
    default_setenv="export PATH=$PWD/bin:\$PATH;"
    combo_setenv="$default_setenv$setenv"
    echo "$combo_setenv">>$CRC
    eval "$combo_setenv";  
  }
  
  # ------------- single setup --------------------    
  bt_setup_one() {
      #echo "root=${CENVROOT}"
      root=${CENVROOT}
      [[ ! "$PWD" =~ "$root" ]]  && bt_usage  
      FUNC=${1:-info}
      # for all individual app
      if [[ "$2" == "" ]]; then
          DIR=$PWD
      else
          DIR=$root/$2
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
    #echo 'export PATH=~/..'"$CENV"'/bin:$PATH' > $CRC 
    echo "# -------------------------- $CENV -------------------------" > $CRC 
  }

  bt_all_install(){
      bt_init_rc
      bt_all $@  config setenv  
  }

  bt_all_uninstall() {
      bt_all $@   
      # update installed list ?
  }

  bt_all_reinstall(){
      bt_init_rc
      bt_all $@ config setenv  
  }

  bt_all_setenv(){
      bt_init_rc
      bt_all $@ 
  }

  # bt_all e f1 f2 ...
  bt_all(){
      cenv=$1  
      shift
      for d in $apps  
      do 
          (
          bt_to_app_or_root $cenv $d; 
          for f in $@
          do 
              $W_APP_EXE $f; 

          done
          )           
      done
  }

  # ------------- all main --------------------    

  bt_setup_all(){
    (
      . ${CENVROOT}/.xenvetc/config.sh
      cenv=$1
      FUNC=$2
      if typeset -f  bt_all_$FUNC > /dev/null; then
        bt_all_$FUNC $@
      else
        echo "OP not predefined for all, try all!"
        bt_all $@ 
      fi
    )
  }


  # ------------- all main --------------------    
  W_APP_EXE=bt_env_app    
  bt_setup_all "$@" 
  # ------------- unset local funcs --------------------    
  unset -f  bt_init_rc
  unset -f  bt_all_install
  unset -f  bt_all_uninstall
  unset -f  bt_all_reinstall
  unset -f  bt_all_setenv
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
  if [[  $EROOT[$eroot] == ""  ]]; then
    echo "$eroot not a configured xenv!"
  elif [[ "$app" == "" ]]; then
    cd $EROOT[$eroot]
  # to app
  else 
    # find unique dir path in each eroot 
    declare -A apppath 
    for k v in ${(kv)EROOT} 
    do
      log "$k $v"
      #DIRS=($([[ -d $v ]] && find $v -type d -name $app)) # not allow even top level link
      DIRS=( 
            $(
              if ( [[ -d $v ]]  ||  [[ -L $v ]]  )  
              then 
                       cd "$v";  find . -type d -name $app |grep -v "\.git"
              fi
            ) # catch output
          ) # to array 
      count=${#DIRS[@]} 
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
        apppath[$k]=$v/${DIRS[1]} 
      fi  
    done
    # to app
    log "found: ${(kv)apppath}"
    if [[ -d "$apppath[$eroot]" ]]; then
      log "cd $apppath[$eroot]"
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

  if ([[ "$PWD" == "$CENVROOT" ]]); then
    #bt_all_app  $CENVROOT  $1 
    bt_all_app $CENV $1 
  elif [[ "$PWD" =~ "$CENVROOT/*/" ]]; then
     bt_single_app "$@" 
  else
    bt_usage
  fi
}

bt_show_app_and_links(){
}

bt_parse_readme(){
  section=" $1"
}

