#!/bin/bash
################################################################################
# U-38: DoS 공격에 취약한 서비스 비활성화
################################################################################
check_U_38() {
    print_security_check "U-38" "DoS 공격에 취약한 서비스 비활성화" 1

    local dos_services=("chargen" "daytime" "echo" "discard" "time")
    local fail=false

    for svc in "${dos_services[@]}"; do
        # inetd 설정 확인
        for f in /etc/inetd.conf /etc/xinetd.d/"$svc"; do
            if [ -f "$f" ]; then
                if grep -qE "^${svc}" "$f" 2>/dev/null; then
                    append_log "  ⚠️  $f 에서 ${svc} 서비스 활성화됨"
                    fail=true
                fi
            fi
        done

        # systemd 서비스 확인
        if command_exists systemctl; then
            local status
            status=$(systemctl is-enabled "${svc}" 2>/dev/null || systemctl is-enabled "${svc}.socket" 2>/dev/null)
            if [ "$status" = "enabled" ]; then
                append_log "  ⚠️  systemd에서 ${svc} 서비스 활성화됨"
                fail=true
            fi
        fi
    done

    if $fail; then
        record_check_result "U-38" "FAIL" "DoS 취약 서비스가 활성화되어 있음"
    else
        record_check_result "U-38" "PASS" "DoS 취약 서비스 비활성화됨"
    fi
}
