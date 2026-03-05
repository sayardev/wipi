#!/bin/sh
# cloudflare ddns update script
# 
cf_zone="cf-dom.com"
cf_record="vpnA.cf-dom.com"
# todo: add auth and refresh-token instead of constant env
cf_token=${CF_API_TOKEN:-$1}

ip=$(curl -s https://api.ipify.org)

zone_id=$(curl -s -X GET \
    "https://api.cloudflare.com/client/v4/zones?name=$cf_zone" \
    -H "Authorization: Bearer $cf_token" \
    -H "Content-Type: application/json" | jq -r '.result[0].id')

record_id=$(curl -s -X GET \
    "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?name=$cf_record" \
    -H "Authorization: Bearer $cf_token" \
    -H "Content-Type: application/json" | jq -r '.result[0].id')

curl -s -X PUT \
    "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records/$record_id" \
    -H "Authorization: Bearer $cf_token" \
    -H "Content-Type: application/json" \
    --data "{\"type\":\"A\",\"name\":\"$cf_record\",\"content\":\"$ip\",\"ttl\":60}"
    