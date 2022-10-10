#!/usr/bin/env zsh
# setups 

bt_setup_one() {
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
        #source ~/.e/lib/single_app.sh  # point to .e only 
        [[ -f ./setup.sh ]] && source ./setup.sh 
        zsh_call_check_defined "$FUNC"
    )
}

#setup_all docker e 
bt_setup_all(){
  (
    #source ~/.e/lib/all_app.sh
    FUNC=$1
    root=$2 
    if typeset -f  $FUNC > /dev/null; then
      $FUNC $root
    else
      echo " op not supported !"
      bt_usage
    fi
  )
}


bt_usage(){ 
echo "Usage: setup [-a |--all] [info | install | uninstall| reinstall|  setenv | config |pkgmgr ]
  *  cd ~/[.p|.e]/app/*/; setup action
  *  cd ~/[.p|.e]; setup -a action
"
exit 1 
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

###################################################
# params: appname, eroot
bt_to_app_or_root() {
  eroot=$1
  app=$2
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
        echo "$k: None" 
      elif [[ $(($count)) -eq 1 ]]; then
        echo "$k: ${DIRS[@]}" 
        apppath[$k]=${DIRS[1]} 
      fi  
    done
    # to app
    #echo "found:"
    #echo "${(kv)apppath}"
    if [[ -d "$apppath[$eroot]" ]]; then
      cd $apppath[$eroot]
    else
      echo "no matching app in $eroot"
    fi
  fi
  
}

# usage
# rename_all p old new
# rename_all w old new
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
  export CENVROOT=$EROOT[$CENV]
  export CRC=~/.$CENVenvrc 
. ${CENVROOT}/etc/config.sh

if [[ "$1" == "-a" ]] || [[ "$1" == "--all" ]]; then 
    [[ ! "$PWD" =~ "$CENVROOT"$ ]] && bt_usage
    shift
    source ~/.x/lib/a.sh
    bt_setup_all bt_all_$1 $CENVROOT 
else
    [[ ! "$PWD" =~ "$CENVROOT/app/*/" ]] && bt_usage
    source ~/.x/lib/s.sh
    bt_setup_one "$@"
fi

}
