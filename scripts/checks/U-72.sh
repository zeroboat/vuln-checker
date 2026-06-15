#!/bin/bash
################################################################################
# U-72: 보안 패치 적용
################################################################################
check_U_72() {
    print_security_check "U-72" "보안 패치 적용" 1

    local fail=false

    if command_exists apt; then
        # apt 패키지 목록 갱신 없이 확인 (캐시 사용)
        local upgradable
        upgradable=$(apt list --upgradable 2>/dev/null | grep -v "Listing" | wc -l)
        append_log "  업데이트 가능한 패키지: ${upgradable}개"

        local security_upgradable
        security_upgradable=$(apt list --upgradable 2>/dev/null | grep -c "security" 2>/dev/null)
        append_log "  보안 업데이트: ${security_upgradable}개"

        if [ "$security_upgradable" -gt 0 ] 2>/dev/null; then
            fail=true
        fi

    elif command_exists yum; then
        local security_updates
        security_updates=$(yum check-update --security -q 2>/dev/null | grep -c "^[a-zA-Z]")
        append_log "  대기 중인 yum 보안 업데이트: ${security_updates}개"
        [ "$security_updates" -gt 0 ] && fail=true

    elif command_exists dnf; then
        local security_updates
        security_updates=$(dnf check-update --security -q 2>/dev/null | grep -c "^[a-zA-Z]")
        append_log "  대기 중인 dnf 보안 업데이트: ${security_updates}개"
        [ "$security_updates" -gt 0 ] && fail=true

    elif command_exists apk; then
        local upgradable
        upgradable=$(apk list --upgradable 2>/dev/null | wc -l)
        append_log "  apk 업데이트 가능한 패키지: ${upgradable}개"
        [ "$upgradable" -gt 0 ] && fail=true
    fi

    # 마지막 업데이트 날짜 확인
    if [ -f /var/log/dpkg.log ]; then
        local last_update
        last_update=$(grep "install\|upgrade" /var/log/dpkg.log 2>/dev/null | tail -1 | awk '{print $1}')
        append_log "  마지막 패키지 업데이트: ${last_update:-알 수 없음}"
    fi

    if $fail; then
        record_check_result "U-72" "FAIL" "적용되지 않은 보안 패치가 있음"
    else
        record_check_result "U-72" "PASS" "보안 패치 최신 상태"
    fi
}
