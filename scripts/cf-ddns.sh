#!/bin/sh
# cf-ddns - update cloudflare a-record with current public ip

[ -f /etc/wipi/ddns.conf ] && . /etc/wipi/ddns.conf

api_token="${CF_API_TOKEN:-}"
api_url="${CF_API_URL:-"https://api.cloudflare.com/client/v4"}"
zone_id="${CF_ZONE_ID:-}"
domain="${CF_DOMAIN:-}"
record_name="${CF_RECORD_NAME:-wipi-pi}"
cf_record="${record_name}.${domain}"

curr_ip=$(curl -fsS https://api.ipify.org) \
    || { echo "error: failed to get public ip"; exit 1; }

# get dns record
record=$(curl -fsS -X GET \
    "${api_url}/zones/${zone_id}/dns_records?name=${cf_record}&type=A" \
    -H "Authorization: Bearer ${api_token}" \
    -H "Content-Type: application/json")

record_id=$(echo "$record"  | jq -r '.result[0].id // empty')
record_ip=$(echo "$record"  | jq -r '.result[0].content // empty')

[ -n "$record_id" ] || { echo "error: dns record not found for ${cf_record}"; exit 1; }

# skip update if ip unchanged
if [ "$record_ip" = "$curr_ip" ]; then
    echo "$(date -u +%FT%TZ) ${cf_record} unchanged (${curr_ip})"
    exit 0
fi

response=$(curl -fsS -X PUT \
    "${api_url}//zones/${zone_id}/dns_records/${record_id}" \
    -H "Authorization: Bearer ${api_token}" \
    -H "Content-Type: application/json" \
    -d "{\"type\":\"A\",\"name\":\"${cf_record}\",\"content\":\"${curr_ip}\",\"ttl\":60}")

if echo "$response" | jq -e '.success' >/dev/null 2>&1; then
    echo "$(date -u +%FT%TZ) ${cf_record} updated ${record_ip:-?} -> ${curr_ip}"
else
    echo "error: update failed"
    echo "$response" | jq . >&2
    exit 1
fi
