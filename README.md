# Vulnerability Checker

> 주요정보통신기반시설 기술적 취약점 분석·평가 방법 상세가이드 기반
> Unix/Linux/macOS 서버 보안 점검 스크립트 (U-01 ~ U-72)

---

## 목차

- [요구 사항](#요구-사항)
- [프로젝트 구조](#프로젝트-구조)
- [실행 방법](#실행-방법)
- [출력 파일](#출력-파일)
- [점검 항목](#점검-항목)
- [지원 환경](#지원-환경)
- [결과 판정 기준](#결과-판정-기준)

---

## 요구 사항

- **실행 권한**: `root` 또는 `sudo` 필수 (shadow 파일 접근, find 전체 탐색 등)
- **Shell**: `bash 4.0` 이상
- **의존 도구**: `stat`, `awk`, `grep`, `find`, `ss` 또는 `netstat` (대부분 기본 내장)

---

## 프로젝트 구조

```
vuln-checker/
├── main.sh                          # 진입점 — OS 감지, 실행 총괄, 요약 생성
├── scripts/
│   ├── common.sh                    # 공통 함수 라이브러리 (파일 권한, 계정, SSH 등)
│   ├── security_codes.sh            # U-01 ~ U-72 코드·명칭 매핑
│   ├── security_details.sh          # 각 항목별 점검 목적·기준·조치 상세
│   ├── linux.sh                     # Linux 배포판 감지 및 라우팅
│   ├── linux/
│   │   ├── debian.sh                # Debian / Ubuntu
│   │   ├── redhat.sh                # CentOS / RHEL / Rocky / AlmaLinux
│   │   ├── alpine.sh                # Alpine Linux
│   │   └── arch.sh                  # Arch Linux
│   ├── macos.sh                     # macOS (Monterey 이상)
│   └── checks/
│       ├── U-01.sh ~ U-72.sh        # 개별 점검 파일 (72개)
├── results/                         # 점검 결과 저장
│   ├── result_YYYYMMDD_HHMMSS.txt   # 전체 상세 결과
│   └── summary_YYYYMMDD_HHMMSS.md   # 요약 보고서 (Markdown)
├── logs/
│   └── run_YYYYMMDD_HHMMSS.log      # 실행 로그
└── README.md
```

---

## 실행 방법

```bash
# 실행 권한 부여 (최초 1회)
chmod +x main.sh

# root로 직접 실행
sudo ./main.sh
```

root 권한이 없으면 아래 메시지와 함께 즉시 종료됩니다.

```
[오류] 이 스크립트는 root 권한으로 실행해야 합니다.
  실행 방법: sudo ./main.sh
```

---

## 출력 파일

실행이 완료되면 `results/` 디렉토리에 두 파일이 생성됩니다.

### 1. 상세 결과 — `result_YYYYMMDD_HHMMSS.txt`

각 점검 항목의 목적·기준·세부 내용과 판정 결과를 순서대로 기록합니다.

```
[U-01] root 계정 원격 접속 제한

  [ 점검 목적 ]
  관리자 계정 탈취로 인한 시스템 장악을 방지하기 위해 ...

  PermitRootLogin: prohibit-password
  ✅ 점검 결과: 양호
  상세: root 원격 접속이 차단되어 있음 (prohibit-password)
```

### 2. 요약 보고서 — `summary_YYYYMMDD_HHMMSS.md`

전체 통계와 취약·확인필요 항목 목록을 Markdown으로 제공합니다.

```markdown
# 취약점 점검 결과 요약

| 구분       | 건수 | 비율 |
|-----------|-----:|-----:|
| ✅ 양호    |   51 |  70% |
| ❌ 취약    |   15 |  20% |
| ⚠️ 확인필요 |    6 |   8% |
| **합계**  |   72 | 100% |

## ❌ 취약 항목 목록
- **U-02** 비밀번호 관리정책 설정
- **U-06** 사용자 계정 su 기능 제한
...
```

---

## 점검 항목

총 **72개 항목**을 자동으로 점검합니다.

### 1. 계정 관리 (U-01 ~ U-13)

| 코드 | 항목 |
|------|------|
| U-01 | root 계정 원격 접속 제한 |
| U-02 | 비밀번호 관리정책 설정 |
| U-03 | 계정 잠금 임계값 설정 |
| U-04 | 비밀번호 파일 보호 |
| U-05 | root 이외의 UID 0 금지 |
| U-06 | 사용자 계정 su 기능 제한 |
| U-07 | 불필요한 계정 제거 |
| U-08 | 관리자 그룹에 최소한의 계정 포함 |
| U-09 | 계정이 존재하지 않는 GID 금지 |
| U-10 | 동일한 UID 금지 |
| U-11 | 사용자 Shell 점검 |
| U-12 | 세션 종료 시간 설정 |
| U-13 | 안전한 비밀번호 암호화 알고리즘 사용 |

### 2. 파일 및 디렉토리 관리 (U-14 ~ U-33)

| 코드 | 항목 |
|------|------|
| U-14 | root 홈·PATH 디렉터리 권한 및 설정 |
| U-15 | 파일 및 디렉터리 소유자 설정 |
| U-16 | /etc/passwd 파일 소유자 및 권한 설정 |
| U-17 | 시스템 시작 스크립트 권한 설정 |
| U-18 | /etc/shadow 파일 소유자 및 권한 설정 |
| U-19 | /etc/hosts 파일 소유자 및 권한 설정 |
| U-20 | /etc/(x)inetd.conf 파일 소유자 및 권한 설정 |
| U-21 | /etc/(r)syslog.conf 파일 소유자 및 권한 설정 |
| U-22 | /etc/services 파일 소유자 및 권한 설정 |
| U-23 | SUID, SGID, Sticky bit 설정 파일 점검 |
| U-24 | 사용자·시스템 환경변수 파일 소유자 및 권한 설정 |
| U-25 | world writable 파일 점검 |
| U-26 | /dev에 존재하지 않는 device 파일 점검 |
| U-27 | $HOME/.rhosts, hosts.equiv 사용 금지 |
| U-28 | 비활성 사용자 계정 정리 (180일 기준) |
| U-29 | 로그인 셸 설정 |
| U-30 | 기본 계정 보안 설정 |
| U-31 | 홈디렉토리 소유자 및 권한 설정 |
| U-32 | 홈 디렉토리로 지정한 디렉토리의 존재 관리 |
| U-33 | 숨겨진 파일 및 디렉토리 검색 |

### 3. 서비스 관리 (U-34 ~ U-67)

| 코드 | 항목 |
|------|------|
| U-34 | Finger 서비스 비활성화 |
| U-35 | 공유 서비스에 대한 익명 접근 제한 (Anonymous FTP) |
| U-36 | r 계열 서비스 비활성화 (rsh, rlogin, rexec) |
| U-37 | crontab 파일 권한 설정 |
| U-38 | DoS 공격에 취약한 서비스 비활성화 |
| U-39 | 불필요한 NFS 서비스 비활성화 |
| U-40 | NFS 접근 통제 |
| U-41 | automountd 제거 |
| U-42 | 불필요한 RPC 서비스 비활성화 |
| U-43 | NIS, NIS+ 점검 |
| U-44 | tftp, talk 서비스 비활성화 |
| U-45 | 메일 서비스 버전 점검 |
| U-46 | 일반 사용자의 메일 서비스 실행 방지 |
| U-47 | 스팸 메일 릴레이 제한 |
| U-48 | expn, vrfy 명령어 제한 |
| U-49 | DNS 보안 버전 패치 |
| U-50 | DNS Zone Transfer 설정 |
| U-51 | DNS 서비스의 취약한 동적 업데이트 설정 금지 |
| U-52 | Telnet 서비스 비활성화 |
| U-53 | FTP 서비스 정보 노출 제한 |
| U-54 | 암호화되지 않는 FTP 서비스 비활성화 |
| U-55 | FTP 계정 shell 제한 |
| U-56 | FTP 서비스 접근 제어 설정 |
| U-57 | Ftpusers 파일 설정 |
| U-58 | 불필요한 SNMP 서비스 구동 점검 |
| U-59 | 안전한 SNMP 버전 사용 |
| U-60 | SNMP Community String 복잡성 설정 |
| U-61 | SNMP Access Control 설정 |
| U-62 | 로그인 시 경고 메시지 설정 |
| U-63 | sudo 명령어 접근 관리 |
| U-64 | 주기적 보안 패치 및 벤더 권고사항 적용 |
| U-65 | NTP 및 시각 동기화 설정 |
| U-66 | 정책에 따른 시스템 로깅 설정 |
| U-67 | 로그 디렉터리 소유자 및 권한 설정 |

### 4. 기타 보안 (U-68 ~ U-72)

| 코드 | 항목 |
|------|------|
| U-68 | NTP 서비스 보안 설정 |
| U-69 | 로그온 배너 설정 |
| U-70 | 원격 접속 보안 설정 (SSH 세션·인증 강화) |
| U-71 | 불필요한 계정 및 그룹 관리 |
| U-72 | 보안 패치 적용 |

---

## 지원 환경

모든 배포판에서 동일한 72개 점검 항목을 수행하며, 배포판별로 패키지 매니저·보안 모듈 정보를 추가로 수집합니다.

| OS | 배포판 | 추가 수집 정보 |
|----|--------|--------------|
| Linux | Debian / Ubuntu | APT 업데이트 수, unattended-upgrades, AppArmor |
| Linux | CentOS / RHEL / Rocky / AlmaLinux | SELinux 상태, Firewalld |
| Linux | Alpine Linux | APK 업데이트 수 |
| Linux | Arch Linux | Pacman 업데이트 수 |
| macOS | Monterey 이상 | SIP(System Integrity Protection), Gatekeeper |

---

## 결과 판정 기준

| 결과 | 의미 |
|------|------|
| ✅ **양호** | 점검 기준을 충족함 |
| ❌ **취약** | 점검 기준 미충족 — 조치 필요 |
| ⚠️ **확인필요** | 자동 판정 불가 — 담당자가 직접 확인 필요 |

- **양호·취약**은 스크립트가 자동 판정합니다.
- **확인필요**는 서비스 미설치, 환경 차이 등으로 자동 판정이 어려운 경우에 부여됩니다.
- 각 항목의 판단 기준·조치 방법은 상세 결과 파일 내 `[ 판단 기준 ]`, `[ 조치 방법 ]` 항목을 참고하세요.
