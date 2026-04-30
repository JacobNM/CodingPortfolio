#!/usr/bin/env bash
# =============================================================================
# azure_ssl_audit.sh — Read-only SSL certificate expiry audit
# Vantage Analytics — v8
#
# Usage:
#   ./azure_ssl_audit.sh                               # all subscriptions
#   ./azure_ssl_audit.sh --filter-sub Vantage-Release  # one sub only
#   ./azure_ssl_audit.sh --filter-sub Vantage-Release --debug-inline
#
# Output: one JSON object per line to stdout
# Prerequisites: az CLI (logged in), jq, openssl, python3
# =============================================================================

set -euo pipefail

FILTER_SUB=""
DEBUG_INLINE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --filter-sub)   FILTER_SUB="$2"; shift 2 ;;
    --debug-inline) DEBUG_INLINE=true; shift ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

TODAY_EPOCH=$(date +%s)
CUTOFF_DAYS=548

log()  { echo "[INFO]  $*" >&2; }
warn() { echo "[WARN]  $*" >&2; }

iso_to_epoch() {
  local date_part="${1:0:10}"
  local epoch
  epoch=$(date -d "${date_part}" +%s 2>/dev/null) \
    || epoch=$(date -j -f "%Y-%m-%d" "${date_part}" +%s 2>/dev/null) \
    || epoch=""
  echo "$epoch"
}

days_left_from_iso() {
  local epoch
  epoch=$(iso_to_epoch "$1")
  [[ -z "$epoch" ]] && { echo ""; return; }
  echo $(( (epoch - TODAY_EPOCH) / 86400 ))
}

should_emit() {
  local days="$1"
  [[ -z "$days" ]] && return 1
  [[ "$days" -le "$CUTOFF_DAYS" ]]
}

jsafe() { printf '%s' "${1//\"/\'}" | tr '\n' ' '; }

emit() {
  local name="$1" type="$2" expiry="$3" resource="$4" sub="$5"
  local used_by="$6" issuer="${7:-Unknown}" in_use="${8:-true}"
  local dl
  dl=$(days_left_from_iso "$expiry")
  should_emit "$dl" || return 0
  printf '{"name":"%s","type":"%s","expiry":"%s","days_left":%d,"issuer":"%s","resource":"%s","subscription":"%s","used_by":"%s","in_use":%s}\n' \
    "$(jsafe "$name")" "$(jsafe "$type")" "${expiry:0:10}" "$dl" \
    "$(jsafe "$issuer")" "$(jsafe "$resource")" "$(jsafe "$sub")" \
    "$(jsafe "$used_by")" "$in_use"
}

extract_issuer_label() {
  local raw="$1"
  local org
  org=$(echo "$raw" | grep -oP '(?<=O = )[^,]+' 2>/dev/null | head -1 \
      || echo "$raw" | grep -oE 'O=[^,/]+' 2>/dev/null | head -1 | sed 's/O=//' || true)
  [[ -n "${org// /}" ]] && { echo "${org#"${org%%[! ]*}"}"; return; }
  local cn
  cn=$(echo "$raw" | grep -oP '(?<=CN = )[^,]+' 2>/dev/null | head -1 \
     || echo "$raw" | grep -oE 'CN=[^,/]+' 2>/dev/null | head -1 | sed 's/CN=//' || true)
  [[ -n "${cn// /}" ]] && { echo "$cn"; return; }
  echo "Unknown CA"
}

# Python cert decoder — avoids bash binary-variable corruption of null bytes
# Writes base64 to a real tempfile, tries DER/PEM/PKCS7-DER/PKCS7-PEM
# Prints "notAfter=...\nissuer=..." on success, exits 1 on failure
CERT_DECODER_PY='
import sys, base64, subprocess, tempfile, os

cert_name  = sys.argv[1]
debug_mode = sys.argv[2].lower() == "true"
raw_b64    = sys.stdin.read().strip()
if not raw_b64:
    sys.exit(1)

try:
    decoded = base64.b64decode(raw_b64)
except Exception as e:
    if debug_mode: print(f"[DEBUG]   {cert_name}: base64 decode error: {e}", file=sys.stderr)
    sys.exit(1)

tmp = tempfile.NamedTemporaryFile(delete=False, suffix=".bin")
tmp.write(decoded); tmp.close()

def try_cmd(label, cmd):
    try:
        r = subprocess.run(cmd, capture_output=True, text=True)
        if r.returncode == 0 and "notAfter" in r.stdout:
            if debug_mode: print(f"[DEBUG]   {cert_name}: {label} ok", file=sys.stderr)
            return r.stdout.strip()
    except Exception as e:
        if debug_mode: print(f"[DEBUG]   {cert_name}: {label} exception: {e}", file=sys.stderr)
    if debug_mode: print(f"[DEBUG]   {cert_name}: {label} failed", file=sys.stderr)
    return None

result = (
    try_cmd("DER/X509",  ["openssl","x509", "-inform","DER","-in",tmp.name,"-noout","-enddate","-issuer"]) or
    try_cmd("PEM/X509",  ["openssl","x509", "-inform","PEM","-in",tmp.name,"-noout","-enddate","-issuer"])
)

if not result:
    for fmt_label, fmt_flag in [("PKCS7/DER","DER"),("PKCS7/PEM","PEM")]:
        try:
            r1 = subprocess.run(
                ["openssl","pkcs7","-inform",fmt_flag,"-in",tmp.name,"-print_certs"],
                capture_output=True)
            if r1.returncode == 0 and b"CERTIFICATE" in r1.stdout:
                t2 = tempfile.NamedTemporaryFile(delete=False, suffix=".pem")
                t2.write(r1.stdout); t2.close()
                r2 = subprocess.run(
                    ["openssl","x509","-in",t2.name,"-noout","-enddate","-issuer"],
                    capture_output=True, text=True)
                os.unlink(t2.name)
                if r2.returncode == 0 and "notAfter" in r2.stdout:
                    if debug_mode: print(f"[DEBUG]   {cert_name}: {fmt_label} ok", file=sys.stderr)
                    result = r2.stdout.strip()
                    break
                elif debug_mode:
                    print(f"[DEBUG]   {cert_name}: {fmt_label} x509-step failed", file=sys.stderr)
            elif debug_mode:
                print(f"[DEBUG]   {cert_name}: {fmt_label} pkcs7-step failed (rc={r1.returncode})", file=sys.stderr)
        except Exception as e:
            if debug_mode: print(f"[DEBUG]   {cert_name}: {fmt_label} exception: {e}", file=sys.stderr)

os.unlink(tmp.name)
if result:
    print(result)
else:
    if debug_mode: print(f"[DEBUG]   {cert_name}: all formats failed", file=sys.stderr)
    sys.exit(1)
'

# ── subscription list ─────────────────────────────────────────────────────────
ALL_SUBS=$(az account list --query "[].{id:id,name:name}" -o json)
if [[ -n "$FILTER_SUB" ]]; then
  SUBSCRIPTIONS=$(echo "$ALL_SUBS" | jq --arg f "$FILTER_SUB" '[.[] | select(.name == $f)]')
  if [[ $(echo "$SUBSCRIPTIONS" | jq length) -eq 0 ]]; then
    echo "[ERROR] No subscription named '$FILTER_SUB'. Available:" >&2
    echo "$ALL_SUBS" | jq -r '.[].name' >&2; exit 1
  fi
else
  SUBSCRIPTIONS="$ALL_SUBS"
fi
log "Scanning $(echo "$SUBSCRIPTIONS" | jq length) subscription(s)$([ -n "$FILTER_SUB" ] && echo " (filter: $FILTER_SUB)" || true)"

# ── main loop ─────────────────────────────────────────────────────────────────
echo "$SUBSCRIPTIONS" | jq -c '.[]' | while read -r sub_obj; do
  SUB_ID=$(echo "$sub_obj"   | jq -r '.id')
  SUB_NAME=$(echo "$sub_obj" | jq -r '.name')
  log "=== Subscription: $SUB_NAME ($SUB_ID) ==="

  KV_MAP=$(mktemp); THUMB_MAP=$(mktemp)
  trap 'rm -f "$KV_MAP" "$THUMB_MAP"' EXIT

  # ── Pass 1: build consumer maps ───────────────────────────────────────────
  log "  [Pass 1] Mapping App Gateways..."
  AGS=$(az network application-gateway list --subscription "$SUB_ID" \
          --query "[].{name:name,rg:resourceGroup}" -o json 2>/dev/null || echo "[]")
  log "  Found $(echo "$AGS" | jq length) App Gateway(s)"

  echo "$AGS" | jq -c '.[]' | while read -r ag; do
    AG_NAME=$(echo "$ag" | jq -r '.name'); AG_RG=$(echo "$ag" | jq -r '.rg')
    AG_DETAIL=$(az network application-gateway show --subscription "$SUB_ID" \
                  --name "$AG_NAME" --resource-group "$AG_RG" \
                  -o json 2>/dev/null || echo "{}")
    echo "$AG_DETAIL" | jq -r \
      '.sslCertificates[]? | select(.keyVaultSecretId != null) | .keyVaultSecretId' \
      | while read -r secret_uri; do
          cert_key=$(echo "$secret_uri" | awk -F'/' '{print tolower($(NF-1))}')
          echo "${cert_key}=App Gateway: ${AG_NAME}" >> "$KV_MAP"
        done
  done

  log "  [Pass 1] Mapping App Services..."
  APPS=$(az webapp list --subscription "$SUB_ID" \
           --query "[].{name:name,rg:resourceGroup,kind:kind}" -o json 2>/dev/null || echo "[]")
  echo "$APPS" | jq -c '.[]' | while read -r app; do
    APP_NAME=$(echo "$app" | jq -r '.name'); APP_RG=$(echo "$app" | jq -r '.rg')
    APP_KIND=$(echo "$app" | jq -r '.kind // ""')
    KIND_LABEL="App Service"; [[ "$APP_KIND" == *"functionapp"* ]] && KIND_LABEL="Azure Function"
    BINDINGS=$(az webapp config ssl list --subscription "$SUB_ID" \
                 --resource-group "$APP_RG" -o json 2>/dev/null || echo "[]")
    echo "$BINDINGS" | jq -r '.[].thumbprint // empty' | while read -r thumb; do
      [[ -z "$thumb" ]] && continue
      echo "${thumb,,}=${KIND_LABEL}: ${APP_NAME}" >> "$THUMB_MAP"
    done
  done

  # ── Pass 2: emit records ──────────────────────────────────────────────────

  # 1. Key Vault Certificates
  log "  [Pass 2] Scanning Key Vaults..."
  KVS=$(az keyvault list --subscription "$SUB_ID" \
          --query "[].{name:name,rg:resourceGroup}" -o json 2>/dev/null || echo "[]")
  log "  Found $(echo "$KVS" | jq length) Key Vault(s)"
  echo "$KVS" | jq -c '.[]' | while read -r kv; do
    KV_NAME=$(echo "$kv" | jq -r '.name'); KV_RG=$(echo "$kv" | jq -r '.rg')
    CERTS=$(az keyvault certificate list --subscription "$SUB_ID" \
              --vault-name "$KV_NAME" \
              --query "[].{name:name,exp:attributes.expires,enabled:attributes.enabled}" \
              -o json 2>/dev/null || echo "[]")
    log "    $KV_NAME: $(echo "$CERTS" | jq length) cert(s)"
    echo "$CERTS" | jq -c '.[]' | while read -r cert; do
      CNAME=$(echo "$cert" | jq -r '.name')
      EXP=$(echo "$cert"   | jq -r '.exp // empty')
      ENABLED=$(echo "$cert" | jq -r '.enabled // true')
      [[ -z "$EXP" || "$ENABLED" == "false" ]] && continue
      CERT_POLICY=$(az keyvault certificate show --subscription "$SUB_ID" \
                      --vault-name "$KV_NAME" --name "$CNAME" \
                      --query "policy.issuerParameters.name" -o tsv 2>/dev/null || echo "Unknown")
      [[ "$CERT_POLICY" == "Self" ]] && CERT_POLICY="Self-signed"
      [[ -z "$CERT_POLICY" || "$CERT_POLICY" == "None" ]] && CERT_POLICY="Unknown"
      CERT_KEY="${CNAME,,}"
      CONSUMER=$(grep "^${CERT_KEY}=" "$KV_MAP" 2>/dev/null | head -1 | cut -d= -f2- || true)
      IN_USE="false"; USED_BY="Key Vault only — no detected consumer"
      if [[ -n "$CONSUMER" ]]; then IN_USE="true"; USED_BY="${CONSUMER} (cert in KV: ${KV_NAME})"; fi
      emit "$CNAME" "Key Vault Certificate" "$EXP" \
           "keyvault/$KV_NAME (rg: $KV_RG)" "$SUB_NAME" "$USED_BY" "$CERT_POLICY" "$IN_USE"
    done
  done

  # 2. App Gateway Inline SSL Certs
  # NOTE: az network application-gateway show does NOT populate publicCertData
  # in the sslCertificates array. Must use ssl-cert list which does.
  log "  [Pass 2] Scanning App Gateway inline certs..."
  echo "$AGS" | jq -c '.[]' | while read -r ag; do
    AG_NAME=$(echo "$ag" | jq -r '.name'); AG_RG=$(echo "$ag" | jq -r '.rg')

    # ssl-cert list: returns publicCertData and keyVaultSecretId per cert
    SSL_CERTS=$(az network application-gateway ssl-cert list --subscription "$SUB_ID" \
                  --gateway-name "$AG_NAME" --resource-group "$AG_RG" \
                  -o json 2>/dev/null || echo "[]")
    CERT_COUNT=$(echo "$SSL_CERTS" | jq length)
    log "    $AG_NAME: $CERT_COUNT SSL cert(s)"

    # show: used only for listener→cert mapping
    AG_DETAIL=$(az network application-gateway show --subscription "$SUB_ID" \
                  --name "$AG_NAME" --resource-group "$AG_RG" \
                  -o json 2>/dev/null || echo "{}")

    echo "$SSL_CERTS" | jq -c '.[]' | while read -r ssl; do
      CNAME=$(echo "$ssl" | jq -r '.name')
      KV_SECRET_ID=$(echo "$ssl" | jq -r '.keyVaultSecretId // empty')
      PUB_CERT=$(echo "$ssl" | jq -r '.publicCertData // empty')

      [[ -n "$KV_SECRET_ID" ]] && { log "    $AG_NAME/$CNAME: KV-backed — handled in KV scan"; continue; }
      [[ -z "$PUB_CERT" ]] && { warn "    $AG_NAME/$CNAME: no publicCertData — skipping"; continue; }

      # Use Python to decode — avoids bash null-byte corruption of binary data.
      # Format is PKCS#7 SignedData DER (confirmed from Azure API inspection).
      CERT_TEXT=$(echo "$PUB_CERT" | python3 -c "$CERT_DECODER_PY" "$CNAME" "$DEBUG_INLINE" 2>&1 \
                  | grep -v "^\[DEBUG\]\|\[WARN\]\|\[INFO\]" || true)

      if [[ -z "$CERT_TEXT" ]]; then
        warn "    $AG_NAME/$CNAME: cert decode failed — skipping"; continue
      fi

      RAW_EXP=$(echo "$CERT_TEXT"    | grep notAfter | sed 's/notAfter=//')
      RAW_ISSUER=$(echo "$CERT_TEXT" | grep issuer   | sed 's/issuer=//')
      ISSUER_LABEL=$(extract_issuer_label "$RAW_ISSUER")
      EXP_ISO=$(date -d "$RAW_EXP" '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null \
                || date -j -f "%b %d %T %Y %Z" "$RAW_EXP" '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || echo "")
      [[ -z "$EXP_ISO" ]] && { warn "    $AG_NAME/$CNAME: date parse failed on '$RAW_EXP'"; continue; }

      LISTENERS=$(echo "$AG_DETAIL" | jq -r \
        --arg cn "$CNAME" \
        '[.httpListeners[]? | select((.sslCertificate.id // "") | endswith($cn)) | .name] | join(", ")')
      USED_BY="App Gateway: $AG_NAME (inline) → Listeners: ${LISTENERS:-unknown}"
      emit "$CNAME" "App Gateway SSL Cert (inline)" "$EXP_ISO" \
           "appgateway/$AG_NAME (rg: $AG_RG)" "$SUB_NAME" "$USED_BY" "$ISSUER_LABEL" "true"
    done
  done

  # 3. App Service / Function TLS Bindings
  log "  [Pass 2] Scanning App Service TLS bindings..."
  echo "$APPS" | jq -c '.[]' | while read -r app; do
    APP_NAME=$(echo "$app" | jq -r '.name'); APP_RG=$(echo "$app" | jq -r '.rg')
    APP_KIND=$(echo "$app" | jq -r '.kind // ""')
    KIND_LABEL="App Service"; [[ "$APP_KIND" == *"functionapp"* ]] && KIND_LABEL="Azure Function"
    BINDINGS=$(az webapp config ssl list --subscription "$SUB_ID" \
                 --resource-group "$APP_RG" -o json 2>/dev/null || echo "[]")
    echo "$BINDINGS" | jq -c '.[]' | while read -r b; do
      BHOST=$(echo "$b" | jq -r \
        '[.hostNames[]? // empty] | map(select(test("^'"$APP_NAME"'\\."; "i"))) | first // empty')
      [[ -z "$BHOST" ]] && continue
      THUMBPRINT=$(echo "$b" | jq -r '.thumbprint // empty')
      EXP=$(echo "$b" | jq -r '.expirationDate // empty')
      [[ -z "$EXP" ]] && continue
      DOMAIN=$(echo "$b" | jq -r '[.hostNames[]? // empty] | first // "unknown"')
      ISSUER_RAW=$(echo "$b" | jq -r '.issuer // "Unknown"')
      emit "$THUMBPRINT" "$KIND_LABEL TLS Binding" "$EXP" \
           "appservice/$APP_NAME (rg: $APP_RG)" "$SUB_NAME" \
           "$KIND_LABEL: $APP_NAME → $DOMAIN" "$ISSUER_RAW" "true"
    done
  done

  # 4. API Management
  log "  [Pass 2] Scanning API Management..."
  APIMS=$(az apim list --subscription "$SUB_ID" \
            --query "[].{name:name,rg:resourceGroup}" -o json 2>/dev/null || echo "[]")
  echo "$APIMS" | jq -c '.[]' | while read -r apim; do
    APIM_NAME=$(echo "$apim" | jq -r '.name'); APIM_RG=$(echo "$apim" | jq -r '.rg')
    APIM_DETAIL=$(az apim show --subscription "$SUB_ID" \
                    --name "$APIM_NAME" --resource-group "$APIM_RG" \
                    -o json 2>/dev/null || echo "{}")
    echo "$APIM_DETAIL" | jq -c '.hostnameConfigurations[]?' | while read -r hc; do
      EXP=$(echo "$hc" | jq -r '.certificate.expiry // empty'); [[ -z "$EXP" ]] && continue
      HOST=$(echo "$hc" | jq -r '.hostName'); TYPE=$(echo "$hc" | jq -r '.type')
      ISSUER_RAW=$(echo "$hc" | jq -r '.certificate.subject // "Unknown"')
      emit "$HOST" "APIM Custom Domain ($TYPE)" "$EXP" \
           "apim/$APIM_NAME (rg: $APIM_RG)" "$SUB_NAME" \
           "APIM: $APIM_NAME → $HOST" "$ISSUER_RAW" "true"
    done
  done

  # 5. Front Door Standard/Premium
  log "  [Pass 2] Scanning Front Door..."
  AFD2=$(az afd profile list --subscription "$SUB_ID" \
           --query "[].{name:name,rg:resourceGroup}" -o json 2>/dev/null || echo "[]")
  echo "$AFD2" | jq -c '.[]' | while read -r p; do
    P_NAME=$(echo "$p" | jq -r '.name'); P_RG=$(echo "$p" | jq -r '.rg')
    SECRETS=$(az afd secret list --subscription "$SUB_ID" \
                --profile-name "$P_NAME" --resource-group "$P_RG" \
                -o json 2>/dev/null || echo "[]")
    echo "$SECRETS" | jq -c '.[]' | while read -r s; do
      SNAME=$(echo "$s" | jq -r '.name')
      EXP=$(echo "$s" | jq -r '.parameters.expirationDate // empty'); [[ -z "$EXP" ]] && continue
      emit "$SNAME" "Front Door Secret (Cert)" "$EXP" \
           "afd-profile/$P_NAME (rg: $P_RG)" "$SUB_NAME" \
           "Front Door: $P_NAME" "Unknown" "true"
    done
  done

  # 6. Container Apps
  log "  [Pass 2] Scanning Container Apps..."
  CA_ENVS=$(az containerapp env list --subscription "$SUB_ID" \
              --query "[].{name:name,rg:resourceGroup}" -o json 2>/dev/null || echo "[]")
  echo "$CA_ENVS" | jq -c '.[]' | while read -r env; do
    ENV_NAME=$(echo "$env" | jq -r '.name'); ENV_RG=$(echo "$env" | jq -r '.rg')
    CERTS=$(az containerapp env certificate list --subscription "$SUB_ID" \
              --name "$ENV_NAME" --resource-group "$ENV_RG" \
              -o json 2>/dev/null || echo "[]")
    echo "$CERTS" | jq -c '.[]' | while read -r cert; do
      CNAME=$(echo "$cert" | jq -r '.name')
      EXP=$(echo "$cert" | jq -r '.properties.expirationDate // empty'); [[ -z "$EXP" ]] && continue
      DOMAIN=$(echo "$cert" | jq -r '.properties.subjectName // "unknown"')
      emit "$CNAME" "Container App Env Cert" "$EXP" \
           "containerapp-env/$ENV_NAME (rg: $ENV_RG)" "$SUB_NAME" \
           "Container Apps Env: $ENV_NAME → $DOMAIN" "Unknown" "true"
    done
  done

  rm -f "$KV_MAP" "$THUMB_MAP"
done

log "Scan complete."