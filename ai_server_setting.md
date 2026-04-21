# AI Server 연동 점검 메모 (AI5000 기준)

현재 증상은 프론트 문제가 아니라 `메뉴 분석 체인`에서 백엔드가 AI 호출에 실패할 때 발생하는 케이스다.

## 1) 왜 헷갈리는지

- 다른 사람이 성공한 캡처는 `POST /avoid/intake` 성공 화면일 수 있다.
- 그런데 앱 메뉴 분석은 `POST /restaurant/search`를 타고, 백엔드 내부에서 AI `POST /rank`를 호출한다.
- 즉 `avoid/intake` 성공과 `rank` 성공은 별개다.

요약:

```text
/avoid/intake = 텍스트 처리
/rank         = 이미지 다운로드 + OCR/추론 + 결과 이미지 업로드
```

## 2) 지금 로그 해석

프론트 로그에서:

1. `/files/presigned-url` 성공
2. `/files/{id}/status` 성공
3. `/restaurant/search`만 500 + `AI5000`

의미:

- 프론트 업로드 경로/S3 업로드/인증은 동작한다.
- 실패 지점은 백엔드 -> AI(`/rank`) 구간이다.

## 3) 빠른 분리 진단

### A. AI 서버 자체 상태

```bash
curl http://127.0.0.1:7860/health
```

### B. AI `/rank` 직접 테스트

```bash
curl -X POST http://127.0.0.1:7860/rank \
  -H "Content-Type: application/json" \
  -d '{
    "image_url":"<백엔드가 받은 메뉴 이미지 URL>",
    "presigned_url":"<결과 이미지 업로드 presigned url>",
    "avoid":["우유","커피"],
    "user_lang":"ko",
    "menu_lang":"es"
  }'
```

### C. AI 컨테이너 로그

```bash
sudo docker logs --tail=200 safeplate-ai
```

`IMAGE_LOAD_FAILED`, `RANK_PIPELINE_FAILED`, `GOOGLE_API_KEY` 관련 오류를 우선 확인.

### D. 컨테이너 내부에서 이미지 URL 접근 가능 여부

```bash
sudo docker exec -it safeplate-ai curl -I "<image_url>"
```

여기서 실패하면 AI 컨테이너가 이미지를 못 읽는 상태다.

## 4) 백엔드 설정 확인

백엔드 실행 환경에서 아래 값 확인:

```properties
ai-server.url=http://127.0.0.1:7860
avoid.ai.url=http://127.0.0.1:7860
```

설정 변경 후에는 백엔드 재시작 필수.

## 5) 핵심 결론

- `AI5000`은 "연결 자체 문제(AI5001)"가 아니라, 대개 AI가 요청을 받았지만 내부 처리에서 실패한 경우다.
- `avoid/intake` 200만으로 전체 메뉴 분석 성공을 보장하지 않는다.
