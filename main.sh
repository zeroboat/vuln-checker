#!/bin/bash

################################################################################
# Vulnerability Checker - Main Script
# OS 감지 및 결과 저장을 담당하는 메인 스크립트
################################################################################

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 디렉토리 설정
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${SCRIPT_DIR}/scripts"
RESULTS_DIR="${SCRIPT_DIR}/results"
LOGS_DIR="${SCRIPT_DIR}/logs"

# 타임스탬프
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="${LOGS_DIR}/run_${TIMESTAMP}.log"
RESULT_FILE="${RESULTS_DIR}/result_${TIMESTAMP}.txt"

################################################################################
# 함수: OS 감지
################################################################################
detect_os() {
    local os_type
    
    case "$(uname -s)" in
        Linux*)
            os_type="LINUX"
            ;;
        Darwin*)
            os_type="MACOS"
            ;;
        *)
            os_type="UNKNOWN"
            ;;
    esac
    
    echo "$os_type"
}

################################################################################
# 함수: Linux 배포판 감지
################################################################################
detect_linux_distro() {
    local distro="UNKNOWN"
    
    if [ -f /etc/os-release ]; then
        distro=$(grep "^ID=" /etc/os-release | cut -d'=' -f2 | tr -d '"')
    elif [ -f /etc/redhat-release ]; then
        distro="rhel"
    elif [ -f /etc/debian_version ]; then
        distro="debian"
    fi
    
    echo "$distro"
}

################################################################################
# 함수: macOS 버전 감지
################################################################################
detect_macos_version() {
    sw_vers -productVersion
}

################################################################################
# 함수: 로그 출력
################################################################################
log() {
    local level="$1"
    shift
    local message="$@"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    echo "[${timestamp}] [${level}] ${message}" | tee -a "$LOG_FILE"
}

################################################################################
# 함수: 초기화
################################################################################
init() {
    # 결과 파일 초기화
    {
        echo "===================================================="
        echo "Vulnerability Checker 결과"
        echo "===================================================="
        echo "실행일시: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "OS: ${OS_TYPE}"
        echo "===================================================="
    } > "$RESULT_FILE"
    
    log "INFO" "=================================="
    log "INFO" "Vulnerability Checker 시작"
    log "INFO" "=================================="
    log "INFO" "OS: ${OS_TYPE}"
    log "INFO" "스크립트 디렉토리: ${SCRIPT_DIR}"
    log "INFO" "결과 저장: ${RESULT_FILE}"
}

################################################################################
# 함수: 종료 처리
################################################################################
finalize() {
    local status=$1
    local message=$2
    
    if [ $status -eq 0 ]; then
        log "INFO" "✓ ${message}"
        echo -e "${GREEN}✓ ${message}${NC}"
    else
        log "ERROR" "✗ ${message}"
        echo -e "${RED}✗ ${message}${NC}"
    fi
    
    log "INFO" "=================================="
    log "INFO" "Vulnerability Checker 종료"
    log "INFO" "=================================="
}

################################################################################
# 메인 로직
################################################################################
main() {
    # 필요한 디렉토리 생성
    mkdir -p "${LOGS_DIR}" "${RESULTS_DIR}"
    
    # 공통 함수 먼저 로드
    if [ -f "${SCRIPTS_DIR}/common.sh" ]; then
        source "${SCRIPTS_DIR}/common.sh"
    fi
    
    # OS 감지
    OS_TYPE=$(detect_os)
    
    # 초기화
    init
    
    # OS별 스크립트 실행
    case "$OS_TYPE" in
        LINUX)
            local DISTRO=$(detect_linux_distro)
            log "INFO" "Linux 배포판: ${DISTRO}"
            log "INFO" "Linux 스크립트 실행 중..."
            
            if [ -f "${SCRIPTS_DIR}/linux.sh" ]; then
                source "${SCRIPTS_DIR}/linux.sh"
                run_linux_checks "$DISTRO"
                local result=$?
            else
                log "ERROR" "linux.sh를 찾을 수 없습니다"
                result=1
            fi
            ;;
        MACOS)
            local MACOS_VERSION=$(detect_macos_version)
            log "INFO" "macOS 버전: ${MACOS_VERSION}"
            log "INFO" "macOS 스크립트 실행 중..."
            
            if [ -f "${SCRIPTS_DIR}/macos.sh" ]; then
                source "${SCRIPTS_DIR}/macos.sh"
                run_macos_checks "$MACOS_VERSION"
                local result=$?
            else
                log "ERROR" "macos.sh를 찾을 수 없습니다"
                result=1
            fi
            ;;
        *)
            log "ERROR" "지원하지 않는 OS입니다: ${OS_TYPE}"
            result=1
            ;;
    esac
    
    # 결과 저장
    {
        echo ""
        echo "===================================================="
        echo "최종 상태: $([ $result -eq 0 ] && echo '성공' || echo '실패')"
        echo "===================================================="
    } >> "$RESULT_FILE"
    
    # 종료 처리
    if [ $result -eq 0 ]; then
        finalize 0 "모든 검사 완료"
    else
        finalize 1 "검사 중 오류 발생"
    fi
    
    return $result
}

# 스크립트 실행
main
exit $?
