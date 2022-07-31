#!/bin/bash

DOWNLOAD_PATH=$HOME/Downloads
INSTALL_PATH=$HOME/.local/share/fonts

commands() {
  case $1 in
    list)
      print_choices
      ;;
    install)
      install_fonts "$@" 
      ;;
  esac
}

# Check if the system is suitable for using this script, if not
# terminate the script.
checks() {
  local exists=$([[   ! -d $DOWNLOAD_PATH ]] && echo 0 || echo 1)

  if [[ $exists -eq 1 ]]; then
    return;
  fi

  echo $exists
}

print_choices() {
  files && local i=1

  for file in ${FILES[@]}; do
    printf "\u001b[1m[%d]\u001b[0m %s\n" $i $file
    i=$(expr $i + 1)
  done 
}

selectd_choices() {
  files && read -a SELECTED

  local res=( )

  for i in ${SELECTED[@]}; do
    res+=${FILES[$(expr $i-1)]}
  done

  echo $res
}

files() {
  FILES=($(find $DOWNLOAD_PATH -name *.zip -or -name *.rar -or -name *.tar*))
}

install_fonts() {
  files
  
  # Create directory if it does not exists.
  mkdir -p $HOME/.local/share/fonts >& /dev/null

  for cmd in "$@"; do
    if [[ $cmd != "install" ]]; then
      local target=$(selectd_choices <<< $cmd)
      local matcher="(.+?)\.(.+)"

      if [[ $target =~ $matcher ]]; then
        local name=$(basename ${BASH_REMATCH[1]})
        local ext=${BASH_REMATCH[2]}

        mkdir -p $INSTALL_PATH/$name >& /dev/null
        cd $INSTALL_PATH/$name

        case $ext in
          zip)
            unzip $target    
            ;;
          tar*)
            tar xvf $target
            ;;
          rar)
            unrar $target
            ;;
        esac

        # Delete after install
        rm $target
      fi
    fi
  done
}

main() {
  if [[ $TEST -eq 1 ]]; then
    source $HOME/Documents/Scripts/tests/font-install-test.sh
    checks_test "$@"
    selectd_choices_test
    return;
  fi

  commands "$@" 
}

main "$@"
