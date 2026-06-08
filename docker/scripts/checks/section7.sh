#!/bin/bash
# 섹션 7: Swarm 설정 (D-66 ~ D-68)

check_D_66() {
    docker_print_check "D-66"
    local swarm_status
    swarm_status=$(docker info 2>/dev/null | grep -i "Swarm:" | awk '{print $2}')
    if [ "$swarm_status" = "inactive" ] || [ -z "$swarm_status" ]; then
        docker_record_result "D-66" "PASS" "Swarm 모드 비활성화됨"
    else
        docker_record_result "D-66" "REVIEW" "Swarm 모드 활성화됨: ${swarm_status} — 미사용 시 비활성화 권장 (docker swarm leave --force)"
    fi
}

check_D_67() {
    docker_print_check "D-67"
    local swarm_status
    swarm_status=$(docker info 2>/dev/null | grep -i "Swarm:" | awk '{print $2}')
    if [ "$swarm_status" != "active" ]; then
        docker_record_result "D-67" "PASS" "Swarm 미사용 — 매니저 노드 점검 불필요"
        return
    fi
    local manager_count
    manager_count=$(docker node ls 2>/dev/null | grep -c "Leader\|Reachable" || echo "0")
    if [ "$manager_count" -le 3 ] 2>/dev/null; then
        docker_record_result "D-67" "PASS" "매니저 노드 ${manager_count}개 (권장: 1, 3, 5 중 홀수)"
    else
        docker_record_result "D-67" "REVIEW" "매니저 노드 ${manager_count}개 — 최소화 권장 (현재 노드 강등: docker node demote <node>)"
    fi
}

check_D_68() {
    docker_print_check "D-68"
    local swarm_status
    swarm_status=$(docker info 2>/dev/null | grep -i "Swarm:" | awk '{print $2}')
    if [ "$swarm_status" != "active" ]; then
        docker_record_result "D-68" "PASS" "Swarm 미사용 — Secret 관리 점검 불필요"
        return
    fi
    local secret_count
    secret_count=$(docker secret ls 2>/dev/null | grep -vc '^ID' || echo "0")
    if [ "$secret_count" -gt 0 ] 2>/dev/null; then
        docker_record_result "D-68" "PASS" "Docker Secret 사용 중 (${secret_count}개)"
    else
        docker_record_result "D-68" "REVIEW" "Docker Secret 미사용 — 민감 정보를 Secret으로 관리 권장"
    fi
}
