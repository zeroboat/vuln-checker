#!/bin/bash

################################################################################
# Debian/Ubuntu-specific Checks
################################################################################

check_debian_ubuntu() {
    append_log ""
    append_log "=== Debian/Ubuntu 보안 검사 시작 ==="

    if command_exists apt; then
        append_log "패키지 매니저: APT"
        local upgradable
        upgradable=$(apt list --upgradable 2>/dev/null | grep -v "Listing" | wc -l)
        append_log "업데이트 가능한 패키지: ${upgradable}개"
    fi

    if [ -f /etc/apt/apt.conf.d/50unattended-upgrades ]; then
        append_log "자동 보안 업데이트: 활성화"
    else
        append_log "자동 보안 업데이트: 비활성화"
    fi

    if command_exists ufw; then
        append_log "UFW 방화벽: $(ufw status 2>/dev/null | head -1)"
    fi

    if command_exists apparmor_status; then
        append_log "AppArmor: $(apparmor_status 2>/dev/null | head -1)"
    fi

    run_all_checks

    log "INFO" "Debian/Ubuntu 검사 완료"
}
