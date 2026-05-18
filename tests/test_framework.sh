#!/bin/bash

################################################################################
# 테스트 프레임워크 - vuln-checker 점검 항목 자동 테스트
#
# 사용법:
#   ./tests/test_framework.sh              # 모든 테스트 실행
#   ./tests/test_framework.sh U-01         # 특정 항목만 테스트
#   ./tests/test_framework.sh --list       # 테스트 목록 표시
################################################################################

set -euo pipefail

# 색상
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# 경로 설정
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$TEST_DIR")"
SCRIPTS_DIR="${PROJECT_DIR}/scripts"

# 테스트 카운터
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# 임시 환경
TEST_TMP=""
RESULT_FILE=""
JSON_CHECKS_TMP=""

################################################################################
# 테스트 유틸리티 함수
################################################################################

setup_test_env() {
    TEST_TMP=$(mktemp -d /tmp/vuln_test_XXXXXX 2>/dev/null || mktemp -d)
    export RESULT_FILE="${TEST_TMP}/result.txt"
    export JSON_CHECKS_TMP="${TEST_TMP}/json.txt"
    > "$RESULT_FILE"
    > "$JSON_CHECKS_TMP"

    # common.sh 로드
    source "${SCRIPTS_DIR}/common.sh"
}

teardown_test_env() {
    rm -rf "$TEST_TMP" 2>/dev/null
}

# Mock 파일 생성 헬퍼
create_mock_file() {
    local path="$1"
    local content="${2:-}"
    local dir
    dir=$(dirname "$path")
    mkdir -p "$dir"
    echo "$content" > "$path"
}

# 테스트 결과 확인
assert_status() {
    local expected="$1"  # PASS, FAIL, REVIEW
    local code="$2"
    local test_name="$3"

    TESTS_TOTAL=$((TESTS_TOTAL + 1))

    local actual=""
    if grep -q "점검 결과: 양호" "$RESULT_FILE" 2>/dev/null; then
        actual="PASS"
    elif grep -q "점검 결과: 취약" "$RESULT_FILE" 2>/dev/null; then
        actual="FAIL"
    elif grep -q "점검 결과: 확인필요" "$RESULT_FILE" 2>/dev/null; then
        actual="REVIEW"
    else
        actual="NO_RESULT"
    fi

    if [ "$actual" = "$expected" ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "  ${GREEN}PASS${NC} [${code}] ${test_name} (expected=${expected})"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "  ${RED}FAIL${NC} [${code}] ${test_name} (expected=${expected}, got=${actual})"
    fi

    # 결과 파일 초기화 (다음 테스트를 위해)
    > "$RESULT_FILE"
}

assert_contains() {
    local pattern="$1"
    local test_name="$2"

    TESTS_TOTAL=$((TESTS_TOTAL + 1))

    if grep -q "$pattern" "$RESULT_FILE" 2>/dev/null; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "  ${GREEN}PASS${NC} ${test_name}"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "  ${RED}FAIL${NC} ${test_name} (패턴 미발견: ${pattern})"
    fi
}

skip_test() {
    local code="$1"
    local reason="$2"
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
    echo -e "  ${YELLOW}SKIP${NC} [${code}] ${reason}"
}

################################################################################
# 공통 함수 테스트
################################################################################

test_common_functions() {
    echo -e "${CYAN}=== 공통 함수 테스트 ===${NC}"

    # json_escape 테스트
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    local escaped
    escaped=$(json_escape 'hello "world"')
    if [ "$escaped" = 'hello \"world\"' ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "  ${GREEN}PASS${NC} json_escape: 따옴표 이스케이프"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "  ${RED}FAIL${NC} json_escape: 따옴표 이스케이프 (got: ${escaped})"
    fi

    # json_escape 백슬래시
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    escaped=$(json_escape 'path\to\file')
    if [ "$escaped" = 'path\\to\\file' ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "  ${GREEN}PASS${NC} json_escape: 백슬래시 이스케이프"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "  ${RED}FAIL${NC} json_escape: 백슬래시 이스케이프 (got: ${escaped})"
    fi

    # get_category 테스트
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    local cat1
    cat1=$(get_category "U-01")
    if [ "$cat1" = "계정 관리" ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "  ${GREEN}PASS${NC} get_category: U-01 → 계정 관리"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "  ${RED}FAIL${NC} get_category: U-01 (got: ${cat1})"
    fi

    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    local cat2
    cat2=$(get_category "U-20")
    if [ "$cat2" = "파일 및 디렉토리 관리" ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "  ${GREEN}PASS${NC} get_category: U-20 → 파일 및 디렉토리 관리"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "  ${RED}FAIL${NC} get_category: U-20 (got: ${cat2})"
    fi

    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    local cat3
    cat3=$(get_category "U-50")
    if [ "$cat3" = "서비스 관리" ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "  ${GREEN}PASS${NC} get_category: U-50 → 서비스 관리"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "  ${RED}FAIL${NC} get_category: U-50 (got: ${cat3})"
    fi

    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    local cat4
    cat4=$(get_category "U-70")
    if [ "$cat4" = "로그 및 감시" ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "  ${GREEN}PASS${NC} get_category: U-70 → 로그 및 감시"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "  ${RED}FAIL${NC} get_category: U-70 (got: ${cat4})"
    fi

    # command_exists 테스트
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    if command_exists bash; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "  ${GREEN}PASS${NC} command_exists: bash 존재"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "  ${RED}FAIL${NC} command_exists: bash 미발견"
    fi

    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    if ! command_exists __nonexistent_cmd_12345__; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "  ${GREEN}PASS${NC} command_exists: 없는 명령어 false 반환"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "  ${RED}FAIL${NC} command_exists: 없는 명령어가 true 반환"
    fi

    # record_check_result 테스트
    record_check_result "U-01" "PASS" "테스트 상세"
    assert_status "PASS" "U-01" "record_check_result PASS 기록"

    record_check_result "U-02" "FAIL" "취약 상세"
    assert_status "FAIL" "U-02" "record_check_result FAIL 기록"

    record_check_result "U-03" "REVIEW" "확인 필요"
    assert_status "REVIEW" "U-03" "record_check_result REVIEW 기록"

    # require_command 테스트
    > "$RESULT_FILE"
    if require_command "bash" "U-99"; then
        TESTS_TOTAL=$((TESTS_TOTAL + 1))
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "  ${GREEN}PASS${NC} require_command: 존재하는 명령어 성공"
    fi

    > "$RESULT_FILE"
    if ! require_command "__fake_cmd__" "U-99" "fake 명령어 없음"; then
        assert_status "REVIEW" "U-99" "require_command: 없는 명령어 REVIEW 처리"
    fi

    # require_file 테스트
    > "$RESULT_FILE"
    if ! require_file "/nonexistent/file/path" "U-98"; then
        assert_status "REVIEW" "U-98" "require_file: 없는 파일 REVIEW 처리"
    fi

    # check_prerequisites 테스트
    > "$RESULT_FILE"
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    if check_prerequisites; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "  ${GREEN}PASS${NC} check_prerequisites: 필수 명령어 확인"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "  ${RED}FAIL${NC} check_prerequisites: 필수 명령어 부재"
    fi
}

################################################################################
# JSON 출력 테스트
################################################################################

test_json_output() {
    echo -e "${CYAN}=== JSON 출력 테스트 ===${NC}"

    # JSON 파일 생성 테스트
    local test_json="${TEST_TMP}/test_output.json"

    record_check_result "U-01" "PASS" "테스트 결과"
    record_check_result "U-02" "FAIL" "취약 발견"

    generate_json "$test_json" "2026-01-01T00:00:00" "testhost" "LINUX" "ubuntu" "x86_64" \
        "1" "1" "0" "2"

    # JSON 파일 존재 확인
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    if [ -f "$test_json" ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "  ${GREEN}PASS${NC} JSON 파일 생성됨"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "  ${RED}FAIL${NC} JSON 파일 미생성"
        return
    fi

    # JSON 구조 검증 (jq 있으면 사용, 없으면 기본 검증)
    if command_exists jq; then
        TESTS_TOTAL=$((TESTS_TOTAL + 1))
        if jq . "$test_json" >/dev/null 2>&1; then
            TESTS_PASSED=$((TESTS_PASSED + 1))
            echo -e "  ${GREEN}PASS${NC} JSON 구문 유효 (jq 검증)"
        else
            TESTS_FAILED=$((TESTS_FAILED + 1))
            echo -e "  ${RED}FAIL${NC} JSON 구문 오류"
        fi

        # metadata 필드 확인
        TESTS_TOTAL=$((TESTS_TOTAL + 1))
        local hostname
        hostname=$(jq -r '.metadata.hostname' "$test_json" 2>/dev/null)
        if [ "$hostname" = "testhost" ]; then
            TESTS_PASSED=$((TESTS_PASSED + 1))
            echo -e "  ${GREEN}PASS${NC} JSON metadata.hostname 정확"
        else
            TESTS_FAILED=$((TESTS_FAILED + 1))
            echo -e "  ${RED}FAIL${NC} JSON metadata.hostname (got: ${hostname})"
        fi

        # summary 필드 확인
        TESTS_TOTAL=$((TESTS_TOTAL + 1))
        local total
        total=$(jq -r '.summary.total' "$test_json" 2>/dev/null)
        if [ "$total" = "2" ]; then
            TESTS_PASSED=$((TESTS_PASSED + 1))
            echo -e "  ${GREEN}PASS${NC} JSON summary.total = 2"
        else
            TESTS_FAILED=$((TESTS_FAILED + 1))
            echo -e "  ${RED}FAIL${NC} JSON summary.total (got: ${total})"
        fi

        # checks 배열 확인
        TESTS_TOTAL=$((TESTS_TOTAL + 1))
        local checks_len
        checks_len=$(jq '.checks | length' "$test_json" 2>/dev/null)
        if [ "$checks_len" = "2" ]; then
            TESTS_PASSED=$((TESTS_PASSED + 1))
            echo -e "  ${GREEN}PASS${NC} JSON checks 배열 길이 = 2"
        else
            TESTS_FAILED=$((TESTS_FAILED + 1))
            echo -e "  ${RED}FAIL${NC} JSON checks 배열 길이 (got: ${checks_len})"
        fi
    else
        # jq 없이 기본 검증
        TESTS_TOTAL=$((TESTS_TOTAL + 1))
        if grep -q '"metadata"' "$test_json" && grep -q '"checks"' "$test_json"; then
            TESTS_PASSED=$((TESTS_PASSED + 1))
            echo -e "  ${GREEN}PASS${NC} JSON 기본 구조 확인 (jq 미설치, 기본 검증)"
        else
            TESTS_FAILED=$((TESTS_FAILED + 1))
            echo -e "  ${RED}FAIL${NC} JSON 기본 구조 누락"
        fi
    fi

    # JSON 재초기화
    init_json
}

################################################################################
# 개별 점검 항목 테스트 (root 권한 필요)
################################################################################

test_check_scripts() {
    echo -e "${CYAN}=== 점검 스크립트 테스트 ===${NC}"

    if [ "$(id -u)" -ne 0 ]; then
        echo -e "  ${YELLOW}SKIP${NC} 점검 스크립트 테스트는 root 권한이 필요합니다"
        TESTS_TOTAL=$((TESTS_TOTAL + 1))
        TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
        return
    fi

    # 모든 점검 스크립트 로드
    load_checks

    # 각 점검 함수 존재 확인 및 실행 테스트
    for i in $(seq 1 72); do
        local padded
        padded=$(printf '%02d' "$i")
        local func="check_U_${padded}"
        local code="U-${padded}"

        TESTS_TOTAL=$((TESTS_TOTAL + 1))

        if ! declare -f "$func" >/dev/null 2>&1; then
            TESTS_FAILED=$((TESTS_FAILED + 1))
            echo -e "  ${RED}FAIL${NC} [${code}] 함수 ${func} 미정의"
            continue
        fi

        # 실행 테스트 (크래시 없이 완료되는지 확인)
        > "$RESULT_FILE"
        if "$func" >/dev/null 2>&1; then
            # 결과가 기록되었는지 확인
            if grep -qE "점검 결과: (양호|취약|확인필요)" "$RESULT_FILE" 2>/dev/null; then
                TESTS_PASSED=$((TESTS_PASSED + 1))
                local status_label
                if grep -q "양호" "$RESULT_FILE"; then status_label="PASS";
                elif grep -q "취약" "$RESULT_FILE"; then status_label="FAIL";
                else status_label="REVIEW"; fi
                echo -e "  ${GREEN}PASS${NC} [${code}] 정상 실행 (결과: ${status_label})"
            else
                TESTS_PASSED=$((TESTS_PASSED + 1))
                echo -e "  ${GREEN}PASS${NC} [${code}] 실행 완료 (결과 미기록 - 조건 미충족)"
            fi
        else
            TESTS_FAILED=$((TESTS_FAILED + 1))
            echo -e "  ${RED}FAIL${NC} [${code}] 실행 중 오류 발생"
        fi
    done
}

################################################################################
# 메인
################################################################################

main() {
    local target="${1:-all}"

    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║   vuln-checker 테스트 프레임워크         ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
    echo ""

    if [ "$target" = "--list" ]; then
        echo "사용 가능한 테스트:"
        echo "  all       - 모든 테스트 실행"
        echo "  common    - 공통 함수 테스트"
        echo "  json      - JSON 출력 테스트"
        echo "  checks    - 점검 스크립트 테스트 (root 필요)"
        echo "  U-XX      - 특정 점검 항목 테스트 (root 필요)"
        exit 0
    fi

    setup_test_env

    case "$target" in
        all)
            test_common_functions
            echo ""
            test_json_output
            echo ""
            test_check_scripts
            ;;
        common)
            test_common_functions
            ;;
        json)
            test_json_output
            ;;
        checks)
            test_check_scripts
            ;;
        U-*)
            # 특정 점검 항목 테스트
            echo -e "${CYAN}=== ${target} 단일 테스트 ===${NC}"
            if [ "$(id -u)" -ne 0 ]; then
                echo -e "  ${YELLOW}SKIP${NC} root 권한이 필요합니다"
                TESTS_SKIPPED=1
                TESTS_TOTAL=1
            else
                load_checks
                local padded="${target#U-}"
                local func="check_U_${padded}"
                > "$RESULT_FILE"
                if declare -f "$func" >/dev/null 2>&1; then
                    "$func"
                    echo -e "  결과:"
                    cat "$RESULT_FILE"
                    TESTS_TOTAL=1
                    TESTS_PASSED=1
                else
                    echo -e "  ${RED}FAIL${NC} 함수 ${func} 미정의"
                    TESTS_TOTAL=1
                    TESTS_FAILED=1
                fi
            fi
            ;;
        *)
            echo -e "${RED}알 수 없는 테스트: ${target}${NC}"
            exit 1
            ;;
    esac

    teardown_test_env

    # 결과 요약
    echo ""
    echo -e "${CYAN}══════════════════════════════════════════${NC}"
    echo -e "  전체: ${TESTS_TOTAL}  ${GREEN}통과: ${TESTS_PASSED}${NC}  ${RED}실패: ${TESTS_FAILED}${NC}  ${YELLOW}건너뜀: ${TESTS_SKIPPED}${NC}"
    echo -e "${CYAN}══════════════════════════════════════════${NC}"

    if [ "$TESTS_FAILED" -gt 0 ]; then
        exit 1
    fi
    exit 0
}

main "$@"
