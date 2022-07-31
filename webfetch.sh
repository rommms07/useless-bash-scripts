#!/bin/bash -

OFFLINE_PAGES="$HOME/.offline-pages"

# To avoid messing up the current working directory
cd /tmp

http_server_args=( -p 32000 --gzip --ext html )

tar_args=(
  --xz
  -cf
)

wget_args=(
  --user-agent=\""Mozilla/5.0 (X11; Linux x86_64; rv:102.0) Gecko/20100101 Firefox/102.0"\"
  --mirror
  --recursive
  --level=3
  --timestamping
  --page-requisites
  --html-extension
  --convert-links
  --no-parent
  --show-progress
  --quiet
)

checks() {
  if [[ $(which sha256sum 2> /dev/null) == "" ]]; then
    echo "error: can't find \`sha256sum\` binary from \$PATH." > /dev/stderr
    echo 0 
    return;
  fi

  if [[ $(which wget 2> /dev/null) == "" ]]; then
    echo "error: can't find \`wget\` binary from \$PATH." > /dev/stderr
    echo 0
    return;
  fi

  if [[ $(which tar 2> /dev/null) == "" ]]; then
    echo "error: can't find \`tar\` binary from \$PATH." > /dev/stderr
    echo 0
    return;
  fi

  if [[ $(which serve 2> /dev/null) == "" ]]; then
    echo "error: can't find \`serve\` binary from \$PATH." > /dev/stderr
    echo 0
    return;
  fi

  echo 1
}

fetch_links() {
  local oksum=0

  for url in ${@}; do
    local domain=$(get_domain $url)

    if [[ ! -d $OFFLINE_PAGES ]]; then
      mkdir -p "$OFFLINE_PAGES" >& /dev/null
      [[ ! $? -eq 0 ]] && { echo "error: fetch_links: could not create directory" > /dev/stderr; exit;  }
    fi
    
    # Check if $url is already downloaded or not from "$HOME/Offline Pages/"
    if [[ $(check_records $url) -eq 1 ]]; then
      echo "[skip] $url" > /dev/stderr
      continue;
    fi

    echo -e "(fetch) $url\n==> wget ${wget_args[@]} --header \"Referrer: $domain\" --domains=$domain $url\n" > /dev/stderr
    eval "wget ${wget_args[@]} --header \"Referrer: $domain\" --domains=$domain $url"

    # Compress the fetched folder and put it inside "$OFFLINE_PAGES"
    tar ${tar_args[@]} "$OFFLINE_PAGES/$(get_url_sha256sum $url).tar.xz" $domain
    if [[ ! $? -eq 0 ]]; then
      echo "error: tar: something went wrong compressing the resources." > /dev/stderr
      exit;
    fi

    rm -rf $domain

    records $url
    oksum=$(expr $oksum + 1)
  done

  echo $oksum
}

delete_links() {
  IFS=$'\n'
  
  local patt="^\[([0-9]+?)\].(.+)"
  local pagepatt="([^,]+),(.+)"
  local choices=$(print_choices)
  local pages=$(cat "$OFFLINE_PAGES/.pages" 2> /dev/null)

  [[ -f "$OFFLINE_PAGES/.pages" ]] \
    && rm -rf "$OFFLINE_PAGES/.pages" \
    && touch "$OFFLINE_PAGES/.pages"

  for choice in $choices; do
    local index=""
    local url=""

    if [[ $choice =~ $patt ]]; then
      index=${BASH_REMATCH[1]}
      url=${BASH_REMATCH[2]}

      if [[ ! $1 -eq $index ]]; then
        continue;
      fi
    fi

    echo "[delete] $url"

    for page in $pages; do
      local purl=""
      local sha256sum=""
      local contains=0

      if [[ $page =~ $pagepatt ]]; then
        purl=${BASH_REMATCH[1]}
        sha256sum=${BASH_REMATCH[2]}
      fi

      if [[ $purl == $url ]]; then
        rm -rf "$OFFLINE_PAGES/$sha256sum.tar.xz"
        contains=1
      fi

      if [[ $contains -eq 0 ]]; then
        echo $page >> "$OFFLINE_PAGES/.pages"
      fi
    done
  done
}

view_link() {
  IFS=$'\n'

  local urlpatt="https?://([^/]+?)(.+?)" # might break in novel cases.
  local patt="^\[([0-9]+?)\] (.+)"
  local choices=$(print_choices)

  for choice in ${choices[@]}; do
    local index=""
    local url=""

    if [[ $choice =~ $patt ]]; then
      index=${BASH_REMATCH[1]}
      url=${BASH_REMATCH[2]}

      if [[ ! $1 -eq $index ]]; then
        continue;
      fi
    fi

    echo "[serve] $url"

    if [[ $url =~ $urlpatt ]]; then
      local domain=${BASH_REMATCH[1]}
      local path=${BASH_REMATCH[2]}
      local sha256sum=$(get_url_sha256sum $url)

      tar xf "$OFFLINE_PAGES/$sha256sum.tar.xz" -C /tmp

      sleep 1 && xdg-open "http://localhost:32000$path" &

      http-server ${http_server_args[@]} /tmp/$domain

      rm -rf /tmp/$domain

      break;
    fi
  done
}

get_domain() {
  local patt="https?://([^/]+?)(.+?)" # might break in novel cases.

  [[ $1 == "" ]] && { echo "error: get_domain: invalid argument" > /dev/stderr; exit; }
  
  if [[ $1 =~ $patt ]]; then
    echo ${BASH_REMATCH[1]}
  fi
}

get_url_sha256sum() {
  local patt="^([0-9a-f]+).+"
  local sha256sum=$(echo $1 | sha256sum)

  if [[ $sha256sum =~ $patt ]]; then
    echo ${BASH_REMATCH[1]}
    return;
  fi

  echo "error: get_url_sha256sum: invalid argument"
  exit;
}

check_records() {
  if [[ ! -f "$OFFLINE_PAGES/.pages" ]]; then
    touch "$OFFLINE_PAGES/.pages" >& /dev/null
    [[ ! $? -eq 0 ]] && { echo "error: check_records: unable to create .pages file"; exit; }
  fi

  local patt="([^,]+),(.+)$"
  local content=$(cat "$OFFLINE_PAGES/.pages")

  for page in ${content[@]}; do
    if [[ "$1,$(get_url_sha256sum $1)" == $page ]]; then
      echo 1      
      return;
    fi
  done

  echo 0
}

# Not a smart guy (actually pretty dumb) but can literally record anything and is heavily coupled with `check_records`.
records() {
  if [[ $1 == "" ]]; then
    echo "error: records: invalid argument"
    exit;
  fi

  echo -e "$(cat "$OFFLINE_PAGES/.pages")\n$1,$(get_url_sha256sum $1)" > "$OFFLINE_PAGES/.pages"
}


print_choices() {
  local patt="([^,]+),(.+)"
  local counter=1

  for page in $(cat "$OFFLINE_PAGES/.pages" 2> /dev/null); do
    local url=""

    if [[ $page =~ $patt ]]; then
      url=${BASH_REMATCH[1]}
    fi

    echo -e "[$counter] $url"

    counter=$(expr $counter + 1)
  done

  return;
}

commands() {
  case $1 in
    list)
      print_choices;
      ;;
    fetch)
      fetch_links "${@:2}" > /dev/null;
      ;;
    view)
      view_link "${@:2}";
      ;;
    delete)
      delete_links "${@:2}";
      ;;
  esac
}

main() {
  if [[ $TEST -eq 1 ]]; then
    OFFLINE_PAGES="/tmp/Offline Pages"

    source $SCRIPTS/tests/webfetch-test.sh
    
    checks_test;
    fetch_links_test;
    check_records_test;
    records_test;
    get_domain_test;
    get_url_sha256sum_test;
    delete_links_test;
    
    cd "$OFFLINE_PAGES" && rm -rf * .pages
    return;

    rm -rf "$OFFLINE_PAGES"
  fi

  commands "$@"
}

main "$@"
