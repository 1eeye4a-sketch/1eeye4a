/* =============================================
   supabase.js — Supabase 연동 공통 스크립트
   ✅ 이 파일 상단 두 줄만 본인 값으로 교체!
   ============================================= */

const SUPABASE_URL  = 'https://wtztteyojrhhubztbfam.supabase.co';
const SUPABASE_ANON = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind0enR0ZXlvanJoaHVienRiZmFtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ1NjcyMDksImV4cCI6MjEwMDE0MzIwOX0.g0LQOzdkg-PeLyMASy-M89siecxl9bteqYwEHeTp198';

// ── Supabase 클라이언트 초기화 ──
const { createClient } = supabase;
const db = createClient(SUPABASE_URL, SUPABASE_ANON);

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
  if (error) { console.error(`insertRow(${table}) 오류:`, error); window.__dbErr = error.message; return false; }
  return true;
}

/** 단건 삭제
 *  예) await deleteRow('work', 3);
 */
async function deleteRow(table, id) {
  const { error } = await db.from(table).delete().eq('id', id);
  if (error) { console.error(`deleteRow(${table}) 오류:`, error); window.__dbErr = error.message; return false; }
  return true;
}

/** 단건 수정
 *  예) await updateRow('schedule', 2, { title: '변경된 제목' });
 */
async function updateRow(table, id, updates) {
  const { error } = await db.from(table).update(updates).eq('id', id);
  if (error) { console.error(`updateRow(${table}) 오류:`, error); window.__dbErr = error.message; return false; }
  return true;
}

/* =============================================
   이미지 압축 & 업로드 헬퍼
   ============================================= */

/** 이미지를 가로 maxW px 이하로 줄이고 JPEG로 압축 → Blob 반환
 *  원본이 10MB여도 보통 0.3~0.8MB로 줄어듦
 */
async function compressImage(file, maxW = 1200, quality = 0.8) {
  // GIF(움짤)는 압축하면 정지화면 되니 원본 유지
  if (file.type === 'image/gif') return file;
  try {
    const img = await new Promise((res, rej) => {
      const i = new Image();
      i.onload = () => res(i);
      i.onerror = rej;
      i.src = URL.createObjectURL(file);
    });
    const scale = Math.min(1, maxW / img.width);
    const w = Math.round(img.width * scale);
    const h = Math.round(img.height * scale);
    const canvas = document.createElement('canvas');
    canvas.width = w; canvas.height = h;
    canvas.getContext('2d').drawImage(img, 0, 0, w, h);
    URL.revokeObjectURL(img.src);
    const blob = await new Promise(res => canvas.toBlob(res, 'image/jpeg', quality));
    return blob || file;
  } catch (e) {
    console.error('compressImage 오류:', e);
    return file; // 실패 시 원본 그대로
  }
}

/** 이미지 압축 후 버킷에 업로드 → 공개 URL 반환 (실패 시 null)
 *  folder 예: 'notice', 'diary'
 */
async function uploadImage(file, folder = 'uploads') {
  try {
    const blob = await compressImage(file);
    const rand = Math.random().toString(36).slice(2, 8);
    const path = `${folder}/${Date.now()}_${rand}.jpg`;
    const { error } = await db.storage.from('images').upload(path, blob, {
      upsert: true, contentType: 'image/jpeg'
    });
    if (error) { console.error('uploadImage 오류:', error); return null; }
    const { data } = db.storage.from('images').getPublicUrl(path);
    return data?.publicUrl || null;
  } catch (e) {
    console.error('uploadImage 예외:', e);
    return null;
  }
}

/* ─ 토스트 유틸 ─ */
function showToast(msg, duration = 2500) {
  let t = document.getElementById('toast');
  if (!t) {
    t = document.createElement('div');
    t.id = 'toast'; t.className = 'toast';
    document.body.appendChild(t);
  }
  t.textContent = msg;
  t.classList.add('show');
  setTimeout(() => t.classList.remove('show'), duration);
}

/* ─ iframe 자동 높이 ─ */
function initIframeResize() {
  const send = () =>
    window.parent.postMessage({ type: 'resize', height: document.body.scrollHeight }, '*');
  send();
  new ResizeObserver(send).observe(document.body);
}

/* ─ 호환용 별칭 ─
   일정/노래/일기/업보 페이지는 enableIframeAutoHeight() 라는 이름으로 호출합니다.
   이 별칭이 없으면 그 페이지들에서 "함수 없음" 에러가 나고 iframe 높이가 자동조절되지 않습니다. */
function enableIframeAutoHeight() { initIframeResize(); }
