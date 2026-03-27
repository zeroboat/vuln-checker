#!/bin/bash
################################################################################
# U-70: 원격 접속 보안 설정
################################################################################
check_U_70() {
    print_security_check "U-70" "원격 접속 보안 설정" 1

    local fail=false

    if [ ! -f /etc/ssh/sshd_config ]; then
        record_check_result "U-70" "REVIEW" "SSH 설정 파일 없음"
        return
    fi

    # Protocol 버전 확인 (SSHv2만 허용)
    local protocol
    protocol=$(grep -v "^#" /etc/ssh/sshd_config | grep "^Protocol" | awk '{print $2}' | tail -1)
    append_log "  SSH Protocol: ${protocol:-2(기본값)}"
    if [ -n "$protocol" ] && [ "$protocol" != "2" ]; then
        append_log "  ⚠️  SSHv1 사용 중 (Protocol ${protocol})"
        fail=true
    fi

    # MaxAuthTries 확인
    local max_tries
    max_tries=$(grep -v "^#" /etc/ssh/sshd_config | grep "^MaxAuthTries" | awk '{print $2}' | tail -1)
    append_log "  MaxAuthTries: ${max_tries:-6(기본값)}"
    if [ -z "$max_tries" ] || [ "$max_tries" -gt 5 ] 2>/dev/null; then
        append_log "  ⚠️  MaxAuthTries가 5보다 큼 (권장: 5 이하)"
        fail=true
    fi

    # ClientAliveInterval 확인
    local alive_interval
    alive_interval=$(grep -v "^#" /etc/ssh/sshd_config | grep "^ClientAliveInterval" | awk '{print $2}' | tail -1)
    append_log "  ClientAliveInterval: ${alive_interval:-0(미설정)}"
    if [ -z "$alive_interval" ] || [ "$alive_interval" -eq 0 ] 2>/dev/null; then
        append_log "  ⚠️  SSH 세션 타임아웃 미설정"
        fail=true
    fi

    # AllowUsers/AllowGroups 설정 확인
    local allow_users allow_groups
    allow_users=$(grep -v "^#" /etc/ssh/sshd_config | grep "^AllowUsers" | tail -1)
    allow_groups=$(grep -v "^#" /etc/ssh/sshd_config | grep "^AllowGroups" | tail -1)
    if [ -n "$allow_users" ]; then
        append_log "  AllowUsers: $allow_users"
    elif [ -n "$allow_groups" ]; then
        append_log "  AllowGroups: $allow_groups"
    else
        append_log "  ⚠️  AllowUsers/AllowGroups 미설정 (모든 사용자 접속 가능)"
    fi

    if $fail; then
        record_check_result "U-70" "FAIL" "원격 접속(SSH) 보안 설정 미흡"
    else
        record_check_result "U-70" "PASS" "원격 접속(SSH) 보안 설정 양호"
    fi
}
