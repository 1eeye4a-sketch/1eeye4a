-- ============================================================
-- 이예다 WEDDING CINEMA 사이트 — Supabase 통합 SQL (신규 설치용)
-- SQL Editor에 전체 붙여넣고 한 번 Run
-- ※ 기존 예다 DB(매거진 버전에서 patch_v2·v3까지 실행한 프로젝트)를
--    그대로 쓰는 경우에도 Run 해도 안전해요 (IF NOT EXISTS) — 데이터 유지됨
-- ============================================================

-- ① 프로필 (한 행 · id=1 고정 · data JSONB)
CREATE TABLE IF NOT EXISTS profile (
  id   INT PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  data JSONB DEFAULT '{}'::jsonb
);
ALTER TABLE profile ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "profile_all" ON profile;
CREATE POLICY "profile_all" ON profile FOR ALL USING (true) WITH CHECK (true);
INSERT INTO profile (id, data) VALUES (1, '{}'::jsonb) ON CONFLICT (id) DO NOTHING;

-- ② 옷장
CREATE TABLE IF NOT EXISTS public.dress_items (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category    TEXT NOT NULL DEFAULT 'hair',   -- hair / outfit / lens
  name        TEXT NOT NULL,
  description TEXT DEFAULT '',
  image_key   TEXT DEFAULT '',
  image_url   TEXT DEFAULT '',
  badges      JSONB DEFAULT '[]',             -- [{"label":"NEW"}] 이면 새 옷(포스터)
  is_event    BOOLEAN DEFAULT FALSE,
  glow_color  TEXT DEFAULT '',
  sort_order  INT DEFAULT 0,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_dress_items_category ON public.dress_items(category);
ALTER TABLE public.dress_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "dress_all" ON public.dress_items;
CREATE POLICY "dress_all" ON public.dress_items FOR ALL USING (true) WITH CHECK (true);

-- ③ 시청자 명단 (업보·시참권·스탬프 공용 · stamp_count 포함)
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
ALTER TABLE viewers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "viewers_all" ON viewers;
CREATE POLICY "viewers_all" ON viewers FOR ALL USING (true) WITH CHECK (true);
-- (기존 DB 대비 컬럼 보강 — 이미 있으면 무시됨)
ALTER TABLE viewers ADD COLUMN IF NOT EXISTS stamp_count INT DEFAULT 0;
ALTER TABLE viewers ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- ④ 업보 종류 / 부여 (개별 항목 · 기한 · 비고)
CREATE TABLE IF NOT EXISTS upbo_types (
  id         BIGSERIAL PRIMARY KEY,
  name       TEXT NOT NULL,
  category   TEXT DEFAULT '일반',             -- 일반 / 이벤트
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE upbo_types ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "upbo_types_all" ON upbo_types;
CREATE POLICY "upbo_types_all" ON upbo_types FOR ALL USING (true) WITH CHECK (true);

CREATE TABLE IF NOT EXISTS upbo_counts (
  id         BIGSERIAL PRIMARY KEY,
  viewer_id  BIGINT NOT NULL,
  type_id    BIGINT NOT NULL,
  count      INT DEFAULT 0,
  expires    DATE,                             -- 비우면 무기한
  note       TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE upbo_counts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "upbo_counts_all" ON upbo_counts;
CREATE POLICY "upbo_counts_all" ON upbo_counts FOR ALL USING (true) WITH CHECK (true);
-- (기존 DB 대비 보강: (viewer,type) 유니크 해제 + 컬럼 추가)
ALTER TABLE upbo_counts DROP CONSTRAINT IF EXISTS upbo_counts_viewer_id_type_id_key;
ALTER TABLE upbo_counts ADD COLUMN IF NOT EXISTS expires DATE;
ALTER TABLE upbo_counts ADD COLUMN IF NOT EXISTS note TEXT;

-- ⑤ 시참권 종류 / 부여 (업보와 동일 구조 · 명단은 viewers 공유)
CREATE TABLE IF NOT EXISTS ticket_types (
  id         BIGSERIAL PRIMARY KEY,
  name       TEXT NOT NULL,
  category   TEXT DEFAULT '일반',
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE ticket_types ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "ticket_types_all" ON ticket_types;
CREATE POLICY "ticket_types_all" ON ticket_types FOR ALL USING (true) WITH CHECK (true);

CREATE TABLE IF NOT EXISTS ticket_counts (
  id         BIGSERIAL PRIMARY KEY,
  viewer_id  BIGINT NOT NULL,
  type_id    BIGINT NOT NULL,
  count      INT DEFAULT 0,
  expires    DATE,
  note       TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE ticket_counts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "ticket_counts_all" ON ticket_counts;
CREATE POLICY "ticket_counts_all" ON ticket_counts FOR ALL USING (true) WITH CHECK (true);

-- ⑥ 편지함 (문의)
CREATE TABLE IF NOT EXISTS inquiries (
  id         BIGSERIAL PRIMARY KEY,
  nickname   TEXT,
  message    TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE inquiries ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "inquiries_all" ON inquiries;
CREATE POLICY "inquiries_all" ON inquiries FOR ALL USING (true) WITH CHECK (true);

-- ⑦ 스탬프 지급 로그 (v2 — 도장마다 비고가 붙는 구조)
--    개수 = 로그 amount 합계 · 각 도장 칸에 지급 사유(note)가 연결돼요
CREATE TABLE IF NOT EXISTS stamp_log (
  id         BIGSERIAL PRIMARY KEY,
  viewer_id  BIGINT NOT NULL,
  amount     INT NOT NULL DEFAULT 1,
  note       TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE stamp_log ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "stamp_log_all" ON stamp_log;
CREATE POLICY "stamp_log_all" ON stamp_log FOR ALL USING (true) WITH CHECK (true);

-- ⑧ 일정 (월간 캘린더)
CREATE TABLE IF NOT EXISTS schedule_events (
  id         BIGSERIAL PRIMARY KEY,
  date       DATE NOT NULL,
  time       TEXT DEFAULT '',
  title      TEXT NOT NULL,
  memo       TEXT DEFAULT '',
  link       TEXT DEFAULT '',
  image_url  TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_schedule_events_date ON schedule_events(date);
ALTER TABLE schedule_events ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "schedule_events_all" ON schedule_events;
CREATE POLICY "schedule_events_all" ON schedule_events FOR ALL USING (true) WITH CHECK (true);
