#!/bin/bash

################################################################################
# Linux-specific Checks
################################################################################

# common.sh 로드 (이미 main.sh에서 로드됨)
# source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

run_linux_checks() {
    local distro="$1"
    
    log "INFO" "Linux 환경 검사 시작..."
    
    append_log ""
    append_log "=== Linux 기본 정보 ==="
    append_log "커널 버전: $(uname -r)"
    append_log "배포판: $(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'=' -f2)"
    append_log "시스템 아키텍처: $(uname -m)"
    
    # 배포판별 검사 실행
    case "$distro" in
        ubuntu|debian)
            log "INFO" "Debian/Ubuntu 배포판 검사 실행..."
            if [ -f "${SCRIPTS_DIR}/linux/debian.sh" ]; then
                source "${SCRIPTS_DIR}/linux/debian.sh"
                check_debian_ubuntu
            fi
            ;;
        centos|rhel|rocky|alma)
            log "INFO" "CentOS/RHEL 계열 검사 실행..."
            if [ -f "${SCRIPTS_DIR}/linux/redhat.sh" ]; then
                source "${SCRIPTS_DIR}/linux/redhat.sh"
                check_redhat_family
            fi
            ;;
        alpine)
            log "INFO" "Alpine Linux 검사 실행..."
            if [ -f "${SCRIPTS_DIR}/linux/alpine.sh" ]; then
                source "${SCRIPTS_DIR}/linux/alpine.sh"
                check_alpine
            fi
            ;;
        arch)
            log "INFO" "Arch Linux 검사 실행..."
            if [ -f "${SCRIPTS_DIR}/linux/arch.sh" ]; then
                source "${SCRIPTS_DIR}/linux/arch.sh"
                check_arch
            fi
            ;;
        *)
            log "WARNING" "알려지지 않은 배포판: ${distro}"
            append_log "배포판별 검사 로직이 없습니다: ${distro}"
            ;;
    esac
    
    log "INFO" "Linux 검사 완료"
    
    return 0
}
