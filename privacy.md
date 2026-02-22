# Privacy Policy – SwiftSieve DNS

**Last updated:** February 22, 2026

SwiftSieve DNS ("the app") is a DNS filtering app for iOS. This policy describes what data the app uses and where it goes.

## Data we do not collect

- We do not operate servers that receive your data.
- We do not collect, store, or have access to your DNS queries, browsing history, or any other personal information.
- We do not use analytics or third‑party SDK's that collect personal data.

## Data stored on your device

The app and its DNS Proxy extension store the following only on your device (using iOS App Group storage, not sent to us):

- **Block list settings** – Which block lists you enable or disable, and any per‑domain include/exclude choices.
- **Custom blocked domains** – Domains you add to block.
- **Allowlist** – Domains you add so they are never blocked.
- **Block log** – A local log of recently blocked queries (domain, time, and which list matched). You can clear it anytime from the app.

This data stays on your device and is not transmitted to us or any other party by the app.

## DNS when the proxy is on

When you turn the DNS proxy on, your device sends DNS queries to the app's system extension. The extension:

- Blocks queries that match your block lists or custom domains (except allowlisted domains).
- Sends all other queries to **Cloudflare** over DNS‑over‑HTTPS (DoH) at `https://cloudflare-dns.com/dns-query`.

We do not receive or log those queries. Cloudflare's handling of DNS queries is governed by their privacy policy: [https://www.cloudflare.com/privacypolicy/](https://www.cloudflare.com/privacypolicy/).

## Children

The app is not directed at children. We do not knowingly collect personal information from anyone.

## Changes to this policy

We may update this policy occasionally. The "Last updated" date at the top will change when we do. Continued use of the app after changes means you accept the updated policy.

## Contact

For any questions or concerns about this policy or the app itself, please open an issue at the app's GitHub repository or contact the developer via the link in the App Store listing. If you send us an email, we will only store information you share with us directly for the amount of time required to help you or address your concerns. We will not use your personal information, other than to assist you, and we will never sell your personal information to any third parties.