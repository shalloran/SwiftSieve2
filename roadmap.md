# SwiftSieve DNS – Roadmap & Changelog

## v.0.0.1

- **DNS proxy** – Single toggle to turn system-wide DNS filtering on/off via `NEDNSProxyProvider` (no VPN badge). First-time setup requires enabling the DNS proxy in iOS Settings.
- **Bundled block lists** – General Marketing, Facebook Trackers, Data Trackers, Marketing Trackers (on by default), plus Crypto Mining (off by default). Enable/disable whole lists, or expand a list to include/exclude individual domains.
- **Custom blocked domains** – Add or remove one-off domains to block, no list required.
- **Allowlist** – Domains that are never blocked; overrides block lists when there’s a match.
- **Block log** – Recent blocked queries with timestamp and which list (or custom) caused the block; clear button. *(Known quirk: custom-domain blocks can show as “unknown” source; polish planned in “Up next.”)*
- **Repair configuration** – Button to reapply proxy config when iOS shows “Invalid” in Settings.
- **Upstream DNS** – All non-blocked queries go to Cloudflare over DoH (`https://cloudflare-dns.com/dns-query`); not configurable in this version.
- **App + extension** – SwiftUI app (Home, Allowlist, Block log tabs) and one DNS Proxy extension; shared storage via App Group so the extension reads block/allow state and writes log entries.

## Up next

1. **Loading screen** – Add a splash/loading screen while the app loads. Keep it fun, Apple-y, and a bit cheeky (e.g. copy or animation that fits “sifting” / DNS filtering).
2. **Block list review** – Review default block lists (including pulling in Lockdown Privacy–style lists), compare with current bundled lists, and decide what to keep, add, or change.
3. ~~**Block list domain dropdown** – For each block list toggle, add a dropdown that expands to show all domains in that list, with a toggle per domain so you can include/exclude individual domains while the list is enabled.~~
4. **Add a refresh pull down to Block log** - Pretty self-explanatory, but basically pulling down on the block log tab should refresh the block log.
5. **Fix "uknkown" block log sources** - Looks like all custom domains are causing an unknown tag. Add custom domain tag and make the UI prettier with little colorful tags for each block list on each block log item.
6. **Export block log lists** - Add an option for export of block log items.
7. **Expand google trackers** - New list with google trackers.

---

*Nothing set in stone, just a short list to keep me honest :-).*
