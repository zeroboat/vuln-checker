#!/bin/bash

################################################################################
# Arch Linux-specific Checks
################################################################################

check_arch() {
    append_log ""
    append_log "=== Arch Linux 보안 검사 시작 ==="

    if command_exists pacman; then
        append_log "패키지 매니저: Pacman"
        local upgradable
        upgradable=$(pacman -Qu 2>/dev/null | wc -l)
        append_log "업데이트 가능한 패키지: ${upgradable}개"
    fi

    run_all_checks

    log "INFO" "Arch Linux 검사 완료"
}
