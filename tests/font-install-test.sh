checks_test() {
  # Test 1) Non existing directories

  local testNonDir=(
    '/blah'
    '/etc/nond'
    "$HOME/.testd"
    '/boot/loader'
  )

  local def=$DOWNLOAD_PATH

  for nonDir in ${testNonDir[@]}; do
    DOWNLOAD_PATH=$nonDir

    if [[ $(checks) -eq 1 ]]; then
      echo "(fail) checks is expected to fail! (input: \"$nonDir\")"
      continue;
    fi

    echo "(ok) checks passed! (input: \"$nonDir\")"
  done

  DOWNLOAD_PATH=$def

  # Test 2) Non existing font zip in parameters.
  checks "$@"
}

selectd_choices_test() {
  DOWNLOAD_PATH="/tmp/tests"
  mkdir -p $DOWNLOAD_PATH

  local testfiles=(
    "Consolas.zip"
    "Go-Mono.zip"
    "InconsolataGo.zip"
    "Membrane-Mono.zip"
  )
  
  for file in ${testfiles[@]}; do
    touch $DOWNLOAD_PATH/$file
  done

  for (( i=${#testfiles[@]}; i>0; i-- )); do
    local index=$(expr 4 - $i)
    local res=$(selectd_choices <<< $i)
    if [[ $(basename $res) == "${testfiles[$index]}" ]]; then 
      echo "(ok) selectd_choices passed! (input: $i)"
      continue;
    fi

    echo "(fail) selectd_choices fail! (input: $i)"
    failed=1
  done

  [[ $failed == 1 ]] && echo -e "\nPossible choices:\n$(print_choices)\n"

  # clean test files
  rm -rf $DOWNLOAD_PATH
}
