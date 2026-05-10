

Dưới đây là Backlog chi tiết dành riêng cho **Frontend Developer (Person B)**. Bảng này tập trung vào tính tương tác, hiệu ứng và khả năng phản hồi thời gian thực (Real-time UI).

---

## **🎨 GIAI ĐOẠN 1: DESIGN SYSTEM & ARCHITECTURE (Ngày 1-3)**

*Mục tiêu: Xây dựng nền móng để code không bị "rác" về sau.*

* **Setup Project:** Khởi tạo Next.js (App Router), cài đặt **Tailwind CSS**, **Shadcn/ui**, và **Framer Motion** (để làm animation).  
* **Design Tokens:** Định nghĩa bảng màu (Primary: Navy/Gold cho vibe công sở, Danger: Red cho trạng thái Sa thải).  
* **Shared Components:** \* Button, Input, Card (từ Shadcn).  
  * TokenBadge: Hiển thị số token đang có với hiệu ứng nhảy số.  
  * CountdownTimer: Bộ đếm ngược đồng bộ với server.  
* **Layout Wrapper:** Tạo 3 Layout riêng biệt cho /student, /admin, và /leaderboard.

---

## **⚙️ GIAI ĐOẠN 2: CORE UI DEVELOPMENT (Ngày 4-7)**

*Mục tiêu: Hoàn thiện giao diện tĩnh và các logic client-side.*

### **1\. Màn hình Sinh viên (/student)**

* **Vòng 1:** UI thanh Slider hoặc Input để đặt cược token (min 1, max 5\) và vùng soạn thảo đáp án câu hỏi.  
* **Vòng 2:** Card hiển thị nội dung 9 tình huống SWOT sau khi đội trưởng bốc thăm.  
* **State UI:** Các trạng thái "Đang chờ sếp...", "Đã nộp bài", "Bị sa thải" (Overlay màu xám).

### **2\. Màn hình Admin (/admin)**

* **Control Panel:** Nút bấm điều khiển trạng thái game (Start \-\> Câu 1 \-\> Chốt cược \-\> Hiện đáp án \-\> Next).  
* **Grading UI:** Bảng danh sách 9 đội để Admin/BGK nhập Đúng/Sai (Vòng 1\) và nhập điểm 1-5 (Vòng 2).

### **3\. Màn hình Leaderboard (/leaderboard)**

* Thiết kế bảng xếp hạng dạng danh sách (List) có khả năng tự động đổi chỗ khi điểm số thay đổi (Sử dụng layout prop của Framer Motion).

---

## **🔄 GIAI ĐOẠN 3: REALTIME UI & STATE MANAGEMENT (Ngày 8-10)**

*Mục tiêu: Kết nối với Firebase/Supabase do Person A quản lý.*

* **Real-time Hooks:** Viết các Custom Hooks (ví dụ: useGameState) để lắng nghe thay đổi từ DB và cập nhật UI ngay lập tức mà không cần F5.  
* **Sync Logic:**  
  * Khóa (Disable) nút nộp bài khi hết giờ trên server.  
  * Hiển thị hiệu ứng "Rung" (Shake) trên màn hình sinh viên nếu họ chọn đáp án sai.  
* **Toast Notification:** Sử dụng Sonner hoặc React Hot Toast để thông báo khi có thông điệp từ "Sếp Tổng".

---

## **🎮 GIAI ĐOẠN 4: MINI-GAME & FINAL POLISH (Ngày 11-14)**

*Mục tiêu: "Wow" người chơi bằng cảm giác mượt mà.*

* **Bonus Game (Cross the Road):** \* Build game bằng **Canvas API** hoặc đơn giản là dùng các thẻ div nếu muốn nhanh.  
  * Xử lý phím mũi tên/vuốt màn hình để điều khiển nhân vật.  
* **Animation & Sound:**  
  * Thêm hiệu ứng pháo hoa (Confetti) khi đội được "Thăng chức".  
  * Thêm âm thanh "Ting" khi nhận được token và "Buzz" khi bị trừ token.  
* **Responsive Optimization:** Kiểm tra kỹ giao diện trên Mobile (vì 78 sinh viên chủ yếu dùng điện thoại tại giảng đường).  
* **Deployment:** Đẩy code lên **Vercel**, cấu hình Domain và test tốc độ load.