# SafePlate Specification (Frontend)

작성 기준일: 2026-03-12

## 1) 서비스 목표

SafePlate는 메뉴판 이미지를 분석해 사용자(또는 팀)의 기피 재료 기준으로 메뉴 위험도를 보여주는 앱이다.  
현재 프론트의 핵심 범위는 아래 4가지다.

- JWT 기반 인증(로그인/회원가입/자동 로그인)
- 자연어 기반 기피재료 관리(텍스트 입력 -> AI 추출 -> 저장)
- 이미지 업로드 + 메뉴 분석 결과 조회
- 분석 히스토리/팀 관리

---

## 2) 현재 라우트/화면 구조

| Route | 화면 | 상태 | 비고 |
|---|---|---|---|
| `/splash` | 스플래시 | 사용 중 | 세션 복원 중 로딩 |
| `/login` | 로그인 | 사용 중 | 인증 실패 메시지 노출 |
| `/signup` | 회원가입 | 사용 중 | 언어(language) 포함 가입 |
| `/home` | 홈/히스토리 | 사용 중 | 분석 진입, 히스토리 삭제, Drawer 기능 |
| `/profile` | 프로필 관리 | 사용 중 | 기피재료 입력/목록 화면 진입 |
| `/profile/avoid-input` | 기피재료 입력 | 사용 중 | 자연어 입력 후 AI 추출 |
| `/profile/avoid-list` | 기피재료 목록 | 사용 중 | 삭제 가능 |
| `/analysis-loading` | 분석 로딩 | 사용 중 | 실패 시 에러 카드 + 복귀 버튼 |
| `/analysis-result` | 분석 결과 | 사용 중 | 메뉴별 안전도/사유 표시 |
| `/camera` | 웹 카메라 | 사용 중 | Web 카메라 촬영 |
| `/history-detail` | 기록 상세 | 사용 중 | 개별 기록 상세 |
| `/teams` | 팀 목록 | 사용 중 | 생성/참여/조회 진입 |
| `/teams/:teamMemberId` | 팀 상세 | 사용 중 | 팀 상세/수정/나가기 |

---

## 3) 핵심 플로우

### 3-1. 인증/세션 복원
1. 앱 시작 시 `authProvider.restoreSession()` 실행
2. Secure Storage의 `accessToken` 존재/만료 확인
3. 유효 세션이면 `/home`, 아니면 `/login` 이동
4. 로그아웃 시 토큰/이메일 삭제 + 인증 상태 초기화

### 3-2. 기피재료 관리(자연어 기반)
1. `/profile/avoid-input`에서 자유 텍스트 입력
2. `POST /avoid-items/my/search`로 AI 추출 요청
3. 추출된 태그를 사용자가 조정(토글)
4. `PUT /avoid-items/my`로 최종 저장
5. `/profile/avoid-list`에서 전체 목록 조회/삭제

### 3-3. 메뉴판 분석
1. 홈에서 개인/팀 기준 선택 후 이미지 촬영/선택
2. `POST /files/presigned-url`로 업로드 URL 발급
3. S3 PUT 업로드 후 `PATCH /files/{id}/status`
4. `POST /restaurant/search`(필요 시 `teamMemberId` 포함)
5. 분석 성공 시 결과 화면 이동, 실패 시 로딩 화면에서 복귀 처리

### 3-4. 히스토리/팀
- 히스토리: `GET /histories?pageNumber`, `DELETE /histories/{id}`
- 팀: 생성/목록/상세/참여/이름변경/나가기 지원

---

## 4) FE-BE API 연동 현황

### 인증
- `POST /auth/login`
- `POST /auth/join`
- `PATCH /members/language`

### 기피재료
- `GET /avoid-items/my`
- `POST /avoid-items/my/search` (자연어 -> 기피재료 추출)
- `PUT /avoid-items/my`

### 파일/분석
- `POST /files/presigned-url`
- `PATCH /files/{fileId}/status`
- `POST /restaurant/search`

### 히스토리
- `GET /histories?pageNumber={n}`
- `DELETE /histories/{historyId}`

### 팀
- `POST /teams`
- `GET /teams?pageNumber={n}`
- `GET /teams/{teamMemberId}`
- `POST /teams/join`
- `PATCH /teams/members/{teamMemberId}`
- `DELETE /teams/members/{teamMemberId}`

참고: 현재 프론트는 외부 AI 엔드포인트를 직접 호출하지 않고, 백엔드의 `POST /restaurant/search`를 통해 분석 결과를 받는다.

---

## 5) 상태 관리/로컬 저장

- 상태관리: Riverpod (`authProvider`, `menuAnalysisProvider`, `historyListProvider`, `avoidItemNotifierProvider`, `team*Provider`)
- 라우팅: GoRouter (인증 상태 기반 redirect)
- 로컬 저장: `FlutterSecureStorage`
  - `accessToken`
  - `userEmail`

---

## 6) 현재 기준 남은 정리 과제(P2)

- 프로필 IA를 "자연어 입력 -> 선택된 재료 관리" 중심으로 단순화
- 개발 로그 정책 확정(`kDebugMode` 제한, 릴리스 전 민감 로그 마스킹/제거)
