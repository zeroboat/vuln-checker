# Vulnerability Checker

> 주요정보통신기반시설 기술적 취약점 분석·평가 방법 상세가이드 기반
> Unix/Linux/macOS/Windows 서버 보안 점검 스크립트 (U-01 ~ U-72 / W-01 ~ W-68)
> Docker 환경 자동 감지 시 CIS Docker Benchmark v1.6.0 기반 점검 스크립트 자동 실행 (D-01 ~ D-68)

🔗 **[결과 뷰어 온라인 데모](https://zeroboat.github.io/vuln-checker/)** — JSON 파일 업로드 없이 링크만으로 보고서 공유 가능

---

## 목차

- [결과 뷰어](#결과-뷰어)
- [요구 사항](#요구-사항)
- [프로젝트 구조](#프로젝트-구조)
- [실행 방법](#실행-방법)
- [출력 파일](#출력-파일)
- [점검 항목](#점검-항목)
- [Docker 점검 (CIS Docker Benchmark)](#docker-점검-cis-docker-benchmark)
- [지원 환경](#지원-환경)
- [결과 판정 기준](#결과-판정-기준)

---

## 결과 뷰어

점검 후 생성된 JSON 파일을 브라우저에서 시각화할 수 있습니다.

**온라인:** [https://zeroboat.github.io/vuln-checker/](https://zeroboat.github.io/vuln-checker/)

**로컬:** `viewer/index.html` 을 브라우저로 직접 열기

> 💡 직접 점검을 돌리지 않아도, 업로드 화면의 **예시 결과 보기** 버튼(주기반 / CIS Linux)으로 대시보드를 바로 체험할 수 있습니다. 예시 데이터는 `viewer/samples/`에 포함되어 있습니다. (로컬에서 `file://`로 열면 브라우저 보안 정책상 예시 로드가 막히므로 GitHub Pages 또는 `python3 -m http.server`로 여세요.)

### 주요 기능

| 기능 | 설명 |
|------|------|
| 📋 예시 결과 보기 | 업로드 없이 주기반·CIS Linux 데모 결과로 대시보드 즉시 체험 |
| 🔴 위험도 점수 | KISA 중요도 가중치 적용 (0~100점) |
| ⚡ Fix-First 액션보드 | FAIL 항목 + 조치 명령어가 첫 화면에 표시, 클립보드 복사 |
| 📊 비교 분석 | 이전·현재 결과 JSON 2개 로드 → 신규 취약/해결/유지 diff 표시 |
| 🔗 링크 공유 | JSON을 URL에 인코딩 — 파일 없이 링크 하나로 보고서 공유 |
| 🌙 다크모드 | 라이트/다크 테마 전환 |
| 📄 PDF 내보내기 | 결과를 PDF로 저장 |

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
├── docker/
│   ├── main.sh                      # Docker 점검 진입점 (main.sh에서 자동 호출)
│   └── scripts/
│       ├── common.sh                # Docker 공통 함수 라이브러리
│       ├── security_codes.sh        # D-01 ~ D-68 코드·명칭 매핑
│       ├── security_details.sh      # 각 항목별 점검 목적·기준·조치 상세
│       └── checks/
│           ├── section1.sh          # 호스트 설정 (D-01 ~ D-07)
│           ├── section2.sh          # 데몬 설정 (D-08 ~ D-25)
│           ├── section3.sh          # 설정 파일 권한 (D-26 ~ D-37)
│           ├── section4.sh          # 이미지 및 빌드 (D-38 ~ D-47)
│           ├── section5.sh          # 컨테이너 런타임 (D-48 ~ D-62)
│           ├── section6.sh          # 보안 운영 (D-63 ~ D-65)
│           └── section7.sh          # Swarm 설정 (D-66 ~ D-68)
├── cis-linux/
│   ├── main.sh                      # CIS Linux 점검 진입점 (--profile cis-linux/all)
│   └── scripts/
│       ├── common.sh                # CIS Linux 공통 함수 라이브러리
│       ├── security_codes.sh        # CL-01 ~ CL-44 코드·명칭 매핑
│       ├── security_details.sh      # 각 항목별 점검 목적·기준·조치 상세
│       └── checks/
│           ├── section1.sh          # 초기 설정 (CL-01 ~ CL-10)
│           ├── section2.sh          # 서비스 (CL-11 ~ CL-17)
│           ├── section3.sh          # 네트워크 설정 (CL-18 ~ CL-26)
│           ├── section4.sh          # 로깅 및 감사 (CL-27 ~ CL-31)
│           ├── section5.sh          # 접근 및 인증 (CL-32 ~ CL-38)
│           └── section6.sh          # 시스템 유지보수 (CL-39 ~ CL-44)
├── windows/
│   ├── main.ps1                     # Windows 진입점 (PowerShell)
│   └── scripts/
│       ├── common.ps1               # 공통 함수
│       ├── security_codes.ps1       # W-01 ~ W-68 코드·명칭 매핑
│       └── checks/
│           └── W-01.ps1 ~ W-68.ps1  # 개별 점검 파일 (68개)
├── viewer/
│   ├── index.html                   # 결과 뷰어 (단일 HTML, CDN 의존)
│   └── samples/                     # 뷰어 예시 결과 (주기반 / CIS Linux)
│       ├── sample_kisa.json
│       └── sample_cis_linux.json
├── results/                         # 점검 결과 저장
│   ├── result_YYYYMMDD_HHMMSS.txt   # 전체 상세 결과
│   ├── result_YYYYMMDD_HHMMSS.json  # JSON 결과 (뷰어용)
│   └── summary_YYYYMMDD_HHMMSS.md   # 요약 보고서 (Markdown)
├── logs/
│   └── run_YYYYMMDD_HHMMSS.log      # 실행 로그
└── README.md
```

---

## 실행 방법

> **요구사항: bash 4.0 이상.** Docker(`D-XX`)·CIS Linux(`CL-XX`) 점검은 연관 배열(`declare -A`)을 사용하므로 bash 4.0+ 가 필요합니다. 대부분의 Linux 배포판은 기본 충족하지만, macOS 기본 bash는 3.2이므로 `--profile docker`/`--profile cis-linux`를 macOS에서 직접 실행하려면 `brew install bash`로 최신 bash를 설치한 뒤 실행하세요. (주기반 `U-XX` 점검은 영향 없음)

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

### 실행 옵션

| 옵션 | 설명 |
|------|------|
| `--profile NAME` | 점검 기준(프로파일) 선택 (기본: `default`) |
| `--parallel` | 병렬 실행 모드 (기본: 순차 실행) |
| `--jobs N`, `-j N` | 병렬 실행 시 동시 작업 수 (기본: 4) |
| `--list-profiles` | 사용 가능한 프로파일 목록 표시 |
| `--help`, `-h` | 도움말 표시 |

### 점검 프로파일

`--profile` 옵션으로 어떤 기준의 점검을 실행할지 선택할 수 있습니다.

| 프로파일 | 점검 대상 | 상태 |
|----------|-----------|------|
| `default` | 주요정보통신기반시설(U-01~U-72) + Docker 자동 감지 | ✅ (기본값) |
| `kisa` | 주요정보통신기반시설 점검만 (U-01~U-72) | ✅ |
| `docker` | Docker CIS Benchmark 점검만 (D-01~D-68) | ✅ |
| `cis-linux` | CIS Linux Benchmark 점검 (CL-01~CL-44) | ✅ |
| `all` | 구현된 모든 기준 실행 (주기반 + Docker + CIS Linux) | ✅ |
| `isms-p` | ISMS-P 기술적 보호조치 | 🚧 준비 중 |

```bash
sudo ./main.sh                      # 기본 (주기반 + Docker 자동감지)
sudo ./main.sh --profile kisa       # 주기반 점검만
sudo ./main.sh --profile docker     # Docker 점검만
sudo ./main.sh --profile cis-linux  # CIS Linux Benchmark 점검만
sudo ./main.sh --profile all        # 모든 기준 실행
sudo ./main.sh --parallel -j 8      # 8개씩 병렬 실행
```

---

## 출력 파일

실행이 완료되면 `results/` 디렉토리에 파일이 생성됩니다. Docker가 감지되면 Docker 전용 결과 파일도 함께 생성됩니다.

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

## Docker 점검 (CIS Docker Benchmark)

`main.sh` 실행 시 호스트에 Docker가 설치·구동 중이면 OS 점검 이후 자동으로 **CIS Docker Benchmark v1.6.0** 기반 점검이 추가로 수행됩니다.

### 자동 실행 조건

- `docker` 바이너리가 PATH에 존재 (`command -v docker`)
- Docker 데몬이 실행 중 (`docker info` 성공)

기본 프로파일(`default`)에서는 별도 옵션 없이 `sudo ./main.sh`만으로 Docker 점검까지 함께 실행됩니다. Docker만 점검하려면 `--profile docker`, OS 점검만 하려면 `--profile kisa`를 사용하세요.

### Docker 점검 결과 파일

Docker 점검 결과는 OS 결과와 **별도 파일**로 저장됩니다.

| 파일 | 설명 |
|------|------|
| `results/docker_result_YYYYMMDD_HHMMSS.txt` | 상세 점검 결과 |
| `results/docker_result_YYYYMMDD_HHMMSS.json` | JSON 결과 (뷰어 업로드 가능) |

뷰어에서 OS 결과와 Docker 결과를 각각 업로드하여 확인하거나, **비교 분석** 기능으로 두 결과를 나란히 볼 수 있습니다.

### Docker 점검 항목 (D-01 ~ D-68)

총 **68개 항목**을 7개 섹션으로 점검합니다.

| 섹션 | 범위 | 항목 수 | 내용 |
|------|------|---------|------|
| 1. 호스트 설정 | D-01 ~ D-07 | 7 | 커널 버전, Docker 전용 파티션, 그룹 멤버, auditd 설정 |
| 2. 데몬 설정 | D-08 ~ D-25 | 18 | ICC, 로깅, iptables, TLS, userns-remap, seccomp 등 |
| 3. 설정 파일 권한 | D-26 ~ D-37 | 12 | docker.service/socket, /etc/docker, TLS 인증서 권한 |
| 4. 이미지 및 빌드 | D-38 ~ D-47 | 10 | non-root 실행, 취약점 스캔, 민감 정보, HEALTHCHECK |
| 5. 컨테이너 런타임 | D-48 ~ D-62 | 15 | privileged, 민감 마운트, SSH, 네트워크 격리, 리소스 제한 |
| 6. 보안 운영 | D-63 ~ D-65 | 3 | 이미지 업데이트, 정지 컨테이너, 컨테이너 수 모니터링 |
| 7. Swarm 설정 | D-66 ~ D-68 | 3 | Swarm 비활성화, 매니저 최소화, Secret 관리 |

### 참고 표준

- **CIS Docker Benchmark v1.6.0** (Center for Internet Security)
- 공식 문서: https://www.cisecurity.org/benchmark/docker

---

## CIS Linux Benchmark 점검

`--profile cis-linux` (또는 `--profile all`) 실행 시 **CIS Linux Benchmark** 기반의 OS 보안 점검이 수행됩니다. 주요정보통신기반시설(U-XX)과는 별개의 국제 표준 기준으로, sysctl 커널 파라미터·마운트 옵션·서비스·감사 설정 등 자동화 친화적인 항목을 점검합니다.

> Linux 환경에서만 의미가 있습니다. macOS 등에서는 일부 항목이 `확인필요`로 처리됩니다.

### CIS Linux 점검 결과 파일

CIS Linux 점검 결과도 **별도 파일**로 저장됩니다.

| 파일 | 설명 |
|------|------|
| `results/cis_linux_result_YYYYMMDD_HHMMSS.txt` | 상세 점검 결과 |
| `results/cis_linux_result_YYYYMMDD_HHMMSS.json` | JSON 결과 (뷰어 업로드 가능) |

### CIS Linux 점검 항목 (CL-01 ~ CL-44)

총 **44개 항목**을 6개 섹션으로 점검합니다.

| 섹션 | 범위 | 항목 수 | 내용 |
|------|------|---------|------|
| 1. 초기 설정 | CL-01 ~ CL-10 | 10 | 파일시스템 모듈, 파티션 분리·마운트 옵션, ASLR, MAC, 배너 |
| 2. 서비스 | CL-11 ~ CL-17 | 7 | inetd, 시간 동기화, 불필요 서버/클라이언트, X Window, rsync |
| 3. 네트워크 설정 | CL-18 ~ CL-26 | 9 | IP 포워딩, 리다이렉트, source route, log_martians, SYN 쿠키, 방화벽 |
| 4. 로깅 및 감사 | CL-27 ~ CL-31 | 5 | auditd, syslog/journald, 로그 권한, audit 저장 정책, logrotate |
| 5. 접근 및 인증 | CL-32 ~ CL-38 | 7 | cron 권한, cron/at 제한, SSH 보안, 패스워드 정책, sudo |
| 6. 시스템 유지보수 | CL-39 ~ CL-44 | 6 | passwd/shadow/group 권한, world-writable, unowned 파일, UID 0 |

### 참고 표준

- **CIS Benchmarks for Linux** (Center for Internet Security)
- 공식 문서: https://www.cisecurity.org/cis-benchmarks

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
