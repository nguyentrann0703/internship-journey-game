

### **🗓️ LỘ TRÌNH TRIỂN KHAI (DỰ KIẾN 2 TUẦN)**

---

### **GIAI ĐOẠN 1: THIẾT KẾ HỆ THỐNG & GIAO DIỆN (NGÀY 1-3)**

| Hạng mục | Person A (Backend & Logic) | Person B (UI/UX & Frontend) |
| :---- | :---- | :---- |
| **Planning** | Thiết lập **System Architecture** & **Database Schema** (Firebase/Supabase). | Vẽ **User Flow Diagram** (Luồng di chuyển của sinh viên và admin). |
| **Design** | Định nghĩa **State Machine** (Các trạng thái: Chờ, Đặt cược, Đang trả lời, Kết quả). | Thiết kế **Wireframe & Mockup** cho 3 màn hình chính: Admin, Sinh viên, Leaderboard. |
| **Setup** | Khởi tạo Project Next.js, cấu hình **Environment** và Git Repository. | Thiết lập **Design System** (Màu sắc, Typography) và cài đặt Tailwind CSS/Shadcn UI. |

---

### **GIAI ĐOẠN 2: PHÁT TRIỂN LÕI (CORE DEV) (NGÀY 4-9)**

| Hạng mục | Person A (Backend & Logic) | Person B (UI/UX & Frontend) |
| :---- | :---- | :---- |
| **Vòng 1** | Viết Logic đặt cược token, kiểm tra số dư và xử lý **Real-time Sync** khi Admin chốt đáp án. | Xây dựng UI Vòng 1: Thanh trượt đặt cược, bảng nhập đáp án, hiệu ứng đếm ngược. |
| **Vòng 2** | Xây dựng **Admin Panel** cho 3 BGK nhập điểm đồng thời và logic tính điểm trung bình (làm tròn xuống). | Thiết kế các Card tình huống SWOT và giao diện hiển thị kết quả chấm điểm realtime cho từng đội. |
| **Leaderboard** | Xây dựng thuật toán xếp hạng tự động cập nhật sau mỗi vòng chơi. | Thiết kế hiệu ứng **Podium (Hạng 1, 2, 3\)** và các hiệu ứng ăn mừng (Confetti). |

---

### **GIAI ĐOẠN 3: TÍCH HỢP & MINI-GAME (NGÀY 10-12)**

| Hạng mục | Person A (Backend & Logic) | Person B (UI/UX & Frontend) |
| :---- | :---- | :---- |
| **Bonus Game** | Tích hợp Game **Cross the Road** vào hệ thống; xử lý logic cộng \+2 điểm khi hoàn thành. | Chỉnh sửa/Tối ưu hóa mã nguồn game Cross the Road để chạy mượt trên mobile/laptop sinh viên. |
| **Security** | Xử lý **Anti-cheat**: Chặn F5 mất điểm, khóa thiết bị theo Session/Cookie để mỗi đội chỉ dùng 1 máy. | Tối ưu hóa **Responsive** (Đảm bảo giao diện hiển thị tốt trên mọi loại điện thoại của 78 sinh viên). |

---

### **GIAI ĐOẠN 4: KIỂM THỬ & TRIỂN KHAI (NGÀY 13-14)**

| Hạng mục | Person A (Backend & Logic) | Person B (UI/UX & Frontend) |
| :---- | :---- | :---- |
| **Testing** | Thực hiện **Load Testing** (Giả lập 78-80 kết nối cùng lúc vào Firebase) để check độ trễ. | Thực hiện **UI Testing** trên các trình duyệt khác nhau (Safari, Chrome, Samsung Internet). |
| **Deployment** | Triển khai lên **Vercel**, trỏ Domain và kiểm tra kết nối tại hội trường UEH. | Soạn thảo **Pre-game Checklist**: Các bước hướng dẫn sinh viên đăng nhập và luật chơi nhanh. |

---

