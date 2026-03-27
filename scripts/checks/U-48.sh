#!/bin/bash
################################################################################
# U-48: expn, vrfy 명령어 제한
################################################################################
check_U_48() {
    print_security_check "U-48" "expn, vrfy 명령어 제한" 1

    local fail=false

    # postfix disable_vrfy_command 확인
    if command_exists postconf; then
        local vrfy
        vrfy=$(postconf disable_vrfy_command 2>/dev/null | awk '{print $3}')
        append_log "  postfix disable_vrfy_command: ${vrfy:-미설정}"
        if [ "$vrfy" != "yes" ]; then
            append_log "  ⚠️  VRFY 명령어가 비활성화되지 않음"
            fail=true
        fi
    fi

    # sendmail EXPN/VRFY 확인
    if [ -f /etc/mail/sendmail.cf ]; then
        if grep -q "^O PrivacyOptions" /etc/mail/sendmail.cf 2>/dev/null; then
            local privacy
            privacy=$(grep "^O PrivacyOptions" /etc/mail/sendmail.cf | head -1)
            append_log "  sendmail PrivacyOptions: $privacy"
            if ! echo "$privacy" | grep -qE "noexpn|novrfy|goaway"; then
                append_log "  ⚠️  EXPN/VRFY가 제한되지 않음"
                fail=true
            fi
        else
            fail=true
            append_log "  ⚠️  sendmail PrivacyOptions 미설정"
        fi
    fi

    if $fail; then
        record_check_result "U-48" "FAIL" "EXPN/VRFY 명령어 제한 설정 미흡"
    else
        record_check_result "U-48" "PASS" "EXPN/VRFY 명령어 제한 설정 양호"
    fi
}
