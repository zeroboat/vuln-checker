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

################################################################################
# root 권한 확인
################################################################################
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}[오류] 이 스크립트는 root 권한으로 실행해야 합니다.${NC}"
    echo -e "${YELLOW}  실행 방법: sudo ${0}${NC}"
    exit 1
fi

# 디렉토리 설정
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${SCRIPT_DIR}/scripts"
RESULTS_DIR="${SCRIPT_DIR}/results"
LOGS_DIR="${SCRIPT_DIR}/logs"

# 타임스탬프
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="${LOGS_DIR}/run_${TIMESTAMP}.log"
RESULT_FILE="${RESULTS_DIR}/result_${TIMESTAMP}.txt"
SUMMARY_FILE="${RESULTS_DIR}/summary_${TIMESTAMP}.md"

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
# 함수: 마크다운 요약 생성
################################################################################
generate_summary() {
    local pass_count="$1"
    local fail_count="$2"
    local review_count="$3"
    local total_count="$4"
    local run_date
    run_date=$(date '+%Y-%m-%d %H:%M:%S')
    local hostname
    hostname=$(hostname 2>/dev/null || echo "unknown")

    # 취약/확인필요 항목 목록 추출
    local fail_list review_list
    fail_list=$(awk '/^\[U-[0-9]/{code=$0} /점검 결과: 취약/{print code}' "$RESULT_FILE")
    review_list=$(awk '/^\[U-[0-9]/{code=$0} /점검 결과: 확인필요/{print code}' "$RESULT_FILE")

    {
        echo "# 취약점 점검 결과 요약"
        echo ""
        echo "| 항목 | 내용 |"
        echo "|------|------|"
        echo "| 점검 일시 | ${run_date} |"
        echo "| 호스트명 | ${hostname} |"
        echo "| OS | ${OS_TYPE} |"
        echo "| 결과 파일 | $(basename "$RESULT_FILE") |"
        echo ""
        echo "## 점검 결과 통계"
        echo ""
        echo "| 구분 | 건수 | 비율 |"
        echo "|------|-----:|-----:|"
        echo "| ✅ 양호 | ${pass_count} | $(( total_count > 0 ? pass_count * 100 / total_count : 0 ))% |"
        echo "| ❌ 취약 | ${fail_count} | $(( total_count > 0 ? fail_count * 100 / total_count : 0 ))% |"
        echo "| ⚠️ 확인필요 | ${review_count} | $(( total_count > 0 ? review_count * 100 / total_count : 0 ))% |"
        echo "| **합계** | **${total_count}** | **100%** |"
        echo ""

        if [ -n "$fail_list" ]; then
            echo "## ❌ 취약 항목 목록"
            echo ""
            while IFS= read -r line; do
                local code detail
                code=$(echo "$line" | grep -oE "U-[0-9]+")
                detail=$(echo "$line" | sed 's/\[U-[0-9]*\] //')
                echo "- **${code}** ${detail}"
            done <<< "$fail_list"
            echo ""
        fi

        if [ -n "$review_list" ]; then
            echo "## ⚠️ 확인필요 항목 목록"
            echo ""
            while IFS= read -r line; do
                local code detail
                code=$(echo "$line" | grep -oE "U-[0-9]+")
                detail=$(echo "$line" | sed 's/\[U-[0-9]*\] //')
                echo "- **${code}** ${detail}"
            done <<< "$review_list"
            echo ""
        fi

        echo "## 상세 결과"
        echo ""
        echo "> 상세 점검 내용은 \`$(basename "$RESULT_FILE")\` 파일을 참고하세요."
    } > "$SUMMARY_FILE"
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
    
    # 결과 집계
    local pass_count fail_count review_count
    pass_count=$(grep -c "점검 결과: 양호"    "$RESULT_FILE" 2>/dev/null || echo 0)
    fail_count=$(grep -c "점검 결과: 취약"    "$RESULT_FILE" 2>/dev/null || echo 0)
    review_count=$(grep -c "점검 결과: 확인필요" "$RESULT_FILE" 2>/dev/null || echo 0)
    local total_count=$(( pass_count + fail_count + review_count ))

    # 결과 파일 마무리
    {
        echo ""
        echo "===================================================="
        echo "검사 완료: 총 ${total_count}개  양호 ${pass_count}  취약 ${fail_count}  확인필요 ${review_count}"
        echo "===================================================="
    } >> "$RESULT_FILE"

    # 마크다운 요약 파일 생성
    generate_summary "$pass_count" "$fail_count" "$review_count" "$total_count"

    log "INFO" "요약 저장: ${SUMMARY_FILE}"

    # 종료 처리
    if [ $result -eq 0 ]; then
        finalize 0 "모든 검사 완료 (총 ${total_count}개 | 양호 ${pass_count} / 취약 ${fail_count} / 확인필요 ${review_count})"
    else
        finalize 1 "검사 중 오류 발생"
    fi
    
    return $result
}

# 스크립트 실행
main
exit $?
