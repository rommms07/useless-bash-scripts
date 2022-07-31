#!/bin/bash -

checks_test() {
  if [[ $(checks 2> /dev/null) -eq 0 ]]; then
    echo "(fail) webfetch:checks failed!"
    return;
  fi

  echo "(ok) webfetch:checks passed!"
}

fetch_links_test()  {
  local links=(
    "https://www.99businessideas.com/business-ideas-philippines/"
    "https://marsdd.com/news/seven-ways-to-generate-business-ideas/"
    "https://smallbiztrends.com/2016/10/business-ideas-for-computer.html"
    "https://www.reddit.com/r/Entrepreneur/comments/55y4pj/how_to_write_a_business_plan_for_early_stage/"
  )

  if [[ $(fetch_links ${links[@]})  -eq 4 ]]; then
    echo "(ok) webfetch:fetch_links passed!"
    return;
  fi

  echo "(fail) webfetch:fetch_links failed!"
}

wget() {
  {
    local args=($@)
    local N=$(expr ${#args[@]} - 1)
    local url=${args[$N]}
    local domain=$(get_domain $url)

    echo -e "\u001b[1m(MOCK)\u001b[0m wget ${args[@]} $url"

    mkdir $domain
    touch $domain/sample.txt
  } > /dev/stderr
}

get_domain_test() {
  local patt="([^,]+),(.+)"
  local urls=(
    "https://itscrap.com,itscrap.com"
    "http://whorepresents.com,whorepresents.com"
    "https://nobjs.org,nobjs.org"
    "https://speedofart.com,speedofart.com"
    "http://therapistinabox.com,therapistinabox.com"
    "https://bettermarketing.pub/the-11-worst-website-names-ever-fc59e2f3242a,bettermarketing.pub"
    "https://www.masterclass.com/articles/how-to-design-a-character#how-to-design-characters,www.masterclass.com"
    "https://inkscape.org/learn/tutorials/avoid-performance-issues/,inkscape.org"
    "https://devdocs.io/,devdocs.io"
    "https://yts.mx/,yts.mx"
    "https://go101.org/optimizations/101.html,go101.org"
    "http://marcelproust.blogspot.com/2008/09/emil-cioran-essay.html,marcelproust.blogspot.com"
  )

  for link in ${urls[@]}; do 
    local url=""
    local expected=""

    if [[ $link =~ $patt ]]; then
      url=${BASH_REMATCH[1]}
      expected=${BASH_REMATCH[2]}
    fi

    local res=$(get_domain $url)

    if [[ $res != $expected ]]; then
      echo "(fail) webfetch:get_domain failed! (output: $res)" > /dev/stderr
      continue;
    fi

    echo "(ok) webfetch:get_domain passed! (output: $res)" > /dev/stderr
  done
}

get_url_sha256sum_test() {
  local patt="(.+?),(.+)"
  local urls=(
    "https://itscrap.com,bf497daf603f638b249b05b687a8d963cf3348cdde1074aad0bad612760caa69"
    "http://whorepresents.com,7ca8fb84412bc1c3055c229c54d40e817043e252f3dc42e76e25f208c28f6008"
    "https://nobjs.org,nobjs.org,e6e57c5624d1eba43312c085c9d46f3dde89cf378dde441bfd7c3642a6b6f7c9"
    "https://speedofart.com,speedofart.com,537f952e7961b25ea3583918f3c636155ab5ffba33d57ab507bc6813754806f7"
    "http://therapistinabox.com,33d5481b2d687b80b064b98ee5bd857f65e8c7baaa295d2a61a5da968450be2c"
    "https://bettermarketing.pub/the-11-worst-website-names-ever-fc59e2f3242a,b104aed6182c9cbf48d6f57b5b0a5acb45f910f74505adaf512239cd740cb7a0"
    "https://www.masterclass.com/articles/how-to-design-a-character#how-to-design-characters,2ac7606848534cb41a6a46b7fe49078f679ad9d37b44d9afa5a235a63ca3dd57"
    "https://inkscape.org/learn/tutorials/avoid-performance-issues/,eb406990b02448280d891cd7d497a0fd04e9082f09e16cf403c309760bc55c4e"
    "https://devdocs.io/,7b3cf8d7332ecf55805b54cbb34d69727b17171559f0bce59dc244e62da95a0a"
    "https://yts.mx/,1a4ff38ca8a01972d603f27ef95045402453e556419fd4bf722c9477f7b9b4fb"
    "https://go101.org/optimizations/101.html,382aa721e42f2414c16b9942869583ebff84217bc542f7f36edcac038877a4fa"
    "http://marcelproust.blogspot.com/2008/09/emil-cioran-essay.html,cb236f96cbae8bc9dfc95435c6c62f46ed3a05b72de5c2bad50806b434a16660"
  )

  for link in ${urls[@]}; do
    local url=""
    local expected=""

    if [[ $link =~ $patt ]]; then
      url=${BASH_REMATCH[1]}
      expected=${BASH_REMATCH[2]}
    fi

    local res=$(get_url_sha256sum $url)

    if [[ $res != $expected ]]; then
      echo -e "(fail) webfetch:get_url_sha256sum failed! \n(input: $url)\n(output: $res)\n(expected: $expected)\n" > /dev/stderr
      
      continue;
    fi

    echo "(ok) webfetch:get_url_sha256sum passed! (output: $res)"
  done

  # echo "(fail) webfetch:get_url_sha256sum not implemented" > /dev/stderr
}

check_records_test() {
  local patt="(.+?),([0-9a-f]+)"
  local pagefile="$OFFLINE_PAGES/.pages"
  local content="
http://marcelproust.blogspot.com/2008/09/emil-cioran-essay.html,cb236f96cbae8bc9dfc95435c6c62f46ed3a05b72de5c2bad50806b434a16660
https://go101.org/optimizations/101.html,382aa721e42f2414c16b9942869583ebff84217bc542f7f36edcac038877a4fa
https://yts.mx/,1a4ff38ca8a01972d603f27ef95045402453e556419fd4bf722c9477f7b9b4fb
"

  echo -e $content > "$pagefile"

  for page in ${content[@]}; do
    local url=""

    if [[ $page =~ $patt ]]; then
      url=${BASH_REMATCH[1]}
    fi

    local res=$(check_records $url)

    if [[ ! $res -eq 1 ]]; then
      echo -e "(fail) webfetch:check_records failed! \n(input: $url)\n(output: $res)\n" > /dev/stderr
      continue;
    fi

    echo "(ok) webfetch:check_records passed!" > /dev/stderr
  done

  # echo "(fail) webfetch:check_records not implemented" > /dev/stderr

  rm "$pagefile"
}

records_test() {
  local urls=(
    "https://itscrap.com"
    "http://whorepresents.com"
    "https://nobjs.org"
    "https://speedofart.com"
    "http://therapistinabox.com"
    "https://bettermarketing.pub/the-11-worst-website-names-ever-fc59e2f3242a"
    "https://www.masterclass.com/articles/how-to-design-a-character#how-to-design-characters"
    "https://inkscape.org/learn/tutorials/avoid-performance-issues/"
    "https://devdocs.io/"
    "https://yts.mx/"
    "https://go101.org/optimizations/101"
    "http://marcelproust.blogspot.com/2008/09/emil-cioran-essay.html"
  )

  for url in ${urls[@]}; do
    records $url
  done

  echo -e "(output) records\n!!! Not going to perform checks but here is the .pages content !!!\n\n$(cat "$OFFLINE_PAGES/.pages")\n=END="

  rm "$OFFLINE_PAGES/.pages"
}

delete_links_test() {
  local urls=(
    "https://itscrap.com"
    "http://whorepresents.com"
    "https://nobjs.org"
    "https://speedofart.com"
    "http://therapistinabox.com"
  )

  for url in ${urls[@]}; do
    rm -rf "$OFFLINE_PAGES/.pages"
    if [[ $(fetch_links $url) -eq 1 ]]; then
      delete_links 1
      local pages=$(cat "$OFFLINE_PAGES/.pages")

      if [[ $pages != "" ]]; then
        echo "(fail) webfetch:delete_links failed! (output: $pages)"
        continue;
      fi

      echo "(ok) webfetch:delete_links passed!"
      continue;
    fi

    echo "(fail) webfetch:fetch_links ~~~> $url (error!)"
  done
}
