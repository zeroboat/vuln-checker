#!/bin/bash
################################################################################
# U-31: 홈디렉토리 소유자 및 권한 설정
################################################################################
check_U_31() {
    print_security_check "U-31" "홈디렉토리 소유자 및 권한 설정" 1

    local fail=false
    while IFS=: read -r user _ uid _ _ home _; do
        [ "$uid" -lt 1000 ] && continue 2>/dev/null
        [ -z "$home" ] || [ ! -d "$home" ] && continue
        local perm owner
        perm=$(stat -c %a "$home" 2>/dev/null || stat -f %Lp "$home" 2>/dev/null)
        owner=$(stat -c %U "$home" 2>/dev/null || stat -f %Su "$home" 2>/dev/null)
        perm=$(echo "$perm" | tr -d '[:space:]' | sed 's/^0*//')

        if [ "$owner" != "$user" ]; then
            append_log "  $home 소유자 불일치: ${owner} (기대: ${user})"
            fail=true
        fi
        if [ "$(printf '%d' "0${perm}")" -gt "$(printf '%d' 0750)" ] 2>/dev/null; then
            append_log "  $home 권한 과다: ${perm} (권장: 750 이하)"
            fail=true
        fi
    done < /etc/passwd

    if $fail; then
        record_check_result "U-31" "FAIL" "홈 디렉토리 소유자 또는 권한 설정 미흡"
    else
        record_check_result "U-31" "PASS" "홈 디렉토리 소유자 및 권한 설정 양호"
    fi
}
