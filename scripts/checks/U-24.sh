#!/bin/bash
################################################################################
# U-24: 사용자, 시스템 환경변수 파일 소유자 및 권한 설정
################################################################################
check_U_24() {
    print_security_check "U-24" "사용자, 시스템 환경변수 파일 소유자 및 권한 설정" 1

    local fail=false
    local env_files=("/etc/profile" "/etc/bashrc" "/etc/bash.bashrc" "/etc/environment")

    for f in "${env_files[@]}"; do
        [ -f "$f" ] || continue
        local perm owner
        perm=$(stat -c %a "$f" 2>/dev/null || stat -f %Lp "$f" 2>/dev/null)
        owner=$(stat -c %U "$f" 2>/dev/null || stat -f %Su "$f" 2>/dev/null)
        perm=$(echo "$perm" | tr -d '[:space:]' | sed 's/^0*//')
        append_log "  $f: 권한=${perm}, 소유자=${owner}"
        # world-writable 확인
        if [ "$(printf '%d' "0${perm}")" -gt "$(printf '%d' 0644)" ] 2>/dev/null; then
            append_log "  $f 권한 과다"
            fail=true
        fi
    done

    # 사용자 홈 디렉토리 환경변수 파일 확인
    while IFS=: read -r user _ uid _ _ home _; do
        [ "$uid" -lt 1000 ] && continue 2>/dev/null
        for dotfile in .profile .bashrc .bash_profile .bash_login .kshrc; do
            local f="${home}/${dotfile}"
            [ -f "$f" ] || continue
            local perm
            perm=$(stat -c %a "$f" 2>/dev/null || stat -f %Lp "$f" 2>/dev/null)
            perm=$(echo "$perm" | tr -d '[:space:]' | sed 's/^0*//')
            if [ "$(printf '%d' "0${perm}")" -gt "$(printf '%d' 0644)" ] 2>/dev/null; then
                append_log "  ${f} 권한 과다: ${perm}"
                fail=true
            fi
        done
    done < /etc/passwd

    if $fail; then
        record_check_result "U-24" "FAIL" "환경변수 파일 권한 설정 미흡"
    else
        record_check_result "U-24" "PASS" "환경변수 파일 권한 설정 양호"
    fi
}
