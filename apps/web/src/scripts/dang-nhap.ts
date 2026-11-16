// Hiện thông báo lỗi khi tsudev.com trả về ?loi=... (không chèn chữ từ URL vào trang).
if (new URLSearchParams(location.search).has('loi')) {
  document.getElementById('thong-bao-loi')?.removeAttribute('hidden');
}
