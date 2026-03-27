#!/bin/bash
################################################################################
# U-61: SNMP Access Control 설정
################################################################################
check_U_61() {
    print_security_check "U-61" "SNMP Access Control 설정" 1

    local snmp_conf=""
    for f in /etc/snmp/snmpd.conf /etc/snmpd.conf; do
        [ -f "$f" ] && snmp_conf="$f" && break
    done

    if [ -z "$snmp_conf" ]; then
        record_check_result "U-61" "PASS" "SNMP 설정 파일 없음 (서비스 미사용)"
        return
    fi

    local fail=false

    # com2sec 또는 view/access 설정 확인
    local access_ctrl
    access_ctrl=$(grep -E "^(com2sec|view|access|rocommunity|rwcommunity)" "$snmp_conf" 2>/dev/null | grep -v "^#")

    if [ -n "$access_ctrl" ]; then
        # 모든 호스트 허용 여부 확인
        if echo "$access_ctrl" | grep -qE "default\s+public|0\.0\.0\.0/0|any"; then
            append_log "  ⚠️  SNMP가 모든 호스트에서 접근 허용됨"
            fail=true
        fi
        append_log "  SNMP 접근 제어 설정:"
        echo "$access_ctrl" | while read -r line; do
            append_log "    $line"
        done
    else
        append_log "  ⚠️  SNMP 접근 제어 설정 없음"
        fail=true
    fi

    if $fail; then
        record_check_result "U-61" "FAIL" "SNMP 접근 제어 설정 미흡"
    else
        record_check_result "U-61" "PASS" "SNMP 접근 제어 설정 양호"
    fi
}
