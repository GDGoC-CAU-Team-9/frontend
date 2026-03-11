# SafePlate Frontend

SafePlate는 사용자의 기피 식재료(알러지, 종교, 비건 등)를 바탕으로 메뉴판 사진을 분석하여 안전하게 먹을 수 있는 메뉴를 추천해주는 애플리케이션입니다.

## 🚀 시작하기 (Getting Started)

이 프로젝트는 Flutter로 개발되었습니다.

### 개발 환경 필수 조건
- Flutter SDK (최신 Stable 버전 권장)
- Dart SDK
- (옵션) Chrome 브라우저 (웹 빌드 및 디버깅용)

### 웹 플랫폼 디버깅 테스트 실행
로컬 개발 시 백엔드 API와의 CORS 문제(Cross-Origin Resource Sharing)를 우회하기 위해 웹 보안을 비활성화하고 실행합니다.

```bash
flutter run -d chrome --web-browser-flag "--disable-web-security"
```

---

## 🏗️ 주요 기능 안내

- **회원가입/로그인 (JWT 인증)**: 사용자의 이메일, 비밀번호, 언어 설정 관리
- **메뉴판 분석**: 카메라/갤러리에서 메뉴판 이미지를 업로드받아 백엔드(`POST /restaurant/search`)로 전송 및 AI 분석 리포트 수신
- **검색 기록 조회**: 사용자가 이전에 분석했던 메뉴판 사진 리스트와 추천 내역 확인

---

## 📌 현재 구현 상태 요약 (2026-03-12)

- [x] 언어 변경 연동 완료 (`PATCH /members/language`)
- [x] 분석 기록 개별 삭제 연동 완료 (`DELETE /histories/{id}`)
- [x] 인증 가드/자동 로그인 흐름 반영 (앱 시작 시 토큰 기반 라우팅)
- [ ] 남은 핵심 과제는 P2(문서/IA 정리) 중심
- [ ] 백엔드 변경 배포/PR은 별도 담당자 일정에 맞춰 마지막 단계에서 진행

---

## ✅ 개발 우선순위 TODO (2026-03-11)

### P0 (필수)
- [x] 회원가입 에러 처리 버그 수정
  - `auth_provider`에서 `AsyncValue.guard` 반환값을 `state`에 정확히 반영
  - `auth_repository.signUp`에서 `statusCode`/`isSuccess` 검증 후 실패 시 예외 처리
- [x] 로그아웃 시 `accessToken` 삭제 + 인증 상태 초기화
  - Secure Storage 토큰 삭제
  - 인증 상태(`authProvider`) 초기화 후 로그인 화면 이동
- [x] 분석 로딩 화면 실패 핸들링
  - `menuAnalysisProvider` 에러 상태 감지
  - 에러 메시지 표시 + 복귀 버튼(홈 이동) 제공

### P1 (핵심 기능 완성)
- [x] 언어 변경 백엔드 연동
  - FE 언어 선택 시 사용자 언어 변경 API 호출
  - 성공 시 로컬 locale + 서버 저장 언어 동기화
- [x] 히스토리 삭제 API 연동
  - 개별 삭제(`DELETE /histories/{id}`) 또는 전체 삭제 API 연결
  - 홈 기록 카드 삭제 UX(휴지통/스와이프) 반영
- [x] 인증 가드/자동 로그인 흐름 보강
  - 앱 시작 시 토큰 유무 점검 후 초기 라우팅
  - 비인증 상태에서 보호 라우트 접근 차단

### P2 (정합성/UX 정리)
- [x] 레거시 알러지 체크리스트 경로 정리
  - 자연어 입력 기반(`'/profile/avoid-input'`) 흐름을 기본으로 유지
  - 미사용 경로(`'/profile/allergy'`) 및 allergy feature 코드 제거
- [x] 문서 정합성 정리
  - `SPECIFICATION.md`를 실제 구현/API 스코프로 업데이트
- [ ] 프로필 IA 통합
  - 자연어 입력/선택된 재료 중심으로 프로필 메뉴 구조를 단순화

### 개발 중 로그 정책
- [ ] 민감 로그는 개발 종료 전까지 유지 가능
- [ ] 단, `kDebugMode`로 개발 빌드에서만 출력되도록 제한
- [ ] 릴리스 직전 토큰/응답 본문 로그 제거 또는 마스킹 점검

## 소개
SafePlate는 여행지나 낯선 식당에서 **알러지·종교·비건 등 개인/팀 기피 재료를 반영해 안전한 메뉴를 추천**하는 앱입니다. 메뉴판 사진을 찍거나 갤러리에서 선택하면 AI가 텍스트를 추출·분석해 위험 재료를 표시하고, 안심하고 먹을 수 있는 메뉴를 추천해 줍니다. 팀 기능을 통해 모임 구성원의 기피 재료를 합산해 한 번에 검증할 수 있으며, 분석 기록을 리스트로 돌려보며 재주문 여부를 판단할 수 있습니다. Flutter 기반 멀티플랫폼 UI와 Spring Boot 백엔드, S3 업로드·AI 분석 연동으로 구성되어 있습니다.

## 아키텍처
```mermaid
flowchart LR
    subgraph Client[프론트엔드 (Flutter)]
        UI[홈/카메라/팀 관리 UI]
        Storage[SecureStorage\nJWT 저장]
    end

    subgraph Backend[백엔드 (Spring Boot)]
        Auth[Auth API\n/login /join]
        FileAPI[File API\n/presigned-url\n/files/{id}/status]
        Menu[Restaurant Search\n/restaurant/search]
        Team[Team API\n/teams...]
        Hist[History API\n/histories]
        DB[(RDS/DB)]
    end

    subgraph Infra[외부 서비스]
        S3[(S3\n메뉴판 이미지)]
        AI[AI 메뉴 분석\n(HF Space)]
    end

    UI -->|HTTP + JWT| Auth
    UI -->|이미지 업로드 요청| FileAPI
    FileAPI -->|Presigned URL| UI
    UI -->|PUT 이미지| S3
    UI -->|업로드 완료 PATCH| FileAPI
    UI -->|분석 요청\n(ids, teamMemberId)| Menu
    Menu -->|TeamMemberId로 팀 멤버 조회| Team
    Menu -->|멤버/팀 기피재료 조회| DB
    Menu -->|분석 요청(이미지 URL, avoid, lang)| AI
    Menu -->|검색 결과 저장| Hist
    UI -->|기록 조회| Hist
    S3 -->|이미지 URL| Menu
```

요약
- 클라이언트는 JWT를 로컬에 저장하고 모든 API 호출에 붙입니다.
- 이미지 업로드는 Presigned URL을 받아 S3에 직접 PUT 후 상태를 PATCH로 업데이트합니다.
- 메뉴 분석 시 `teamMemberId`를 넘기면 백엔드가 팀 전체 기피 재료를 합산하여 AI에 전달합니다.
- 분석 결과와 업로드 이력은 백엔드 DB에 저장되고 `/histories`로 조회합니다.
