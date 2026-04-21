# client failover

two methods for multi-server failover.

## architecture

```mermaid
graph TB
    subgraph dns["dns layer (cf-dom.com)"]
        rr["round-robin or failover<br/>wipi-a.cf-dom.com<br/>wipi-b.cf-dom.com"]
    end
    
    subgraph client["client device"]
        wg_client["wireguard client<br/>method: dns-failover or dual-endpoint"]
    end
    
    subgraph servers["wireguard servers + pihole"]
        server_a["server-a<br/>alpine + wg + pihole<br/>wipi-a.cf-dom.com<br/>20X.X.X.10"]
        server_b["server-b<br/>alpine + wg + pihole<br/>wipi-b.cf-dom.com<br/>20X.X.X.20"]
    end
    
    subgraph tunnel["wireguard tunnel<br/>10.0.100.0/24"]
        client_ip["client: 10.0.100.2"]
        server_ip["servers: 10.0.100.1"]
    end
    
    dns -.->|dns query| rr
    wg_client -->|method 1-4| rr
    rr -->|resolved ip| server_a
    rr -->|resolved ip| server_b
    server_a <--> tunnel
    server_b <--> tunnel
    client_ip <--> server_ip
    
    classDef dns fill:#e1f5ff,stroke:#01579b
    classDef client fill:#f3e5f5,stroke:#4a148c
    classDef server fill:#e8f5e9,stroke:#1b5e20
    classDef tunnel fill:#fff3e0,stroke:#e65100
    
    class dns dns
    class wg_client client
    class server_a,server_b server
    class tunnel tunnel
```

---

## method 1: dns failover

single endpoint hostname, dns resolves to active server.

**dns setup (cloudflare or any provider):**

```
wipi.domain.com  A  203.0.113.10   (server a)
wipi.domain.com  A  198.51.100.20  (server b)
ttl = 60
```

**generate client config:**

```sh
export CLIENT_PRIVATE_KEY=$(wg genkey)
export CLIENT_ADDRESS=10.0.100.2/32
export PIHOLE_IP=10.0.100.1
export SERVER_PUBLIC_KEY=<server-pubkey>
export WG_ENDPOINT=wipi.domain.com

envsubst < templates/client-dns-failover.conf > wg0.conf
```

---

## method 2: dual endpoint

two peers in one client config. wireguard switches automatically.

**requires:** a separate public key per server.

**generate client config:**

```sh
export CLIENT_PRIVATE_KEY=$(wg genkey)
export CLIENT_ADDRESS=10.0.100.2/32
export PIHOLE_IP=10.0.100.1
export SERVER_A_PUBLIC_KEY=<pubkey-a>
export SERVER_B_PUBLIC_KEY=<pubkey-b>
export WG_ENDPOINT_A=wipi-a.domain.com
export WG_ENDPOINT_B=wipi-b.domain.com

envsubst < templates/client-dual-endpoint.conf > wg0.conf
```

---

## recommendation

use method 2 (dual endpoint) for true wireguard-native failover.

use method 1 for simplicity when both servers share the same public key (active-passive).
