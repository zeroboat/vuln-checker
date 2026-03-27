#!/bin/bash
################################################################################
# U-27: $HOME/.rhosts, hosts.equiv 사용 금지
################################################################################
check_U_27() {
    print_security_check "U-27" "\$HOME/.rhosts, hosts.equiv 사용 금지" 1

    local fail=false

    # /etc/hosts.equiv 확인
    if [ -f /etc/hosts.equiv ]; then
        append_log "  /etc/hosts.equiv 파일이 존재함"
        fail=true
    fi

    # 각 사용자 홈의 .rhosts 확인
    while IFS=: read -r user _ _ _ _ home _; do
        [ -d "$home" ] || continue
        if [ -f "${home}/.rhosts" ]; then
            append_log "  ${home}/.rhosts 파일이 존재함"
            fail=true
        fi
    done < /etc/passwd

    if $fail; then
        record_check_result "U-27" "FAIL" ".rhosts 또는 hosts.equiv 파일이 존재함"
    else
        record_check_result "U-27" "PASS" ".rhosts 및 hosts.equiv 파일 없음"
    fi
}
