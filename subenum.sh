#!/bin/bash

# ========= CONFIGURATION =========
ASSETFINDER_PATH="/home/r1ckt0r/go/bin/assetfinder"
SUBLIST3R_PATH="/home/r1ckt0r/Sublist3r/sublist3r.py"
SUBFINDER_PATH="/home/r1ckt0r/go/bin/subfinder"
HTTPX_PATH="/home/r1ckt0r/go/bin/httpx"

OUTPUT_DIR="./output"
mkdir -p "$OUTPUT_DIR"
# =================================

if [ -z "$1" ]; then
  echo "Usage: $0 domain.com"
  exit 1
fi

DOMAIN=$1
SUBDOMAINS_RAW="$OUTPUT_DIR/${DOMAIN}_raw.txt"
SUBDOMAINS_CLEAN="$OUTPUT_DIR/${DOMAIN}_unique.txt"
HTTPX_OUTPUT="$OUTPUT_DIR/${DOMAIN}_httpx.txt"

# Step 1: Assetfinder
echo "[+] Running assetfinder..."
$ASSETFINDER_PATH --subs-only $DOMAIN >> "$SUBDOMAINS_RAW"

# Step 2: Sublist3r (Python)
echo "[+] Running sublist3r..."
python3 $SUBLIST3R_PATH -d $DOMAIN -o "$OUTPUT_DIR/sublist3r_temp.txt"
cat "$OUTPUT_DIR/sublist3r_temp.txt" >> "$SUBDOMAINS_RAW"
rm "$OUTPUT_DIR/sublist3r_temp.txt"

# Step 3: Subfinder
echo "[+] Running subfinder..."
$SUBFINDER_PATH -d $DOMAIN -silent >> "$SUBDOMAINS_RAW"

# Step 4: Remove duplicates
echo "[+] Removing duplicates..."
cat "$SUBDOMAINS_RAW" | sort -u > "$SUBDOMAINS_CLEAN"

# Step 5: Run httpx
echo "[+] Running httpx on unique subdomains..."
cat "$SUBDOMAINS_CLEAN" | $HTTPX_PATH -status-code -title -silent > "$HTTPX_OUTPUT"

echo "[+] Done! Results saved in: $HTTPX_OUTPUT"
