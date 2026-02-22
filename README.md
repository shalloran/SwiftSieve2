# SwiftSieve DNS

<img src="SwiftSieveDNS/Assets.xcassets/AppIcon.appiconset/AppIcon.png" width="96" height="96" align="left" style="margin-right: 1em;" />

A lightweight iOS app that does system-wide DNS filtering using the **DNS Proxy** API (`NEDNSProxyProvider`). No VPN, no tunnel, just a DNS proxy. When you turn it on, the system sends all DNS queries to the extension. Blocked domains get no answer (NXDOMAIN), and the rest go to Cloudflare over DoH.

## how it works

- **One toggle** – Enable or disable the DNS proxy. When on, the device uses the extension for DNS (no VPN badge in Settings). First setup requires enabling the dns proxy in iOS settings.
- **Block lists** – Bundled lists (e.g. General Marketing, Facebook Trackers, Data Trackers) plus custom domains. You can enable/disable whole lists and, per list, include or exclude individual domains.
- **Allowlist** – Domains that are never blocked, even if they appear in a block list. *Please note, the allowlist will override the blocklist.*
- **Block log** – Recent blocked queries with time and which list (or custom) caused the block.

## technology

- **Upstream DNS:** All non-blocked queries are sent to **Cloudflare** via DNS-over-HTTPS (DoH), at `https://cloudflare-dns.com/dns-query`. No other provider is used or configurable at this time.
- **App:** SwiftUI, iOS 14+. Uses `NEDNSProxyManager` to install and enable the DNS proxy. Block list, allowlist, and log live in an App Group so the extension can read (and write the log).
- **Extension:** Single DNS Proxy Provider target. Reads block list and allowlist from the App Group, blocks by domain, forwards everything else to Cloudflare DoH, and appends to the block log when it blocks.
- **SwiftSieveDNS** – Main app (views, storage, `DNSProxyController`, block list `.txt` files).
- **SwiftSieveDNSProxy** – DNS Proxy extension (`DNSProxyProvider`, `DoHClient`, minimal DNS wire parse/build).

## build and run

Open `SwiftSieveDNS.xcodeproj` in Xcode, set your team and App Group on both targets, and run on a **real device** (DNS proxy behavior isn’t reliable in the Simulator). *Apple Developer account required.*

## support

Please open a github issue in this repo, or send mail to [support@swiftsieve.com](mailto:support@swiftsieve.com), we'd love to collaborate or help!

---

*The main contributor to this repo was a part-time developer of Lockdown Privacy, but this project is independent and not affiliated with Lockdown Privacy in any way. The AppStore App will always be compiled directly from this repository, and any changes will be noted here and linked to from the AppStore App changelog.*

[Privacy policy](privacy.md)