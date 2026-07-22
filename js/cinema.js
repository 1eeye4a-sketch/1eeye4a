/* ============================================================
   cinema.js — LEE YEDA "WEDDING CINEMA" 공통 동작
   낮밤(localStorage 'yeda-mode') · 꽃잎 · 클릭 ♥ · D-Day ·
   편지(inquiries.message 실전송) · 페이지 전환 커버 · 리빌 · FOUC 게이트
   supabase.js 뒤, </body> 직전에 로드
   ============================================================ */
(function () {
  var $ = function (s) { return document.querySelector(s); };
  var $$ = function (s) { return Array.prototype.slice.call(document.querySelectorAll(s)); };
  var CN = window.CN = {};
  var noMotion = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  /* ---- 낮/밤 모드 ---- */
  function syncMode() {
    var d = document.body.classList.contains('day');
    $$('.mode-toggle').forEach(function (b) {
      b.textContent = d ? '☾' : '☀';
      b.setAttribute('aria-label', d ? '이브닝 모드로' : '모닝 모드로');
      b.title = d ? 'EVENING' : 'MORNING';
    });
  }
  syncMode();
  document.addEventListener('click', function (e) {
    var b = e.target.closest('.mode-toggle');
    if (!b) return;
    document.body.classList.toggle('day');
    localStorage.setItem('yeda-mode', document.body.classList.contains('day') ? 'day' : 'night');
    syncMode();
  });

  /* ---- 모바일 메뉴 ---- */
  var toggle = $('.menu-toggle'), nav = $('.main-navigation');
  if (toggle && nav) {
    var closeMenu = function () {
      toggle.setAttribute('aria-expanded', 'false');
      nav.classList.remove('is-open');
    };
    toggle.addEventListener('click', function () {
      var open = toggle.getAttribute('aria-expanded') === 'true';
      toggle.setAttribute('aria-expanded', String(!open));
      nav.classList.toggle('is-open', !open);
    });
    nav.querySelectorAll('a').forEach(function (a) { a.addEventListener('click', closeMenu); });
    document.addEventListener('keydown', function (e) { if (e.key === 'Escape') closeMenu(); });
  }

  /* ---- D-Day 유틸 ---- */
  CN.dday = function (md) {                       // 'MM-DD' → 다음 생일까지 남은 일수
    var p = String(md || '').split('-'); if (p.length < 2) return null;
    var n = new Date(), today = new Date(n.getFullYear(), n.getMonth(), n.getDate());
    var t = new Date(n.getFullYear(), +p[0] - 1, +p[1]);
    if (t < today) t = new Date(n.getFullYear() + 1, +p[0] - 1, +p[1]);
    return Math.round((t - today) / 864e5);
  };
  CN.dplus = function (iso) {                     // 'YYYY-MM-DD' 또는 'YYYY.MM.DD' → 데뷔 D+
    var p = String(iso || '').split(/[-.]/); if (p.length < 3) return null;
    var s = new Date(+p[0], +p[1] - 1, +p[2]);
    var n = new Date(), today = new Date(n.getFullYear(), n.getMonth(), n.getDate());
    return Math.floor((today - s) / 864e5);
  };

  /* ---- SOOP 프사 URL ---- */
  CN.soopAvatar = function (id) {
    id = String(id || '').trim();
    if (!id) return '';
    return 'https://profile.img.sooplive.co.kr/LOGO/' + id.slice(0, 2) + '/' + id + '/' + id + '.jpg';
  };

  /* ---- 값 방어(문자열화) — [object Object] 금지 ---- */
  CN.txt = function (v) {
    if (v == null) return '';
    if (typeof v === 'string' || typeof v === 'number') return String(v);
    if (Array.isArray(v)) return v.map(CN.txt).join(', ');
    if (typeof v === 'object') return Object.values(v).map(CN.txt).join(' ');
    return String(v);
  };
  CN.esc = function (s) {
    return CN.txt(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  };

  /* ---- 꽃잎 ---- */
  var petals = $('#cnPetals');
  if (petals && !noMotion) {
    var GLYPH = ['♥', '❀', '♥', '✿', '♡'];
    for (var i = 0; i < 12; i++) {
      var el = document.createElement('i');
      el.textContent = GLYPH[i % GLYPH.length];
      el.style.left = (Math.random() * 100) + '%';
      el.style.fontSize = (8 + Math.random() * 7) + 'px';
      el.style.animationDuration = (11 + Math.random() * 12) + 's';
      el.style.animationDelay = (-Math.random() * 18) + 's';
      petals.appendChild(el);
    }
  }

  /* ---- 클릭 ♥ ---- */
  CN.pop = function (x, y, n) {
    var fx = $('#cnFx'); if (!fx) return;
    for (var i = 0; i < (n || 1); i++) {
      var p = document.createElement('span');
      p.className = 'cn-pop'; p.textContent = '♥';
      p.style.left = (x + (Math.random() * 26 - 13)) + 'px';
      p.style.top = (y + (Math.random() * 10 - 5)) + 'px';
      fx.appendChild(p);
      (function (q) { setTimeout(function () { q.remove(); }, 900); })(p);
    }
  };
  document.addEventListener('click', function (e) {
    if (e.target.closest('button, a, textarea, input, select, #cnLetter')) return;
    CN.pop(e.clientX, e.clientY, 1);
  });
  CN.bump = function (el) { el.classList.remove('cn-bump'); void el.offsetWidth; el.classList.add('cn-bump'); };

  /* ---- 편지(문의) 모달 ---- */
  var mask = $('#cnMask'), M = $('#cnLetter');
  function openLetter() {
    if (!M) return;
    mask.classList.add('on'); M.classList.add('on'); M.classList.remove('ok');
    var t = $('#cnTa'); if (t) { t.value = ''; setTimeout(function () { t.focus(); }, 120); }
  }
  function closeLetter() { if (!M) return; mask.classList.remove('on'); M.classList.remove('on'); }
  CN.openLetter = openLetter;
  if (M) {
    $$('[data-letter]').forEach(function (b) { b.addEventListener('click', function (e) { e.preventDefault(); openLetter(); }); });
    mask.addEventListener('click', closeLetter);
    var cb = $('#cnClose'); if (cb) cb.addEventListener('click', closeLetter);
    var sb = $('#cnSend');
    if (sb) sb.addEventListener('click', function () {
      var t = $('#cnTa'), v = (t && t.value || '').trim();
      if (!v) { alert('내용을 입력해 주세요!'); return; }
      if (typeof insertRow !== 'function' || (typeof SB_READY !== 'undefined' && !SB_READY)) {
        alert('서버 연결 전이에요 — 키 설정 후 전송할 수 있어요.'); return;
      }
      sb.disabled = true;
      insertRow('inquiries', { message: v }).then(function (ok) {
        sb.disabled = false;
        if (ok) { M.classList.add('ok'); setTimeout(closeLetter, 1500); }
        else alert('전송에 실패했어요. 잠시 후 다시 시도해 주세요.');
      });
    });
    document.addEventListener('keydown', function (e) { if (e.key === 'Escape') closeLetter(); });
  }

  /* ---- 페이지 전환 커버 ---- */
  var cover = document.createElement('div');
  cover.id = 'cnCover';
  cover.innerHTML = '<div class="in"><div class="mono">Lee <b>♥</b> Yeda</div><i></i><div class="cap">NOW SHOWING</div></div>';
  document.body.appendChild(cover);
  document.addEventListener('click', function (e) {
    var a = e.target.closest('a[href]');
    if (!a || noMotion) return;
    var href = a.getAttribute('href');
    if (!href || a.target === '_blank' || href.charAt(0) === '#') return;
    if (/^(https?:|mailto:|tel:)/i.test(href)) return;
    if (a.hasAttribute('data-letter')) return;
    e.preventDefault();
    cover.classList.add('on');
    setTimeout(function () { location.href = href; }, 260);
  });

  /* ---- 스크롤 리빌 + 게이지 ---- */
  function fill(scope) {
    Array.prototype.forEach.call(scope.querySelectorAll('.fl[data-w]'), function (f) {
      if (!f.dataset.done) { f.dataset.done = 1; setTimeout(function () { f.style.width = f.dataset.w + '%'; }, 120); }
    });
  }
  CN.reveal = function () {
    var rvs = $$('.rv');
    if ('IntersectionObserver' in window) {
      var io = new IntersectionObserver(function (es) {
        es.forEach(function (en) {
          if (en.isIntersecting) { en.target.classList.add('in'); fill(en.target); io.unobserve(en.target); }
        });
      }, { threshold: .12 });
      rvs.forEach(function (el) { if (!el.classList.contains('in')) io.observe(el); });
    } else rvs.forEach(function (el) { el.classList.add('in'); fill(el); });
  };
  CN.reveal();

  /* ---- FOUC 게이트 ---- */
  CN.ready = function () {
    if (document.body.classList.contains('ready')) return;
    document.body.classList.add('ready');
    $$('.rv').forEach(function (el) {
      var r = el.getBoundingClientRect();
      if (r.top < window.innerHeight * .92) { el.classList.add('in'); fill(el); }
    });
  };
  if (document.readyState === 'complete') CN.ready();
  else window.addEventListener('load', CN.ready);
  setTimeout(CN.ready, 1600);

  /* ---- 🎨 테마 적용 — profile.data의 theme-* 키를 전 페이지 CSS 변수로 ---- */
  var THEME_MAP={ 'theme-main':'--main','theme-point':'--point','theme-wine':'--wine','theme-deep':'--deep','theme-ink':'--ink' };
  CN.applyTheme=function(d){
    if(!d) return;
    Object.keys(THEME_MAP).forEach(function(k){
      var v=d[k];
      if(typeof v==='string' && /^#[0-9a-fA-F]{6}$/.test(v.trim()))
        document.documentElement.style.setProperty(THEME_MAP[k], v.trim());
    });
  };
  (function(){
    try{
      if(typeof db==='undefined' || (typeof SB_READY!=='undefined' && !SB_READY)) return;
      db.from('profile').select('data').eq('id',1).then(function(res){
        var d=res && res.data && res.data[0] && res.data[0].data;
        if(d) CN.applyTheme(d);
      });
    }catch(e){}
  })();

  /* ---- 연도 ---- */
  var y = $('#copyright-year'); if (y) y.textContent = String(new Date().getFullYear());
})();
