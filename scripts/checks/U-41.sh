#!/bin/bash
################################################################################
# U-41: 불필요한 automountd 제거
################################################################################
check_U_41() {
    print_security_check "U-41" "불필요한 automountd 제거" 1

    local autofs_running=false

    if command_exists systemctl; then
        for svc in autofs automount; do
            local status
            status=$(systemctl is-active "$svc" 2>/dev/null)
            if [ "$status" = "active" ]; then
                append_log "  ⚠️  automount 서비스 실행 중: $svc"
                autofs_running=true
            fi
            local enabled
            enabled=$(systemctl is-enabled "$svc" 2>/dev/null)
            if [ "$enabled" = "enabled" ]; then
                append_log "  ⚠️  automount 서비스 활성화됨: $svc"
                autofs_running=true
            fi
        done
    fi

    if $autofs_running; then
        record_check_result "U-41" "FAIL" "automountd 서비스가 실행 중이거나 활성화됨"
    else
        record_check_result "U-41" "PASS" "automountd 서비스 비활성화됨"
    fi
}
