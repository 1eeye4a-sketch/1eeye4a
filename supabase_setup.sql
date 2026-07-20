-- =============================================================
-- 버추얼 팬페이지 템플릿 — Supabase 전체 셋업 SQL (한 번에 붙여넣기용)
-- 사용법: Supabase → SQL Editor → 아래 전체 복붙 → Run.
-- ✅ 여러 번 다시 실행해도 안전 (CREATE ... IF NOT EXISTS / DROP POLICY IF EXISTS).
-- ✅ 모든 표는 anon(공개) 키로 읽기+쓰기 허용 — 관리자 페이지가 anon 키로 동작하므로 필수.
-- 안 쓰는 카테고리가 있어도 표는 그냥 둬도 무방(빈 표는 아무 영향 없음).
-- 이미지는 "링크" 방식이라 Storage(버킷) 없이도 동작합니다.
-- =============================================================


-- ── 프로필 (메인: id=1 한 칸에 JSON 저장) ──
CREATE TABLE IF NOT EXISTS profile (
  id         BIGINT PRIMARY KEY,
  data       JSONB NOT NULL DEFAULT '{}'::jsonb,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE profile ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "profile_all" ON profile;
CREATE POLICY "profile_all" ON profile FOR ALL USING (true) WITH CHECK (true);


-- ── 공지 ──
CREATE TABLE IF NOT EXISTS notice (
  id         BIGSERIAL PRIMARY KEY,
  title      TEXT NOT NULL,
  content    TEXT,
  pinned     BOOLEAN DEFAULT FALSE,
  image_url  TEXT,
  images     JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE notice ADD COLUMN IF NOT EXISTS image_url TEXT;
ALTER TABLE notice ADD COLUMN IF NOT EXISTS images JSONB DEFAULT '[]'::jsonb;
ALTER TABLE notice ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "notice_all" ON notice;
CREATE POLICY "notice_all" ON notice FOR ALL USING (true) WITH CHECK (true);


-- ── 일기 ──
CREATE TABLE IF NOT EXISTS diary (
  id         BIGSERIAL PRIMARY KEY,
  title      TEXT NOT NULL,
  content    TEXT,
  mood       TEXT,
  diary_date DATE,
  image_url  TEXT,
  images     JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE diary ADD COLUMN IF NOT EXISTS image_url TEXT;
ALTER TABLE diary ADD COLUMN IF NOT EXISTS images JSONB DEFAULT '[]'::jsonb;
ALTER TABLE diary ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "diary_all" ON diary;
CREATE POLICY "diary_all" ON diary FOR ALL USING (true) WITH CHECK (true);


-- ── 일기 댓글 (일기 페이지에서 사용) ──
CREATE TABLE IF NOT EXISTS comments (
  id         BIGSERIAL PRIMARY KEY,
  diary_id   BIGINT NOT NULL,
  nickname   TEXT,
  message    TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "comments_all" ON comments;
CREATE POLICY "comments_all" ON comments FOR ALL USING (true) WITH CHECK (true);


-- ── 일정 (달력) — 색/하이라이트/2부/설명 포함 ──
CREATE TABLE IF NOT EXISTS schedule (
  id          BIGSERIAL PRIMARY KEY,
  title       TEXT NOT NULL,
  date        DATE NOT NULL,
  time        TEXT,
  type        TEXT DEFAULT '일반',          -- 일반 / 특별 / 콜라보 / 휴방
  note        TEXT,
  color       TEXT DEFAULT 'green',
  highlight   BOOLEAN DEFAULT FALSE,
  time2       TEXT,
  title2      TEXT,
  type2       TEXT,
  description TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE schedule ADD COLUMN IF NOT EXISTS color       TEXT DEFAULT 'green';
ALTER TABLE schedule ADD COLUMN IF NOT EXISTS color2      TEXT DEFAULT 'blue';
ALTER TABLE schedule ADD COLUMN IF NOT EXISTS highlight   BOOLEAN DEFAULT FALSE;
ALTER TABLE schedule ADD COLUMN IF NOT EXISTS time2       TEXT;
ALTER TABLE schedule ADD COLUMN IF NOT EXISTS title2      TEXT;
ALTER TABLE schedule ADD COLUMN IF NOT EXISTS type2       TEXT;
ALTER TABLE schedule ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE schedule ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "schedule_all" ON schedule;
CREATE POLICY "schedule_all" ON schedule FOR ALL USING (true) WITH CHECK (true);


-- ── 노래책: 커버곡 ──
CREATE TABLE IF NOT EXISTS songs (
  id         BIGSERIAL PRIMARY KEY,
  title      TEXT NOT NULL,
  artist     TEXT,
  genre      TEXT DEFAULT '기타',
  difficulty INT  DEFAULT 3,
  memo       TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE songs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "songs_all" ON songs;
CREATE POLICY "songs_all" ON songs FOR ALL USING (true) WITH CHECK (true);


-- ── 노래책: 오리지널 곡 (SOOP VOD) ──
CREATE TABLE IF NOT EXISTS original_songs (
  id         BIGSERIAL PRIMARY KEY,
  title      TEXT NOT NULL,
  vod_id     TEXT,
  thumbnail  TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE original_songs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "original_songs_all" ON original_songs;
CREATE POLICY "original_songs_all" ON original_songs FOR ALL USING (true) WITH CHECK (true);


-- ── 옷장 (헤어 / 렌즈 / 의상) — 이미지는 image_url(링크) ──
CREATE TABLE IF NOT EXISTS public.dress_items (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category    TEXT NOT NULL DEFAULT 'hair',   -- hair / lens / outfit
  name        TEXT NOT NULL,
  description TEXT DEFAULT '',
  image_key   TEXT DEFAULT '',                -- (안 씀) R2용 키
  image_url   TEXT DEFAULT '',                -- 이미지 링크(붙여넣은 주소)
  badges      JSONB DEFAULT '[]',             -- 예: [{"label":"NEW"}]
  is_event    BOOLEAN DEFAULT FALSE,
  glow_color  TEXT DEFAULT '',
  sort_order  INT DEFAULT 0,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_dress_items_category ON public.dress_items(category);
ALTER TABLE public.dress_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "dress_all" ON public.dress_items;
CREATE POLICY "dress_all" ON public.dress_items FOR ALL USING (true) WITH CHECK (true);


-- ── 업보: 시청자 ──
CREATE TABLE IF NOT EXISTS viewers (
  id         BIGSERIAL PRIMARY KEY,
  nickname   TEXT NOT NULL,
  soop_id    TEXT,
  memo       TEXT,
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE viewers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "viewers_all" ON viewers;
CREATE POLICY "viewers_all" ON viewers FOR ALL USING (true) WITH CHECK (true);


-- ── 업보: 타입(종류) ──
CREATE TABLE IF NOT EXISTS upbo_types (
  id         BIGSERIAL PRIMARY KEY,
  name       TEXT NOT NULL,
  category   TEXT DEFAULT '일반',            -- 일반 / 이벤트
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE upbo_types ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "upbo_types_all" ON upbo_types;
CREATE POLICY "upbo_types_all" ON upbo_types FOR ALL USING (true) WITH CHECK (true);


-- ── 업보: 카운트 (시청자 × 타입 = 횟수) ──
CREATE TABLE IF NOT EXISTS upbo_counts (
  id         BIGSERIAL PRIMARY KEY,
  viewer_id  BIGINT NOT NULL,
  type_id    BIGINT NOT NULL,
  count      INT DEFAULT 0,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (viewer_id, type_id)
);
ALTER TABLE upbo_counts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "upbo_counts_all" ON upbo_counts;
CREATE POLICY "upbo_counts_all" ON upbo_counts FOR ALL USING (true) WITH CHECK (true);


-- ── 문의함 ──
CREATE TABLE IF NOT EXISTS inquiries (
  id         BIGSERIAL PRIMARY KEY,
  nickname   TEXT,
  message    TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE inquiries ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "inquiries_all" ON inquiries;
CREATE POLICY "inquiries_all" ON inquiries FOR ALL USING (true) WITH CHECK (true);


-- ── (옷장 OBS 오버레이 쓸 때만) "지금 트는 노래" 상태 1행 ──
CREATE TABLE IF NOT EXISTS public.overlay_state (
  id          INT PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  song_title  TEXT DEFAULT '',
  song_artist TEXT DEFAULT '',
  is_visible  BOOLEAN DEFAULT FALSE,          -- ⚠️ OBS에 보이려면 true
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);
INSERT INTO public.overlay_state (id) VALUES (1) ON CONFLICT (id) DO NOTHING;
ALTER TABLE public.overlay_state ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "overlay_all" ON public.overlay_state;
CREATE POLICY "overlay_all" ON public.overlay_state FOR ALL USING (true) WITH CHECK (true);


-- ── 프로필 기본 행(id=1) 보장 ──
-- ⚠️ 한 Supabase 프로젝트는 "한 사람"에게만 쓰세요.
--    이미 다른 사람 데이터가 들어있는 프로젝트를 재사용하면, 아래 INSERT는
--    DO NOTHING 때문에 옛 데이터를 덮어쓰지 않습니다(= 프사·이름이 옛 사람으로 보임).
--    새 사람으로 갈아끼울 땐, 아래 줄의 맨 앞 '--' 를 지워서 한 번 실행하면 프로필이 비워집니다.
-- DELETE FROM profile WHERE id = 1;
INSERT INTO profile (id, data) VALUES (1, '{}'::jsonb) ON CONFLICT (id) DO NOTHING;

-- 끝! 이미지는 전부 "링크" 방식이라 Storage 설정이 필요 없습니다.
