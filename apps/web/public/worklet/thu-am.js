// AudioWorklet: gom các khung 128 mẫu thành khối 2048 mẫu rồi gửi về luồng chính (Sound Db, /do/).
// Chỉ đọc kênh đầu; không ghi âm, không gửi đi đâu ngoài trang.
class ThuAm extends AudioWorkletProcessor {
  constructor() {
    super();
    this.dem = new Float32Array(2048);
    this.viTri = 0;
  }
  process(inputs) {
    const kenh = inputs[0] && inputs[0][0];
    if (kenh) {
      let i = 0;
      while (i < kenh.length) {
        const n = Math.min(kenh.length - i, this.dem.length - this.viTri);
        this.dem.set(kenh.subarray(i, i + n), this.viTri);
        this.viTri += n;
        i += n;
        if (this.viTri === this.dem.length) {
          this.port.postMessage(this.dem, [this.dem.buffer]);
          this.dem = new Float32Array(2048);
          this.viTri = 0;
        }
      }
    }
    return true;
  }
}
registerProcessor('thu-am', ThuAm);
