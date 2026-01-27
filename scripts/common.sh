#!/bin/bash

################################################################################
# Common Functions - 공통 함수들
################################################################################

# 보안 항목 코드 로드
source "$(dirname "${BASH_SOURCE[0]}")/security_codes.sh"

# 로그 파일 추가
append_log() {
    local message="$1"
    echo "${message}" >> "$RESULT_FILE"
}

# 명령어 실행 여부 확인
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 파일 존재 확인
file_exists() {
    [ -f "$1" ]
}

# 디렉토리 존재 확인
dir_exists() {
    [ -d "$1" ]
}

# 권한 확인
check_permission() {
    local file="$1"
    [ -r "$file" ] && echo "readable" || echo "not_readable"
}

################################################################################
# 계정 관리 관련 함수
################################################################################

# 모든 계정 목록 조회
get_all_users() {
    awk -F: '{print $1}' /etc/passwd
}

# 시스템 계정 확인 (UID < 1000)
get_system_accounts() {
    awk -F: '$3 < 1000 {print $1}' /etc/passwd
}

# 일반 사용자 계정 확인 (UID >= 1000)
get_user_accounts() {
    awk -F: '$3 >= 1000 {print $1}' /etc/passwd
}

# 특정 계정의 UID 조회
get_uid() {
    local username="$1"
    awk -F: -v user="$username" '$1 == user {print $3}' /etc/passwd
}

# 특정 계정의 GID 조회
get_gid() {
    local username="$1"
    awk -F: -v user="$username" '$1 == user {print $4}' /etc/passwd
}

# 특정 계정의 홈디렉토리 조회
get_home() {
    local username="$1"
    awk -F: -v user="$username" '$1 == user {print $6}' /etc/passwd
}

# 특정 계정의 쉘 조회
get_shell() {
    local username="$1"
    awk -F: -v user="$username" '$1 == user {print $7}' /etc/passwd
}

# 로그인 불가능한 쉘 확인 (nologin, false, shutdown 등)
is_nologin_shell() {
    local shell="$1"
    if [[ "$shell" == *"nologin"* ]] || [[ "$shell" == *"false"* ]] || [[ "$shell" == *"shutdown"* ]] || [[ "$shell" == *"halt"* ]]; then
        echo "true"
    else
        echo "false"
    fi
}

# 계정 잠금 여부 확인 (shadow 파일)
is_account_locked() {
    local username="$1"
    if [ ! -f /etc/shadow ]; then
        echo "unknown"
        return
    fi
    
    local passwd_field=$(awk -F: -v user="$username" '$1 == user {print $2}' /etc/shadow)
    if [[ "$passwd_field" == "!" ]] || [[ "$passwd_field" == "*" ]]; then
        echo "locked"
    elif [[ "$passwd_field" == "*LK*" ]] || [[ "$passwd_field" == "!!"* ]]; then
        echo "locked"
    else
        echo "unlocked"
    fi
}

# sudo 권한 있는 계정 확인
get_sudo_users() {
    if [ -f /etc/sudoers ]; then
        grep -E "^[^#]*%?[a-zA-Z0-9_-]+.*ALL=" /etc/sudoers 2>/dev/null | grep -v "^#"
    fi
}

# 패스워드 정책 확인 (login.defs)
get_password_policy() {
    if [ -f /etc/login.defs ]; then
        append_log ""
        append_log "패스워드 정책:"
        grep -E "^PASS_MAX_DAYS|^PASS_MIN_DAYS|^PASS_WARN_AGE|^PASS_MIN_LEN" /etc/login.defs
    fi
}

################################################################################
# 파일 권한 관련 함수
################################################################################

# 파일 권한 확인
check_file_permissions() {
    local file="$1"
    local recommended="$2"
    
    if [ ! -e "$file" ]; then
        append_log "파일 없음: $file"
        return 1
    fi
    
    local current=$(stat -c %a "$file" 2>/dev/null || stat -f %A "$file" 2>/dev/null)
    local result="OK"
    
    if [ "$current" != "$recommended" ]; then
        result="경고: 권한이 $recommended이어야 하는데 현재 $current"
    fi
    
    append_log "$file: $current ($result)"
}

# 주요 설정 파일 권한 검사
check_critical_files() {
    append_log ""
    append_log "=== [2] 파일 및 디렉토리 관리 점검 ==="
    
    append_log ""
    print_security_check "U-07" "/etc/passwd 파일 및 권한 설정"
    check_file_permissions "/etc/passwd" "644"
    
    append_log ""
    print_security_check "U-08" "/etc/shadow 파일 소유자 및 권한 설정"
    check_file_permissions "/etc/shadow" "640"
    
    append_log ""
    print_security_check "U-10" "/etc/group 파일 및 권한 설정"
    check_file_permissions "/etc/group" "644"
    
    append_log ""
    print_security_check "U-10" "/etc/gshadow 파일 및 권한 설정"
    check_file_permissions "/etc/gshadow" "640"
    
    append_log ""
    print_security_check "U-04" "패스워드 파일 보호"
    check_file_permissions "/etc/sudoers" "440"
    
    append_log ""
    print_security_check "U-11" "/etc/syslog.conf 파일 소유자 및 권한 설정"
    check_file_permissions "/etc/syslog.conf" "644"
    check_file_permissions "/etc/rsyslog.conf" "644"
    
    append_log ""
    print_security_check "U-17" "\$HOME/.rhosts 파일 설정"
    for user in $(get_user_accounts); do
        local home=$(get_home "$user")
        if [ -f "$home/.rhosts" ]; then
            append_log "  경고: $home/.rhosts 파일이 존재합니다"
        fi
    done
}

################################################################################
# 시스템 로그 관련 함수
################################################################################

# 주요 로그 파일 확인
check_system_logs() {
    append_log ""
    append_log "=== [3] 시스템 로그 확인 ==="
    
    print_security_check "U-57" "로그 파일 소유자 및 권한 설정"
    
    local log_files=("/var/log/auth.log" "/var/log/secure" "/var/log/syslog" "/var/log/messages")
    
    for log in "${log_files[@]}"; do
        if [ -f "$log" ]; then
            local size=$(stat -c%s "$log" 2>/dev/null || stat -f%z "$log" 2>/dev/null)
            local last_modified=$(stat -c%y "$log" 2>/dev/null || stat -f "%Sm" "$log" 2>/dev/null)
            append_log "  $log: ${size} bytes (마지막 수정: $last_modified)"
        fi
    done
}

# 최근 로그인 기록 확인
check_last_login() {
    append_log ""
    print_security_check "U-58" "로그 디렉토리의 준 관리"
    
    if command_exists last; then
        append_log "$(last -n 5)"
    fi
}

################################################################################
# 네트워크 포트 관련 함수
################################################################################

# 열린 포트 확인
check_open_ports() {
    append_log ""
    append_log "=== [4] 네트워크 포트 확인 ==="
    
    print_security_check "U-18" "접속 IP 필터 제정"
    
    if command_exists ss; then
        append_log "$(ss -tlnp 2>/dev/null | grep LISTEN || netstat -tlnp 2>/dev/null | grep LISTEN)"
    elif command_exists netstat; then
        append_log "$(netstat -tlnp 2>/dev/null | grep LISTEN)"
    fi
}

# 위험한 포트 확인
check_dangerous_ports() {
    append_log ""
    print_security_check "U-12" "/etc/services 파일 소유자 및 권한 설정"
    
    local dangerous_ports=("21" "23" "69" "111" "135" "139" "445" "512" "513" "514" "873")
    
    for port in "${dangerous_ports[@]}"; do
        if command_exists ss; then
            local result=$(ss -tlnp 2>/dev/null | grep ":$port ")
            if [ -n "$result" ]; then
                append_log "  ⚠️  경고: 위험한 포트 $port가 열려 있습니다"
            fi
        fi
    done
}

################################################################################
# 서비스/데몬 관련 함수
################################################################################

# 실행 중인 서비스 확인
check_running_services() {
    append_log ""
    append_log "=== [5] 서비스/데몬 확인 ==="
    
    if command_exists systemctl; then
        append_log "$(systemctl list-units --type=service --state=running --no-pager 2>/dev/null | grep -E "\.service")"
    fi
}

# 불필요한 서비스 확인
check_unnecessary_services() {
    append_log ""
    append_log "=== [3-1] 불필요한 서비스 비활성화 ==="
    
    local dangerous_services=(
        "finger:U-19:finger 서비스"
        "ftp:U-20:Anonymous FTP"
        "rsh:U-21:r 서비스"
        "rlogin:U-21:r 서비스"
        "rcp:U-21:r 서비스"
        "nis:U-28:NIS 서비스"
        "nfs:U-24:NFS 서비스"
        "tftp:U-29:tftp 서비스"
        "talk:U-29:talk 서비스"
        "telnet:U-29:telnet 서비스"
        "cups:U-70:프린트 서버"
        "avahi-daemon:U-26:automount/avahi"
    )
    
    if command_exists systemctl; then
        for service_info in "${dangerous_services[@]}"; do
            IFS=':' read -r service code name <<< "$service_info"
            local status=$(systemctl is-enabled "$service" 2>/dev/null)
            if [ "$status" = "enabled" ] || [ "$status" = "enabled-runtime" ]; then
                print_security_check "$code" "$name"
                append_log "    ⚠️  경고: $name이 활성화되어 있습니다"
            fi
        done
    fi
    
    # Sendmail 버전 확인
    if command_exists sendmail; then
        print_security_check "U-30" "Sendmail 버전 확인"
        append_log "    $(sendmail -v 2>&1 | head -1)"
    fi
    
    print_security_check "U-31" "스팸 메일 정지"
    print_security_check "U-32" "임시사용자의 Sendmail 설정 방지"
    
    # DNS 보안
    if command_exists named; then
        print_security_check "U-33" "DNS 보안 설정"
        print_security_check "U-34" "DNS Zone Transfer 설정"
        print_security_check "U-35" "DNS 버전 숨김"
    fi
    
    # NFS/RPC 보안
    print_security_check "U-27" "RPC 서비스 차단"
    print_security_check "U-25" "NFS 접근 통제"
    
    # Cron 보안
    print_security_check "U-22" "cron 파일 소유자 및 권한설정"
    if [ -f /etc/crontab ]; then
        append_log "    /etc/crontab 권한: $(stat -c %a /etc/crontab 2>/dev/null || stat -f %A /etc/crontab 2>/dev/null)"
    fi
    
    # SUID/SGID 확인
    print_security_check "U-13" "SUID, SGID, Sticky bit 설정"
    
    # World Writable 파일
    print_security_check "U-14" "world writable 파일 확인"
    
    # SSH 심화 보안
    print_security_check "U-60" "ssh 암호정책 적용"
    print_security_check "U-61" "sftp 서비스 사용"
    print_security_check "U-62" "sftp/shell 설정"
    
    # FTP 보안
    print_security_check "U-63" "FTPusers 파일 설정"
    
    # SNMP 보안
    if command_exists snmpd; then
        print_security_check "U-64" "SNMP 커뮤니티 공개 설정"
        print_security_check "U-65" "SNMP 서비스 자동 시작 설정"
        print_security_check "U-66" "SNMP 서비스 네트워크 라우팅 설정"
    fi
    
    # 웹 서버 보안
    if command_exists apache2 || command_exists httpd; then
        print_security_check "U-36" "웹서비스 프로세스 권한 제한"
        print_security_check "U-37" "웹서비스 디렉토리 접근 금지"
        print_security_check "U-38" "웹서비스 불필요한 기능 제거"
        print_security_check "U-39" "웹서비스 링크 다운로드 제한"
        print_security_check "U-40" "웹서비스 심볼릭 링크"
        print_security_check "U-41" "웹서비스 영역외 보안"
        print_security_check "U-71" "Apache 웹 서버 정보 설정"
    fi
    
    # 추가 파일 권한
    print_security_check "U-15" "/dev/null 파일의 파일 설정"
    print_security_check "U-16" "심볼릭 링크 및 Device 파일 설정"
    print_security_check "U-56" "UMASK 설정"
    print_security_check "U-59" "중거 파일 및 디렉토리 접근 설정"
    print_security_check "U-68" "로그 스트림 제정"
    print_security_check "U-69" "NFS 설정파일 제어"
    print_security_check "U-72" "정책 파일 시스템 발정 설정"
}

################################################################################
# SSH 설정 관련 함수
################################################################################

# SSH 설정 확인
check_ssh_config() {
    append_log ""
    append_log "=== [6] SSH 설정 점검 ==="
    
    if [ -f /etc/ssh/sshd_config ]; then
        print_security_check "U-01" "root 계정 원격 접속 제한"
        append_log "  PermitRootLogin: $(grep -w PermitRootLogin /etc/ssh/sshd_config | grep -v "^#")"
        
        print_security_check "U-02" "패스워드 복잡성 설정"
        append_log "  PasswordAuthentication: $(grep -w PasswordAuthentication /etc/ssh/sshd_config | grep -v "^#")"
        
        append_log "  PermitEmptyPasswords: $(grep -w PermitEmptyPasswords /etc/ssh/sshd_config | grep -v "^#")"
        append_log "  Protocol: $(grep -w Protocol /etc/ssh/sshd_config | grep -v "^#")"
        append_log "  Port: $(grep -w Port /etc/ssh/sshd_config | grep -v "^#")"
        append_log "  X11Forwarding: $(grep -w X11Forwarding /etc/ssh/sshd_config | grep -v "^#")"
    fi
}

# SSH 보안 권장사항 확인
check_ssh_security() {
    append_log ""
    append_log "=== SSH 보안 권장사항 ==="
    
    if [ -f /etc/ssh/sshd_config ]; then
        # PermitRootLogin 확인
        local permit_root=$(grep -w PermitRootLogin /etc/ssh/sshd_config | grep -v "^#" | awk '{print $2}')
        if [ "$permit_root" = "yes" ]; then
            append_log "⚠️  [U-01] 경고: PermitRootLogin이 yes로 설정되어 있습니다 (권장: no)"
        fi
        
        # PasswordAuthentication 확인
        local pass_auth=$(grep -w PasswordAuthentication /etc/ssh/sshd_config | grep -v "^#" | awk '{print $2}')
        if [ "$pass_auth" = "yes" ]; then
            append_log "⚠️  [U-02] 경고: PasswordAuthentication이 yes로 설정되어 있습니다 (권장: no, PubkeyAuthentication 사용)"
        fi
        
        # Protocol 확인
        local protocol=$(grep -w Protocol /etc/ssh/sshd_config | grep -v "^#" | awk '{print $2}')
        if [ "$protocol" = "1" ] || [[ "$protocol" == *"1"* ]]; then
            append_log "⚠️  [U-01] 심각: SSH Protocol 1이 활성화되어 있습니다 (반드시 비활성화해야 함)"
        fi
    fi
}

################################################################################
# 방화벽 관련 함수
################################################################################

# 방화벽 상태 확인
check_firewall_status() {
    append_log ""
    append_log "=== [7] 방화벽 설정 확인 ==="
    
    if command_exists ufw; then
        print_security_check "U-18" "접속 IP 필터 제정"
        append_log "  UFW: $(ufw status)"
    fi
    
    if command_exists firewall-cmd; then
        append_log "  Firewalld: $(firewall-cmd --state 2>/dev/null || echo '비활성화')"
    fi
    
    if command_exists iptables; then
        append_log "  iptables: $(iptables -L -n 2>/dev/null | head -5)"
    fi
}

