/* =============================================
   supabase.js — Supabase 연동 공통 스크립트
   ✅ 이 파일 상단 두 줄만 본인 값으로 교체!
   ============================================= */

const SUPABASE_URL  = 'https://wtztteyojrhhubztbfam.supabase.co';
const SUPABASE_ANON = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind0enR0ZXlvanJoaHVienRiZmFtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ1NjcyMDksImV4cCI6MjEwMDE0MzIwOX0.g0LQOzdkg-PeLyMASy-M89siecxl9bteqYwEHeTp198';

// ── Supabase 클라이언트 초기화 (키 미설정이면 안전 모드) ──
const SB_READY = typeof supabase !== 'undefined';
const db = SB_READY ? supabase.createClient(SUPABASE_URL, SUPABASE_ANON) : {
  from(){ const q={select:()=>q,order:()=>q,limit:()=>q,eq:()=>q,insert:()=>q,update:()=>q,delete:()=>q,
    then(res){ res({ data:null, error:{ message:'키 미설정' } }); } }; return q; }
};

/* =============================================
   CRUD 헬퍼 함수
   ============================================= */

/** 전체 조회 (최신순)
 *  예) const rows = await fetchAll('schedule');
 */
async function fetchAll(table, options = {}) {
  let query = db.from(table).select('*');
  if (options.order)  query = query.order(options.order, { ascending: options.asc ?? false });
  if (options.limit)  query = query.limit(options.limit);
  if (options.filter) query = query.eq(options.filter.col, options.filter.val);
  const { data, error } = await query;
  if (error) { console.error(`fetchAll(${table}) 오류:`, error); return []; }
  return data;
}

/** 단건 삽입
 *  예) await insertRow('song', { title: '봄날', artist: 'BTS' });
 */
async function insertRow(table, row) {
  const { error } = await db.from(table).insert(row);
  if (error) { console.error(`insertRow(${table}) 오류:`, error); return false; }
  return true;
}

/** 단건 삭제
 *  예) await deleteRow('work', 3);
 */
async function deleteRow(table, id) {
  const { error } = await db.from(table).delete().eq('id', id);
  if (error) { console.error(`deleteRow(${table}) 오류:`, error); return false; }
  return true;
}

/** 단건 수정
 *  예) await updateRow('schedule', 2, { title: '변경된 제목' });
 */
async function updateRow(table, id, updates) {
  const { error } = await db.from(table).update(updates).eq('id', id);
  if (error) { console.error(`updateRow(${table}) 오류:`, error); return false; }
  return true;
}
