# jjajuka-infra

> jjajuka 서비스의 AWS 인프라를 Terraform으로 관리하는 레포지토리입니다.
> _(서비스 소개는 여기에 작성해주세요)_

---

## Architecture

### 인프라 아키텍처

<img width="1103" height="894" alt="Image" src="https://github.com/user-attachments/assets/6eb15537-188c-438e-af26-7cb9c4b485c5" />

### 네트워크 및 보안 구조

<img width="410" height="533" alt="Image" src="https://github.com/user-attachments/assets/9853c518-92ec-407c-bc23-da2e0115e4f5" />

### CI/CD 파이프라인

<img width="446" height="482" alt="Image" src="https://github.com/user-attachments/assets/d4123894-76ff-4406-9928-1f49108fc9ce" />

**트래픽 흐름**

```
User
 └── ALB (HTTPS 443 / HTTP 80 → 301 redirect)
      ├── /* → Frontend EC2 (port 3000)
      └── /api/* → Backend EC2 (port 8888)
                        └── AI EC2 (port 8000, internal only)
                        └── RDS MySQL (private subnet, port 3306)
```

---

## 📌 설계 포인트

- 프리티어 한도 내 비용 최소화
- 개발환경은 단일 구성, 운영환경은 일부 이중화 (RDS Multi-AZ)
- 보안 요건을 고려한 서브넷 분리 (Public/Private)
- NAT Gateway 미사용으로 네트워크 비용 최소화 (인스턴스 Public 서브넷 배치),
  - 계층적 Security Group으로 인바운드 접근 제어

- SSH 미오픈, SSM Session Manager로만 인스턴스 접근
- 최소 권한 IAM
- CloudWatch, EventBridge Rules → SNS로 장애 감지 및 알림 구성
- 개발 환경 비용 절감을 위한 EC2/RDS 자동 정지/시작 스케줄러 구성
  - EC2: EventBridge Scheduler → EC2 API 직접 호출
  - RDS: EventBridge Rules → Lambda

### 보안 요건

- DB 퍼블릭 노출 차단 → RDS Private Subnet 배치
- HTTPS 적용 → ALB + ACM (Wildcard 인증서)
- 시크릿 관리 → SSM Parameter Store

---

## 📌 Design Decisions

**SSH 미사용, SSM Session Manager로 접근**
EC2에 SSH 포트(22)를 열지 않고 AWS SSM을 통해서만 접속합니다. 키 관리 부담을 없애고 접근 이력이 CloudTrail에 기록됩니다.

**RDS Private 서브넷 배치**
데이터베이스는 인터넷 라우팅이 없는 Private 서브넷에 배치하고, Backend EC2 Security Group에서만 접근을 허용합니다.

**Security Group 계층 구조**
ALB → Frontend/Backend → AI 방향으로만 통신을 허용하여, AI 서비스가 인터넷 또는 ALB에 직접 노출되지 않습니다.

**GitHub Actions CD: OIDC + SSM Send Command**
GitHub Actions에서 AWS Access Key를 직접 발급하지 않고 OIDC(OpenID Connect)로 임시 자격증명을 발급받습니다. ECR push 후 `ssm:SendCommand`로 EC2에 docker pull/run 명령을 원격 실행하여 배포합니다. OIDC Role의 권한은 dev ECR 레포지토리 3개와 SSM 명령 실행으로만 한정했습니다.

**SSM Parameter Store로 시크릿 관리**
DB 접속 정보, API 키 등 민감한 값을 SSM Parameter Store(SecureString)에 저장하고, EC2 IAM 역할을 통해 런타임에 읽어옵니다.

**AI 서버 EIP 부착**
Backend 서버가 AI 서버의 IP를 환경변수로 참조합니다. AI 인스턴스가 재시작되면 퍼블릭 IP가 바뀌어 Backend 환경변수를 수정하고 재배포해야 하는 문제가 발생합니다. EIP로 고정 IP를 부여하여 AI 서버가 재시작되어도 Backend 환경변수 변경 없이 통신이 유지됩니다. Internal ALB 구성도 검토했으나 해커톤 일정상 EIP로 간단하게 해결했습니다.

**CloudWatch Alarms + SNS로 장애 감지**
EC2 CPU 과부하 및 상태 이상, RDS CPU/스토리지/연결 수에 대한 알람을 구성하고 SNS 이메일 구독으로 알림을 수신합니다. 알람 복구 시에도 OK 알림을 발송하여 정상화 여부를 확인할 수 있습니다. `terraform apply` 후 수신 이메일에서 구독 확인(Confirm subscription)이 필요합니다.

**EC2/RDS 자동 정지·시작 스케줄러 (비용 절감)**

RDS는 `EventBridge Rules → Lambda` 구조로 정상 동작한다. EC2는 처음에 `EventBridge Rules → SSM Automation → EC2` 구조로 설계했으나 끝내 동작하지 않았고, 원인도 명확히 파악하지 못했다.

돌이켜보면 이 설계 자체가 문제였다. 실제 요구사항은 **"특정 시간에 EC2를 껐다 켜기"** 라는 단순한 것이었는데, SSM Automation은 그 용도에 맞지 않았다.

- 조건 분기, 승인 프로세스, 운영 Runbook이 필요한 상황이 아니었다
- 디버깅 경로가 `EventBridge Rules → IAM(EventBridge) → SSM Automation → IAM(SSM) → EC2 API` 로 실패 지점이 5개 이상이었고, 4시간 넘게 소요됐다
- SSM Automation을 도입해서 얻는 이점이 이 문제에서는 없었다

단순한 문제를 너무 어렵게 풀려고 했다. 결국 `EventBridge Scheduler → EC2 API 직접 호출` 로 구조를 교체했고, IAM role 하나에 StopInstances/StartInstances 권한만 부여하는 형태로 단순화했다.

---

## Tech Stack

| Category          | Tool / Service                                |
| ----------------- | --------------------------------------------- |
| IaC               | Terraform >= 1.10.0                           |
| Cloud             | AWS (ap-northeast-2)                          |
| Compute           | EC2 (Amazon Linux 2023)                       |
| Container         | Docker, Amazon ECR                            |
| Load Balancer     | ALB (Application Load Balancer)               |
| Database          | RDS MySQL                                     |
| DNS / TLS         | 가비아, ACM (Wildcard Certificate)            |
| Secret Management | SSM Parameter Store                           |
| Access            | AWS Systems Manager (Session Manager, no SSH) |
| Monitoring        | CloudWatch Alarms, SNS, EventBridge           |

---

## Directory Structure

```
jjajuka-infra/
├── envs/
│   ├── global/         # 전역 공유 리소스 (ACM 인증서)
│   ├── dev/            # 개발 환경
│   └── prod/           # 운영 환경
└── modules/
    ├── acm/            # ACM TLS 인증서
    ├── vpc/            # VPC, 서브넷, 라우팅
    ├── ecr/            # ECR 레포지토리 (frontend / backend / ai)
    ├── backend/        # EC2 인스턴스, ALB, Security Group, IAM
    ├── database/       # RDS MySQL, DB Subnet Group, Security Group
    └── monitoring/     # SNS Topic, CloudWatch Alarms (EC2 / RDS), EventBridge
```

각 환경(`dev`, `prod`)은 독립된 `terraform.tfstate`를 가지며, 동일한 모듈을 재사용합니다.
`global` 환경은 ACM 인증서처럼 환경에 무관하게 공유되는 리소스를 관리합니다.

---

## Modules

### `vpc`

- VPC, Internet Gateway, Public/Private 서브넷 2개씩, 라우팅 테이블 구성
- Public 서브넷: ALB, EC2 배치
- Private 서브넷: RDS 배치 (인터넷 접근 차단)

### `ecr`

- `frontend`, `backend`, `ai` 3개 레포지토리를 `for_each`로 생성

### `backend`

- EC2 인스턴스 3개 (Frontend / Backend / AI)
- ALB: HTTP(80) → HTTPS(301) 리다이렉트, HTTPS(443) 리스너
- ALB 라우팅 룰: `/api/*` → Backend, 그 외 → Frontend
- Security Group 계층 분리:
  - ALB SG ← 인터넷 (80, 443)
  - Frontend SG ← ALB SG만 허용
  - Backend SG ← ALB SG만 허용 (지정 포트)
  - AI SG ← Backend SG만 허용 (내부 통신)
- AI 인스턴스에 EIP 부착 (고정 퍼블릭 IP)
- IAM Instance Profile: SSM Session Manager + ECR ReadOnly 권한만 부여 (최소 권한 원칙)
- EC2 접속: SSH 키 없이 SSM Session Manager로만 접근

### `database`

- RDS MySQL, Private 서브넷 배치
- Security Group: Backend EC2 SG에서만 인바운드 허용
- DB 접속 정보는 SSM Parameter Store에 저장 (평문 환경변수 미사용)

### `acm`

- `jjajuka.site`, `*.jjajuka.site` 와일드카드 인증서 발급 (DNS 검증)
- `global` 환경에서 한 번 발급 후, 각 환경에서 `data` 소스로 참조

### `ssm` (각 환경 내 `ssm.tf`)

Terraform으로 관리하지만 별도 모듈이 아닌 환경 디렉토리(`envs/dev`, `envs/prod`)에 직접 선언됩니다.

EC2 애플리케이션이 런타임에 읽는 SSM Parameter Store 값을 생성합니다. 파라미터 경로 규칙: `/{app}/{env}/{KEY}`

| Parameter                          | Type         | 설명                                   | 사용 서버 |
| ---------------------------------- | ------------ | -------------------------------------- | --------- |
| `/{app}/{env}/DB_HOST`             | String       | RDS 엔드포인트                         | Backend   |
| `/{app}/{env}/DB_NAME`             | String       | DB명 (`{app}`)                         | Backend   |
| `/{app}/{env}/DB_USERNAME`         | String       | DB 유저명                              | Backend   |
| `/{app}/{env}/DB_PASSWORD`         | SecureString | DB 비밀번호 (암호화)                   | Backend   |
| `/{app}/{env}/DB_PORT`             | String       | DB 포트 (3306)                         | Backend   |
| `/{app}/{env}/DISCORD_WEBHOOK_URL` | SecureString | Discord 알림 Webhook (암호화)          | Backend   |
| `/{app}/{env}/AI_BASE_URL`         | String       | AI 서버 EIP 주소 (`http://<EIP>:8000`) | Backend   |
| `/{app}/{env}/GOOGLE_API_KEY`      | SecureString | Google API Key (암호화)                | AI        |

### `monitoring`

- SNS Topic + 이메일 구독으로 알림 수신 채널 구성
- **CloudWatch Alarms → SNS 직접**: CPU, StatusCheckFailed, RDS 스토리지/연결 수 등 메트릭 임계치 초과 시
  - EC2 알람 (frontend / app / ai 공통): CPU > 80% (5분 평균, 2회 연속), StatusCheckFailed >= 1
  - RDS 알람: CPU > 80%, FreeStorageSpace < 2GB, DatabaseConnections > 100
  - 알람 복구 시에도 OK 알림 발송
- **EventBridge Rules (`aws_cloudwatch_event_rule`) → SNS 직접**: 상태 변경 이벤트 감지
  - EC2 stopped / terminated 이벤트 감지 (instance-id 기반 필터링)
  - RDS 정지(EVENT-0087) / 시작(EVENT-0088) 이벤트 감지

> CloudWatch와 EventBridge Rules는 각각 독립적으로 SNS에 직접 연결됩니다. CloudWatch → EventBridge → SNS 구조가 아닙니다.

### `scheduler` _(modules/monitoring 내 관리)_

비용 절감을 위해 개발 환경 리소스를 야간에 자동 정지하고 낮에 재시작합니다.

- **EC2**: EventBridge Scheduler (`aws_scheduler_schedule`) → EC2 API 직접 호출 (`scheduler.tf`)
  - 신규 스케줄 전용 서비스, `schedule_expression_timezone = "Asia/Seoul"` 지정 가능 (UTC 변환 불필요)
  - 정지: KST 01:00 (`cron(0 1 * * ? *)`)
  - 시작: KST 13:00 (`cron(0 13 * * ? *)`)
  - IAM: `scheduler_ec2` role (`scheduler.amazonaws.com`) — StopInstances/StartInstances 권한
- **RDS**: EventBridge Rules (`aws_cloudwatch_event_rule`, schedule_expression) → Lambda (`rds_scheduler.py`) (`eventbridge.tf`)
  - 구형 EventBridge 방식, cron 표현식은 UTC 기준
  - 정지: UTC 16:00 = KST 01:00 (`cron(0 16 * * ? *)`)
  - 프리-스타트: UTC 03:50 = KST 12:50 (`cron(50 3 * * ? *)`)

---

## Environments

| Resource                | dev         | prod        |
| ----------------------- | ----------- | ----------- |
| VPC CIDR                | 10.0.0.0/16 | 10.1.0.0/16 |
| ECR                     | ✅          | ✅          |
| ALB + EC2               | ✅          | ✅          |
| RDS MySQL               | ✅          | ✅          |
| SSM Parameters          | ✅          | ✅          |
| CloudWatch Alarms + SNS | ✅          | ✅          |
| Multi-AZ RDS            | ❌          | ✅          |

---

## How to Deploy

### 사전 조건

- Terraform >= 1.10.0
- AWS CLI 설정 완료 (`aws configure`)
- `terraform.tfvars` 파일에 변수 값 입력

### 배포 순서

**1. 인증서 발급 (최초 1회)**

```bash
cd envs/global
terraform init
terraform apply
```

**2. 환경 프로비저닝**

```bash
cd envs/dev   # 또는 envs/prod
terraform init
terraform plan
terraform apply
```

> **주의:** `terraform apply` 후 아래 순서로 AI EIP를 tfvars에 반영해야 합니다.
>
> ```bash
> terraform output ai_eip
> # 출력된 IP를 terraform.tfvars의 AI_BASE_URL에 입력
> # AI_BASE_URL = "http://<출력된 EIP>:8000"
> terraform apply
> ```
>
> SSM Parameter Store의 `AI_BASE_URL`이 올바른 EIP로 업데이트됩니다.
> 이후 deploy.sh 작성 후 배포 진행해주세요.

### 주요 변수 (`terraform.tfvars`)

| Variable                        | Description                    |
| ------------------------------- | ------------------------------ |
| `ami`                           | EC2 AMI ID (Amazon Linux 2023) |
| `MYSQL_USER` / `MYSQL_PASSWORD` | RDS 접속 정보                  |
| `discord_webhook_url`           | 알림용 Discord Webhook         |
| `google_api_key`                | AI 서비스용 Google API Key     |
| `alert_email`                   | CloudWatch 알림 수신 이메일    |

> 민감한 변수는 `.gitignore`에 추가하거나 별도로 관리하세요.

---

## Manually Managed Resources

Terraform으로 관리하지 않고 AWS 콘솔에서 수동으로 생성한 리소스입니다.

| Resource               | Description                                                                                                          |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------- |
| OIDC Identity Provider | GitHub Actions → AWS 연동을 위한 OIDC Provider 및 IAM Role. AWS 자격증명 없이 아래 권한으로 CI/CD 수행               |
| DNS (가비아)           | `jjajuka.site` 도메인의 DNS 레코드를 가비아에서 직접 관리. ACM 인증서 DNS 검증용 CNAME 및 ALB 연결용 CNAME 설정 포함 |

**OIDC Role 권한 (최소 권한 원칙 적용)**

| Permission                           | 용도                                               |
| ------------------------------------ | -------------------------------------------------- |
| `ec2:DescribeInstances`              | 배포 대상 EC2 인스턴스 ID 조회                     |
| `ecr:GetAuthorizationToken`          | ECR 로그인                                         |
| `ecr:BatchCheck / Upload / PutImage` | ECR 이미지 push (dev 레포지토리 3개로 리소스 한정) |
| `ssm:SendCommand`                    | EC2에 docker pull / run 명령 원격 실행             |
| `ssm:GetCommandInvocation`           | SSM 명령 실행 결과 확인                            |

**IAM User Group: `jjajuka-developer`**

jiyeon, jihye, ujin, jyu 유저가 소속되어 있습니다.

| Permission                                                                 | 용도                                   |
| -------------------------------------------------------------------------- | -------------------------------------- |
| `ec2:DescribeInstances`                                                    | EC2 인스턴스 목록 조회                 |
| `ssm:StartSession` (EC2, `tier=backend` 태그 조건)                         | SSM Session Manager로 backend EC2 접속 |
| `ssm:StartSession` (`AWS-StartPortForwardingSessionToRemoteHost` 도큐먼트) | SSM 포트 포워딩 세션 시작              |
| `ssm:TerminateSession` / `ssm:ResumeSession` (본인 세션만)                 | 본인이 시작한 SSM 세션 종료 및 재개    |

**가비아 DNS 레코드 설정**

| 구분            | 호스트                    | 타입  | 값                  |
| --------------- | ------------------------- | ----- | ------------------- |
| ACM 인증서 검증 | (ACM 콘솔에서 확인)       | CNAME | (ACM 콘솔에서 확인) |
| prod ALB 연결   | `@` (또는 `jjajuka.site`) | CNAME | prod ALB DNS 주소   |
| dev ALB 연결    | `dev`                     | CNAME | dev ALB DNS 주소    |

> ALB DNS 주소는 `terraform output` 또는 AWS 콘솔 → EC2 → Load Balancers에서 확인할 수 있습니다.
> 수동 생성 리소스는 변경 시 이 문서에 반영해주세요.

---

## 현재 발생하고 있는 이슈

### `userdata` 실행 시 ssm-user docker 권한 미부여

인스턴스가 userdata로 초기화될 때 `usermod -aG docker ssm-user` 명령이 실행되지만, ssm-user는 첫 SSM 세션 접속 시 생성되는 계정이라 **userdata 실행 시점에는 존재하지 않아** docker 그룹 추가가 실패합니다.

**증상**

- SSM Session Manager로 접속 후 `docker` 명령 실행 시 permission denied 발생

**현재 임시 대응**

- SSM 세션 접속 후 수동으로 아래 명령 실행

```bash
sudo usermod -aG docker ssm-user
```

**미해결**

---

## 한계

### 신뢰성 (Reliability)

- **EC2 단일 인스턴스**: ASG 없이 역할당 인스턴스 1개 — 장애 시 자동 복구 불가, 수동 재시작 필요. ALB 타겟그룹도 수동 관리
- **RDS 백업 미설정**: `skip_final_snapshot = true` — `terraform destroy` 시 최종 스냅샷 없이 삭제됨
- **단일 AZ 구성 (dev)**: AZ 장애 발생 시 서비스 전체 중단
- **스케줄러 false positive**: EC2/RDS 자동 정지 시 EventBridge state-change 알람이 함께 발송됨 (정상 정지임에도 알림 수신)

### 성능 효율성 (Performance Efficiency)

- **수평 확장 불가**: ASG 미구성으로 트래픽 급증 시 인스턴스 타입 수동 변경만 가능
- **AI 서버 단일 장애점**: Backend → AI 통신이 EIP 직접 호출 방식 — Internal ALB 없이 AI 인스턴스 1대에 의존
- **고정 인스턴스 타입**: t3.small 고정으로 부하에 따른 탄력적 조정 불가

### 비용 최적화 (Cost Optimization)

- **EIP 정지 중 요금 발생**: EC2 정지 시간(야간)에도 연결되지 않은 EIP에 대해 시간당 /bin/zsh.005 요금 부과
- **RDS gp2 스토리지**: gp3 전환 시 동일 성능에 약 20% 비용 절감 가능
- **CloudWatch 로그 보존 기간 미설정**: Lambda 로그 그룹에 보존 기간 미지정 시 무기한 보관으로 비용 증가 가능

### 운영 구조

- 환경별 `main.tf` 단일 state로 모든 리소스 관리 — 특정 리소스만 제거 시 `-target` 필요 (`terraform destroy -target module.database`)
- Terraform state 로컬 관리 — 추후 협업 및 동시 작업 불가, Remote Backend 전환 검토 필요
