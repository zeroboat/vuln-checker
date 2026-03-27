#!/bin/bash

################################################################################
# Common Functions - 공통 함수들
################################################################################

# 보안 항목 코드 로드
source "$(dirname "${BASH_SOURCE[0]}")/security_codes.sh"
source "$(dirname "${BASH_SOURCE[0]}")/security_details.sh"

# 보안 검사 항목 출력 (코드 + 이름 + 상세정보 + 구분선)
print_security_check() {
    local code="$1"
    local name="${SECURITY_CODES[$code]}"
    local show_detail="${3:-0}"  # 3번째 인자로 상세정보 표시 여부 결정
    
    if [ -z "$name" ]; then
        name="$2"  # 명시적으로 전달된 이름 사용
    fi
    
    append_log ""
    append_log "────────────────────────────────────────"
    append_log "[${code}] ${name}"
    
    # 상세정보 표시 옵션이 활성화된 경우
    if [ "$show_detail" = "1" ]; then
        print_security_detail "$code"
    fi
}

# 점검 결과 기록 함수 (양호/취약/확인필요)
record_check_result() {
    local code="$1"
    local status="$2"  # PASS(양호), FAIL(취약), REVIEW(확인필요)
    local detail="$3"  # 상세 결과
    
    append_log ""
    case "$status" in
        PASS)
            append_log "  ✅ 점검 결과: 양호"
            ;;
        FAIL)
            append_log "  ❌ 점검 결과: 취약"
            ;;
        REVIEW)
            append_log "  ⚠️  점검 결과: 확인필요"
            ;;
    esac
    
    if [ -n "$detail" ]; then
        append_log "  상세: $detail"
    fi
    
    append_log "────────────────────────────────────────"
}

# 로그 파일 추가
append_log() {
    local message="$1"
    echo "${message}" >> "$RESULT_FILE"
}

# 섹션 헤더 출력 함수
print_section_header() {
    local section_name="$1"
    append_log ""
    append_log "############################################################################"
    append_log "## $section_name"
    append_log "############################################################################"
    append_log ""
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
    local max_perm="$2"
    local code="$3"
    local expected_owner="${4:-root}"

    if [ ! -e "$file" ]; then
        if [ -n "$code" ]; then
            record_check_result "$code" "REVIEW" "파일이 존재하지 않음: $file"
        fi
        return 1
    fi

    local current_perm current_owner
    current_perm=$(stat -c %a "$file" 2>/dev/null || stat -f %Lp "$file" 2>/dev/null)
    current_owner=$(stat -c %U "$file" 2>/dev/null || stat -f %Su "$file" 2>/dev/null)
    current_perm=$(echo "$current_perm" | tr -d '[:space:]' | sed 's/^0*//')
    [ -z "$current_perm" ] && current_perm="0"

    local status="PASS"
    local issues=""

    if [ -n "$current_perm" ] && [ -n "$max_perm" ]; then
        local cur_dec max_dec
        cur_dec=$(printf "%d" "0${current_perm}" 2>/dev/null) || cur_dec=9999
        max_dec=$(printf "%d" "0${max_perm}" 2>/dev/null) || max_dec=0
        if [ "$cur_dec" -gt "$max_dec" ] 2>/dev/null; then
            status="FAIL"
            issues="${issues}권한 초과(현재:${current_perm}, 최대:${max_perm}) "
        fi
    fi

    if [ -n "$expected_owner" ] && [ "$current_owner" != "$expected_owner" ]; then
        status="FAIL"
        issues="${issues}소유자 불일치(현재:${current_owner}, 기대:${expected_owner}) "
    fi

    local detail="$file: 권한=${current_perm}(최대 ${max_perm}), 소유자=${current_owner}"
    if [ -n "$code" ]; then
        if [ "$status" = "PASS" ]; then
            record_check_result "$code" "PASS" "$detail"
        else
            record_check_result "$code" "FAIL" "${issues}| $detail"
        fi
    fi
}

# 주요 설정 파일 권한 검사
check_critical_files() {
    append_log ""
    append_log "========================================"
    append_log "[2] 파일 및 디렉토리 관리 점검"
    append_log "========================================"
    
    append_log ""
    print_security_check "U-07" "/etc/passwd 파일 및 권한 설정" 1
    check_file_permissions "/etc/passwd" "644" "U-07"
    
    append_log ""
    print_security_check "U-08" "/etc/shadow 파일 소유자 및 권한 설정" 1
    check_file_permissions "/etc/shadow" "640" "U-08"
    
    append_log ""
    print_security_check "U-10" "/etc/group 파일 및 권한 설정" 1
    check_file_permissions "/etc/group" "644" "U-10"
    
    append_log ""
    print_security_check "U-10" "/etc/gshadow 파일 및 권한 설정" 1
    check_file_permissions "/etc/gshadow" "640" "U-10"
    
    append_log ""
    print_security_check "U-04" "패스워드 파일 보호" 1
    check_file_permissions "/etc/sudoers" "440" "U-04"
    
    append_log ""
    print_security_check "U-11" "/etc/syslog.conf 파일 소유자 및 권한 설정" 1
    check_file_permissions "/etc/syslog.conf" "644" "U-11"
    check_file_permissions "/etc/rsyslog.conf" "644" "U-11"
    
    append_log ""
    print_security_check "U-17" "\$HOME/.rhosts 파일 설정" 1
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
    append_log "========================================"
    append_log "[3] 시스템 로그 확인"
    append_log "========================================"
    
    print_security_check "U-57" "로그 파일 소유자 및 권한 설정" 1
    
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
    print_security_check "U-58" "로그 디렉토리의 준 관리" 1
    
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
    append_log "========================================"
    append_log "[4] 네트워크 포트 확인"
    append_log "========================================"
    
    print_security_check "U-18" "접속 IP 필터 제정" 1
    
    if command_exists ss; then
        append_log "$(ss -tlnp 2>/dev/null | grep LISTEN || netstat -tlnp 2>/dev/null | grep LISTEN)"
    elif command_exists netstat; then
        append_log "$(netstat -tlnp 2>/dev/null | grep LISTEN)"
    fi
}

# 위험한 포트 확인
check_dangerous_ports() {
    append_log ""
    print_security_check "U-12" "/etc/services 파일 소유자 및 권한 설정" 1
    
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
    append_log "========================================"
    append_log "[5] 서비스/데몬 확인"
    append_log "========================================"
    
    if command_exists systemctl; then
        append_log "$(systemctl list-units --type=service --state=running --no-pager 2>/dev/null | grep -E "\.service")"
    fi
}

# 불필요한 서비스 확인
check_unnecessary_services() {
    append_log ""
    append_log "========================================"
    append_log "[3-1] 불필요한 서비스 비활성화"
    append_log "========================================"
    
    local dangerous_services=(
        "finger:U-34:finger 서비스"
        "vsftpd:U-35:Anonymous FTP"
        "rsh:U-36:r 계열 서비스"
        "rlogin:U-36:r 계열 서비스"
        "rexec:U-36:r 계열 서비스"
        "nis:U-43:NIS 서비스"
        "nfs-server:U-39:NFS 서비스"
        "tftp:U-44:tftp 서비스"
        "talk:U-44:talk 서비스"
        "telnet:U-52:telnet 서비스"
        "rpcbind:U-42:RPC 서비스"
        "autofs:U-41:automount 서비스"
    )
    
    if command_exists systemctl; then
        for service_info in "${dangerous_services[@]}"; do
            IFS=':' read -r service code name <<< "$service_info"
            local status=$(systemctl is-enabled "$service" 2>/dev/null)
            if [ "$status" = "enabled" ] || [ "$status" = "enabled-runtime" ]; then
                print_security_check "$code" "$name" 1
                append_log "    ⚠️  경고: $name이 활성화되어 있습니다"
            fi
        done
    fi
    
    # Sendmail 버전 확인
    if command_exists sendmail; then
        print_security_check "U-30" "Sendmail 버전 확인" 1
        append_log "    $(sendmail -v 2>&1 | head -1)"
    fi
    
    print_security_check "U-31" "스팸 메일 정지" 1
    print_security_check "U-32" "임시사용자의 Sendmail 설정 방지" 1
    
    # DNS 보안
    if command_exists named; then
        print_security_check "U-33" "DNS 보안 설정" 1
        print_security_check "U-34" "DNS Zone Transfer 설정" 1
        print_security_check "U-35" "DNS 버전 숨김" 1
    fi
    
    # NFS/RPC 보안
    print_security_check "U-27" "RPC 서비스 차단" 1
    print_security_check "U-25" "NFS 접근 통제" 1
    
    # Cron 보안
    print_security_check "U-22" "cron 파일 소유자 및 권한설정" 1
    if [ -f /etc/crontab ]; then
        append_log "    /etc/crontab 권한: $(stat -c %a /etc/crontab 2>/dev/null || stat -f %A /etc/crontab 2>/dev/null)"
    fi
    
    # SUID/SGID 확인
    print_security_check "U-13" "SUID, SGID, Sticky bit 설정" 1
    
    # World Writable 파일
    print_security_check "U-14" "world writable 파일 확인" 1
    
    # SSH 심화 보안
    print_security_check "U-60" "ssh 암호정책 적용" 1
    print_security_check "U-61" "sftp 서비스 사용" 1
    print_security_check "U-62" "sftp/shell 설정" 1
    
    # FTP 보안
    print_security_check "U-63" "FTPusers 파일 설정" 1
    
    # SNMP 보안
    if command_exists snmpd; then
        print_security_check "U-64" "SNMP 커뮤니티 공개 설정" 1
        print_security_check "U-65" "SNMP 서비스 자동 시작 설정" 1
        print_security_check "U-66" "SNMP 서비스 네트워크 라우팅 설정" 1
    fi
    
    # 웹 서버 보안
    if command_exists apache2 || command_exists httpd; then
        print_security_check "U-36" "웹서비스 프로세스 권한 제한" 1
        print_security_check "U-37" "웹서비스 디렉토리 접근 금지" 1
        print_security_check "U-38" "웹서비스 불필요한 기능 제거" 1
        print_security_check "U-39" "웹서비스 링크 다운로드 제한" 1
        print_security_check "U-40" "웹서비스 심볼릭 링크" 1
        print_security_check "U-41" "웹서비스 영역외 보안" 1
        print_security_check "U-71" "Apache 웹 서버 정보 설정" 1
    fi
    
    # 추가 파일 권한
    print_security_check "U-15" "/dev/null 파일의 파일 설정" 1
    print_security_check "U-16" "심볼릭 링크 및 Device 파일 설정" 1
    print_security_check "U-56" "UMASK 설정" 1
    print_security_check "U-59" "중요 파일 및 디렉토리 접근 설정" 1
    print_security_check "U-68" "로그 스트림 제한" 1
    print_security_check "U-69" "NFS 설정파일 제어"
    print_security_check "U-72" "정책에 따른 파일 시스템 접근 설정"
}

################################################################################
# SSH 설정 관련 함수
################################################################################

# SSH 설정 확인
check_ssh_config() {
    append_log ""
    append_log "========================================"
    append_log "[6] SSH 설정 점검"
    append_log "========================================"
    
    if [ -f /etc/ssh/sshd_config ]; then
        print_security_check "U-01" "root 계정 원격 접속 제한" 1
        append_log "  PermitRootLogin: $(grep -w PermitRootLogin /etc/ssh/sshd_config | grep -v "^#")"
        
        print_security_check "U-02" "패스워드 복잡성 설정" 1
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
        local permit_root=$(grep -w PermitRootLogin /etc/ssh/sshd_config | grep -v "^#" | awk '{print $2}' | tail -1)
        if [ "$permit_root" = "yes" ]; then
            append_log "⚠️  [U-01] 경고: PermitRootLogin이 yes로 설정되어 있습니다 (권장: no)"
        fi

        # PasswordAuthentication 확인
        local pass_auth=$(grep -w PasswordAuthentication /etc/ssh/sshd_config | grep -v "^#" | awk '{print $2}' | tail -1)
        if [ "$pass_auth" = "yes" ]; then
            append_log "⚠️  [U-02] 경고: PasswordAuthentication이 yes로 설정되어 있습니다 (권장: no, PubkeyAuthentication 사용)"
        fi

        # Protocol 확인
        local protocol=$(grep -w Protocol /etc/ssh/sshd_config | grep -v "^#" | awk '{print $2}' | tail -1)
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
    append_log "========================================"
    append_log "[7] 방화벽 설정 확인"
    append_log "========================================"
    
    if command_exists ufw; then
        print_security_check "U-18" "접속 IP 필터 제정" 1
        append_log "  UFW: $(ufw status)"
    fi
    
    if command_exists firewall-cmd; then
        append_log "  Firewalld: $(firewall-cmd --state 2>/dev/null || echo '비활성화')"
    fi
    
    if command_exists iptables; then
        append_log "  iptables: $(iptables -L -n 2>/dev/null | head -5)"
    fi
}

################################################################################
# checks 디렉토리의 개별 점검 파일 로드 함수
################################################################################
load_checks() {
    local checks_dir="$(dirname "${BASH_SOURCE[0]}")/checks"
    local check_code=$1
    
    if [ -z "$check_code" ]; then
        # 모든 점검 파일 로드
        for check_file in "$checks_dir"/U-*.sh; do
            if [ -f "$check_file" ]; then
                source "$check_file"
            fi
        done
    else
        # 특정 점검 파일만 로드
        local check_file="$checks_dir/${check_code}.sh"
        if [ -f "$check_file" ]; then
            source "$check_file"
        else
            append_log "경고: $check_file 파일을 찾을 수 없습니다"
        fi
    fi
}

################################################################################
# 모든 점검 항목 실행 함수
################################################################################
run_all_checks() {
    load_checks
    
    # 섹션 1: 계정 관리 (U-01 ~ U-13)
    print_section_header "1. 계정 관리 (U-01 ~ U-13)"
    check_U_01
    check_U_02
    check_U_03
    check_U_04
    check_U_05
    check_U_06
    check_U_07
    check_U_08
    check_U_09
    check_U_10
    check_U_11
    check_U_12
    check_U_13
    
    # 섹션 2: 파일 및 디렉토리 관리 (U-14 ~ U-32)
    print_section_header "2. 파일 및 디렉토리 관리 (U-14 ~ U-32)"
    check_U_14
    check_U_15
    check_U_16
    check_U_17
    check_U_18
    check_U_19
    check_U_20
    check_U_21
    check_U_22
    check_U_23
    check_U_24
    check_U_25
    check_U_26
    check_U_27
    check_U_28
    check_U_29
    check_U_30
    check_U_31
    check_U_32
    
    # 섹션 3: 서비스 관리 (U-33 ~ U-60)
    print_section_header "3. 서비스 관리 (U-34 ~ U-67)"
    check_U_33
    check_U_34
    check_U_35
    check_U_36
    check_U_37
    check_U_38
    check_U_39
    check_U_40
    check_U_41
    check_U_42
    check_U_43
    check_U_44
    check_U_45
    check_U_46
    check_U_47
    check_U_48
    check_U_49
    check_U_50
    check_U_51
    check_U_52
    check_U_53
    check_U_54
    check_U_55
    check_U_56
    check_U_57
    check_U_58
    check_U_59
    check_U_60
    
    # 섹션 4: 로그 및 감시, 기타 보안 (U-61 ~ U-72)
    print_section_header "4. 로그 및 감시, 기타 보안 (U-61 ~ U-72)"
    check_U_61
    check_U_62
    check_U_63
    check_U_64
    check_U_65
    check_U_66
    check_U_67
    check_U_68
    check_U_69
    check_U_70
    check_U_71
    check_U_72
}
