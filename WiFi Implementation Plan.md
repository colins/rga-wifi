# WiFi Setup Implementation Plan

## Overview
Setup a dual-tier captive portal network for a public business space using OpenWrt on a Netgear R6220 router and TP-Link Deco S4R mesh units in Access Point mode.

---

## Network Architecture & Hardware

- **Netgear R6220 (OpenWrt Router)**: Main network gateway handling DHCP, DNS, Firewall, Captive Portal (`openNDS`), and Traffic Control (`SQM`).
- **TP-Link Deco S4R (Mesh)**: Configured in **Access Point (AP) / Bridge Mode** (disable DHCP/Routing on Deco). Connect the main Deco node to a LAN port on the R6220 so client MAC/IP addresses pass directly through to OpenWrt.

---

## Task 1: OpenWrt Router Configuration

### A. Essential OpenWrt Packages
SSH into the OpenWrt router and run:
```bash
opkg update
opkg install opennds luci-app-sqm git
```

### B. Captive Portal (`openNDS`)
`openNDS` provides captive portal functionality with Forwarding Authentication Service (FAS) support to delegate user onboarding and business logic to an external or local web page.

1. **Configure `/etc/config/opennds`**:
   - Set interface to `br-lan` (or dedicated Guest VLAN).
   - Enable FAS (`option fasport '80'`).
   - Configure default rate-limiting parameters:
     - Free/Default upload rate limit (e.g., `512` kbps).
     - Free/Default download rate limit (e.g., `2048` kbps / 2 Mbps).
2. **Speed Capping & Quality of Service (`luci-app-sqm`)**:
   - Navigate to **Network > SQM QoS** in LuCI.
   - Set upload and download bandwidth limits slightly below ISP max using `cake` queue discipline to eliminate bufferbloat across all users.

---

## Task 2: Payment Processing & Coupon Management

Use **FAS (Forwarding Authentication Service)** hosted on a local web server (e.g., Raspberry Pi) or a cloud service (Vercel, Cloudflare Workers, VPS).

```
[ Client Connects ] ──> [ openNDS Redirects ] ──> [ FAS Web Portal Page ]
                                                         │
         ┌───────────────────────┼───────────────────────┘
         ▼                       ▼                       ▼
  [ Enter Email ]        [ Pay via Stripe ]     [ Redeem Coupon Code ]
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 ▼
                     [ openNDS Grant Token ]
            (Sets Speed Cap & Time Limit per Client)
```

### Access Tiers

1. **Free Access Tier (Email Entry)**:
   - User submits their email address.
   - FAS stores the email in a database/CSV.
   - FAS redirects back to openNDS with an authentication token granting **Tier 1 Access** (e.g., 2 Mbps download limit, 60-minute duration).

2. **Paid Access Tier (Online Payment)**:
   - Integrated with **Stripe Checkout** or **PayPal Commerce**.
   - User chooses a time pass (e.g., $3 for 24 Hours).
   - FAS redirects client to hosted Stripe Checkout.
   - Upon payment webhook notification, FAS grants **Tier 2 Access** (Full network speed, 24-hour expiration).

3. **Coupon Redemption Tier (In-Person Sales)**:
   - Generate unique 6–8 character alphanumeric codes stored in a database/JSON store.
   - Schema per coupon: `code`, `duration_minutes`, `speed_tier` (`full`), `is_redeemed` (`true/false`).
   - User submits coupon code on portal -> FAS validates & marks code redeemed -> FAS issues openNDS token for full speed and set duration.

---

## Task 3: Configuration Checkpoints & Rollback

### Method A: Git Version Control on `/etc` (Recommended)
OpenWrt stores configuration files in `/etc/config/`. Tracking `/etc` with Git enables snapshot commits and easy rollbacks:

1. **Initialize Git repository**:
   ```bash
   cd /etc
   git init
   git config user.name "admin"
   git config user.email "admin@router.local"
   git add .
   git commit -m "Checkpoint 0: Fresh OpenWrt installation"
   ```

2. **Save Checkpoints during setup**:
   ```bash
   # After configuring Deco AP & network interfaces
   git add .
   git commit -m "Checkpoint 1: Configured Deco AP bridge & network interfaces"

   # After configuring openNDS & SQM
   git add .
   git commit -m "Checkpoint 2: Configured openNDS and rate limiting"
   ```

3. **Rollback if needed**:
   ```bash
   git log --oneline
   git reset --hard HEAD~1
   ```

### Method B: System Backup Tarballs (`sysupgrade`)
Create snapshot tarballs via CLI before major changes:

```bash
# Backup state
sysupgrade -b /tmp/backup-step1-network.tar.gz

# Restore state
sysupgrade -r /tmp/backup-step1-network.tar.gz
```
Or download backups via **System > Backup / Flash Firmware** in LuCI.

---

## Step-by-Step Implementation Roadmap

1. [ ] Configure TP-Link Deco S4R mesh nodes into **Access Point Mode**.
2. [ ] SSH into OpenWrt router and install `openNDS`, `luci-app-sqm`, and `git`.
3. [ ] Initialize Git repository in `/etc` on OpenWrt for configuration checkpoints.
4. [ ] Configure basic openNDS captive portal redirect and default rate limits.
5. [ ] Build or deploy FAS web application (handling email form, Stripe Checkout, and coupon validation).
6. [ ] Test free tier email signup, paid tier Stripe checkout, and coupon redemption workflows.
