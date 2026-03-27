#!/bin/bash
################################################################################
# U-29: 로그인 셸 설정
################################################################################
check_U_29() {
    print_security_check "U-29" "로그인 셸 설정" 1

    # /etc/shells에 등록된 유효한 쉘 목록 확인
    if [ -f /etc/shells ]; then
        append_log "  유효한 쉘 목록 (/etc/shells):"
        grep -v "^#" /etc/shells | while read -r sh; do
            if [ -f "$sh" ]; then
                append_log "    $sh (존재)"
            else
                append_log "    $sh (파일 없음)"
            fi
        done
    fi

    # 유효하지 않은 쉘을 사용하는 일반 계정 확인
    local invalid_shell_users=""
    while IFS=: read -r user _ uid _ _ _ shell; do
        [ "$uid" -lt 1000 ] && continue 2>/dev/null
        if [ -n "$shell" ] && [ "$shell" != "/sbin/nologin" ] && [ "$shell" != "/usr/sbin/nologin" ] && [ "$shell" != "/bin/false" ]; then
            if [ ! -f "$shell" ]; then
                invalid_shell_users="${invalid_shell_users} ${user}(${shell})"
            fi
        fi
    done < /etc/passwd

    if [ -n "$invalid_shell_users" ]; then
        append_log "  유효하지 않은 쉘 사용 계정:${invalid_shell_users}"
        record_check_result "U-29" "FAIL" "유효하지 않은 쉘 사용 계정:${invalid_shell_users}"
    else
        record_check_result "U-29" "PASS" "모든 계정의 쉘 설정 유효함"
    fi
}
