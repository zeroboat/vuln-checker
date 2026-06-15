#!/bin/bash

################################################################################
# CIS Linux Benchmark 공통 함수 라이브러리
################################################################################

source "$(dirname "${BASH_SOURCE[0]}")/security_codes.sh"
source "$(dirname "${BASH_SOURCE[0]}")/security_details.sh"

################################################################################
# JSON 관련 변수 및 함수
################################################################################

CIS_JSON_CHECKS_TMP=""

init_cis_json() {
    CIS_JSON_CHECKS_TMP=$(mktemp /tmp/cis_json_XXXXXX 2>/dev/null || echo "/tmp/cis_json_$$")
    > "$CIS_JSON_CHECKS_TMP"
}

# json_escape는 main.sh의 common.sh에서 이미 정의되어 있으나
# 독립 실행을 대비해 미정의 시에만 정의
if ! declare -f json_escape >/dev/null 2>&1; then
    json_escape() {
        local str="$1"
        str="${str//\\/\\\\}"
        str="${str//\"/\\\"}"
        str="${str//$'\n'/\\n}"
        str="${str//$'\r'/}"
        str="${str//$'\t'/\\t}"
        echo -n "$str"
    }
fi

record_cis_json_check() {
    local code="$1"
    local status="$2"
    local detail="$3"
    local name=$(json_escape "${CIS_CODES[$code]}")
    local category=$(json_escape "$(get_cis_category "$code")")
    local esc_detail=$(json_escape "$detail")
    local purpose=$(json_escape "${CIS_DETAILS[${code}_PURPOSE]}")
    local check=$(json_escape "${CIS_DETAILS[${code}_CHECK]}")
    local good=$(json_escape "${CIS_DETAILS[${code}_GOOD]}")
    local bad=$(json_escape "${CIS_DETAILS[${code}_BAD]}")
    local action=$(json_escape "${CIS_DETAILS[${code}_ACTION]}")
    local threat=$(json_escape "${CIS_DETAILS[${code}_THREAT]}")

    cat >> "$CIS_JSON_CHECKS_TMP" <<JSONENTRY
{"code":"${code}","name":"${name}","category":"${category}","status":"${status}","detail":"${esc_detail}","reference":{"purpose":"${purpose}","check":"${check}","goodCriteria":"${good}","badCriteria":"${bad}","remediation":"${action}","threat":"${threat}"}},
JSONENTRY
}

generate_cis_json() {
    local json_file="$1"
    local exec_time="$2"
    local hostname="$3"
    local distro="$4"
    local arch="$5"
    local pass_count="$6"
    local fail_count="$7"
    local review_count="$8"
    local total_count="$9"

    local esc_hostname=$(json_escape "$hostname")
    local esc_distro=$(json_escape "$distro")

    local checks_json=""
    if [ -f "$CIS_JSON_CHECKS_TMP" ] && [ -s "$CIS_JSON_CHECKS_TMP" ]; then
        checks_json=$(sed '$ s/,$//' "$CIS_JSON_CHECKS_TMP")
    fi

    cat > "$json_file" <<JSONEOF
{
  "metadata": {
    "executionTime": "${exec_time}",
    "hostname": "${esc_hostname}",
    "os": "CIS-Linux",
    "distro": "${esc_distro}",
    "architecture": "${arch}"
  },
  "summary": {
    "total": ${total_count},
    "pass": ${pass_count},
    "fail": ${fail_count},
    "review": ${review_count}
  },
  "checks": [
${checks_json}
  ]
}
JSONEOF

    rm -f "$CIS_JSON_CHECKS_TMP" 2>/dev/null
}

################################################################################
# 로그 / 출력 함수
################################################################################

cis_append_log() {
    local message="$1"
    echo "${message}" >> "$CIS_RESULT_FILE"
}

cis_print_section() {
    local title="$1"
    cis_append_log ""
    cis_append_log "############################################################################"
    cis_append_log "## $title"
    cis_append_log "############################################################################"
    cis_append_log ""
}

cis_print_check() {
    local code="$1"
    local name="${CIS_CODES[$code]}"
    cis_append_log ""
    cis_append_log "────────────────────────────────────────"
    cis_append_log "[${code}] ${name}"
}

cis_record_result() {
    local code="$1"
    local status="$2"
    local detail="$3"

    cis_append_log ""
    case "$status" in
        PASS)   cis_append_log "  ✅ 점검 결과: 양호" ;;
        FAIL)   cis_append_log "  ❌ 점검 결과: 취약" ;;
        REVIEW) cis_append_log "  ⚠️  점검 결과: 확인필요" ;;
    esac

    if [ -n "$detail" ]; then
        cis_append_log "  상세: $detail"
    fi
    cis_append_log "────────────────────────────────────────"

    if [ -n "$CIS_JSON_CHECKS_TMP" ]; then
        record_cis_json_check "$code" "$status" "$detail"
    fi

    case "$status" in
        PASS)   CIS_PASS_COUNT=$((CIS_PASS_COUNT + 1)) ;;
        FAIL)   CIS_FAIL_COUNT=$((CIS_FAIL_COUNT + 1)) ;;
        REVIEW) CIS_REVIEW_COUNT=$((CIS_REVIEW_COUNT + 1)) ;;
    esac
}

################################################################################
# 유틸리티 함수
################################################################################

cis_command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# sysctl 현재 적용값 조회 (실패 시 빈 문자열)
cis_sysctl_get() {
    local key="$1"
    sysctl -n "$key" 2>/dev/null
}

# 패키지 설치 여부 확인 (dpkg/rpm 양쪽 지원)
cis_package_installed() {
    local pkg="$1"
    if cis_command_exists dpkg-query; then
        dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed" && return 0
    fi
    if cis_command_exists rpm; then
        rpm -q "$pkg" >/dev/null 2>&1 && return 0
    fi
    return 1
}

# 서비스 활성화(enabled 또는 active) 여부 확인
cis_service_active() {
    local svc="$1"
    if cis_command_exists systemctl; then
        local enabled active
        enabled=$(systemctl is-enabled "$svc" 2>/dev/null)
        active=$(systemctl is-active "$svc" 2>/dev/null)
        if [ "$enabled" = "enabled" ] || [ "$active" = "active" ]; then
            return 0
        fi
    fi
    return 1
}

# 파일 권한(8진수) 조회 — Linux/BSD 양쪽 stat 지원
cis_file_perm() {
    local f="$1"
    stat -c %a "$f" 2>/dev/null || stat -f %Lp "$f" 2>/dev/null
}

# 파일 소유자 조회
cis_file_owner() {
    local f="$1"
    stat -c %U "$f" 2>/dev/null || stat -f %Su "$f" 2>/dev/null
}

# 현재 권한이 최대 허용 권한 이하인지 비교 (8진수)
# 사용법: cis_perm_le "$cur" "640"  → 0(이하) / 1(초과)
cis_perm_le() {
    local cur="$1" max="$2"
    local cur_dec max_dec
    cur_dec=$(printf "%d" "0${cur}" 2>/dev/null) || return 1
    max_dec=$(printf "%d" "0${max}" 2>/dev/null) || return 1
    [ "$cur_dec" -le "$max_dec" ]
}

################################################################################
# 섹션별 점검 파일 로드
################################################################################

load_cis_checks() {
    local checks_dir="$(dirname "${BASH_SOURCE[0]}")/checks"
    for section_file in "$checks_dir"/section*.sh; do
        [ -f "$section_file" ] && source "$section_file"
    done
}
