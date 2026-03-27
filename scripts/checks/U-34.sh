#!/bin/bash
################################################################################
# U-34: Finger 서비스 비활성화
################################################################################
check_U_34() {
    print_security_check "U-34" "Finger 서비스 비활성화" 1

    local finger_running=false

    if command_exists systemctl; then
        local status
        status=$(systemctl is-enabled finger 2>/dev/null || systemctl is-enabled finger.socket 2>/dev/null)
        if [ "$status" = "enabled" ]; then
            finger_running=true
        fi
    fi

    # inetd/xinetd 설정 확인
    for f in /etc/inetd.conf /etc/xinetd.d/finger; do
        if [ -f "$f" ]; then
            if grep -q "^finger\|^[^#].*finger" "$f" 2>/dev/null; then
                finger_running=true
                append_log "  $f 에서 finger 서비스 활성화됨"
            fi
        fi
    done

    if command_exists finger; then
        append_log "  finger 명령어가 설치되어 있음"
    fi

    if $finger_running; then
        record_check_result "U-34" "FAIL" "finger 서비스가 활성화되어 있음"
    else
        record_check_result "U-34" "PASS" "finger 서비스 비활성화됨"
    fi
}
