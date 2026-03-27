#!/bin/bash
################################################################################
# U-50: DNS Zone Transfer 설정
################################################################################
check_U_50() {
    print_security_check "U-50" "DNS Zone Transfer 설정" 1

    if ! command_exists named && [ ! -f /etc/named.conf ] && [ ! -f /etc/bind/named.conf ]; then
        record_check_result "U-50" "PASS" "DNS 서비스 미설치"
        return
    fi

    local fail=false
    local named_conf=""
    for f in /etc/named.conf /etc/bind/named.conf; do
        [ -f "$f" ] && named_conf="$f" && break
    done

    if [ -n "$named_conf" ]; then
        # allow-transfer 설정 확인
        if grep -q "allow-transfer" "$named_conf" 2>/dev/null; then
            local transfer_cfg
            transfer_cfg=$(grep "allow-transfer" "$named_conf")
            append_log "  allow-transfer 설정: $transfer_cfg"
            if echo "$transfer_cfg" | grep -qE "any|0\.0\.0\.0"; then
                append_log "  ⚠️  Zone Transfer가 모든 호스트에 허용됨"
                fail=true
            fi
        else
            append_log "  ⚠️  allow-transfer 설정 없음 (기본값: 모두 허용 가능)"
            fail=true
        fi
    fi

    if $fail; then
        record_check_result "U-50" "FAIL" "DNS Zone Transfer 제한 설정 미흡"
    else
        record_check_result "U-50" "PASS" "DNS Zone Transfer 접근 제한 설정 양호"
    fi
}
