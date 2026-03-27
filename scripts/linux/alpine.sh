#!/bin/bash

################################################################################
# Alpine Linux-specific Checks
################################################################################

check_alpine() {
    append_log ""
    append_log "=== Alpine Linux 보안 검사 시작 ==="

    if command_exists apk; then
        append_log "패키지 매니저: APK"
        local upgradable
        upgradable=$(apk list --upgradable 2>/dev/null | wc -l)
        append_log "업데이트 가능한 패키지: ${upgradable}개"
    fi

    append_log "C 라이브러리: musl"

    run_all_checks

    log "INFO" "Alpine Linux 검사 완료"
}
