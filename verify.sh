#!/bin/bash

base64_to_hex() {
  local base64_str="$1"
  echo -n "$base64_str" | base64 -d | xxd -p | tr -d '\n'
}

nubit_verify() {
  local address="$1"
  local key="$2"
  local pub_key=$(base64_to_hex "$key")

  local headers=(
    -H "accept: */*"
    -H "accept-language: zh-CN,zh;q=0.9,en;q=0.8"
    -H "cache-control: no-cache"
    -H "content-type: application/json"
    -H "pragma: no-cache"
    -H "priority: u=1, i"
    -H "sec-ch-ua: \"Not/A)Brand\";v=\"8\", \"Chromium\";v=\"126\", \"Google Chrome\";v=\"126\""
    -H "sec-ch-ua-mobile: ?0"
    -H "sec-ch-ua-platform: \"macOS\""
    -H "sec-fetch-dest: empty"
    -H "sec-fetch-mode: cors"
    -H "sec-fetch-site: same-site"
    -H "Referer: https://alpha.nubit.org/"
    -H "Referrer-Policy: strict-origin-when-cross-origin"
  )

  local body="{\"address\":\"$address\",\"pub_key\":\"$pub_key\",\"key\":\"$key\"}"

  response=$(curl -s -X POST "${headers[@]}" \
    -d "$body" \
    'https://alpha-callback.nubit.org/v1/node/verify')

  echo "$response"
}

# 读取 keys.md 文件并处理每组数据
while IFS= read -r line || [[ -n "$line" ]]; do
  if [[ $line == "Container:"* ]]; then
    container=${line#*: }
    echo "开始验证 $container"
  elif [[ $line == "Address:"* ]]; then
    address=${line#*: }
  elif [[ $line == "Pubkey:"* ]]; then
    pubkey=${line#*: }
    echo "验证地址：$address"
    nubit_verify "$address" "$pubkey"
    # 生成2到10之间的随机秒数
    sleep_time=$(( ( RANDOM % 9 )  + 2 ))
    sleep $sleep_time
  elif [[ $line == "---" ]]; then
    echo "------------------------"
  fi
done <"keys.md"
