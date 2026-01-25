#!/bin/bash

################################################################################
# macOS-specific Checks
################################################################################

run_macos_checks() {
    local macos_version="$1"
    
    log "INFO" "macOS 환경 검사 시작..."
    
    append_log ""
    append_log "=== macOS 검사 ==="
    append_log "OS 버전: ${macos_version}"
    append_log "빌드 번호: $(sw_vers -buildVersion)"
    append_log "시스템 아키텍처: $(uname -m)"
    
    # macOS 버전별 검사
    local major_version=$(echo "$macos_version" | cut -d'.' -f1)
    log "INFO" "macOS 주 버전: ${major_version}"
    
    case "$major_version" in
        14)
            log "INFO" "macOS Sonoma 검사..."
            append_log "macOS Sonoma 버전 검사"
            ;;
        13)
            log "INFO" "macOS Ventura 검사..."
            append_log "macOS Ventura 버전 검사"
            ;;
        12)
            log "INFO" "macOS Monterey 검사..."
            append_log "macOS Monterey 버전 검사"
            ;;
        *)
            log "WARNING" "지원하지 않는 macOS 버전: ${macos_version}"
            ;;
    esac
    
    # 계정관리 검사
    check_account_management_macos
    
    # 파일 권한 검사
    check_critical_files
    
    # 시스템 로그 확인
    check_system_logs
    
    # 열린 포트 확인
    check_open_ports
    
    # SSH 설정 확인
    check_ssh_config
    check_ssh_security
    
    log "INFO" "macOS 검사 완료"
    
    return 0
}

################################################################################
# 계정관리 검사 (macOS)
################################################################################
check_account_management_macos() {
    append_log ""
    append_log "=== 계정 관리 점검 ==="
    
    # 1. 시스템 계정 확인
    append_log ""
    append_log "[1] 시스템 계정 (UID < 500)"
    local system_accounts=$(awk -F: '$3 < 500 {print $1}' /etc/passwd)
    append_log "$system_accounts"
    
    # 2. 일반 사용자 계정 확인
    append_log ""
    append_log "[2] 일반 사용자 계정 (UID >= 500)"
    local user_accounts=$(awk -F: '$3 >= 500 {print $1}' /etc/passwd)
    append_log "$user_accounts"
    
    # 3. 기본 시스템 계정 상태 확인
    append_log ""
    append_log "[3] 기본 시스템 계정 상태"
    local system_users=("root" "daemon" "bin" "sys" "sync" "guest" "nobody" "sshd" "_www" "_cvs" "_svn" "_mysql")
    
    for user in "${system_users[@]}"; do
        local uid=$(dscl . -read "/Users/$user" UniqueID 2>/dev/null | awk '{print $2}')
        if [ -n "$uid" ]; then
            append_log "계정: $user | UID: $uid"
        fi
    done
    
    # 4. 패스워드 정책 확인
    append_log ""
    append_log "[4] 패스워드 정책"
    if command_exists pwpolicy; then
        append_log "$(pwpolicy getaccountpolicies 2>/dev/null | grep -E "passwordCannotBeSameAsLoginName|passwordMinimumLength|passwordMaximumLength")"
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
    for user in $(awk -F: '$3 >= 500 {print $1}' /etc/passwd); do
        local home=$(dscl . -read "/Users/$user" NFSHomeDirectory 2>/dev/null | awk '{print $2}')
        if [ -d "$home" ]; then
            local perms=$(stat -f %A "$home" 2>/dev/null || stat -c %a "$home" 2>/dev/null)
            append_log "  $user: $home ($perms)"
        fi
    done
}
