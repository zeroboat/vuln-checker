#!/bin/bash
################################################################################
# U-68: NTP 서비스 보안 설정
################################################################################
check_U_68() {
    print_security_check "U-68" "NTP 서비스 보안 설정" 1

    local fail=false

    # ntpd 설정 확인
    if [ -f /etc/ntp.conf ]; then
        # restrict 설정 확인 (접근 제어)
        local restrict_default
        restrict_default=$(grep "^restrict default" /etc/ntp.conf 2>/dev/null | head -1)
        append_log "  ntpd restrict default: ${restrict_default:-미설정}"

        if [ -z "$restrict_default" ] || echo "$restrict_default" | grep -q "^restrict default$"; then
            append_log "  ⚠️  NTP 기본 접근 제한 미설정"
            fail=true
        fi

        # noquery, notrap 설정 확인
        if ! echo "$restrict_default" | grep -q "noquery\|notrap\|kod\|limited"; then
            append_log "  ⚠️  NTP 접근 제한 옵션 미흡 (noquery, notrap 권장)"
            fail=true
        fi
    fi

    # chrony 설정 확인
    for f in /etc/chrony.conf /etc/chrony/chrony.conf; do
        if [ -f "$f" ]; then
            local allow_line
            allow_line=$(grep "^allow\|^deny" "$f" 2>/dev/null)
            append_log "  chrony 접근 제어: ${allow_line:-미설정}"
            [ -z "$allow_line" ] && append_log "  chrony 접근 제어 미설정"
        fi
    done

    if $fail; then
        record_check_result "U-68" "FAIL" "NTP 서비스 보안 설정 미흡"
    else
        record_check_result "U-68" "PASS" "NTP 서비스 보안 설정 양호"
    fi
}
