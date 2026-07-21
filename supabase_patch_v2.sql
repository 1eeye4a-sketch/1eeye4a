-- ============================================
-- 이예다 사이트 v2 패치 SQL
-- (이미 supabase_setup.sql 을 Run 한 DB에서 "이것만" 한 번 Run)
-- 내용: 업보 개별항목화(사용기한·비고) + 시참권 + 스탬프
-- ============================================

-- ① 업보: 같은 업보를 기한별로 각각 등록할 수 있게 (viewer,type) 유니크 해제 + 컬럼 추가
ALTER TABLE upbo_counts DROP CONSTRAINT IF EXISTS upbo_counts_viewer_id_type_id_key;
ALTER TABLE upbo_counts ADD COLUMN IF NOT EXISTS expires DATE;   -- 사용 기한 (비우면 무기한)
ALTER TABLE upbo_counts ADD COLUMN IF NOT EXISTS note TEXT;      -- 비고

-- ② 시참권 (업보와 동일 구조 · 별개 운영, 시청자 명단은 viewers 공유)
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

-- ③ 스탬프 명단 (닉네임·SOOP아이디·개수)
CREATE TABLE IF NOT EXISTS stamps (
  id         BIGSERIAL PRIMARY KEY,
  nickname   TEXT NOT NULL,
  soop_id    TEXT,
  count      INT DEFAULT 0,
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE stamps ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "stamps_all" ON stamps;
CREATE POLICY "stamps_all" ON stamps FOR ALL USING (true) WITH CHECK (true);
