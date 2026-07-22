# 이예다 WEDDING CINEMA 사이트 — 셋업 순서

## 0. 페이지 구성
- `index.html` 메인(웨딩 시네마) · `profile/` 프로필 · `schedule/` 일정(캘린더) · `dress/` 옷장 · `work/` 업보 · `ticket/` 시참권 · `stamp/` 스탬프 · `admin/` 관리자 콘솔
- 공통: `css/cinema.css` · `js/cinema.js` · `supabase.js` · `assets/`
- ☀/☾ 버튼 = EVENING(버건디 시네마) / MORNING(아이보리 브라이덜) 모드 — 방문자 브라우저에 저장돼요

## 1. 키 꽂는 곳 (2파일)
1. **`supabase.js` 상단 2줄** — Supabase 프로젝트 ID + anon public 키
2. **`admin/index.html`** — `ADMIN_PASSWORD = '{{관리자비밀번호}}'` (소스에 보이므로 버리는 비번!)

## 2. Supabase
- 기존 예다 프로젝트를 그대로 쓰면: SQL Editor에서 `supabase_setup.sql` 한 번 Run (IF NOT EXISTS라 데이터 유지 · 부족한 컬럼만 보강)
- 새 프로젝트면: 동일하게 `supabase_setup.sql` 한 번 Run

## 3. GitHub + Cloudflare Pages
- 이 폴더 구조 그대로 저장소에 업로드 (`.github/workflows/keep-alive.yml` 포함)
- 저장소 Settings → Secrets → Actions 에 `SUPABASE_URL` / `SUPABASE_ANON` 등록 (무료 티어 절전 방지)
- Cloudflare Pages → Connect to Git → 빌드 설정 비움(Framework = None) → Deploy
- 재배포: 파일 덮어쓰기 → Commit → 1~2분 → Ctrl+Shift+R

## 4. admin 사용 요약
- 🎀 프로필: 기본 정보 · 소개 · 능력치(`이름:숫자`) · 주간 상영표 · 진행·참여 컨텐츠(`날짜|제목|링크`) · 링크
- 📅 일정: 등록(날짜·시간·제목·메모·링크·이미지) · 🔁 매주 반복(요일+종료일) · ⧉ 날짜 복사 · 자주 쓰는 문구 · 키워드 검색 — 페이지에서는 메모가 마우스 오버 툴팁으로 떠요
- 👗 옷장: 추가/순서(▲▼)/NEW 전환/삭제 — 이미지는 SOOP 게시판 "이미지 주소 복사"
- 📜 업보: 시청자 명단(공용) · 업보 종류 · 부여(개수·기한·비고, −/＋ 조절)
- 🎟 시참권: 종류 · 부여 (명단은 업보 탭 공용)
- 💌 스탬프: 시청자 골라 **개수+비고(지급 사유)로 지급** — 한 번에 여러 개 지급하면 그 도장 전부에 같은 비고가 붙어요(페이지에서 도장 호버 시 표시) · 지급 내역 삭제로 정정 · 안내 문구/보상 편집
- 📮 편지함: 문의 확인/삭제
- 🎨 테마: 5색 팔레트 — 저장하면 전 페이지 CSS 변수로 즉시 적용

## 5. 시청자 프라이버시
- 업보·시참권·스탬프는 **검색 전에는 명단이 노출되지 않아요** — 닉네임/아이디를 검색해야 본인 기록이 열려요.
