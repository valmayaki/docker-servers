# nft-forward

A production-grade nftables port-forwarding manager for Linux systems. This script provides a simplified interface for managing port forwarding rules using nftables, with support for service presets, rule persistence, and automated systemd integration.

## Features

- Manage nftables port forwarding rules via simple CLI commands
- Service presets for common applications (Pi-hole, Portainer)
- LAN-only restriction support for internal services
- Automatic LAN subnet and network interface detection
- Rule persistence with backup/rollback capabilities
- systemd service integration for boot-time rule loading
- Idempotent rule operations (prevents duplicate rules)
- Interactive interface selection in TTY mode

## Requirements

- Linux kernel with nftables support
- `nft` command-line tool installed
- Root/sudo privileges
- systemd (for systemd-setup feature)

## Installation

1. Copy the script to a system location:
```bash
sudo cp nft-forward.sh /usr/local/bin/nft-forward
sudo chmod +x /usr/local/bin/nft-forward
```

2. (Optional) Create a configuration file at `/etc/nft-forward.conf`:
```bash
# Example configuration
LAN_SUBNET="192.168.1.0/24"
DEFAULT_IFACE="eth0"
PIHOLE_IP="192.168.1.100"
PORTAINER_IP="192.168.1.101"
```

## Usage

### Basic Syntax
```bash
nft-forward <action> [options]
```

### Actions

#### `add` - Add a port forwarding rule

**Manual configuration:**
```bash
nft-forward add \
  --proto tcp \
  --host-port 8080 \
  --dest-ip 192.168.1.50 \
  --dest-port 80 \
  --iface eth0
```

**With LAN-only restriction:**
```bash
nft-forward add \
  --proto tcp \
  --host-port 9443 \
  --dest-ip 192.168.3.4 \
  --dest-port 9443 \
  --lan-only
```

**Using service presets:**
```bash
nft-forward add --service pihole
nft-forward add --service portainer
```

#### `delete` - Remove a port forwarding rule
```bash
nft-forward delete \
  --proto tcp \
  --host-port 8080 \
  --dest-ip 192.168.1.50 \
  --dest-port 80
```

#### `list` - List NAT table rules
```bash
nft-forward list
```

#### `status` - Show complete nftables ruleset
```bash
nft-forward status
```

#### `persist` - Save current rules to disk
```bash
nft-forward persist
```
Saves rules to `/etc/nftables.conf` and creates a timestamped backup in `/etc/nftables.backups/`

#### `rollback` - Restore rules from a backup
```bash
nft-forward rollback 20231228-143022
```

#### `diff` - Show differences between saved and active rules
```bash
nft-forward diff
```

#### `validate` - Validate the saved nftables configuration
```bash
nft-forward validate
```

#### `doctor` - System diagnostics
```bash
nft-forward doctor
```
Checks nftables availability and system configuration

#### `systemd-setup` - Install systemd service
```bash
nft-forward systemd-setup
```
Creates and enables a systemd service to load nftables rules at boot

### Options

| Option | Description | Example |
|--------|-------------|---------|
| `--proto` | Protocol (tcp, udp, or both) | `--proto tcp` |
| `--host-port` | Port on the host machine | `--host-port 8080` |
| `--dest-ip` | Destination IP address | `--dest-ip 192.168.1.50` |
| `--dest-port` | Destination port | `--dest-port 80` |
| `--iface` | Network interface | `--iface eth0` |
| `--lan-only` | Restrict access to LAN subnet only | `--lan-only` |
| `--service` | Use a service preset (pihole, portainer) | `--service pihole` |

## Service Presets

### Pi-hole
Forwards DNS traffic (port 53) to a Pi-hole instance, restricted to LAN only.
```bash
nft-forward add --service pihole
```
Requires `PIHOLE_IP` to be set in `/etc/nft-forward.conf`

### Portainer
Forwards HTTPS traffic (port 9443) to a Portainer instance, restricted to LAN only.
```bash
nft-forward add --service portainer
```
Requires `PORTAINER_IP` to be set in `/etc/nft-forward.conf`

## How It Works

The script manages nftables rules by:

1. **NAT Rule (PREROUTING)**: Redirects incoming traffic on the specified port to the destination IP and port
2. **Filter Rules (FORWARD)**: Allows forwarded traffic in both directions for established connections

### Rule Structure

For each forwarding rule, three nftables rules are created:

1. DNAT rule to redirect traffic: `ip nat prerouting ...`
2. Forward rule for incoming traffic: `ip filter forward ... accept`
3. Forward rule for return traffic: `ip filter forward ... accept`

All rules are tagged with `comment "nft-forward"` for easy identification.

## Configuration File

Create `/etc/nft-forward.conf` to set defaults:

```bash
# Network configuration
LAN_SUBNET="192.168.1.0/24"      # Auto-detected if not set
DEFAULT_IFACE="eth0"              # Auto-selected if not set

# Service IP addresses
PIHOLE_IP="192.168.1.100"
PORTAINER_IP="192.168.1.101"
```

## Best Practices

1. **Always persist after adding rules**: Run `nft-forward persist` after making changes
2. **Test before persisting**: Add rules, test connectivity, then persist
3. **Use LAN-only for internal services**: Add `--lan-only` for services that shouldn't be exposed externally
4. **Set up systemd service**: Run `nft-forward systemd-setup` to ensure rules survive reboots
5. **Regular backups**: The script automatically creates timestamped backups when persisting

## Troubleshooting

### Check if nftables is working
```bash
nft-forward doctor
```

### View active rules
```bash
nft-forward status
```

### Compare saved vs active rules
```bash
nft-forward diff
```

### Rollback to a previous configuration
```bash
# List available backups
ls /etc/nftables.backups/

# Rollback to a specific timestamp
nft-forward rollback 20231228-143022
```

## Examples

### Forward HTTP traffic to a web server
```bash
nft-forward add \
  --proto tcp \
  --host-port 80 \
  --dest-ip 192.168.1.50 \
  --dest-port 8080 \
  --iface eth0

nft-forward persist
```

### Forward both TCP and UDP for a game server
```bash
nft-forward add \
  --proto both \
  --host-port 27015 \
  --dest-ip 192.168.1.60 \
  --dest-port 27015

nft-forward persist
```

### Set up Pi-hole DNS forwarding (LAN only)
```bash
# Add PIHOLE_IP to /etc/nft-forward.conf first
nft-forward add --service pihole
nft-forward persist
```

## Security Considerations

- Always use `--lan-only` for internal services that shouldn't be exposed to the internet
- The script requires root privileges to modify firewall rules
- Rules are persisted to `/etc/nftables.conf` which is loaded at boot
- Keep backups of working configurations in `/etc/nftables.backups/`

## Files

- `/etc/nft-forward.conf` - Configuration file
- `/etc/nftables.conf` - Active nftables ruleset
- `/etc/nftables.backups/` - Timestamped backup directory
- `/etc/systemd/system/nft-forward.service` - systemd service unit

## License

This script is provided as-is for production use.
