
checks_test() {
  local expected=$(which dwebp > /dev/null; echo $?)

  if [[ $expected -eq 0 && $(checks 2> /dev/null) -eq 1 ]]; then
    echo "(fail) checks failed! (output: $(checks))"
  fi

  echo "(ok) checks passed!"
}

dir_exists_test() {
  local patt="(.+?),([0-1])"
  local tests=(
    "/usr/share/fonts,1"
    "/usr/share/aclocal2,0",
    "/home/rom/Documents,1",
    "/home/rom/Downloads/Movies,0",
    "/home/rom/Videos/.gallery,1",
    "/home/rom/Files,0",
    "/boot/grub2,0",
    "/boot,1",
    "/boot/grub/themes,1"
  )

  for _test in ${tests[@]}; do
    [[ $_test =~ $patt ]] && {
      local input=${BASH_REMATCH[1]}
      local expected=${BASH_REMATCH[2]}

      if [[ ! $expected -eq $(dir_exists $input 2> /dev/null) ]]; then
        echo "(fail) dir_exists failed! (input: $input)"
        continue;
      fi

      echo "(ok) dir_exists passed! (input: $input)"
    }
  done
}

convert_webps_test() {
  local rm_count=0
  local ffmpeg_ccount=0

  rm() { 
    echo "(mock) rm $@"
    rm_count=$(expr $rm_count + 1)
  }

  ffmpeg() {
    echo "(mock) ffmpeg $@"
    ffmpeg_ccount=$(expr $ffmpeg_ccount + 1)
  }

  local testwebps=(
    "$HOME/Pictures/Inspirations/07222020/31782d9cd5567528c8c9db06d3341a32.webp"
    "$HOME/Pictures/Inspirations/07222020/original-15f054e4faae2faf93821134ca358a10.webp"
  )

  convert_webps "${testwebps[@]}" 2> /dev/null

  if [[ ! $ffmpeg_ccount -eq ${#testwebps[@]} && ! $rm_count -eq ${#testwebps[@]} ]]; then
    echo "(fail) convert_webps did not called ffmpeg ${#testwebps[@]} times!"
    return;
  fi

  echo "(ok) convert_webps passed!"
}
