#!/bin/bash
################################################################################
# U-59: 안전한 SNMP 버전 사용
################################################################################
check_U_59() {
    print_security_check "U-59" "안전한 SNMP 버전 사용" 1

    local snmp_conf=""
    for f in /etc/snmp/snmpd.conf /etc/snmpd.conf; do
        [ -f "$f" ] && snmp_conf="$f" && break
    done

    if [ -z "$snmp_conf" ]; then
        record_check_result "U-59" "PASS" "SNMP 설정 파일 없음 (서비스 미사용)"
        return
    fi

    append_log "  SNMP 설정 파일: $snmp_conf"

    # SNMPv1, v2c community string 확인
    local v1v2_community
    v1v2_community=$(grep -E "^(rocommunity|rwcommunity|com2sec)" "$snmp_conf" 2>/dev/null | grep -v "^#")

    # SNMPv3 사용자 확인
    local v3_user
    v3_user=$(grep -E "^(rouser|rwuser|createUser)" "$snmp_conf" 2>/dev/null | grep -v "^#")

    if [ -n "$v1v2_community" ] && [ -z "$v3_user" ]; then
        append_log "  ⚠️  SNMPv1/v2c만 사용 중 (보안 취약)"
        record_check_result "U-59" "FAIL" "취약한 SNMP v1/v2c만 사용 중 (SNMPv3 권장)"
    elif [ -n "$v3_user" ]; then
        append_log "  SNMPv3 사용자 설정 발견"
        record_check_result "U-59" "PASS" "SNMPv3 사용 설정됨"
    else
        record_check_result "U-59" "REVIEW" "SNMP 버전 설정 확인 필요"
    fi
}
