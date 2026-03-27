#!/bin/bash
################################################################################
# U-47: 스팸 메일 릴레이 제한
################################################################################
check_U_47() {
    print_security_check "U-47" "스팸 메일 릴레이 제한" 1

    local fail=false

    # postfix relay 설정 확인
    if command_exists postconf; then
        local relay_domains
        relay_domains=$(postconf relay_domains 2>/dev/null)
        local mynetworks
        mynetworks=$(postconf mynetworks 2>/dev/null)
        append_log "  postfix relay_domains: ${relay_domains}"
        append_log "  postfix mynetworks: ${mynetworks}"

        local smtpd_relay
        smtpd_relay=$(postconf smtpd_relay_restrictions 2>/dev/null)
        if echo "$smtpd_relay" | grep -q "permit_all\|permit$"; then
            append_log "  ⚠️  모든 릴레이가 허용될 수 있음"
            fail=true
        fi
    fi

    # sendmail access 파일 확인
    if [ -f /etc/mail/access ]; then
        local open_relay
        open_relay=$(grep -v "^#" /etc/mail/access 2>/dev/null | grep "RELAY" | head -5)
        if [ -n "$open_relay" ]; then
            append_log "  sendmail RELAY 설정:"
            echo "$open_relay" | while read -r line; do
                append_log "    $line"
            done
        fi
    fi

    if $fail; then
        record_check_result "U-47" "FAIL" "메일 릴레이 제한 설정 미흡"
    else
        record_check_result "U-47" "PASS" "메일 릴레이 제한 설정 양호"
    fi
}
