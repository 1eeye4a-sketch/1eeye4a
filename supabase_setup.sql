-- ============================================================
-- 이예다 WEDDING CINEMA — Supabase 통합 SQL (표 생성 + 접근 권한)
--
-- 실행 순서를 꼭 지켜 주세요
--   ① Supabase → Authentication → Users → Add user 로 관리자 계정 먼저 생성
--      (Auto Confirm User 켜기)
--   ② 그 다음 이 파일 전체를 SQL Editor에 붙여넣고 Run
--   순서를 바꾸면 쓰기 권한이 로그인 계정에만 열린 상태에서 계정이 없어
--   본인도 관리자 페이지에서 저장할 수 없게 됩니다.
--
-- 권한 요약
--   읽기(사이트 표시)       : 누구나
--   등록·수정·삭제          : 로그인한 관리자만 (TO authenticated)
--   편지 보내기             : 누구나
--   편지 열람·삭제          : 관리자만  ← 개인정보
--   노래 메모(song_memos)   : 관리자만 (열람·수정 모두)
--
-- 여러 번 실행해도 안전합니다 (IF NOT EXISTS / DROP POLICY IF EXISTS).
-- ============================================================

-- ① 프로필 (한 행 · id=1 고정 · data JSONB)
CREATE TABLE IF NOT EXISTS profile (
  id   INT PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  data JSONB DEFAULT '{}'::jsonb
);
INSERT INTO profile (id, data) VALUES (1, '{}'::jsonb) ON CONFLICT (id) DO NOTHING;

-- ② 옷장
CREATE TABLE IF NOT EXISTS public.dress_items (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category    TEXT NOT NULL DEFAULT 'hair',
  name        TEXT NOT NULL,
  description TEXT DEFAULT '',
  image_key   TEXT DEFAULT '',
  image_url   TEXT DEFAULT '',
  badges      JSONB DEFAULT '[]',
  is_event    BOOLEAN DEFAULT FALSE,
  glow_color  TEXT DEFAULT '',
  sort_order  INT DEFAULT 0,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_dress_items_category ON public.dress_items(category);

-- ③ 시청자 명단 (업보·시참권·스탬프 공용)
CREATE TABLE IF NOT EXISTS viewers (
  id          BIGSERIAL PRIMARY KEY,
  nickname    TEXT NOT NULL,
  soop_id     TEXT,
  memo        TEXT,
  sort_order  INT DEFAULT 0,
  stamp_count INT DEFAULT 0,
  updated_at  TIMESTAMPTZ DEFAULT NOW(),
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE viewers ADD COLUMN IF NOT EXISTS stamp_count INT DEFAULT 0;
ALTER TABLE viewers ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- ④ 업보 종류 / 부여
CREATE TABLE IF NOT EXISTS upbo_types (
  id BIGSERIAL PRIMARY KEY, name TEXT NOT NULL, category TEXT DEFAULT '일반',
  sort_order INT DEFAULT 0, created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS upbo_counts (
  id BIGSERIAL PRIMARY KEY, viewer_id BIGINT NOT NULL, type_id BIGINT NOT NULL,
  count INT DEFAULT 0, expires DATE, note TEXT, updated_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE upbo_counts DROP CONSTRAINT IF EXISTS upbo_counts_viewer_id_type_id_key;
ALTER TABLE upbo_counts ADD COLUMN IF NOT EXISTS expires DATE;
ALTER TABLE upbo_counts ADD COLUMN IF NOT EXISTS note TEXT;

-- ⑤ 시참권 종류 / 부여
CREATE TABLE IF NOT EXISTS ticket_types (
  id BIGSERIAL PRIMARY KEY, name TEXT NOT NULL, category TEXT DEFAULT '일반',
  sort_order INT DEFAULT 0, created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS ticket_counts (
  id BIGSERIAL PRIMARY KEY, viewer_id BIGINT NOT NULL, type_id BIGINT NOT NULL,
  count INT DEFAULT 0, expires DATE, note TEXT, updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ⑥ 편지함
CREATE TABLE IF NOT EXISTS inquiries (
  id BIGSERIAL PRIMARY KEY, nickname TEXT, message TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ⑦ 스탬프 지급 로그 (도장마다 지급 사유)
CREATE TABLE IF NOT EXISTS stamp_log (
  id BIGSERIAL PRIMARY KEY, viewer_id BIGINT NOT NULL, amount INT NOT NULL DEFAULT 1,
  note TEXT DEFAULT '', created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ⑧ 일정 (월간 캘린더)
CREATE TABLE IF NOT EXISTS schedule_events (
  id BIGSERIAL PRIMARY KEY, date DATE NOT NULL, time TEXT DEFAULT '', title TEXT NOT NULL,
  memo TEXT DEFAULT '', link TEXT DEFAULT '', image_url TEXT DEFAULT '', color TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE schedule_events ADD COLUMN IF NOT EXISTS color TEXT DEFAULT '';
CREATE INDEX IF NOT EXISTS idx_schedule_events_date ON schedule_events(date);

-- ⑨ 안내 게시판
CREATE TABLE IF NOT EXISTS guide_posts (
  id BIGSERIAL PRIMARY KEY, category TEXT DEFAULT '가이드', title TEXT NOT NULL,
  content_html TEXT DEFAULT '', pinned BOOLEAN DEFAULT FALSE, sort_order INT DEFAULT 0,
  updated_at TIMESTAMPTZ DEFAULT NOW(), created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ⑩ 노래책 (공개 정보)
CREATE TABLE IF NOT EXISTS songs (
  id BIGSERIAL PRIMARY KEY, category TEXT DEFAULT '', artist TEXT DEFAULT '', title TEXT NOT NULL,
  genre TEXT DEFAULT '', level TEXT DEFAULT '', mastery TEXT DEFAULT '', price INT DEFAULT 0,
  note TEXT DEFAULT '', memo TEXT DEFAULT '', sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);



-- ============================================================
-- 컬럼 보강
--   이미 만들어져 있는 표는 위의 CREATE TABLE이 건너뛰어집니다.
--   그래서 예전 표에 없던 컬럼을 여기서 채웁니다. (기존 데이터는 그대로)
-- ============================================================
ALTER TABLE profile         ADD COLUMN IF NOT EXISTS data JSONB DEFAULT '{}'::jsonb;

ALTER TABLE dress_items     ADD COLUMN IF NOT EXISTS category TEXT DEFAULT 'hair';
ALTER TABLE dress_items     ADD COLUMN IF NOT EXISTS description TEXT DEFAULT '';
ALTER TABLE dress_items     ADD COLUMN IF NOT EXISTS image_url TEXT DEFAULT '';
ALTER TABLE dress_items     ADD COLUMN IF NOT EXISTS badges JSONB DEFAULT '[]';
ALTER TABLE dress_items     ADD COLUMN IF NOT EXISTS sort_order INT DEFAULT 0;
ALTER TABLE dress_items     ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE viewers         ADD COLUMN IF NOT EXISTS soop_id TEXT;
ALTER TABLE viewers         ADD COLUMN IF NOT EXISTS sort_order INT DEFAULT 0;
ALTER TABLE viewers         ADD COLUMN IF NOT EXISTS stamp_count INT DEFAULT 0;
ALTER TABLE viewers         ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE upbo_types      ADD COLUMN IF NOT EXISTS category TEXT DEFAULT '일반';
ALTER TABLE upbo_types      ADD COLUMN IF NOT EXISTS sort_order INT DEFAULT 0;
ALTER TABLE upbo_counts     ADD COLUMN IF NOT EXISTS expires DATE;
ALTER TABLE upbo_counts     ADD COLUMN IF NOT EXISTS note TEXT;
ALTER TABLE upbo_counts     ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE ticket_types    ADD COLUMN IF NOT EXISTS category TEXT DEFAULT '일반';
ALTER TABLE ticket_types    ADD COLUMN IF NOT EXISTS sort_order INT DEFAULT 0;
ALTER TABLE ticket_counts   ADD COLUMN IF NOT EXISTS expires DATE;
ALTER TABLE ticket_counts   ADD COLUMN IF NOT EXISTS note TEXT;
ALTER TABLE ticket_counts   ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE stamp_log       ADD COLUMN IF NOT EXISTS note TEXT DEFAULT '';
ALTER TABLE stamp_log       ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE schedule_events ADD COLUMN IF NOT EXISTS time TEXT DEFAULT '';
ALTER TABLE schedule_events ADD COLUMN IF NOT EXISTS memo TEXT DEFAULT '';
ALTER TABLE schedule_events ADD COLUMN IF NOT EXISTS link TEXT DEFAULT '';
ALTER TABLE schedule_events ADD COLUMN IF NOT EXISTS image_url TEXT DEFAULT '';
ALTER TABLE schedule_events ADD COLUMN IF NOT EXISTS color TEXT DEFAULT '';

ALTER TABLE guide_posts     ADD COLUMN IF NOT EXISTS category TEXT DEFAULT '가이드';
ALTER TABLE guide_posts     ADD COLUMN IF NOT EXISTS content_html TEXT DEFAULT '';
ALTER TABLE guide_posts     ADD COLUMN IF NOT EXISTS pinned BOOLEAN DEFAULT FALSE;
ALTER TABLE guide_posts     ADD COLUMN IF NOT EXISTS sort_order INT DEFAULT 0;
ALTER TABLE guide_posts     ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- 노래책: 예전 표에는 category/level/mastery/price/note/sort_order 가 없습니다
ALTER TABLE songs           ADD COLUMN IF NOT EXISTS category TEXT DEFAULT '';
ALTER TABLE songs           ADD COLUMN IF NOT EXISTS artist TEXT DEFAULT '';
ALTER TABLE songs           ADD COLUMN IF NOT EXISTS genre TEXT DEFAULT '';
ALTER TABLE songs           ADD COLUMN IF NOT EXISTS level TEXT DEFAULT '';
ALTER TABLE songs           ADD COLUMN IF NOT EXISTS mastery TEXT DEFAULT '';
ALTER TABLE songs           ADD COLUMN IF NOT EXISTS price INT DEFAULT 0;
ALTER TABLE songs           ADD COLUMN IF NOT EXISTS note TEXT DEFAULT '';
ALTER TABLE songs           ADD COLUMN IF NOT EXISTS memo TEXT DEFAULT '';
ALTER TABLE songs           ADD COLUMN IF NOT EXISTS sort_order INT DEFAULT 0;
-- 예전 노래책의 난이도(difficulty 숫자)가 있으면 새 난이도 칸으로 한 번 옮깁니다
DO $mig$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_name='songs' AND column_name='difficulty') THEN
    UPDATE songs SET level = difficulty::text
     WHERE COALESCE(level,'') = '' AND difficulty IS NOT NULL;
  END IF;
END $mig$;

ALTER TABLE inquiries       ADD COLUMN IF NOT EXISTS nickname TEXT;

CREATE INDEX IF NOT EXISTS idx_songs_category ON songs(category);

-- ⑪ 노래 메모 (관리자 전용 — 공개 표와 분리해야 외부에서 못 읽습니다)
CREATE TABLE IF NOT EXISTS song_memos (
  song_id BIGINT PRIMARY KEY, memo TEXT DEFAULT '', updated_at TIMESTAMPTZ DEFAULT NOW()
);
INSERT INTO song_memos (song_id, memo)
SELECT id, memo FROM songs WHERE COALESCE(memo,'') <> ''
ON CONFLICT (song_id) DO NOTHING;
UPDATE songs SET memo = '' WHERE COALESCE(memo,'') <> '';

-- ============================================================
-- 접근 권한 (RLS)
--   anon 키는 브라우저에 공개되는 값이라 숨길 수 없습니다.
--   "누가 무엇을 할 수 있는지"는 여기 DB에서 정합니다.
-- ============================================================

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'profile','dress_items','viewers','upbo_types','upbo_counts',
    'ticket_types','ticket_counts','stamp_log','schedule_events','guide_posts','songs'
  ] LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I', t || '_all', t);
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I', 'dress_all', t);
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I', t || '_read', t);
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I', t || '_write', t);
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I', t || '_modify', t);
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I', t || '_remove', t);
    EXECUTE format('CREATE POLICY %I ON %I FOR SELECT USING (true)', t || '_read', t);
    EXECUTE format('CREATE POLICY %I ON %I FOR INSERT TO authenticated WITH CHECK (true)', t || '_write', t);
    EXECUTE format('CREATE POLICY %I ON %I FOR UPDATE TO authenticated USING (true) WITH CHECK (true)', t || '_modify', t);
    EXECUTE format('CREATE POLICY %I ON %I FOR DELETE TO authenticated USING (true)', t || '_remove', t);
  END LOOP;
END $$;

-- 편지함: 보내기는 누구나, 열람·삭제는 관리자만
ALTER TABLE inquiries ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "inquiries_all" ON inquiries;
DROP POLICY IF EXISTS "inquiries_send" ON inquiries;
DROP POLICY IF EXISTS "inquiries_read" ON inquiries;
DROP POLICY IF EXISTS "inquiries_remove" ON inquiries;
CREATE POLICY "inquiries_send"   ON inquiries FOR INSERT WITH CHECK (true);
CREATE POLICY "inquiries_read"   ON inquiries FOR SELECT TO authenticated USING (true);
CREATE POLICY "inquiries_remove" ON inquiries FOR DELETE TO authenticated USING (true);

-- 노래 메모: 열람까지 관리자만
ALTER TABLE song_memos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "song_memos_all" ON song_memos;
DROP POLICY IF EXISTS "song_memos_admin" ON song_memos;
CREATE POLICY "song_memos_admin" ON song_memos FOR ALL TO authenticated USING (true) WITH CHECK (true);


-- ── 예전 템플릿에서 만들어졌지만 지금은 쓰지 않는 표들 ──
--    (notice · diary · comments · schedule · original_songs · overlay_state)
--    이 표들이 남아 있으면 "누구나 수정·삭제" 정책도 함께 남습니다. 있으면 잠급니다.
DO $legacy$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['notice','diary','comments','schedule','original_songs','overlay_state'] LOOP
    IF to_regclass('public.'||t) IS NOT NULL THEN
      EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
      EXECUTE format('DROP POLICY IF EXISTS %I ON %I', t || '_all', t);
      EXECUTE format('DROP POLICY IF EXISTS %I ON %I', t || '_read', t);
      EXECUTE format('DROP POLICY IF EXISTS %I ON %I', t || '_admin', t);
      EXECUTE format('CREATE POLICY %I ON %I FOR SELECT USING (true)', t || '_read', t);
      EXECUTE format('CREATE POLICY %I ON %I FOR ALL TO authenticated USING (true) WITH CHECK (true)', t || '_admin', t);
    END IF;
  END LOOP;
END $legacy$;

-- 확인용 (선택): 정책이 어떻게 걸렸는지 보기
-- SELECT tablename, policyname, cmd, roles FROM pg_policies WHERE schemaname='public' ORDER BY tablename, cmd;
