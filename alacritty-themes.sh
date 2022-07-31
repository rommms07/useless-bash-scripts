#!/bin/bash -

CONFIG=$HOME/.alacritty.yml
THEMES_FOLDER=$HOME/.alacritty-themes
DEFAULT_CONFIG=$SCRIPTS/.alacritty.yml
IFS=$'\n'

print_choices() {
  local selected=$(cat $THEMES_FOLDER/.selected-theme)
  files && local j=1;

  for theme in ${FILES[@]}; do
    local toggled=""
    if [[ $selected == $j ]]; then
      toggled="(*)"
    fi

    printf "\u001b[1m[%2d]\u001b[0m %s %s\n" $j $(basename $theme) $toggled
    j=$(expr $j + 1)
  done
}

select_themes() {
  files;
  local matcher="[0-9]+"
  if [[ ! $1 =~ $matcher ]]; then
    echo "error: invalid parameter (NaN)"
    exit;
  fi

  local themefile=${FILES[$(expr $1 - 1)]}

  echo -e "$(cat $DEFAULT_CONFIG)\n\n$(cat "$THEMES_FOLDER/$themefile")" > $HOME/.alacritty.yml
  echo $1 > $THEMES_FOLDER/.selected-theme
}

select_themes_test() {
  select_themes $1
}

files() {
  FILES=($(ls $THEMES_FOLDER))
}

main() {
  touch $THEMES_FOLDER/.selected-theme
  
  case $1 in
    list)
      print_choices
      ;;
    set)
      [[ $TEST -eq 1 ]] && select_themes_test $2 || select_themes $2
      ;;
  esac

}

main "$@"
