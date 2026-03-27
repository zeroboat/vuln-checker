#!/bin/bash
################################################################################
# U-49: DNS 보안 버전 패치
################################################################################
check_U_49() {
    print_security_check "U-49" "DNS 보안 버전 패치" 1

    if ! command_exists named && ! command_exists bind; then
        record_check_result "U-49" "PASS" "DNS(BIND) 서비스 미설치"
        return
    fi

    local version=""
    if command_exists named; then
        version=$(named -v 2>/dev/null | head -1)
        append_log "  BIND 버전: ${version:-확인 불가}"
    fi

    # version.bind 노출 여부 확인
    if command_exists dig; then
        local exposed_ver
        exposed_ver=$(dig @localhost version.bind CHAOS TXT 2>/dev/null | grep "version.bind" | grep -v "^;")
        if [ -n "$exposed_ver" ]; then
            append_log "  ⚠️  DNS 버전 정보 노출: $exposed_ver"
        fi
    fi

    record_check_result "U-49" "REVIEW" "DNS 버전을 최신 보안 패치 버전과 비교 필요: ${version:-알 수 없음}"
}
