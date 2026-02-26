#!/usr/bin/env python3

import re
import sys
from urllib.request import urlopen
from urllib.parse import urlparse


# script to generate domain-only ublock-derived lists into BlockLists/*.txt

SOURCES = {
    "ub_easylist": "https://raw.githubusercontent.com/easylist/easylist/gh-pages/easylist.txt",
    "ub_easyprivacy": "https://raw.githubusercontent.com/easylist/easylist/gh-pages/easyprivacy.txt",
    "ub_ublock_ads": "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/filters.txt",
    "ub_ublock_privacy": "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/privacy.txt",
    "ub_peter_lowe": "https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext",
    "ub_malicious_urlhaus": "https://malware-filter.gitlab.io/malware-filter/urlhaus-filter-online.txt",
}


DOMAIN_RE = re.compile(r"([a-z0-9.-]+\.[a-z]{2,})", re.IGNORECASE)


def is_ip(s: str) -> bool:
    # simple ipv4 check; urlhaus may also contain ipv6, which this treats as non-domain
    parts = s.split(".")
    if len(parts) != 4:
        return False
    for p in parts:
        if not p.isdigit():
            return False
        v = int(p)
        if v < 0 or v > 255:
            return False
    return True


def extract_domains_generic(line: str) -> set[str]:
    # extract domain-like tokens from a filter line
    out: set[str] = set()
    for match in DOMAIN_RE.findall(line):
        d = match.lower()
        if is_ip(d):
            continue
        out.add(d)
    return out


def extract_domains_peter_lowe(line: str) -> set[str]:
    # hosts file format: "127.0.0.1 example.com"
    line = line.strip()
    if not line or line.startswith("#"):
        return set()
    parts = line.split()
    if len(parts) < 2:
        return set()
    host = parts[-1].strip().lower()
    if is_ip(host):
        return set()
    return {host}


def extract_domains_urlhaus(line: str) -> set[str]:
    # urlhaus format: either ip or hostname; sometimes full urls
    line = line.strip()
    if not line or line.startswith("!"):
        return set()
    # try as url
    if "://" in line:
        parsed = urlparse(line)
        host = parsed.hostname or ""
    else:
        host = line
    host = host.strip().lower()
    if not host or is_ip(host):
        return set()
    if "/" in host:
        host = host.split("/", 1)[0]
    if is_ip(host):
        return set()
    return {host}


def fetch(url: str) -> list[str]:
    with urlopen(url) as resp:
        data = resp.read().decode("utf-8", errors="ignore")
    return data.splitlines()


def main() -> None:
    root = sys.path[0]
    out_dir = f"{root}/BlockLists"

    for key, url in SOURCES.items():
        print(f"fetching {key} from {url}...", flush=True)
        lines = fetch(url)
        domains: set[str] = set()

        if key == "ub_peter_lowe":
            extractor = extract_domains_peter_lowe
        elif key == "ub_malicious_urlhaus":
            extractor = extract_domains_urlhaus
        else:
            extractor = extract_domains_generic

        for line in lines:
            domains.update(extractor(line))

        out_path = f"{out_dir}/{key}.txt"
        print(f"writing {len(domains)} domains to {out_path}", flush=True)
        with open(out_path, "w", encoding="utf-8") as f:
            for d in sorted(domains):
                f.write(d)
                f.write("\n")


if __name__ == "__main__":
    main()

