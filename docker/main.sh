#!/bin/bash

################################################################################
# Docker 보안 점검 진입점 (CIS Docker Benchmark v1.6.0)
################################################################################

DOCKER_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${DOCKER_SCRIPT_DIR}/scripts/common.sh"

# 점검 결과 카운터
DOCKER_PASS_COUNT=0
DOCKER_FAIL_COUNT=0
DOCKER_REVIEW_COUNT=0

run_docker_checks() {
    local exec_time
    exec_time=$(date '+%Y-%m-%d %H:%M:%S')
    local hostname
    hostname=$(hostname 2>/dev/null || echo "unknown")

    # 결과 파일 경로 (main.sh에서 RESULTS_DIR을 설정한 후 호출됨)
    local ts
    ts=$(date '+%Y%m%d_%H%M%S')
    local result_dir="${RESULTS_DIR:-./results}"
    mkdir -p "$result_dir"

    DOCKER_RESULT_FILE="${result_dir}/docker_result_${ts}.txt"
    local json_file="${result_dir}/docker_result_${ts}.json"

    # JSON 임시 파일 초기화
    init_docker_json

    # 헤더 출력
    {
        echo "========================================================"
        echo "  Docker 보안 취약점 점검 보고서"
        echo "  CIS Docker Benchmark v1.6.0 기반"
        echo "========================================================"
        echo ""
        echo "  점검 일시  : ${exec_time}"
        echo "  호스트명   : ${hostname}"
        docker_version_info=$(docker version --format 'Client: {{.Client.Version}} / Server: {{.Server.Version}}' 2>/dev/null || echo "버전 확인 불가")
        echo "  Docker 버전: ${docker_version_info}"
        echo ""
        echo "========================================================"
    } > "$DOCKER_RESULT_FILE"

    # 섹션별 점검 실행
    load_docker_checks

    docker_print_section "1. 호스트 설정 (D-01 ~ D-07)"
    check_D_01; check_D_02; check_D_03; check_D_04
    check_D_05; check_D_06; check_D_07

    docker_print_section "2. Docker 데몬 설정 (D-08 ~ D-25)"
    check_D_08; check_D_09; check_D_10; check_D_11; check_D_12
    check_D_13; check_D_14; check_D_15; check_D_16; check_D_17
    check_D_18; check_D_19; check_D_20; check_D_21; check_D_22
    check_D_23; check_D_24; check_D_25

    docker_print_section "3. 설정 파일 권한 (D-26 ~ D-37)"
    check_D_26; check_D_27; check_D_28; check_D_29; check_D_30
    check_D_31; check_D_32; check_D_33; check_D_34; check_D_35
    check_D_36; check_D_37

    docker_print_section "4. 이미지 및 빌드 (D-38 ~ D-47)"
    check_D_38; check_D_39; check_D_40; check_D_41; check_D_42
    check_D_43; check_D_44; check_D_45; check_D_46; check_D_47

    docker_print_section "5. 컨테이너 런타임 (D-48 ~ D-62)"
    check_D_48; check_D_49; check_D_50; check_D_51; check_D_52
    check_D_53; check_D_54; check_D_55; check_D_56; check_D_57
    check_D_58; check_D_59; check_D_60; check_D_61; check_D_62

    docker_print_section "6. 보안 운영 (D-63 ~ D-65)"
    check_D_63; check_D_64; check_D_65

    docker_print_section "7. Swarm 설정 (D-66 ~ D-68)"
    check_D_66; check_D_67; check_D_68

    # 요약 계산
    local total_count=$((DOCKER_PASS_COUNT + DOCKER_FAIL_COUNT + DOCKER_REVIEW_COUNT))

    # 결과 파일 요약 추가
    {
        echo ""
        echo "========================================================"
        echo "  점검 결과 요약"
        echo "========================================================"
        echo ""
        printf "  %-12s %d건\n" "✅ 양호(PASS):"   "$DOCKER_PASS_COUNT"
        printf "  %-12s %d건\n" "❌ 취약(FAIL):"   "$DOCKER_FAIL_COUNT"
        printf "  %-12s %d건\n" "⚠️  확인필요:"    "$DOCKER_REVIEW_COUNT"
        printf "  %-12s %d건\n" "합계:"             "$total_count"
        echo ""
        echo "  JSON 결과: ${json_file}"
        echo "========================================================"
    } >> "$DOCKER_RESULT_FILE"

    # JSON 생성
    generate_docker_json "$json_file" "$exec_time" "$hostname" \
        "$DOCKER_PASS_COUNT" "$DOCKER_FAIL_COUNT" "$DOCKER_REVIEW_COUNT" "$total_count"

    # 콘솔 출력
    echo ""
    echo "  [Docker 점검 완료]"
    echo "  ✅ 양호: ${DOCKER_PASS_COUNT}  ❌ 취약: ${DOCKER_FAIL_COUNT}  ⚠️  확인필요: ${DOCKER_REVIEW_COUNT}  (합계: ${total_count})"
    echo "  결과 파일: ${DOCKER_RESULT_FILE}"
    echo "  JSON 파일: ${json_file}"
}
