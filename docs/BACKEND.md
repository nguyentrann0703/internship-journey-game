  
Dưới đây là Backlog chi tiết cho **Person A (Backend & System Architecture)**. Với một sinh viên chuyên ngành **Data Science** như bạn, phần này sẽ tập trung mạnh vào cấu trúc dữ liệu, luồng xử lý logic thời gian thực và đảm bảo hệ thống không bị "sập" khi 78 người cùng thao tác.

---

## **🏗️ GIAI ĐOẠN 1: SYSTEM ARCHITECTURE & DATABASE (Ngày 1-3)**

*Mục tiêu: Thiết lập "xương sống" cho toàn bộ game.*

* **Database Schema:** Thiết kế các Collection/Table trên **Firebase/Supabase** bao gồm:  
  * game\_state: Lưu trạng thái hiện tại (Vòng 1, Vòng 2, Câu hỏi số mấy, trạng thái Khóa/Mở).  
  * teams: Tên 9 phòng ban, số token hiện có, điểm số qua các vòng.  
  * submissions: Lưu đáp án và số token đặt cược của từng đội theo từng câu hỏi.  
* **Auth & Session Logic:** Xây dựng cơ chế định danh đội chơi qua **Session/Cookie** để tránh việc một đội đăng nhập bằng nhiều thiết bị.  
* **API Contract:** Định nghĩa các Endpoint hoặc Function để Frontend gọi (ví dụ: submitAnswer, placeBet, updateScore).

---

## **🧠 GIAI ĐOẠN 2: GAME ENGINE & LOGIC (Ngày 4-9)**

*Mục tiêu: Hiện thực hóa luật chơi thành code.*

* **Vòng 1 \- Token Engine:**  
  * Viết logic cộng/trừ token tự động dựa trên kết quả Đúng/Sai từ Admin.  
  * Xây dựng hàm kiểm tra (Validation): Không cho phép đặt cược vượt quá số token hiện có hoặc vượt mức tối đa (5 token).  
* **Vòng 2 \- Scoring Logic:**  
  * Xử lý logic nhận điểm từ 3 BGK đồng thời và tính điểm trung bình (Làm tròn xuống).  
  * Đảm bảo dữ liệu điểm được đồng bộ ngay lập tức lên màn hình Leaderboard.  
* **Admin Command Center:** Xây dựng các hàm điều khiển trạng thái game để Person B tích hợp vào nút bấm của Admin.

---

## **🛡️ GIAI ĐOẠN 3: SECURITY & REAL-TIME SYNC (Ngày 10-12)**

*Mục tiêu: Chống gian lận và tối ưu hóa hiệu năng.*

* **Real-time Strategy:** Sử dụng **Firebase Realtime Database** hoặc **Supabase Realtime** để đẩy thông báo thay đổi trạng thái game đến toàn bộ 78 thiết bị sinh viên trong \< 500ms.  
* **Anti-Cheat & Reliability:**  
  * Khóa khả năng gửi dữ liệu khi trạng thái câu hỏi đã chuyển sang "Hết giờ".  
  * Xử lý trường hợp sinh viên mất mạng: Khi reconnect, hệ thống tự động trả về đúng trạng thái mà game đang diễn ra.  
* **Bonus Game Integration:** Xây dựng endpoint nhận tín hiệu "Hoàn thành" từ game Cross the Road và tự động cộng \+2 điểm bonus vào DB.

---

## **🚀 GIAI ĐOẠN 4: LOAD TESTING & DEPLOYMENT (Ngày 13-14)**

*Mục tiêu: Sẵn sàng cho "giờ G".*

* **Load Testing:** Giả lập 78-80 kết nối đồng thời để kiểm tra giới hạn của Firebase/Supabase (Đảm bảo không bị vượt quá giới hạn free tier hoặc gây trễ).  
* **Data Export Tool:** Viết một script nhỏ để xuất toàn bộ kết quả cuối cùng ra file **CSV/Excel** làm minh chứng chấm điểm cho giảng viên UEH.  
* **Final Deployment:** Triển khai Backend, thiết lập biến môi trường (Environment Variables) và thực hiện **Pre-game Checklist** cùng Person B.

Giao diện **Admin Control Panel** là "trạm điều khiển" trung tâm. Vì máy tính của Admin (thường là MacBook Pro M3 Pro của bạn) sẽ vừa dùng để điều hành, vừa dùng để trình chiếu tại giảng đường UEH, giao diện này cần được thiết kế cực kỳ trực quan để MC không bị rối khi đang dẫn chương trình.