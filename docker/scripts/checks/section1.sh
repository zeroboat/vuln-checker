#!/bin/bash
# 섹션 1: 호스트 설정 (D-01 ~ D-07)

check_D_01() {
    docker_print_check "D-01"
    local kernel_ver
    kernel_ver=$(uname -r 2>/dev/null)
    local major minor
    major=$(echo "$kernel_ver" | cut -d. -f1)
    minor=$(echo "$kernel_ver" | cut -d. -f2)
    if [ "${major:-0}" -ge 5 ] 2>/dev/null || { [ "${major:-0}" -eq 4 ] && [ "${minor:-0}" -ge 15 ] 2>/dev/null; }; then
        docker_record_result "D-01" "PASS" "커널 버전: ${kernel_ver}"
    else
        docker_record_result "D-01" "REVIEW" "커널 버전 확인 필요: ${kernel_ver} (권장: 4.15 이상)"
    fi
}

check_D_02() {
    docker_print_check "D-02"
    local docker_partition
    docker_partition=$(df /var/lib/docker 2>/dev/null | awk 'NR==2{print $1}')
    local root_partition
    root_partition=$(df / 2>/dev/null | awk 'NR==2{print $1}')
    if [ -n "$docker_partition" ] && [ "$docker_partition" != "$root_partition" ]; then
        docker_record_result "D-02" "PASS" "/var/lib/docker 전용 파티션 사용 중: ${docker_partition}"
    else
        docker_record_result "D-02" "REVIEW" "/var/lib/docker가 루트 파티션과 동일 — 전용 파티션 분리 권장"
    fi
}

check_D_03() {
    docker_print_check "D-03"
    local docker_members
    docker_members=$(getent group docker 2>/dev/null | cut -d: -f4)
    if [ -z "$docker_members" ]; then
        docker_record_result "D-03" "PASS" "docker 그룹에 일반 사용자 없음"
    else
        local count
        count=$(echo "$docker_members" | tr ',' '\n' | grep -vc '^$' 2>/dev/null || echo "1")
        docker_record_result "D-03" "REVIEW" "docker 그룹 멤버 ${count}명 존재: ${docker_members} — 최소화 확인 필요"
    fi
}

check_D_04() {
    docker_print_check "D-04"
    local docker_bin
    docker_bin=$(which docker 2>/dev/null || echo "/usr/bin/docker")
    if auditctl -l 2>/dev/null | grep -q "$docker_bin"; then
        docker_record_result "D-04" "PASS" "Docker 바이너리 감사 규칙 설정됨: ${docker_bin}"
    else
        docker_record_result "D-04" "REVIEW" "Docker 바이너리 감사 규칙 없음 — auditd 미설치 또는 규칙 미설정"
    fi
}

check_D_05() {
    docker_print_check "D-05"
    if auditctl -l 2>/dev/null | grep -q "/var/lib/docker"; then
        docker_record_result "D-05" "PASS" "/var/lib/docker 감사 규칙 설정됨"
    else
        docker_record_result "D-05" "REVIEW" "/var/lib/docker 감사 규칙 없음"
    fi
}

check_D_06() {
    docker_print_check "D-06"
    if auditctl -l 2>/dev/null | grep -q "/etc/docker"; then
        docker_record_result "D-06" "PASS" "/etc/docker 감사 규칙 설정됨"
    else
        docker_record_result "D-06" "REVIEW" "/etc/docker 감사 규칙 없음"
    fi
}

check_D_07() {
    docker_print_check "D-07"
    local found=false
    for svc_file in /lib/systemd/system/docker.service /usr/lib/systemd/system/docker.service; do
        if [ -f "$svc_file" ] && auditctl -l 2>/dev/null | grep -q "docker.service"; then
            found=true
            break
        fi
    done
    if $found; then
        docker_record_result "D-07" "PASS" "docker.service 감사 규칙 설정됨"
    else
        docker_record_result "D-07" "REVIEW" "docker.service 감사 규칙 없음"
    fi
}
