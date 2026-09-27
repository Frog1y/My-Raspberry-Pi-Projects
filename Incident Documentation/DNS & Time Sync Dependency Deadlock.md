## Incident
The outage resulted from a circular dependency lock between domain name resolution, Tailscale's control plane, and system time synchronization.

```text
[ Application / User CLI Commands ]
                │
                ▼
        /etc/resolv.conf ──────────────► Points system queries to active resolver
                │
        ┌───────┴──────────────────────────────┐
        ▼                                      ▼
systemd-resolved                     Tailscale Subnet / MagicDNS
(Local Stub: 127.0.0.53)             (Local Stub: 100.100.100.100)
        │                                      │
        ▼                                      ▼
Upstream DNS Servers                 Encrypted Tailnet / Overridden Routes
(1.1.1.1 / 8.8.8.8)
        │
        ▼
NTP / Time Sync Daemon (chrony)
  ├── Requires active DNS resolution to query pool.ntp.org
  └── Synchronized system clock required for TLS handshakes & SSH authentication
```  
### Phase 1: Breaking the Dependency Loop

Bypass Tailscale's unresponsive local stub (`100.100.100.100`) and instruct Linux to send DNS queries directly to Cloudflare's public resolver:

* **Why:** Injects a direct, working public nameserver into `/etc/resolv.conf`.

* **Result:** Public domain resolution was immediately restored, allowing `ping pool.ntp.org` to succeed.

### Phase 2: Restoring Time Synchronization

With domain resolution functional, restart `chrony` to force it to re-resolve upstream NTP pool addresses and update system time:

Verify synchronization status:

* **Why:** Forces `chrony` to perform an immediate lookup against public time servers now that DNS is functional.

* **Result:** `chronyc sources` populated active upstream servers, and `timedatectl status` confirmed `System clock synchronized: yes`.

### Phase 3: Permanently Reconfiguring Tailscale

Instruct Tailscale to leave system-wide DNS settings untouched across reboots:

* **Why:** Disables Tailscale's MagicDNS `/etc/resolv.conf` override while keeping the encrypted mesh network and SSH capabilities fully active.

* **Result:** Tailscale maintains secure mesh network connectivity while preventing future `/etc/resolv.conf` hijacking and boot deadlocks.

## 4. Prevention & Best Practices

10. **Keep `--accept-dns=false` set** if the host relies on static or local system resolvers that must remain reachable prior to Tailscale daemon authentication.

11. **Hardware RTC Battery (Optional):** Installing a CR1220 coin-cell battery on the Raspberry Pi 5 RTC port prevents time drift across complete power disconnects.

12. **Manual Bootstrap Recovery:** If network deadlocks reoccur, temporarily populating `/etc/resolv.conf` with a public resolver (`1.1.1.1` or `8.8.8.8`) is the standard method to restore baseline network services before persistent daemon reconfiguration.