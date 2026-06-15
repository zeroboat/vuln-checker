#!/bin/bash
# 섹션 4: 로깅 및 감사 (CL-27 ~ CL-31)

check_CL_27() {
    cis_print_check "CL-27"
    if cis_package_installed auditd || cis_command_exists auditctl; then
        if cis_service_active auditd; then
            cis_record_result "CL-27" "PASS" "auditd가 설치되고 활성화됨"
        else
            cis_record_result "CL-27" "FAIL" "auditd가 설치되었으나 비활성화 상태"
        fi
    else
        cis_record_result "CL-27" "FAIL" "auditd가 설치되어 있지 않음"
    fi
}

check_CL_28() {
    cis_print_check "CL-28"
    local active=""
    for svc in rsyslog syslog-ng systemd-journald; do
        if cis_service_active "$svc"; then
            active="${active}${svc} "
        fi
    done
    if [ -n "$active" ]; then
        cis_record_result "CL-28" "PASS" "시스템 로깅 데몬 동작 중: ${active}"
    else
        cis_record_result "CL-28" "FAIL" "시스템 로깅 데몬이 비활성화됨"
    fi
}

check_CL_29() {
    cis_print_check "CL-29"
    local logs=("/var/log/auth.log" "/var/log/secure" "/var/log/syslog" "/var/log/messages")
    local found="" bad=""
    for f in "${logs[@]}"; do
        [ -f "$f" ] || continue
        found="$f"
        local perm
        perm=$(cis_file_perm "$f")
        if cis_perm_le "$perm" "640"; then
            :
        else
            bad="${bad}${f}(${perm}) "
        fi
    done
    if [ -z "$found" ]; then
        cis_record_result "CL-29" "REVIEW" "점검 대상 로그 파일을 찾을 수 없음"
    elif [ -z "$bad" ]; then
        cis_record_result "CL-29" "PASS" "주요 로그 파일 권한이 640 이하"
    else
        cis_record_result "CL-29" "FAIL" "권한 초과 로그 파일: ${bad}"
    fi
}

check_CL_30() {
    cis_print_check "CL-30"
    local conf="/etc/audit/auditd.conf"
    if [ ! -f "$conf" ]; then
        cis_record_result "CL-30" "REVIEW" "auditd.conf가 없어 점검 불가 (auditd 미설치 가능성)"
        return
    fi
    local max_size action
    max_size=$(grep -iE "^\s*max_log_file\s*=" "$conf" 2>/dev/null | awk -F= '{gsub(/ /,"",$2);print $2}' | head -1)
    action=$(grep -iE "^\s*max_log_file_action\s*=" "$conf" 2>/dev/null | awk -F= '{gsub(/ /,"",$2);print $2}' | head -1)
    if [ -n "$max_size" ] && [ -n "$action" ]; then
        cis_record_result "CL-30" "PASS" "audit 로그 정책 설정됨 (max_log_file=${max_size}, action=${action})"
    else
        cis_record_result "CL-30" "FAIL" "audit 로그 저장 정책 미흡 (max_log_file=${max_size:-미설정}, action=${action:-미설정})"
    fi
}

check_CL_31() {
    cis_print_check "CL-31"
    if cis_command_exists logrotate && { [ -f /etc/logrotate.conf ] || [ -d /etc/logrotate.d ]; }; then
        cis_record_result "CL-31" "PASS" "logrotate가 설치되고 설정 파일이 존재함"
    else
        cis_record_result "CL-31" "FAIL" "logrotate가 설치되어 있지 않거나 설정이 없음"
    fi
}
