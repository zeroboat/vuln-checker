#!/bin/bash
# 섹션 3: 데몬 설정 파일 권한 (D-26 ~ D-37)

_check_file_owner() {
    local code="$1"
    local filepath="$2"
    local expected_owner="${3:-root}"
    local expected_group="${4:-root}"

    if [ ! -e "$filepath" ]; then
        docker_record_result "$code" "REVIEW" "파일 없음: ${filepath}"
        return
    fi
    local owner group
    owner=$(stat -c '%U' "$filepath" 2>/dev/null || stat -f '%Su' "$filepath" 2>/dev/null)
    group=$(stat -c '%G' "$filepath" 2>/dev/null || stat -f '%Sg' "$filepath" 2>/dev/null)
    if [ "$owner" = "$expected_owner" ] && [ "$group" = "$expected_group" ]; then
        docker_record_result "$code" "PASS" "${filepath}: 소유자=${owner}:${group}"
    else
        docker_record_result "$code" "FAIL" "${filepath}: 소유자=${owner}:${group} (기대: ${expected_owner}:${expected_group})"
    fi
}

_check_file_perm() {
    local code="$1"
    local filepath="$2"
    local max_perm="$3"

    if [ ! -e "$filepath" ]; then
        docker_record_result "$code" "REVIEW" "파일 없음: ${filepath}"
        return
    fi
    local perm
    perm=$(stat -c '%a' "$filepath" 2>/dev/null || stat -f '%Lp' "$filepath" 2>/dev/null)
    perm=$(echo "$perm" | tr -d '[:space:]' | sed 's/^0*//')
    [ -z "$perm" ] && perm="0"
    local cur_dec max_dec
    cur_dec=$(printf '%d' "0${perm}" 2>/dev/null) || cur_dec=9999
    max_dec=$(printf '%d' "0${max_perm}" 2>/dev/null) || max_dec=0
    if [ "$cur_dec" -le "$max_dec" ] 2>/dev/null; then
        docker_record_result "$code" "PASS" "${filepath}: 권한=${perm} (최대 ${max_perm})"
    else
        docker_record_result "$code" "FAIL" "${filepath}: 권한=${perm} — ${max_perm} 이하로 설정 필요"
    fi
}

check_D_26() {
    docker_print_check "D-26"
    local f
    for f in /lib/systemd/system/docker.service /usr/lib/systemd/system/docker.service; do
        [ -f "$f" ] && { _check_file_owner "D-26" "$f"; return; }
    done
    docker_record_result "D-26" "REVIEW" "docker.service 파일 없음 (systemd 미사용 환경)"
}

check_D_27() {
    docker_print_check "D-27"
    local f
    for f in /lib/systemd/system/docker.service /usr/lib/systemd/system/docker.service; do
        [ -f "$f" ] && { _check_file_perm "D-27" "$f" "644"; return; }
    done
    docker_record_result "D-27" "REVIEW" "docker.service 파일 없음"
}

check_D_28() {
    docker_print_check "D-28"
    local f
    for f in /lib/systemd/system/docker.socket /usr/lib/systemd/system/docker.socket; do
        [ -f "$f" ] && { _check_file_owner "D-28" "$f"; return; }
    done
    docker_record_result "D-28" "REVIEW" "docker.socket 파일 없음"
}

check_D_29() {
    docker_print_check "D-29"
    local f
    for f in /lib/systemd/system/docker.socket /usr/lib/systemd/system/docker.socket; do
        [ -f "$f" ] && { _check_file_perm "D-29" "$f" "644"; return; }
    done
    docker_record_result "D-29" "REVIEW" "docker.socket 파일 없음"
}

check_D_30() {
    docker_print_check "D-30"
    if [ -d /etc/docker ]; then
        _check_file_owner "D-30" "/etc/docker"
    else
        docker_record_result "D-30" "REVIEW" "/etc/docker 디렉토리 없음"
    fi
}

check_D_31() {
    docker_print_check "D-31"
    if [ -d /etc/docker ]; then
        _check_file_perm "D-31" "/etc/docker" "755"
    else
        docker_record_result "D-31" "REVIEW" "/etc/docker 디렉토리 없음"
    fi
}

check_D_32() {
    docker_print_check "D-32"
    local ca_cert
    ca_cert=$(ps aux 2>/dev/null | grep dockerd | grep -v grep | grep -o 'tlscacert[= ]*[^ ]*' | sed 's/tlscacert[= ]*//' | head -1)
    if [ -z "$ca_cert" ]; then
        docker_record_result "D-32" "PASS" "TLS 미사용 — CA 인증서 불필요"
        return
    fi
    _check_file_owner "D-32" "$ca_cert"
}

check_D_33() {
    docker_print_check "D-33"
    local ca_cert
    ca_cert=$(ps aux 2>/dev/null | grep dockerd | grep -v grep | grep -o 'tlscacert[= ]*[^ ]*' | sed 's/tlscacert[= ]*//' | head -1)
    if [ -z "$ca_cert" ]; then
        docker_record_result "D-33" "PASS" "TLS 미사용 — CA 인증서 불필요"
        return
    fi
    _check_file_perm "D-33" "$ca_cert" "444"
}

check_D_34() {
    docker_print_check "D-34"
    local cert
    cert=$(ps aux 2>/dev/null | grep dockerd | grep -v grep | grep -o 'tlscert[= ]*[^ ]*' | sed 's/tlscert[= ]*//' | head -1)
    if [ -z "$cert" ]; then
        docker_record_result "D-34" "PASS" "TLS 미사용 — 서버 인증서 불필요"
        return
    fi
    _check_file_owner "D-34" "$cert"
}

check_D_35() {
    docker_print_check "D-35"
    local cert
    cert=$(ps aux 2>/dev/null | grep dockerd | grep -v grep | grep -o 'tlscert[= ]*[^ ]*' | sed 's/tlscert[= ]*//' | head -1)
    if [ -z "$cert" ]; then
        docker_record_result "D-35" "PASS" "TLS 미사용 — 서버 인증서 불필요"
        return
    fi
    _check_file_perm "D-35" "$cert" "444"
}

check_D_36() {
    docker_print_check "D-36"
    local key
    key=$(ps aux 2>/dev/null | grep dockerd | grep -v grep | grep -o 'tlskey[= ]*[^ ]*' | sed 's/tlskey[= ]*//' | head -1)
    if [ -z "$key" ]; then
        docker_record_result "D-36" "PASS" "TLS 미사용 — 서버 키 불필요"
        return
    fi
    _check_file_owner "D-36" "$key"
}

check_D_37() {
    docker_print_check "D-37"
    local key
    key=$(ps aux 2>/dev/null | grep dockerd | grep -v grep | grep -o 'tlskey[= ]*[^ ]*' | sed 's/tlskey[= ]*//' | head -1)
    if [ -z "$key" ]; then
        docker_record_result "D-37" "PASS" "TLS 미사용 — 서버 키 불필요"
        return
    fi
    _check_file_perm "D-37" "$key" "400"
}
