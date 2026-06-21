#!/bin/bash
# ============================================================
# subenum.sh - Full passive + active subdomain enumeration
# Usage: ./subenum.sh domain.com
# ============================================================

set -uo pipefail

# ========= CONFIGURATION =========
DOMAIN="${1:-}"
OUTPUT_DIR="./output/${DOMAIN}"
RESOLVERS="$HOME/resolvers/resolvers.txt"          # trickest/resolvers
THREADS=100
GITHUB_TOKEN="${GITHUB_TOKEN:-}"                    # export GITHUB_TOKEN before running, optional

# Wordlists to merge for brute forcing — add/remove paths as you install more
WORDLIST_SOURCES=(
  "$HOME/wordlists/n0kovo/n0kovo_subdomains.txt"
  "/usr/share/seclists/Discovery/DNS/subdomains-top1million-110000.txt"
  "/usr/share/seclists/Discovery/DNS/dns-Jhaddix.txt"
)
# ==================================

if [ -z "$DOMAIN" ]; then
  echo "Usage: $0 domain.com"
  exit 1
fi

mkdir -p "$OUTPUT_DIR"
cd "$OUTPUT_DIR" || exit 1

RAW="raw_all.txt"
PASSIVE="passive.txt"
BRUTE="brute.txt"
PERM="permutations.txt"
PERM_RESOLVED="permutations_resolved.txt"
RESOLVED="resolved.txt"
FINAL="${DOMAIN}_final_subdomains.txt"
HTTPX_OUT="${DOMAIN}_httpx_results.txt"

> "$RAW"

echo "[*] Target: $DOMAIN"
echo "[*] Output dir: $(pwd)"
echo

# ---------------------------------------------------------
# PHASE 1: PASSIVE ENUMERATION
# ---------------------------------------------------------
echo "[+] [1/8] Assetfinder..."
assetfinder --subs-only "$DOMAIN" 2>/dev/null >> "$RAW"

echo "[+] [1/8] Subfinder (all sources)..."
subfinder -d "$DOMAIN" -all -silent 2>/dev/null >> "$RAW"

echo "[+] [1/8] Sublist3r..."
sublist3r -d "$DOMAIN" -o sublist3r_tmp.txt >/dev/null 2>&1
[ -f sublist3r_tmp.txt ] && cat sublist3r_tmp.txt >> "$RAW" && rm -f sublist3r_tmp.txt

echo "[+] [1/8] Amass (passive mode, fast)..."
timeout 300 amass enum -passive -d "$DOMAIN" -o amass_tmp.txt >/dev/null 2>&1
[ -f amass_tmp.txt ] && cat amass_tmp.txt >> "$RAW" && rm -f amass_tmp.txt

echo "[+] [1/8] crt.sh (Certificate Transparency)..."
curl -s "https://crt.sh/?q=%25.${DOMAIN}&output=json" \
  | grep -oE '"name_value":"[^"]*"' \
  | sed 's/"name_value":"//;s/"//' \
  | sed 's/\*\.//g' \
  | tr ',' '\n' \
  >> "$RAW" 2>/dev/null

echo "[+] [1/8] RapidDNS..."
curl -s "https://rapiddns.io/subdomain/${DOMAIN}?full=1" \
  | grep -oE "[a-zA-Z0-9._-]+\.${DOMAIN}" \
  >> "$RAW" 2>/dev/null

if [ -n "$GITHUB_TOKEN" ] && command -v github-subdomains >/dev/null 2>&1; then
  echo "[+] [1/8] GitHub code search..."
  github-subdomains -d "$DOMAIN" -t "$GITHUB_TOKEN" -raw 2>/dev/null >> "$RAW"
else
  echo "[!] [1/8] Skipping GitHub source (set GITHUB_TOKEN to enable)"
fi

# Clean + dedupe passive results
sed -i '/^\s*$/d' "$RAW"
sort -u "$RAW" | grep -E "(^|\.)${DOMAIN}$" > "$PASSIVE"
echo "[+] Passive sources found: $(wc -l < "$PASSIVE") unique subdomains"
echo

# ---------------------------------------------------------
# PHASE 2: WILDCARD DETECTION
# ---------------------------------------------------------
echo "[+] [2/8] Checking for wildcard DNS..."
RANDSTR=$(tr -dc 'a-z0-9' </dev/urandom | head -c 12)
WILDCARD_IP=$(dig +short "${RANDSTR}.${DOMAIN}" @8.8.8.8 | tail -n1)
if [ -n "$WILDCARD_IP" ]; then
  echo "[!] Wildcard DNS detected (resolves to $WILDCARD_IP) — puredns will filter this automatically"
else
  echo "[+] No wildcard DNS detected"
fi
echo

# ---------------------------------------------------------
# PHASE 3: BUILD MERGED WORDLIST
# ---------------------------------------------------------
echo "[+] [3/8] Building merged brute-force wordlist..."
MERGED_WORDLIST="merged_wordlist.txt"
> "$MERGED_WORDLIST"
FOUND_ANY_WORDLIST=0
for wl in "${WORDLIST_SOURCES[@]}"; do
  if [ -f "$wl" ]; then
    echo "    using: $wl ($(wc -l < "$wl") lines)"
    cat "$wl" >> "$MERGED_WORDLIST"
    FOUND_ANY_WORDLIST=1
  else
    echo "    missing (skipped): $wl"
  fi
done

if [ "$FOUND_ANY_WORDLIST" -eq 1 ]; then
  sort -u "$MERGED_WORDLIST" -o "$MERGED_WORDLIST"
  echo "[+] Merged wordlist total: $(wc -l < "$MERGED_WORDLIST") unique entries"
else
  echo "[!] No wordlists found on disk — brute force phase will be skipped"
fi
echo

# ---------------------------------------------------------
# PHASE 4: ACTIVE DNS BRUTE FORCING
# ---------------------------------------------------------
if command -v puredns >/dev/null 2>&1 && [ -f "$RESOLVERS" ] && [ "$FOUND_ANY_WORDLIST" -eq 1 ]; then
  echo "[+] [4/8] Brute forcing with puredns + massdns (this can take a while)..."
  puredns bruteforce "$MERGED_WORDLIST" "$DOMAIN" \
    -r "$RESOLVERS" \
    --write "$BRUTE" \
    -q 2>/dev/null
  echo "[+] Brute force found: $(wc -l < "$BRUTE" 2>/dev/null || echo 0) subdomains"
else
  echo "[!] [4/8] Skipping brute force — puredns/resolvers/wordlist not found. See setup notes."
  > "$BRUTE"
fi
echo

# ---------------------------------------------------------
# PHASE 5: PERMUTATION / MUTATION SCAN
# ---------------------------------------------------------
if command -v dnsgen >/dev/null 2>&1; then
  echo "[+] [5/8] Generating permutations from known subdomains (dev-, staging-, api-, etc.)..."
  cat "$PASSIVE" "$BRUTE" 2>/dev/null | sort -u > combined_known.txt
  dnsgen combined_known.txt 2>/dev/null > "$PERM"

  if command -v puredns >/dev/null 2>&1 && [ -f "$RESOLVERS" ]; then
    puredns resolve "$PERM" -r "$RESOLVERS" --write "$PERM_RESOLVED" -q 2>/dev/null
  else
    cp "$PERM" "$PERM_RESOLVED"
  fi
  echo "[+] Permutations resolved: $(wc -l < "$PERM_RESOLVED" 2>/dev/null || echo 0)"
else
  echo "[!] [5/8] Skipping permutations — dnsgen not installed (pip3 install dnsgen --break-system-packages)"
  > "$PERM_RESOLVED"
fi
echo

# ---------------------------------------------------------
# PHASE 6: MERGE EVERYTHING + RESOLVE
# ---------------------------------------------------------
echo "[+] [6/8] Merging all sources and resolving final list..."
cat "$PASSIVE" "$BRUTE" "$PERM_RESOLVED" 2>/dev/null \
  | sed 's/\*\.//g' \
  | grep -E "(^|\.)${DOMAIN}$" \
  | sort -u > "$RESOLVED"

if command -v dnsx >/dev/null 2>&1; then
  dnsx -l "$RESOLVED" -silent -o "$FINAL" 2>/dev/null
else
  cp "$RESOLVED" "$FINAL"
fi

TOTAL=$(wc -l < "$FINAL")
echo "[+] Total unique LIVE (DNS-resolving) subdomains: $TOTAL"
echo

# ---------------------------------------------------------
# PHASE 7: HTTP PROBING
# ---------------------------------------------------------
echo "[+] [7/8] Probing for live HTTP(S) services with httpx..."
httpx -l "$FINAL" \
  -status-code -title -tech-detect -follow-redirects \
  -silent -threads "$THREADS" \
  -o "$HTTPX_OUT" 2>/dev/null

echo "[+] Live web services: $(wc -l < "$HTTPX_OUT" 2>/dev/null || echo 0)"
echo

# ---------------------------------------------------------
# PHASE 8: CLEANUP + SUMMARY
# ---------------------------------------------------------
rm -f amass_tmp.txt sublist3r_tmp.txt combined_known.txt merged_wordlist.txt 2>/dev/null

echo "[8/8] ===================== SUMMARY ====================="
echo " Domain:                  $DOMAIN"
echo " Passive subdomains:      $(wc -l < "$PASSIVE" 2>/dev/null || echo 0)"
echo " Brute-forced subdomains: $(wc -l < "$BRUTE" 2>/dev/null || echo 0)"
echo " Permutation subdomains:  $(wc -l < "$PERM_RESOLVED" 2>/dev/null || echo 0)"
echo " TOTAL resolving:         $TOTAL"
echo " Live HTTP(S) hosts:      $(wc -l < "$HTTPX_OUT" 2>/dev/null || echo 0)"
echo
echo " Final subdomain list: $(pwd)/$FINAL"
echo " HTTPX results:        $(pwd)/$HTTPX_OUT"
echo "======================================================="
