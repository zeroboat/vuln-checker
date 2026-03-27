#!/bin/bash

################################################################################
# macOS-specific Checks
################################################################################

run_macos_checks() {
    local macos_version="$1"

    log "INFO" "macOS 환경 검사 시작..."

    append_log ""
    append_log "=== macOS 검사 ==="
    append_log "OS 버전: ${macos_version}"
    append_log "빌드 번호: $(sw_vers -buildVersion 2>/dev/null)"
    append_log "시스템 아키텍처: $(uname -m)"

    local major_version
    major_version=$(echo "$macos_version" | cut -d'.' -f1)
    log "INFO" "macOS 주 버전: ${major_version}"

    case "$major_version" in
        15) append_log "macOS Sequoia" ;;
        14) append_log "macOS Sonoma" ;;
        13) append_log "macOS Ventura" ;;
        12) append_log "macOS Monterey" ;;
        *)  log "WARNING" "지원하지 않는 macOS 버전: ${macos_version}" ;;
    esac

    # SIP 상태 확인 (macOS 전용)
    if command_exists csrutil; then
        append_log "SIP(System Integrity Protection): $(csrutil status 2>/dev/null)"
    fi

    # Gatekeeper 상태 확인
    if command_exists spctl; then
        append_log "Gatekeeper: $(spctl --status 2>/dev/null)"
    fi

    run_all_checks

    log "INFO" "macOS 검사 완료"

    return 0
}
