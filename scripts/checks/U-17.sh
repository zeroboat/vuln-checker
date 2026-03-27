#!/bin/bash
################################################################################
# U-17: 시스템 시작 스크립트 권한 설정
################################################################################
check_U_17() {
    print_security_check "U-17" "시스템 시작 스크립트 권한 설정" 1

    local fail=false
    local dirs=("/etc/init.d" "/etc/rc.d" "/etc/rc.local")

    for dir in "${dirs[@]}"; do
        if [ -d "$dir" ]; then
            # world-writable 스크립트 확인
            local ww_files
            ww_files=$(find "$dir" -perm -002 -type f 2>/dev/null)
            if [ -n "$ww_files" ]; then
                append_log "  world-writable 시작 스크립트: $ww_files"
                fail=true
            fi
            # root 소유 아닌 스크립트 확인
            local non_root
            non_root=$(find "$dir" -not -user root -type f 2>/dev/null)
            if [ -n "$non_root" ]; then
                append_log "  root 소유 아닌 시작 스크립트: $non_root"
                fail=true
            fi
        fi
    done

    if [ -f /etc/rc.local ]; then
        local perm
        perm=$(stat -c %a /etc/rc.local 2>/dev/null || stat -f %Lp /etc/rc.local 2>/dev/null)
        perm=$(echo "$perm" | tr -d '[:space:]' | sed 's/^0*//')
        append_log "  /etc/rc.local 권한: ${perm}"
        if [ "$(printf '%d' "0${perm}")" -gt "$(printf '%d' 0755)" ] 2>/dev/null; then
            fail=true
        fi
    fi

    if $fail; then
        record_check_result "U-17" "FAIL" "시스템 시작 스크립트 권한 설정 미흡"
    else
        record_check_result "U-17" "PASS" "시스템 시작 스크립트 권한 설정 양호"
    fi
}
