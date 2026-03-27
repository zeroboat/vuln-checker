#!/bin/bash
################################################################################
# U-44: tftp, talk 서비스 비활성화
################################################################################
check_U_44() {
    print_security_check "U-44" "tftp, talk 서비스 비활성화" 1

    local fail=false
    local insecure_services=("tftp" "talk" "ntalk" "tftpd")

    for svc in "${insecure_services[@]}"; do
        if command_exists systemctl; then
            local status
            status=$(systemctl is-enabled "$svc" 2>/dev/null || systemctl is-enabled "${svc}.socket" 2>/dev/null)
            if [ "$status" = "enabled" ]; then
                append_log "  ⚠️  ${svc} 서비스 활성화됨"
                fail=true
            fi
        fi

        for f in /etc/inetd.conf /etc/xinetd.d/"$svc"; do
            if [ -f "$f" ]; then
                if grep -qE "^${svc}" "$f" 2>/dev/null; then
                    append_log "  ⚠️  $f 에서 ${svc} 활성화됨"
                    fail=true
                fi
            fi
        done
    done

    if $fail; then
        record_check_result "U-44" "FAIL" "tftp/talk 서비스가 활성화됨"
    else
        record_check_result "U-44" "PASS" "tftp/talk 서비스 비활성화됨"
    fi
}
