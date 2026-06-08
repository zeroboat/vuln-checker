#!/bin/bash

################################################################################
# Docker 공통 함수 라이브러리 (CIS Docker Benchmark v1.6.0)
################################################################################

source "$(dirname "${BASH_SOURCE[0]}")/security_codes.sh"
source "$(dirname "${BASH_SOURCE[0]}")/security_details.sh"

################################################################################
# JSON 관련 변수 및 함수
################################################################################

DOCKER_JSON_CHECKS_TMP=""

init_docker_json() {
    DOCKER_JSON_CHECKS_TMP=$(mktemp /tmp/docker_json_XXXXXX 2>/dev/null || echo "/tmp/docker_json_$$")
    > "$DOCKER_JSON_CHECKS_TMP"
}

json_escape() {
    local str="$1"
    str="${str//\\/\\\\}"
    str="${str//\"/\\\"}"
    str="${str//$'\n'/\\n}"
    str="${str//$'\r'/}"
    str="${str//$'\t'/\\t}"
    echo -n "$str"
}

record_docker_json_check() {
    local code="$1"
    local status="$2"
    local detail="$3"
    local name=$(json_escape "${DOCKER_CODES[$code]}")
    local category=$(json_escape "$(get_docker_category "$code")")
    local esc_detail=$(json_escape "$detail")
    local purpose=$(json_escape "${DOCKER_DETAILS[${code}_PURPOSE]}")
    local check=$(json_escape "${DOCKER_DETAILS[${code}_CHECK]}")
    local good=$(json_escape "${DOCKER_DETAILS[${code}_GOOD]}")
    local bad=$(json_escape "${DOCKER_DETAILS[${code}_BAD]}")
    local action=$(json_escape "${DOCKER_DETAILS[${code}_ACTION]}")
    local threat=$(json_escape "${DOCKER_DETAILS[${code}_THREAT]}")

    cat >> "$DOCKER_JSON_CHECKS_TMP" <<JSONENTRY
{"code":"${code}","name":"${name}","category":"${category}","status":"${status}","detail":"${esc_detail}","reference":{"purpose":"${purpose}","check":"${check}","goodCriteria":"${good}","badCriteria":"${bad}","remediation":"${action}","threat":"${threat}"}},
JSONENTRY
}

generate_docker_json() {
    local json_file="$1"
    local exec_time="$2"
    local hostname="$3"
    local pass_count="$4"
    local fail_count="$5"
    local review_count="$6"
    local total_count="$7"

    local esc_hostname=$(json_escape "$hostname")
    local docker_version
    docker_version=$(docker version --format '{{.Server.Version}}' 2>/dev/null || echo "unknown")
    local esc_version=$(json_escape "$docker_version")

    local checks_json=""
    if [ -f "$DOCKER_JSON_CHECKS_TMP" ] && [ -s "$DOCKER_JSON_CHECKS_TMP" ]; then
        checks_json=$(sed '$ s/,$//' "$DOCKER_JSON_CHECKS_TMP")
    fi

    cat > "$json_file" <<JSONEOF
{
  "metadata": {
    "executionTime": "${exec_time}",
    "hostname": "${esc_hostname}",
    "os": "Docker",
    "distro": "Docker ${esc_version}",
    "architecture": "CIS Docker Benchmark v1.6.0"
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

    rm -f "$DOCKER_JSON_CHECKS_TMP" 2>/dev/null
}

################################################################################
# 로그 / 출력 함수
################################################################################

docker_append_log() {
    local message="$1"
    echo "${message}" >> "$DOCKER_RESULT_FILE"
}

docker_print_section() {
    local title="$1"
    docker_append_log ""
    docker_append_log "############################################################################"
    docker_append_log "## $title"
    docker_append_log "############################################################################"
    docker_append_log ""
}

docker_print_check() {
    local code="$1"
    local name="${DOCKER_CODES[$code]}"
    docker_append_log ""
    docker_append_log "────────────────────────────────────────"
    docker_append_log "[${code}] ${name}"
}

docker_record_result() {
    local code="$1"
    local status="$2"
    local detail="$3"

    docker_append_log ""
    case "$status" in
        PASS)   docker_append_log "  ✅ 점검 결과: 양호" ;;
        FAIL)   docker_append_log "  ❌ 점검 결과: 취약" ;;
        REVIEW) docker_append_log "  ⚠️  점검 결과: 확인필요" ;;
    esac

    if [ -n "$detail" ]; then
        docker_append_log "  상세: $detail"
    fi
    docker_append_log "────────────────────────────────────────"

    if [ -n "$DOCKER_JSON_CHECKS_TMP" ]; then
        record_docker_json_check "$code" "$status" "$detail"
    fi

    case "$status" in
        PASS)   DOCKER_PASS_COUNT=$((DOCKER_PASS_COUNT + 1)) ;;
        FAIL)   DOCKER_FAIL_COUNT=$((DOCKER_FAIL_COUNT + 1)) ;;
        REVIEW) DOCKER_REVIEW_COUNT=$((DOCKER_REVIEW_COUNT + 1)) ;;
    esac
}

################################################################################
# 유틸리티 함수
################################################################################

docker_command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# docker inspect 결과에서 필드 추출
docker_inspect_field() {
    local container="$1"
    local field="$2"
    docker inspect "$container" 2>/dev/null | grep -i "$field" | head -1
}

# 실행 중인 컨테이너 ID 목록
get_running_containers() {
    docker ps -q 2>/dev/null
}

# 모든 컨테이너 ID 목록
get_all_containers() {
    docker ps -aq 2>/dev/null
}

# daemon.json 경로
DOCKER_DAEMON_JSON="/etc/docker/daemon.json"

# daemon.json에서 키 값 읽기 (간단한 단일 값)
daemon_json_get() {
    local key="$1"
    if [ -f "$DOCKER_DAEMON_JSON" ]; then
        grep -o "\"${key}\"[[:space:]]*:[[:space:]]*[^,}]*" "$DOCKER_DAEMON_JSON" 2>/dev/null | \
            sed "s/\"${key}\"[[:space:]]*:[[:space:]]*//" | tr -d '"' | tr -d ' '
    fi
}

################################################################################
# 섹션별 점검 파일 로드
################################################################################

load_docker_checks() {
    local checks_dir="$(dirname "${BASH_SOURCE[0]}")/checks"
    for section_file in "$checks_dir"/section*.sh; do
        [ -f "$section_file" ] && source "$section_file"
    done
}
