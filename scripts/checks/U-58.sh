#!/bin/bash
################################################################################
# U-58: 불필요한 SNMP 서비스 구동 점검
################################################################################
check_U_58() {
    print_security_check "U-58" "불필요한 SNMP 서비스 구동 점검" 1

    local snmp_running=false

    if command_exists systemctl; then
        local status
        status=$(systemctl is-active snmpd 2>/dev/null)
        if [ "$status" = "active" ]; then
            append_log "  ⚠️  SNMP 서비스가 실행 중"
            snmp_running=true
        fi
        local enabled
        enabled=$(systemctl is-enabled snmpd 2>/dev/null)
        if [ "$enabled" = "enabled" ]; then
            append_log "  ⚠️  SNMP 서비스가 활성화됨"
            snmp_running=true
        fi
    fi

    # 161/162 포트 확인
    if command_exists ss; then
        if ss -ulnp 2>/dev/null | grep -qE ":161 |:162 "; then
            append_log "  ⚠️  SNMP 포트(161/162)가 열려 있음"
            snmp_running=true
        fi
    fi

    if $snmp_running; then
        record_check_result "U-58" "FAIL" "SNMP 서비스가 실행 중이거나 활성화됨"
    else
        record_check_result "U-58" "PASS" "SNMP 서비스 비활성화됨"
    fi
}
