#!/bin/bash
################################################################################
# U-66: 정책에 따른 시스템 로깅 설정
################################################################################
check_U_66() {
    print_security_check "U-66" "정책에 따른 시스템 로깅 설정" 1

    local fail=false
    local logging_active=false

    # rsyslog 확인
    if command_exists systemctl; then
        local rsyslog_status
        rsyslog_status=$(systemctl is-active rsyslog 2>/dev/null)
        append_log "  rsyslog 상태: ${rsyslog_status:-알 수 없음}"
        [ "$rsyslog_status" = "active" ] && logging_active=true
    fi

    # syslog 확인
    if command_exists systemctl; then
        local syslog_status
        syslog_status=$(systemctl is-active syslog 2>/dev/null)
        append_log "  syslog 상태: ${syslog_status:-알 수 없음}"
        [ "$syslog_status" = "active" ] && logging_active=true
    fi

    # journald 확인 (systemd)
    if command_exists journalctl; then
        local journal_status
        journal_status=$(systemctl is-active systemd-journald 2>/dev/null)
        append_log "  systemd-journald 상태: ${journal_status:-알 수 없음}"
        [ "$journal_status" = "active" ] && logging_active=true
    fi

    # /var/log 주요 로그 파일 확인
    local log_files=("/var/log/auth.log" "/var/log/secure" "/var/log/messages" "/var/log/syslog")
    local log_found=false
    for f in "${log_files[@]}"; do
        if [ -f "$f" ]; then
            append_log "  로그 파일 존재: $f"
            log_found=true
        fi
    done

    if ! $log_found; then
        append_log "  ⚠️  주요 로그 파일이 없음"
        fail=true
    fi

    if ! $logging_active; then
        append_log "  ⚠️  로깅 서비스가 활성화되지 않음"
        fail=true
    fi

    if $fail; then
        record_check_result "U-66" "FAIL" "시스템 로깅 설정 미흡"
    else
        record_check_result "U-66" "PASS" "시스템 로깅 설정 양호"
    fi
}
