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
# CLI 옵션 파싱
################################################################################
PARALLEL_MODE="false"
PARALLEL_JOBS=4
PROFILE="default"

show_help() {
    echo "사용법: sudo $0 [옵션]"
    echo ""
    echo "옵션:"
    echo "  --profile NAME     점검 기준(프로파일) 선택 (기본: default)"
    echo "  --parallel         병렬 실행 모드 (기본: 순차 실행)"
    echo "  --jobs N, -j N     병렬 실행 시 동시 작업 수 (기본: 4)"
    echo "  --list-profiles    사용 가능한 프로파일 목록 표시"
    echo "  --help, -h         도움말 표시"
    echo ""
    echo "프로파일:"
    echo "  default     주요정보통신기반시설(U-01~U-72) + Docker 자동 감지 (기본값)"
    echo "  kisa        주요정보통신기반시설 점검만 (U-01~U-72)"
    echo "  docker      Docker CIS Benchmark 점검만 (D-01~D-68)"
    echo "  all         구현된 모든 기준 실행"
    echo "  cis-linux   CIS Linux Benchmark (CL-01~CL-44)"
    echo "  isms-p      ISMS-P 기술적 보호조치 (준비 중)"
    echo ""
    echo "예시:"
    echo "  sudo $0                       # 기본 (주기반 + Docker 자동감지)"
    echo "  sudo $0 --profile kisa        # 주기반 점검만"
    echo "  sudo $0 --profile docker      # Docker 점검만"
    echo "  sudo $0 --profile all         # 모든 기준 실행"
    echo "  sudo $0 --parallel -j 8       # 8개씩 병렬 실행"
    exit 0
}

list_profiles() {
    echo "사용 가능한 프로파일:"
    echo "  default     주요정보통신기반시설(U-01~U-72) + Docker 자동 감지 [기본값]"
    echo "  kisa        주요정보통신기반시설 점검만 (U-01~U-72)"
    echo "  docker      Docker CIS Benchmark 점검만 (D-01~D-68)"
    echo "  all         구현된 모든 기준 실행"
    echo "  cis-linux   CIS Linux Benchmark (CL-01~CL-44)"
    echo "  isms-p      ISMS-P 기술적 보호조치 (준비 중)"
    exit 0
}

while [ $# -gt 0 ]; do
    case "$1" in
        --profile)
            PROFILE="${2:-default}"
            # 값이 없는 마지막 인자일 때 shift 2가 무한루프를 유발하므로 안전 처리
            shift 2 2>/dev/null || shift
            ;;
        --parallel)
            PARALLEL_MODE="true"
            shift
            ;;
        --jobs|-j)
            PARALLEL_JOBS="${2:-4}"
            shift 2 2>/dev/null || shift
            ;;
        --list-profiles)
            list_profiles
            ;;
        --help|-h)
            show_help
            ;;
        *)
            echo -e "${RED}[오류] 알 수 없는 옵션: $1${NC}"
            show_help
            ;;
    esac
done

# 프로파일 유효성 검사
case "$PROFILE" in
    default|kisa|docker|all|isms-p|cis-linux)
        ;;
    *)
        echo -e "${RED}[오류] 알 수 없는 프로파일: ${PROFILE}${NC}"
        echo -e "${YELLOW}  --list-profiles 로 사용 가능한 프로파일을 확인하세요.${NC}"
        exit 1
        ;;
esac

export PARALLEL_MODE PARALLEL_JOBS PROFILE

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
JSON_FILE="${RESULTS_DIR}/result_${TIMESTAMP}.json"

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
    if [ "$PARALLEL_MODE" = "true" ]; then
        log "INFO" "실행 모드: 병렬 (동시 ${PARALLEL_JOBS}개)"
    else
        log "INFO" "실행 모드: 순차"
    fi
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
# 함수: 프로파일 판정
################################################################################
# 현재 프로파일에 KISA(주기반 U-01~U-72) 점검이 포함되는지
profile_includes_kisa() {
    case "$PROFILE" in
        default|kisa|all) return 0 ;;
        *) return 1 ;;
    esac
}

# 현재 프로파일에 Docker 점검이 포함되는지
profile_includes_docker() {
    case "$PROFILE" in
        default|docker|all) return 0 ;;
        *) return 1 ;;
    esac
}

# 현재 프로파일에 CIS Linux Benchmark 점검이 포함되는지
profile_includes_cis_linux() {
    case "$PROFILE" in
        cis-linux|all) return 0 ;;
        *) return 1 ;;
    esac
}

# 아직 구현되지 않은 프로파일 안내
show_not_implemented_profile() {
    local name="$1"
    local desc="$2"
    echo -e "${YELLOW}[준비 중] '${name}' 프로파일은 아직 구현되지 않았습니다.${NC}"
    echo -e "${YELLOW}  ${desc}${NC}"
    echo -e "${YELLOW}  현재 사용 가능한 프로파일: default, kisa, docker, all${NC}"
    log "INFO" "미구현 프로파일 요청: ${name}"
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
    
    # JSON 초기화
    init_json

    # 초기화
    init

    # 필수 명령어 사전 확인
    check_prerequisites

    local result=0
    log "INFO" "실행 프로파일: ${PROFILE}"

    # 미구현 프로파일 처리 (안내 후 종료)
    case "$PROFILE" in
        isms-p)
            show_not_implemented_profile "isms-p" "ISMS-P 기술적 보호조치 점검 기준"
            return 0
            ;;
    esac

    # OS별 스크립트 실행 (KISA 주기반 점검 — U-01~U-72)
    if profile_includes_kisa; then
        case "$OS_TYPE" in
            LINUX)
                local DISTRO=$(detect_linux_distro)
                log "INFO" "Linux 배포판: ${DISTRO}"
                log "INFO" "Linux 스크립트 실행 중..."

                if [ -f "${SCRIPTS_DIR}/linux.sh" ]; then
                    source "${SCRIPTS_DIR}/linux.sh"
                    run_linux_checks "$DISTRO"
                    result=$?
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
                    result=$?
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
    else
        log "INFO" "프로파일 '${PROFILE}': 주기반(U-01~U-72) 점검 건너뜀"
    fi

    # Docker 점검 실행
    if profile_includes_docker; then
        if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
            log "INFO" "Docker 감지됨 — Docker 보안 점검 실행 중..."
            echo -e "${BLUE}[Docker] Docker 환경이 감지되었습니다. CIS Docker Benchmark 점검을 시작합니다...${NC}"
            if [ -f "${SCRIPT_DIR}/docker/main.sh" ]; then
                export RESULTS_DIR
                source "${SCRIPT_DIR}/docker/main.sh"
                run_docker_checks
            else
                log "ERROR" "docker/main.sh를 찾을 수 없습니다"
            fi
        elif [ "$PROFILE" = "docker" ]; then
            # docker 프로파일을 명시했는데 Docker 환경이 없는 경우 안내
            log "WARNING" "Docker를 찾을 수 없거나 데몬이 실행 중이 아닙니다"
            echo -e "${YELLOW}[Docker] Docker가 설치되어 있지 않거나 데몬이 실행 중이 아닙니다.${NC}"
            result=1
        fi
    else
        log "INFO" "프로파일 '${PROFILE}': Docker 점검 건너뜀"
    fi

    # CIS Linux Benchmark 점검 실행
    if profile_includes_cis_linux; then
        if [ "$OS_TYPE" != "LINUX" ]; then
            log "WARNING" "CIS Linux Benchmark는 Linux 환경에서만 의미가 있습니다 (현재: ${OS_TYPE})"
            echo -e "${YELLOW}[CIS-Linux] Linux 환경이 아니므로 일부 항목이 '확인필요'로 처리됩니다.${NC}"
        fi
        log "INFO" "CIS Linux Benchmark 점검 실행 중..."
        echo -e "${BLUE}[CIS-Linux] CIS Linux Benchmark 점검을 시작합니다...${NC}"
        if [ -f "${SCRIPT_DIR}/cis-linux/main.sh" ]; then
            export RESULTS_DIR
            source "${SCRIPT_DIR}/cis-linux/main.sh"
            run_cis_linux_checks
        else
            log "ERROR" "cis-linux/main.sh를 찾을 수 없습니다"
        fi
    fi

    # 결과 집계
    # grep -c는 일치가 없어도 "0"을 출력하므로 `|| echo 0`을 붙이면 "0\n0"이 되어
    # 산술식이 깨진다. 출력을 그대로 받고 비어있을 때만 0으로 보정한다.
    local pass_count fail_count review_count
    pass_count=$(grep -c "점검 결과: 양호"    "$RESULT_FILE" 2>/dev/null); pass_count=${pass_count:-0}
    fail_count=$(grep -c "점검 결과: 취약"    "$RESULT_FILE" 2>/dev/null); fail_count=${fail_count:-0}
    review_count=$(grep -c "점검 결과: 확인필요" "$RESULT_FILE" 2>/dev/null); review_count=${review_count:-0}
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

    # JSON 결과 파일 생성
    local run_date
    run_date=$(date '+%Y-%m-%dT%H:%M:%S')
    local json_hostname
    json_hostname=$(hostname 2>/dev/null || echo "unknown")
    local json_distro="${DISTRO:-}"
    local json_arch
    json_arch=$(uname -m 2>/dev/null || echo "unknown")

    generate_json "$JSON_FILE" "$run_date" "$json_hostname" "$OS_TYPE" "$json_distro" "$json_arch" \
        "$pass_count" "$fail_count" "$review_count" "$total_count"

    log "INFO" "JSON 저장: ${JSON_FILE}"
    log "INFO" "요약 저장: ${SUMMARY_FILE}"

    # 종료 처리
    if [ $result -eq 0 ]; then
        finalize 0 "모든 검사 완료 (총 ${total_count}개 | 양호 ${pass_count} / 취약 ${fail_count} / 확인필요 ${review_count}) | JSON: ${JSON_FILE}"
    else
        finalize 1 "검사 중 오류 발생"
    fi
    
    return $result
}

# 스크립트 실행
main
exit $?
