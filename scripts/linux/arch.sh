#!/bin/bash

################################################################################
# Arch Linux-specific Checks
################################################################################

check_arch() {
    append_log ""
    append_log "=== Arch Linux 보안 검사 시작 ==="
    
    # Pacman 패키지 매니저 확인
    if command_exists pacman; then
        append_log "패키지 매니저: Pacman"
        append_log "업데이트 가능한 패키지: $(pacman -Qu 2>/dev/null | wc -l)"
    fi
    
    # 계정관리 검사
    check_account_management_arch
    
    # 파일 권한 검사
    check_critical_files
    
    # 시스템 로그 확인
    check_system_logs
    check_last_login
    
    # 열린 포트 확인
    check_open_ports
    check_dangerous_ports
    
    # 서비스 검사 (모든 U-19~U-72 항목)
    check_running_services
    check_unnecessary_services
    
    # SSH 설정 확인
    check_ssh_config
    check_ssh_security
    
    # 방화벽 확인
    check_firewall_status
    
    log "INFO" "Arch Linux 검사 완료"
}

################################################################################
# 계정관리 검사 (Arch Linux)
################################################################################
check_account_management_arch() {
    append_log ""
    append_log "=== 계정 관리 점검 ==="
    
    # 1. 시스템 계정 확인
    append_log ""
    append_log "[1] 시스템 계정 (UID < 1000)"
    local system_accounts=$(get_system_accounts)
    append_log "$system_accounts"
    
    # 2. 일반 사용자 계정 확인
    append_log ""
    append_log "[2] 일반 사용자 계정 (UID >= 1000)"
    local user_accounts=$(get_user_accounts)
    append_log "$user_accounts"
    
    # 3. 기본 시스템 계정 상태 확인
    append_log ""
    append_log "[3] 기본 시스템 계정 상태"
    local system_users=("root" "bin" "sys" "sync" "games" "man" "lp" "mail" "news" "uucp" "proxy" "list" "irc" "gnats" "nobody" "sshd" "http" "dbus" "systemd-network" "systemd-resolve")
    
    for user in "${system_users[@]}"; do
        local uid=$(get_uid "$user")
        local shell=$(get_shell "$user")
        local lock_status=$(is_account_locked "$user")
        
        if [ -n "$uid" ]; then
            local nologin=$(is_nologin_shell "$shell")
            append_log "계정: $user | UID: $uid | 쉘: $shell | 로그인불가: $nologin | 잠금: $lock_status"
        fi
    done
    
    # 4. 패스워드 정책 확인
    append_log ""
    append_log "[4] 패스워드 정책"
    if [ -f /etc/login.defs ]; then
        append_log "PASS_MAX_DAYS: $(grep ^PASS_MAX_DAYS /etc/login.defs | awk '{print $2}')"
        append_log "PASS_MIN_DAYS: $(grep ^PASS_MIN_DAYS /etc/login.defs | awk '{print $2}')"
        append_log "PASS_WARN_AGE: $(grep ^PASS_WARN_AGE /etc/login.defs | awk '{print $2}')"
    fi
    
    # 5. sudo 권한 확인
    append_log ""
    append_log "[5] sudo 권한 사용자"
    if [ -f /etc/sudoers ]; then
        local sudo_users=$(grep -E "^[^#]*%?[a-zA-Z0-9_-]+.*ALL=" /etc/sudoers 2>/dev/null | grep -v "^#")
        if [ -n "$sudo_users" ]; then
            append_log "$sudo_users"
        else
            append_log "권한 설정 없음"
        fi
    fi
    
    # 6. 홈디렉토리 권한 확인
    append_log ""
    append_log "[6] 사용자 홈디렉토리 권한"
    for user in $(get_user_accounts); do
        local home=$(get_home "$user")
        if [ -d "$home" ]; then
            local perms=$(stat -c %a "$home" 2>/dev/null || stat -f %A "$home" 2>/dev/null)
            append_log "  $user: $home ($perms)"
        fi
    done
}

