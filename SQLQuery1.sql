CREATE DATABASE CREDIT_CARD
USE CREDIT_CARD
SELECT *
FROM DBO.[default of credit card clients]
--Định dạng
--EXEC sp_rename 'DBO.[default of credit card clients].default_payment_next_month', 'DEFAULT_FLAG', 'COLUMN';
--GO
---- Đảm bảo cột ID không cho phép NULL
--ALTER TABLE DBO.[default of credit card clients]
--ALTER COLUMN ID INT NOT NULL;
--GO

---- Thêm Primary Key
--ALTER TABLE DBO.[default of credit card clients]
--ADD CONSTRAINT PK_CreditCardClients PRIMARY KEY (ID);
--GO
---- Đổi kiểu dữ liệu cho các cột thông tin chung
--ALTER TABLE DBO.[default of credit card clients] ALTER COLUMN LIMIT_BAL INT;
--ALTER TABLE DBO.[default of credit card clients] ALTER COLUMN SEX SMALLINT;
--ALTER TABLE DBO.[default of credit card clients] ALTER COLUMN EDUCATION SMALLINT;
--ALTER TABLE DBO.[default of credit card clients] ALTER COLUMN MARRIAGE SMALLINT;
--ALTER TABLE DBO.[default of credit card clients] ALTER COLUMN AGE INT;
--GO

---- Đổi kiểu dữ liệu cho các cột PAY_X (Trạng thái thanh toán)
--ALTER TABLE DBO.[default of credit card clients] ALTER COLUMN PAY_0 SMALLINT;
--ALTER TABLE DBO.[default of credit card clients] ALTER COLUMN PAY_2 SMALLINT;
--ALTER TABLE DBO.[default of credit card clients] ALTER COLUMN PAY_3 SMALLINT;
--ALTER TABLE DBO.[default of credit card clients] ALTER COLUMN PAY_4 SMALLINT;
--ALTER TABLE DBO.[default of credit card clients] ALTER COLUMN PAY_5 SMALLINT;
--ALTER TABLE DBO.[default of credit card clients] ALTER COLUMN PAY_6 SMALLINT;
--GO

---- Đổi kiểu dữ liệu cho các cột BILL_AMTX (Dư nợ)
--ALTER TABLE DBO.[default of credit card clients] ALTER COLUMN BILL_AMT1 INT;
--ALTER TABLE DBO.[default of credit card clients] ALTER COLUMN BILL_AMT2 INT;
--ALTER TABLE DBO.[default of credit card clients] ALTER COLUMN BILL_AMT3 INT;
--ALTER TABLE DBO.[default of credit card clients] ALTER COLUMN BILL_AMT4 INT;
--ALTER TABLE DBO.[default of credit card clients] ALTER COLUMN BILL_AMT5 INT;
--ALTER TABLE DBO.[default of credit card clients] ALTER COLUMN BILL_AMT6 INT;
--GO

---- Đổi kiểu dữ liệu cho các cột PAY_AMTX (Số tiền đã trả)
--ALTER TABLE DBO.[default of credit card clients] ALTER COLUMN PAY_AMT1 INT;
--ALTER TABLE DBO.[default of credit card clients] ALTER COLUMN PAY_AMT2 INT;
--ALTER TABLE DBO.[default of credit card clients] ALTER COLUMN PAY_AMT3 INT;
--ALTER TABLE DBO.[default of credit card clients] ALTER COLUMN PAY_AMT4 INT;
--ALTER TABLE DBO.[default of credit card clients] ALTER COLUMN PAY_AMT5 INT;
--ALTER TABLE DBO.[default of credit card clients] ALTER COLUMN PAY_AMT6 INT;
--GO

---- Đổi kiểu dữ liệu cho cột cờ vỡ nợ (đã được đổi tên)
--ALTER TABLE DBO.[default of credit card clients] ALTER COLUMN DEFAULT_FLAG SMALLINT;
--ALTER TABLE DBO.[default of credit card clients] 
--ALTER COLUMN DEFAULT_FLAG FLOAT;
--GO

-- 1. Tổng số bản ghi & tỷ lệ vỡ nợ
SELECT COUNT(*)                              AS total,
       SUM(DEFAULT_FLAG)                     AS defaulted,
       ROUND(AVG(DEFAULT_FLAG)*100.0, 2)     AS default_rate_pct
FROM   DBO.[default of credit card clients];
 
-- 2. Kiểm tra mã EDUCATION không hợp lệ
SELECT EDUCATION, COUNT(*) AS cnt,
       ROUND(COUNT(*)*100.0/(SELECT COUNT(*) FROM DBO.[default of credit card clients]),2) AS pct
FROM   DBO.[default of credit card clients]
WHERE  EDUCATION NOT IN (1,2,3)
GROUP  BY EDUCATION ORDER BY EDUCATION;
 
-- 3. Kiểm tra mã MARRIAGE không hợp lệ
SELECT MARRIAGE, COUNT(*) AS cnt
FROM   DBO.[default of credit card clients] WHERE MARRIAGE = 0
GROUP  BY MARRIAGE;
 
-- 4. Đếm giá trị PAY = -2 (undocumented) theo từng tháng
SELECT
    SUM(CASE WHEN PAY_0=-2 THEN 1 ELSE 0 END) AS pay0_neg2,
    SUM(CASE WHEN PAY_2=-2 THEN 1 ELSE 0 END) AS pay2_neg2,
    SUM(CASE WHEN PAY_3=-2 THEN 1 ELSE 0 END) AS pay3_neg2,
    SUM(CASE WHEN PAY_4=-2 THEN 1 ELSE 0 END) AS pay4_neg2,
    SUM(CASE WHEN PAY_5=-2 THEN 1 ELSE 0 END) AS pay5_neg2,
    SUM(CASE WHEN PAY_6=-2 THEN 1 ELSE 0 END) AS pay6_neg2
FROM DBO.[default of credit card clients];
 
-- 5. Dư nợ âm theo tháng
SELECT
    SUM(CASE WHEN BILL_AMT1<0 THEN 1 ELSE 0 END) AS bill1_neg,
    SUM(CASE WHEN BILL_AMT2<0 THEN 1 ELSE 0 END) AS bill2_neg,
    SUM(CASE WHEN BILL_AMT3<0 THEN 1 ELSE 0 END) AS bill3_neg
FROM DBO.[default of credit card clients];

--Phân Tích Tỷ Lệ Vỡ Nợ Theo Nhân Khẩu Học

-- Theo giới tính
SELECT CASE SEX WHEN 1 THEN 'Nam' ELSE 'Nu' END   AS gioi_tinh,
       COUNT(*)                                    AS so_khach,
       ROUND(AVG(DEFAULT_FLAG)*100.0, 2)           AS ty_le_vo_no
FROM   DBO.[default of credit card clients]
GROUP  BY SEX ORDER BY SEX;
 
-- Theo học vấn
SELECT CASE 
         WHEN EDUCATION=1 THEN 'Sau Dai hoc'
         WHEN EDUCATION=2 THEN 'Dai hoc'
         WHEN EDUCATION=3 THEN 'THPT'
         ELSE                  'Khac/Unknown'
       END AS hoc_van,
       COUNT(*) AS so_khach,
       ROUND(AVG(DEFAULT_FLAG)*100.0, 2) AS ty_le_vo_no
FROM DBO.[default of credit card clients]
GROUP BY CASE 
           WHEN EDUCATION=1 THEN 'Sau Dai hoc'
           WHEN EDUCATION=2 THEN 'Dai hoc'
           WHEN EDUCATION=3 THEN 'THPT'
           ELSE                  'Khac/Unknown'
         END
ORDER BY ty_le_vo_no DESC;
 
-- Theo nhóm tuổi (CASE + window function)
WITH age_grp AS (
    SELECT *,
        CASE WHEN AGE<=25 THEN '21-25'
             WHEN AGE<=30 THEN '26-30'
             WHEN AGE<=40 THEN '31-40'
             WHEN AGE<=50 THEN '41-50'
             ELSE              '50+'
        END AS nhom_tuoi
    FROM DBO.[default of credit card clients]
)
SELECT nhom_tuoi,
       COUNT(*)                              AS so_khach,
       ROUND(AVG(DEFAULT_FLAG)*100.0, 2)     AS ty_le_vo_no,
       ROUND(AVG(LIMIT_BAL),0)               AS han_muc_tb
FROM   age_grp
GROUP  BY nhom_tuoi ORDER BY nhom_tuoi;

-- Phân Tích Hạn Mức & Trạng Thái Thanh Toán
-- Tỷ lệ vỡ nợ theo nhóm hạn mức
SELECT CASE 
         WHEN LIMIT_BAL < 50000 THEN 'A. <50K'
         WHEN LIMIT_BAL < 100000 THEN 'B. 50-100K'
         WHEN LIMIT_BAL < 200000 THEN 'C. 100-200K'
         WHEN LIMIT_BAL < 300000 THEN 'D. 200-300K'
         WHEN LIMIT_BAL < 500000 THEN 'E. 300-500K'
         ELSE                         'F. >500K'
       END AS nhom_han_muc,
       COUNT(*) AS so_khach,
       -- Thêm * 1.0 vào đây để không bị lỗi 0% nhé:
       ROUND(AVG(DEFAULT_FLAG * 1.0)*100.0, 2) AS ty_le_vo_no, 
       ROUND(AVG(BILL_AMT1)/1000.0, 1) AS du_no_tb_k
FROM DBO.[default of credit card clients]
GROUP BY CASE 
           WHEN LIMIT_BAL < 50000 THEN 'A. <50K'
           WHEN LIMIT_BAL < 100000 THEN 'B. 50-100K'
           WHEN LIMIT_BAL < 200000 THEN 'C. 100-200K'
           WHEN LIMIT_BAL < 300000 THEN 'D. 200-300K'
           WHEN LIMIT_BAL < 500000 THEN 'E. 300-500K'
           ELSE                         'F. >500K'
         END
ORDER BY nhom_han_muc;
 
-- Tỷ lệ vỡ nợ theo trạng thái thanh toán PAY_0
SELECT
    CASE PAY_0
        WHEN -2 THEN '-2: Khong phat sinh GD'
        WHEN -1 THEN '-1: Tra dung han'
        WHEN  0 THEN ' 0: Tra toi thieu'
        WHEN  1 THEN ' 1: Tre 1 thang'
        WHEN  2 THEN ' 2: Tre 2 thang'
        WHEN  3 THEN ' 3: Tre 3 thang'
        ELSE         '4+: Tre >= 4 thang'
    END                                           AS trang_thai,
    COUNT(*)                                      AS so_khach,
    ROUND(AVG(DEFAULT_FLAG)*100.0, 2)             AS ty_le_vo_no
FROM   DBO.[default of credit card clients]
GROUP  BY PAY_0 ORDER BY PAY_0;

-- Phân Tích Nâng Cao — So Sánh & Phân Khúc
-- So sánh hành vi tài chính: vỡ nợ vs không vỡ nợ
SELECT DEFAULT_FLAG AS vo_no,
       ROUND(AVG(CAST(LIMIT_BAL AS FLOAT)), 0) AS han_muc_tb,
       ROUND(AVG(CAST(BILL_AMT1 AS FLOAT)), 0) AS du_no_t9_tb,
       ROUND(AVG(CAST(PAY_AMT1 AS FLOAT)), 0)  AS tien_tra_t9_tb,
       ROUND(AVG(AGE * 1.0), 1)                AS tuoi_tb,
       COUNT(*)                                AS so_luong
FROM   DBO.[default of credit card clients] 
GROUP  BY DEFAULT_FLAG;

-- Top khách hàng rủi ro cao: trễ nhiều tháng + hạn mức thấp
SELECT TOP 10 
       ID, LIMIT_BAL, AGE, PAY_0, PAY_2, PAY_3,
       BILL_AMT1, PAY_AMT1, DEFAULT_FLAG
FROM   DBO.[default of credit card clients]
WHERE  PAY_0 >= 2 AND PAY_2 >= 2 AND LIMIT_BAL < 100000
ORDER  BY PAY_0 DESC, LIMIT_BAL ASC;
 
-- Crosstab: tỷ lệ vỡ nợ theo giới tính x học vấn
SELECT 
    CASE SEX WHEN 1 THEN 'Nam' ELSE 'Nu' END AS gioi_tinh,
    CASE WHEN EDUCATION=1 THEN 'Sau DH'
         WHEN EDUCATION=2 THEN 'Dai hoc'
         WHEN EDUCATION=3 THEN 'THPT'
         ELSE 'Khac' END AS hoc_van,
    COUNT(*) AS so_khach,
    ROUND(AVG(DEFAULT_FLAG * 1.0)*100.0, 2) AS ty_le_vo_no
FROM DBO.[default of credit card clients]
GROUP BY 
    CASE SEX WHEN 1 THEN 'Nam' ELSE 'Nu' END,
    CASE WHEN EDUCATION=1 THEN 'Sau DH'
         WHEN EDUCATION=2 THEN 'Dai hoc'
         WHEN EDUCATION=3 THEN 'THPT'
         ELSE 'Khac' END
ORDER BY ty_le_vo_no DESC;
