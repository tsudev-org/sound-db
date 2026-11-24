-- Tìm/lọc Lịch sử (SEARCH_AND_FILTER.md mục 4): nhãn + ghi chú + thiết bị đã chuẩn hoá (chữ thường, bỏ dấu, bỏ dấu
-- câu), tính lúc GHI bằng src/lib/vi-text.ts. NULL = bản ghi trước migration này, điền lại khi người dùng liệt kê
-- (src/me/routes.ts) - SQLite không bỏ dấu tiếng Việt được nên không điền bằng SQL ở đây.
ALTER TABLE records ADD COLUMN search_norm TEXT;
