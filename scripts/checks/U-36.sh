#!/bin/bash
################################################################################
# U-36: r 계열 서비스 비활성화
################################################################################
check_U_36() {
    print_security_check "U-36" "r 계열 서비스 비활성화" 1

    local fail=false
    local r_services=("rsh" "rlogin" "rexec" "rcp")

    for svc in "${r_services[@]}"; do
        if command_exists systemctl; then
            local status
            status=$(systemctl is-enabled "${svc}" 2>/dev/null || systemctl is-enabled "${svc}.socket" 2>/dev/null)
            if [ "$status" = "enabled" ]; then
                append_log "  ${svc} 서비스가 활성화됨"
                fail=true
            fi
        fi
        # inetd 설정 확인
        if [ -f /etc/inetd.conf ]; then
            if grep -qE "^${svc}" /etc/inetd.conf 2>/dev/null; then
                append_log "  /etc/inetd.conf에서 ${svc} 활성화됨"
                fail=true
            fi
        fi
    done

    if $fail; then
        record_check_result "U-36" "FAIL" "r 계열 서비스가 활성화되어 있음"
    else
        record_check_result "U-36" "PASS" "r 계열 서비스 비활성화됨"
    fi
}
