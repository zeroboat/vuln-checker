#!/bin/bash

################################################################################
# CentOS/RHEL-specific Checks
################################################################################

# common.sh 로드 (이미 main.sh에서 로드되지만, 직접 실행 시 필요)
if ! declare -f append_log &>/dev/null; then
    source "$(dirname "${BASH_SOURCE[0]}")/../common.sh"
fi

check_redhat_family() {
    append_log ""
    append_log "=== CentOS/RHEL 보안 검사 시작 ==="
    
    # YUM/DNF 패키지 매니저 확인
    if command_exists dnf; then
        append_log "패키지 매니저: DNF"
    elif command_exists yum; then
        append_log "패키지 매니저: YUM"
    fi
    
    # SELinux 상태 확인
    if command_exists getenforce; then
        append_log "SELinux 상태: $(getenforce)"
    fi
    
    # Firewalld 상태 확인
    if command_exists firewall-cmd; then
        append_log "Firewalld 상태: $(firewall-cmd --state 2>/dev/null || echo '비활성화')"
    fi
    
    # 모든 점검 항목 실행 (U-01 ~ U-18)
    # checks 디렉토리의 개별 파일들을 통해 관리됨
    run_all_checks
    
    log "INFO" "CentOS/RHEL 검사 완료"
}
