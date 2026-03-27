#!/bin/bash
################################################################################
# U-43: NIS, NIS+ 점검
################################################################################
check_U_43() {
    print_security_check "U-43" "NIS, NIS+ 점검" 1

    local fail=false

    if command_exists systemctl; then
        for svc in nis ypbind ypserv yppasswdd ypupdated; do
            local status
            status=$(systemctl is-enabled "$svc" 2>/dev/null)
            if [ "$status" = "enabled" ]; then
                append_log "  ⚠️  NIS 서비스 활성화됨: $svc"
                fail=true
            fi
        done
    fi

    # /etc/nsswitch.conf에서 nis 사용 확인 (netgroup만 있는 경우는 주의 수준으로만 처리)
    if [ -f /etc/nsswitch.conf ]; then
        local nis_lines
        nis_lines=$(grep -E "^(passwd|group|shadow|hosts|services|protocols).*nis" /etc/nsswitch.conf 2>/dev/null)
        if [ -n "$nis_lines" ]; then
            append_log "  ⚠️  /etc/nsswitch.conf에서 핵심 서비스에 NIS 사용 설정 발견:"
            echo "$nis_lines" | while read -r line; do
                append_log "    $line"
            done
            fail=true
        elif grep -q "nis\|yp" /etc/nsswitch.conf 2>/dev/null; then
            append_log "  참고: /etc/nsswitch.conf에 NIS 참조 존재 (netgroup 등 부가 서비스)"
        fi
    fi

    if $fail; then
        record_check_result "U-43" "FAIL" "NIS/NIS+ 서비스가 활성화됨"
    else
        record_check_result "U-43" "PASS" "NIS/NIS+ 서비스 비활성화됨"
    fi
}
