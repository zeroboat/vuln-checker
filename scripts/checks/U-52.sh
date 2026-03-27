#!/bin/bash
################################################################################
# U-52: Telnet 서비스 비활성화
################################################################################
check_U_52() {
    print_security_check "U-52" "Telnet 서비스 비활성화" 1

    local telnet_running=false

    if command_exists systemctl; then
        for svc in telnet telnetd telnet.socket; do
            local status
            status=$(systemctl is-enabled "$svc" 2>/dev/null)
            if [ "$status" = "enabled" ]; then
                append_log "  ⚠️  Telnet 서비스 활성화됨: $svc"
                telnet_running=true
            fi
        done
    fi

    # inetd 설정 확인
    for f in /etc/inetd.conf /etc/xinetd.d/telnet; do
        if [ -f "$f" ]; then
            if grep -qE "^telnet" "$f" 2>/dev/null; then
                append_log "  ⚠️  $f 에서 telnet 활성화됨"
                telnet_running=true
            fi
        fi
    done

    # 23번 포트 listening 확인
    if command_exists ss; then
        if ss -tlnp 2>/dev/null | grep -q ":23 "; then
            append_log "  ⚠️  23번 포트(telnet)가 열려 있음"
            telnet_running=true
        fi
    fi

    if $telnet_running; then
        record_check_result "U-52" "FAIL" "Telnet 서비스가 활성화되어 있음"
    else
        record_check_result "U-52" "PASS" "Telnet 서비스 비활성화됨"
    fi
}
