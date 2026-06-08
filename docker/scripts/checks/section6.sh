#!/bin/bash
# 섹션 6: Docker 보안 운영 (D-63 ~ D-65)

check_D_63() {
    docker_print_check "D-63"
    local images
    images=$(docker images --format '{{.Repository}}:{{.Tag}} {{.CreatedAt}}' 2>/dev/null | grep -v '<none>')
    if [ -z "$images" ]; then
        docker_record_result "D-63" "REVIEW" "로컬 이미지 없음"
        return
    fi
    # 90일 이상 된 이미지 확인 (createdAt 형식: 2024-01-01 ...)
    local old_images=""
    local threshold_days=90
    local now_epoch
    now_epoch=$(date +%s 2>/dev/null)
    while IFS= read -r line; do
        local img_name img_date
        img_name=$(echo "$line" | awk '{print $1}')
        img_date=$(echo "$line" | awk '{print $2}')
        if [ -n "$img_date" ] && [ -n "$now_epoch" ]; then
            local img_epoch
            img_epoch=$(date -d "$img_date" +%s 2>/dev/null || date -j -f "%Y-%m-%d" "$img_date" +%s 2>/dev/null || echo "0")
            if [ "$img_epoch" -gt 0 ] 2>/dev/null; then
                local age_days=$(( (now_epoch - img_epoch) / 86400 ))
                if [ "$age_days" -gt "$threshold_days" ] 2>/dev/null; then
                    old_images="${old_images}${img_name}(${age_days}일) "
                fi
            fi
        fi
    done <<< "$images"
    if [ -n "$old_images" ]; then
        docker_record_result "D-63" "REVIEW" "${threshold_days}일 이상 된 이미지: ${old_images}"
    else
        docker_record_result "D-63" "PASS" "모든 이미지가 ${threshold_days}일 이내에 업데이트됨"
    fi
}

check_D_64() {
    docker_print_check "D-64"
    local stopped
    stopped=$(docker ps -a --filter "status=exited" --filter "status=dead" --format '{{.Names}}' 2>/dev/null)
    if [ -z "$stopped" ]; then
        docker_record_result "D-64" "PASS" "정지된 컨테이너 없음"
    else
        local count
        count=$(echo "$stopped" | grep -c . || echo "0")
        docker_record_result "D-64" "REVIEW" "정지된 컨테이너 ${count}개 존재 — docker container prune 실행 권장"
    fi
}

check_D_65() {
    docker_print_check "D-65"
    local running_count
    running_count=$(docker ps -q 2>/dev/null | wc -l | tr -d ' ')
    local all_count
    all_count=$(docker ps -aq 2>/dev/null | wc -l | tr -d ' ')
    docker_record_result "D-65" "REVIEW" "실행 중: ${running_count}개 / 전체(정지 포함): ${all_count}개 — 인가된 컨테이너인지 확인 필요"
}
