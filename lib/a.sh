###################################
#  all
#
###################################
W_APP_EXE=bt_env_app    

bt_init_rc(){
    echo 'export PATH=~/.e/bin:$PATH'>$CRC
}

# install curroot
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
