#!/bin/bash -

checks() {
  if [[ ! $(which ffmpeg 2> /dev/null) == "" ]]; then
    echo "error: ffmpeg is missing from \$PATH." > /dev/stderr
    echo 0
    return;
  fi
  echo 1
}

dir_exists() {
  if [[ ! -d $1 ]]; then
    echo "error: missing directory." > /dev/stderr
    echo 0
    return;
  fi
  echo 1
}

convert_webps() {
  local patt="(.+?)\.webp"

  for webp in ${@}; do
    if [[ -f $webp ]]; then
      [[ $webp =~ $patt ]] && {
        local filename=${BASH_REMATCH[1]}
        echo -e "Converting: $webp -> $filename.png\n" > /dev/stderr 
        ffmpeg -i $webp $filename.png > /dev/null && rm -rf $webp
      }

      continue;
    fi

    echo "error: $webp does not exist!" > /dev/stderr
  done
}

commands() { 
  for dir in ${@}; do
    if [[ ! -d $dir ]]; then
      echo "error: $dir does not exists!"
      exit;
    fi

    convert_webps $(find $dir -name \*.webp)
  done
}

main() {
  if [[ $TEST -eq 1 ]]; then
    source $SCRIPTS/tests/webp2png-test.sh

    checks_test;
    dir_exists_test;
    convert_webps_test;

    return;
  fi

  commands "$@" 
}

main "$@"
