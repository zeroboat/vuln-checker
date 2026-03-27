#!/bin/bash
################################################################################
# U-51: DNS 서비스의 취약한 동적 업데이트 설정 금지
################################################################################
check_U_51() {
    print_security_check "U-51" "DNS 서비스의 취약한 동적 업데이트 설정 금지" 1

    if ! command_exists named && [ ! -f /etc/named.conf ] && [ ! -f /etc/bind/named.conf ]; then
        record_check_result "U-51" "PASS" "DNS 서비스 미설치"
        return
    fi

    local fail=false
    local named_conf=""
    for f in /etc/named.conf /etc/bind/named.conf; do
        [ -f "$f" ] && named_conf="$f" && break
    done

    if [ -n "$named_conf" ]; then
        if grep -q "allow-update" "$named_conf" 2>/dev/null; then
            local update_cfg
            update_cfg=$(grep "allow-update" "$named_conf")
            append_log "  allow-update 설정: $update_cfg"
            if echo "$update_cfg" | grep -qE "any|0\.0\.0\.0"; then
                append_log "  ⚠️  동적 업데이트가 모든 호스트에 허용됨"
                fail=true
            fi
        else
            append_log "  allow-update 미설정 (동적 업데이트 비활성화)"
        fi
    fi

    if $fail; then
        record_check_result "U-51" "FAIL" "DNS 동적 업데이트 제한 설정 미흡"
    else
        record_check_result "U-51" "PASS" "DNS 동적 업데이트 설정 양호"
    fi
}
