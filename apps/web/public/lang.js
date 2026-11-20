// Ngôn ngữ của sound.tsudev.com (PRODUCT_POLICY mục 1): tiếng Việt ở `/`, tiếng Anh ở `/en/`.
// - Lần vào đầu (chưa lưu lựa chọn): theo ngôn ngữ trình duyệt (`navigator.languages`, cùng nguồn với Accept-Language);
//   có tiếng Việt đứng trước ⇒ vi, ngôn ngữ khác/chưa hỗ trợ ⇒ en. Lưu ngay để chỉ tự chọn MỘT lần.
// - Đã lưu (bấm bộ chọn ngôn ngữ ở chân trang) ⇒ lựa chọn đó thắng.
// - KHÔNG theo IP; trình thu thập (bot) không bị chuyển; trang không có bản tương ứng (404) không bị chuyển.
// Nạp CHẶN trong <head> (không defer) để chuyển trước khung hình đầu. Tệp cùng nguồn: CSP chỉ cần script-src 'self'.
(function () {
  'use strict';
  var KHOA = 'sounddb-lang';
  var HO_TRO = ['vi', 'en'];
  var goc = document.documentElement;
  var dang = goc.getAttribute('lang') === 'en' ? 'en' : 'vi';

  function docLuu() {
    try {
      var v = window.localStorage.getItem(KHOA);
      return HO_TRO.indexOf(v) >= 0 ? v : null;
    } catch (e) {
      return null;
    }
  }
  function luu(v) {
    try { window.localStorage.setItem(KHOA, v); } catch (e) { /* bị chặn: lần sau lại tự chọn */ }
  }
  function theoTrinhDuyet() {
    var ds = (navigator.languages && navigator.languages.length ? navigator.languages : [navigator.language || '']);
    for (var i = 0; i < ds.length; i++) {
      var m = String(ds[i] || '').toLowerCase().split('-')[0];
      if (m === 'vi') return 'vi';
      if (m === 'en') return 'en';
    }
    return 'en'; // chưa hỗ trợ ngôn ngữ nào ⇒ tiếng Anh (mục 1.1)
  }
  // Chạy trước khi <link rel="alternate"> được phân tích ⇒ suy đường dẫn: `/x/` ↔ `/en/x/`.
  function dichCua(lang) {
    if (goc.hasAttribute('data-mot-ngon-ngu')) return null;
    var p = location.pathname;
    if (lang === 'en') return p === '/en' || p.indexOf('/en/') === 0 ? null : '/en' + p;
    return p === '/en' ? '/' : p.indexOf('/en/') === 0 ? p.slice(3) : null;
  }

  var luuSan = docLuu();
  var bot = /bot|crawl|spider|slurp|lighthouse|headless/i.test(navigator.userAgent || '');
  var muon = luuSan;
  if (!muon && !bot) {
    muon = theoTrinhDuyet();
    luu(muon);
  }
  if (muon && muon !== dang) {
    var dich = dichCua(muon);
    if (dich) {
      location.replace(dich + location.search + location.hash);
    }
  }

  // Bộ chọn ngôn ngữ ở chân trang: lưu lựa chọn trước khi rời trang.
  document.addEventListener('click', function (e) {
    var a = e.target && e.target.closest ? e.target.closest('[data-chon-ngon-ngu]') : null;
    if (a) luu(a.getAttribute('data-chon-ngon-ngu'));
  });
})();
