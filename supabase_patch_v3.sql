-- ============================================
-- 이예다 사이트 v3 패치 SQL
-- (v2 패치까지 Run 한 DB에서 "이것만" 한 번 Run)
-- 내용: 스탬프 명단을 업보 시청자 명단(viewers)과 통합
-- ============================================

-- ① viewers 에 스탬프 개수·갱신일 컬럼 추가
ALTER TABLE viewers ADD COLUMN IF NOT EXISTS stamp_count INT DEFAULT 0;
ALTER TABLE viewers ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- ② 기존 stamps 명단이 있었다면 viewers 로 이관 (닉네임 기준 · 없던 사람은 새로 추가)
INSERT INTO viewers (nickname, soop_id, sort_order, stamp_count)
SELECT s.nickname, s.soop_id, s.sort_order, COALESCE(s.count,0)
FROM stamps s
WHERE NOT EXISTS (SELECT 1 FROM viewers v WHERE v.nickname = s.nickname);

UPDATE viewers v SET stamp_count = COALESCE(s.count,0)
FROM stamps s WHERE v.nickname = s.nickname;

-- ③ (선택) 이관 확인 후 옛 stamps 표는 직접 지워도 돼요 — 남겨둬도 무해
-- DROP TABLE IF EXISTS stamps;
