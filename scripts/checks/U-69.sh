#!/bin/bash
################################################################################
# U-69: 로그온 배너 설정
################################################################################
check_U_69() {
    print_security_check "U-69" "로그온 배너 설정" 1

    local fail=false

    # SSH 배너 설정 확인
    if [ -f /etc/ssh/sshd_config ]; then
        local ssh_banner
        ssh_banner=$(grep -v "^#" /etc/ssh/sshd_config | grep "^Banner" | awk '{print $2}' | tail -1)
        append_log "  SSH Banner 설정: ${ssh_banner:-미설정}"

        if [ -z "$ssh_banner" ] || [ "$ssh_banner" = "none" ]; then
            append_log "  ⚠️  SSH 배너 미설정"
            fail=true
        elif [ -f "$ssh_banner" ]; then
            local banner_content
            banner_content=$(cat "$ssh_banner" 2>/dev/null)
            append_log "  SSH 배너 내용: $(echo "$banner_content" | head -2)"
            # 버전 정보 노출 확인
            if echo "$banner_content" | grep -qiE "ubuntu|debian|centos|red hat|version [0-9]"; then
                append_log "  ⚠️  배너에 시스템 정보 노출"
                fail=true
            fi
        fi
    fi

    # 경고 메시지 포함 여부
    if [ -f /etc/motd ]; then
        local motd
        motd=$(cat /etc/motd 2>/dev/null | tr -d '[:space:]')
        if [ -z "$motd" ]; then
            append_log "  ⚠️  /etc/motd 비어있음"
        fi
    fi

    if $fail; then
        record_check_result "U-69" "FAIL" "로그온 배너 설정 미흡"
    else
        record_check_result "U-69" "PASS" "로그온 배너 설정 양호"
    fi
}
