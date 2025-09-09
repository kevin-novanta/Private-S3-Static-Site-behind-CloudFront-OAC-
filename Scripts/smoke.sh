# Smoke test for the Private S3 CloudFront OAC project
# This script checks if the necessary files and directories exist
# and verifies that the AWS CLI is installed.
# Usage: ./smoke.sh
# Or provide values manually:
#   CDN_HOST=cdn.staging.example.com SITE_BUCKET=my-bucket ./Scripts/smoke.sh

set -euo pipefail

# config & inputs

ENV_DIR="${ENV_DIR:-Infra/Terraform/environments/staging}"
REGION="${REGION:-us-east-1}"

CDN_HOST="${CDN_HOST:-${1:-}}"
SITE_BUCKET="${SITE_BUCKET:-${2:-}}"
DIST_ID="${DIST_ID:-${3:-}}"

# helper: color output
bold()  { printf "\033[1m%s\033[0m\n" "$*"; }
ok()    { printf "✅ %s\n" "$*"; }
warn()  { printf "⚠️  %s\n" "$*"; }
err()   { printf "❌ %s\n" "$*"; }

# Try to read Terraform outputs if not provided 

if [[ -z "${CDN_HOST}" || -z "${SITE_BUCKET}" || -z "${DIST_ID}" ]]; then
  if [[ -d "${ENV_DIR}" ]]; then
    pushd "${ENV_DIR}" >/dev/null
    CDN_URL_TF=$(terraform output -raw cdn_url 2>/dev/null || true)
    SITE_BUCKET_TF=$(terraform output -raw s3_bucket_name 2>/dev/null || true)
    DIST_ID_TF=$(terraform output -raw cloudfront_distribution_id 2>/dev/null || true)
    popd >/dev/null

    [[ -z "${CDN_HOST}"    && -n "${CDN_URL_TF}"    ]] && CDN_HOST="${CDN_URL_TF#https://}"
    [[ -z "${SITE_BUCKET}" && -n "${SITE_BUCKET_TF}" ]] && SITE_BUCKET="${SITE_BUCKET_TF}"
    [[ -z "${DIST_ID}"     && -n "${DIST_ID_TF}"     ]] && DIST_ID="${DIST_ID_TF}"
  fi
fi

if [[ -z "${CDN_HOST}" || -z "${SITE_BUCKET}" ]]; then
  err "Missing CDN_HOST or SITE_BUCKET. Set env vars or ensure Terraform outputs exist in ${ENV_DIR}."
  echo "Examples:"
  echo "  CDN_HOST=cdn.staging.kevinscloudlab.click SITE_BUCKET=p1-private-site-staging-site-123456789 ./Scripts/smoke.sh"
  echo "  (or just run with Terraform outputs ready): ./Scripts/smoke.sh"
  exit 2
fi

bold "Smoke test starting"
echo "ENV_DIR:     ${ENV_DIR}"
echo "CDN_HOST:    ${CDN_HOST}"
echo "SITE_BUCKET: ${SITE_BUCKET}"
echo "REGION:      ${REGION}"
[[ -n "${DIST_ID:-}" ]] && echo "DIST_ID:     ${DIST_ID}"

FAIL=0

# 1) DNS resolution
bold "1) DNS resolves to CloudFront"
if command -v dig >/dev/null 2>&1; then
  echo "A records:"
  dig +short "${CDN_HOST}" || true
  echo "AAAA records:"
  dig +short AAAA "${CDN_HOST}" || true
  ok "DNS resolution attempted"
else
  warn "dig not installed; skipping DNS detail (optional)"
fi

# 2) HTTPS reachability + headers 
bold "2) HTTPS reachable and headers look like CloudFront"
HEADERS=$(mktemp)
HTTP_CODE=$(curl -sS -I "https://${CDN_HOST}" -o "${HEADERS}" -w "%{http_code}")
echo "HTTP ${HTTP_CODE}"
sed -n '1,20p' "${HEADERS}" || true

if [[ "${HTTP_CODE}" != "200" && "${HTTP_CODE}" != "304" ]]; then
  err "Expected 200/304 from CDN, got ${HTTP_CODE}"
  ((FAIL++)) || true
else
  ok "CDN returned ${HTTP_CODE}"
fi

if grep -qi '^server: *cloudfront' "${HEADERS}"; then
  ok "Server header is CloudFront"
else
  warn "Server header not clearly CloudFront (might still be OK)"
fi

if grep -qi '^x-cache: ' "${HEADERS}"; then
  ok "x-cache header present"
else
  warn "No x-cache header found (not fatal)"
fi

# 3) TLS certificate sanity 
bold "3) TLS subject/issuer"
if command -v openssl >/dev/null 2>&1; then
  echo | openssl s_client -servername "${CDN_HOST}" -connect "${CDN_HOST}:443" 2>/dev/null \
    | openssl x509 -noout -subject -issuer | sed 's/^/  /'
  ok "TLS chain read"
else
  warn "openssl not installed; skipping TLS subject/issuer (optional)"
fi

# 4) CDN content (first 10 lines) 
bold "4) Fetch sample content from CDN"
curl -sS "https://${CDN_HOST}" | head -n 10 || true
ok "Fetched sample content (truncated)"

# 5) Direct S3 access MUST be blocked (403)
bold "5) Direct S3 object access is forbidden (OAC working)"
S3_URLS=(
  "https://${SITE_BUCKET}.s3.amazonaws.com/index.html"
  "https://${SITE_BUCKET}.s3.${REGION}.amazonaws.com/index.html"
)

S3_OK_403=0
for url in "${S3_URLS[@]}"; do
  code=$(curl -sS -o /dev/null -w "%{http_code}" -I "${url}" || true)
  echo "${url} -> HTTP ${code}"
  if [[ "${code}" == "403" ]]; then
    S3_OK_403=1
  fi
done

if [[ "${S3_OK_403}" -eq 1 ]]; then
  ok "S3 direct GET is blocked (403) as expected"
else
  err "S3 direct GET did NOT return 403 (check bucket policy/OAC wiring)"
  ((FAIL++)) || true
fi

# -------- 6) (Optional) Access logs quick peek --------
bold "6) (Optional) CloudFront access logs presence (may take minutes)"
if command -v aws >/dev/null 2>&1; then
  LOGS_BUCKET=$(aws s3api list-buckets \
    --query "Buckets[?contains(Name, '-cf-logs-')].Name | [0]" --output text 2>/dev/null || true)
  if [[ -n "${LOGS_BUCKET}" && "${LOGS_BUCKET}" != "None" ]]; then
    echo "Listing recent objects in s3://${LOGS_BUCKET}/cloudfront/ (might be empty if too fresh):"
    aws s3 ls "s3://${LOGS_BUCKET}/cloudfront/" | tail -n 5 || true
    ok "Logs bucket detected: ${LOGS_BUCKET}"
  else
    warn "No logs bucket matched pattern '*-cf-logs-*' (skipping)"
  fi
else
  warn "AWS CLI not installed; skipping logs check (optional)"
fi

# 7) (Optional) Invalidation
if [[ "${INVALIDATE:-false}" == "true" ]]; then
  if [[ -n "${DIST_ID}" ]] && command -v aws >/dev/null 2>&1; then
    bold "7) Creating CloudFront invalidation /*"
    aws cloudfront create-invalidation --distribution-id "${DIST_ID}" --paths "/*" >/dev/null
    ok "Invalidation requested"
  else
    warn "INVALIDATE=true but missing DIST_ID or aws cli; skipping"
  fi
fi

# Summary 
bold "Summary"
if [[ "${FAIL}" -eq 0 ]]; then
  ok "All critical smoke checks passed ✅"
  exit 0
else
  err "${FAIL} check(s) failed ❌"
  exit 1
fi