#!/bin/bash
################################################################################
# U-64: 주기적 보안 패치 및 벤더 권고사항 적용
################################################################################
check_U_64() {
    print_security_check "U-64" "주기적 보안 패치 및 벤더 권고사항 적용" 1

    local fail=false

    if command_exists apt; then
        # Debian/Ubuntu: 보안 업데이트 확인
        local security_updates
        security_updates=$(apt list --upgradable 2>/dev/null | grep -c "security" 2>/dev/null)
        append_log "  대기 중인 보안 업데이트: ${security_updates}개"
        if [ "$security_updates" -gt 0 ] 2>/dev/null; then
            fail=true
        fi

        # unattended-upgrades 확인
        if [ -f /etc/apt/apt.conf.d/50unattended-upgrades ]; then
            append_log "  자동 보안 업데이트(unattended-upgrades): 설정됨"
        else
            append_log "  ⚠️  자동 보안 업데이트 미설정"
        fi
    elif command_exists yum || command_exists dnf; then
        local pkg_manager
        command_exists dnf && pkg_manager="dnf" || pkg_manager="yum"
        local security_updates
        security_updates=$($pkg_manager check-update --security 2>/dev/null | grep -c "^[a-zA-Z]")
        append_log "  대기 중인 보안 업데이트: ${security_updates}개"
        [ "$security_updates" -gt 0 ] 2>/dev/null && fail=true
    fi

    if $fail; then
        record_check_result "U-64" "FAIL" "적용되지 않은 보안 업데이트가 있음"
    else
        record_check_result "U-64" "PASS" "보안 패치 최신 상태"
    fi
}
