#!/bin/bash
################################################################################
# U-60: SNMP Community String 복잡성 설정
################################################################################
check_U_60() {
    print_security_check "U-60" "SNMP Community String 복잡성 설정" 1

    local snmp_conf=""
    for f in /etc/snmp/snmpd.conf /etc/snmpd.conf; do
        [ -f "$f" ] && snmp_conf="$f" && break
    done

    if [ -z "$snmp_conf" ]; then
        record_check_result "U-60" "PASS" "SNMP 설정 파일 없음 (서비스 미사용)"
        return
    fi

    local fail=false
    local weak_strings=("public" "private" "community" "test" "admin" "default")

    while IFS= read -r line; do
        [[ "$line" =~ ^# ]] && continue
        for weak in "${weak_strings[@]}"; do
            if echo "$line" | grep -qiE "(rocommunity|rwcommunity|com2sec)[[:space:]].*[[:space:]]${weak}([[:space:]]|$)"; then
                append_log "  ⚠️  취약한 Community String 사용: ${weak}"
                fail=true
            fi
        done
    done < "$snmp_conf"

    if $fail; then
        record_check_result "U-60" "FAIL" "취약한 SNMP Community String 사용 중 (public/private 등)"
    else
        record_check_result "U-60" "PASS" "SNMP Community String 복잡성 설정 양호"
    fi
}
