#!/bin/sh
# wi-adm - wireguard client management cli tool
# todo: revoke

while true; do
    echo "wi-adm"
    echo "1) add client"
    echo "2) revoke client"
    echo "3) list clients"
    echo "4) exit"
    read -p "select an option: " option
    case $option in
        1)
            openssl genpkey -algorithm ed25519 -out privatekey.pem
            CLIENT_PRIVATE_KEY=$(cat privatekey.pem)
            CLIENT_PUBLIC_KEY=$(openssl pkey -in privatekey.pem -pubout -outform PEM | tail -n +2 | head -n -1 | tr -d '\n')
            envsubst < client-dual-endpoint.conf > wg0.conf
            ;;
        2)
            echo "not available.."
            ;;
        3)
            ls -la /etc/wireguard/clients/ 2>/dev/null || echo "no clients found"
            ;;
        4)
            exit 0
            ;;
        *)
            echo "invalid option"
            ;;
    esac
done

