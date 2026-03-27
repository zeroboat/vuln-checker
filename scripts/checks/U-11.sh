#!/bin/bash
################################################################################
# U-11: 사용자 Shell 점검
################################################################################
check_U_11() {
    print_security_check "U-11" "사용자 Shell 점검" 1

    local fail_list=""
    while IFS=: read -r user _ uid _ _ _ shell; do
        # UID < 1000 인 시스템 계정 (root 제외)
        if [ "$uid" -lt 1000 ] && [ "$user" != "root" ] 2>/dev/null; then
            local nologin
            nologin=$(is_nologin_shell "$shell")
            if [ "$nologin" = "false" ]; then
                fail_list="${fail_list} ${user}(${shell})"
            fi
        fi
    done < /etc/passwd

    if [ -n "$fail_list" ]; then
        append_log "  로그인 가능한 시스템 계정:${fail_list}"
        record_check_result "U-11" "FAIL" "로그인 가능한 쉘을 가진 시스템 계정 존재:${fail_list}"
    else
        record_check_result "U-11" "PASS" "모든 시스템 계정이 nologin 쉘 사용"
    fi
}
