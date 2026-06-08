#!/bin/bash
# 섹션 4: 컨테이너 이미지 및 빌드 (D-38 ~ D-47)

check_D_38() {
    docker_print_check "D-38"
    local containers
    containers=$(get_running_containers)
    if [ -z "$containers" ]; then
        docker_record_result "D-38" "REVIEW" "실행 중인 컨테이너 없음"
        return
    fi
    local fail_list=""
    for cid in $containers; do
        local readonly
        readonly=$(docker inspect "$cid" 2>/dev/null | grep '"ReadonlyRootfs"' | grep -o 'true\|false' | head -1)
        if [ "$readonly" != "true" ]; then
            local name
            name=$(docker inspect "$cid" 2>/dev/null | grep '"Name"' | head -1 | sed 's/.*: "\(.*\)".*/\1/')
            fail_list="${fail_list}${name} "
        fi
    done
    if [ -z "$fail_list" ]; then
        docker_record_result "D-38" "PASS" "모든 컨테이너 ReadonlyRootfs 설정됨"
    else
        docker_record_result "D-38" "REVIEW" "읽기 전용 루트 미설정 컨테이너: ${fail_list}"
    fi
}

check_D_39() {
    docker_print_check "D-39"
    local images
    images=$(docker images --format '{{.Repository}}:{{.Tag}}' 2>/dev/null | grep -v '^<none>')
    if [ -z "$images" ]; then
        docker_record_result "D-39" "PASS" "로컬 이미지 없음"
        return
    fi
    docker_record_result "D-39" "REVIEW" "이미지 출처를 수동으로 확인하세요: $(echo "$images" | head -5 | tr '\n' ' ')"
}

check_D_40() {
    docker_print_check "D-40"
    docker_record_result "D-40" "REVIEW" "이미지 내 불필요한 패키지는 Dockerfile 리뷰 필요 — 자동 판정 불가"
}

check_D_41() {
    docker_print_check "D-41"
    if docker_command_exists "docker" && docker scout version >/dev/null 2>&1; then
        docker_record_result "D-41" "REVIEW" "docker scout cves <image>으로 취약점 스캔 실행 권장"
    elif docker_command_exists "trivy"; then
        docker_record_result "D-41" "REVIEW" "trivy image <image>으로 취약점 스캔 실행 권장"
    else
        docker_record_result "D-41" "REVIEW" "취약점 스캐너(docker scout/trivy) 미설치 — 별도 스캔 필요"
    fi
}

check_D_42() {
    docker_print_check "D-42"
    local containers
    containers=$(get_running_containers)
    if [ -z "$containers" ]; then
        docker_record_result "D-42" "REVIEW" "실행 중인 컨테이너 없음"
        return
    fi
    local root_list=""
    for cid in $containers; do
        local user
        user=$(docker inspect "$cid" 2>/dev/null | grep '"User"' | head -1 | sed 's/.*: "\(.*\)".*/\1/' | tr -d ' ')
        if [ -z "$user" ] || [ "$user" = "0" ] || [ "$user" = "root" ]; then
            local name
            name=$(docker inspect "$cid" 2>/dev/null | grep '"Name"' | head -1 | sed 's/.*: "\(.*\)".*/\1/')
            root_list="${root_list}${name} "
        fi
    done
    if [ -z "$root_list" ]; then
        docker_record_result "D-42" "PASS" "모든 컨테이너가 non-root 사용자로 실행 중"
    else
        docker_record_result "D-42" "FAIL" "root로 실행 중인 컨테이너: ${root_list}"
    fi
}

check_D_43() {
    docker_print_check "D-43"
    local latest_images
    latest_images=$(docker images --format '{{.Repository}}:{{.Tag}}' 2>/dev/null | grep ':latest$')
    if [ -z "$latest_images" ]; then
        docker_record_result "D-43" "PASS" "latest 태그 이미지 없음"
    else
        local count
        count=$(echo "$latest_images" | grep -c ':latest' || echo "0")
        docker_record_result "D-43" "REVIEW" "latest 태그 이미지 ${count}개 — 명시적 버전 태그 사용 권장"
    fi
}

check_D_44() {
    docker_print_check "D-44"
    local containers
    containers=$(get_running_containers)
    if [ -z "$containers" ]; then
        docker_record_result "D-44" "REVIEW" "실행 중인 컨테이너 없음"
        return
    fi
    local no_health=""
    for cid in $containers; do
        local health
        health=$(docker inspect "$cid" 2>/dev/null | grep -A2 '"Healthcheck"' | grep '"Test"')
        if [ -z "$health" ]; then
            local name
            name=$(docker inspect "$cid" 2>/dev/null | grep '"Name"' | head -1 | sed 's/.*: "\(.*\)".*/\1/')
            no_health="${no_health}${name} "
        fi
    done
    if [ -z "$no_health" ]; then
        docker_record_result "D-44" "PASS" "모든 컨테이너에 HEALTHCHECK 설정됨"
    else
        docker_record_result "D-44" "REVIEW" "HEALTHCHECK 미설정 컨테이너: ${no_health}"
    fi
}

check_D_45() {
    docker_print_check "D-45"
    local images
    images=$(docker images -q 2>/dev/null | head -5)
    if [ -z "$images" ]; then
        docker_record_result "D-45" "REVIEW" "검사할 이미지 없음"
        return
    fi
    docker_record_result "D-45" "REVIEW" "setuid/setgid 바이너리는 수동 확인 필요: docker run --rm <image> find / -perm /6000 -type f 2>/dev/null"
}

check_D_46() {
    docker_print_check "D-46"
    docker_record_result "D-46" "REVIEW" "Dockerfile의 ADD 지시어 사용 여부는 소스코드 리뷰 필요 — 자동 판정 불가"
}

check_D_47() {
    docker_print_check "D-47"
    local images
    images=$(docker images --format '{{.Repository}}:{{.Tag}}' 2>/dev/null | grep -v '<none>' | head -10)
    if [ -z "$images" ]; then
        docker_record_result "D-47" "REVIEW" "검사할 이미지 없음"
        return
    fi
    local found_sensitive=""
    for img in $images; do
        local history
        history=$(docker history --no-trunc "$img" 2>/dev/null | grep -iE 'password|passwd|secret|token|api.?key|credential' | grep -iv 'grep\|comment')
        if [ -n "$history" ]; then
            found_sensitive="${found_sensitive}${img} "
        fi
    done
    if [ -n "$found_sensitive" ]; then
        docker_record_result "D-47" "FAIL" "이미지 레이어에 민감 정보 의심 키워드 발견: ${found_sensitive}"
    else
        docker_record_result "D-47" "PASS" "이미지 레이어에서 명백한 민감 정보 없음 (완전한 검사는 수동 확인 권장)"
    fi
}
