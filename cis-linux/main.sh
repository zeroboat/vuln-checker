#!/bin/bash

################################################################################
# CIS Linux Benchmark 점검 진입점
################################################################################

CIS_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${CIS_SCRIPT_DIR}/scripts/common.sh"

# 점검 결과 카운터
CIS_PASS_COUNT=0
CIS_FAIL_COUNT=0
CIS_REVIEW_COUNT=0

run_cis_linux_checks() {
    local exec_time
    exec_time=$(date '+%Y-%m-%d %H:%M:%S')
    local hostname
    hostname=$(hostname 2>/dev/null || echo "unknown")
    local distro="unknown"
    if [ -f /etc/os-release ]; then
        distro=$(grep "^PRETTY_NAME=" /etc/os-release 2>/dev/null | cut -d'=' -f2 | tr -d '"')
    fi
    local arch
    arch=$(uname -m 2>/dev/null || echo "unknown")

    # 결과 파일 경로 (main.sh에서 RESULTS_DIR을 설정한 후 호출됨)
    local ts
    ts=$(date '+%Y%m%d_%H%M%S')
    local result_dir="${RESULTS_DIR:-./results}"
    mkdir -p "$result_dir"

    CIS_RESULT_FILE="${result_dir}/cis_linux_result_${ts}.txt"
    local json_file="${result_dir}/cis_linux_result_${ts}.json"
    # 통합 JSON 생성을 위해 경로를 전역으로 노출 (main.sh에서 참조)
    CIS_JSON_OUTPUT="$json_file"

    # JSON 임시 파일 초기화
    init_cis_json

    # 헤더 출력
    {
        echo "========================================================"
        echo "  CIS Linux Benchmark 보안 취약점 점검 보고서"
        echo "========================================================"
        echo ""
        echo "  점검 일시  : ${exec_time}"
        echo "  호스트명   : ${hostname}"
        echo "  배포판     : ${distro}"
        echo "  아키텍처   : ${arch}"
        echo ""
        echo "========================================================"
    } > "$CIS_RESULT_FILE"

    # 섹션별 점검 실행
    load_cis_checks

    cis_print_section "1. 초기 설정 (CL-01 ~ CL-10)"
    check_CL_01; check_CL_02; check_CL_03; check_CL_04; check_CL_05
    check_CL_06; check_CL_07; check_CL_08; check_CL_09; check_CL_10

    cis_print_section "2. 서비스 (CL-11 ~ CL-17)"
    check_CL_11; check_CL_12; check_CL_13; check_CL_14; check_CL_15
    check_CL_16; check_CL_17

    cis_print_section "3. 네트워크 설정 (CL-18 ~ CL-26)"
    check_CL_18; check_CL_19; check_CL_20; check_CL_21; check_CL_22
    check_CL_23; check_CL_24; check_CL_25; check_CL_26

    cis_print_section "4. 로깅 및 감사 (CL-27 ~ CL-31)"
    check_CL_27; check_CL_28; check_CL_29; check_CL_30; check_CL_31

    cis_print_section "5. 접근 및 인증 (CL-32 ~ CL-38)"
    check_CL_32; check_CL_33; check_CL_34; check_CL_35; check_CL_36
    check_CL_37; check_CL_38

    cis_print_section "6. 시스템 유지보수 (CL-39 ~ CL-44)"
    check_CL_39; check_CL_40; check_CL_41; check_CL_42; check_CL_43
    check_CL_44

    # 요약 계산
    local total_count=$((CIS_PASS_COUNT + CIS_FAIL_COUNT + CIS_REVIEW_COUNT))

    # 결과 파일 요약 추가
    {
        echo ""
        echo "========================================================"
        echo "  점검 결과 요약"
        echo "========================================================"
        echo ""
        printf "  %-14s %d건\n" "✅ 양호(PASS):"   "$CIS_PASS_COUNT"
        printf "  %-14s %d건\n" "❌ 취약(FAIL):"   "$CIS_FAIL_COUNT"
        printf "  %-14s %d건\n" "⚠️  확인필요:"    "$CIS_REVIEW_COUNT"
        printf "  %-14s %d건\n" "합계:"             "$total_count"
        echo ""
        echo "  JSON 결과: ${json_file}"
        echo "========================================================"
    } >> "$CIS_RESULT_FILE"

    # JSON 생성
    generate_cis_json "$json_file" "$exec_time" "$hostname" "$distro" "$arch" \
        "$CIS_PASS_COUNT" "$CIS_FAIL_COUNT" "$CIS_REVIEW_COUNT" "$total_count"

    # 콘솔 출력
    echo ""
    echo "  [CIS Linux 점검 완료]"
    echo "  ✅ 양호: ${CIS_PASS_COUNT}  ❌ 취약: ${CIS_FAIL_COUNT}  ⚠️  확인필요: ${CIS_REVIEW_COUNT}  (합계: ${total_count})"
    echo "  결과 파일: ${CIS_RESULT_FILE}"
    echo "  JSON 파일: ${json_file}"
}
