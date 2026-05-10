Việc tách biệt này không chỉ giúp bạn dễ quản lý luồng dữ liệu mà còn đảm bảo tính chuyên nghiệp khi trình chiếu trước 78 người. Dưới đây là cách phân bổ quyền hạn và giao diện cho từng loại tài khoản:

### **1\. Account Admin (The Orchestrator \- Dùng để trình chiếu)**

Đây là tài khoản "quyền lực" nhất, được đăng nhập trên máy tính kết nối với máy chiếu của lớp.

* **Vòng 1:**  
  * Điều khiển trạng thái câu hỏi (Hiện câu hỏi \-\> Bắt đầu đếm ngược \-\> Khóa đặt cược).  
  * **Verify đáp án:** Vì các đội ghi trên bảng trắng ngoài đời, Admin sẽ nhìn bảng và click "Đúng" hoặc "Sai" trên giao diện Admin Panel. Hệ thống sẽ tự động cập nhật token dựa trên số lượng các đội đã đặt cược trước đó.  
* **Vòng 2:**  
  * Kích hoạt trạng thái "Bốc thăm tình huống".  
  * Hiển thị đồng hồ đếm ngược 1 phút cho phần thuyết trình.  
* **Tổng quan:** Luôn hiển thị **Leaderboard Real-time** để cả lớp theo dõi bảng xếp hạng.

### **2\. Account BGK (The Evaluators \- 3 tài khoản riêng)**

Trong Vòng 2, khi 3 vị giám khảo tham gia, họ sẽ dùng thiết bị cá nhân (điện thoại hoặc máy tính bảng) để truy cập vào link dành riêng cho BGK.

* **Giao diện riêng:** Chỉ hiển thị bảng chấm điểm theo **Rubric** (SWOT, Logic, Trình bày) cho đội đang thuyết trình.  
* **Tính độc lập:** Mỗi BGK nhập điểm riêng. Admin Panel (trên máy chiếu) sẽ chỉ nhận dữ liệu và tính toán điểm trung bình (làm tròn xuống) để hiển thị lên màn hình chính sau khi cả 3 người đã nhấn "Submit".

---

### **💡 Gợi ý kỹ thuật cho Team Code**

Với "vibe code" của nhóm bạn, đây là cách triển khai nhanh nhất trên **Next.js** và **Firebase/Supabase**:

* **Phân quyền (RBAC):**  
  * Sử dụng một trường role trong database hoặc cấu trúc URL khác nhau: /admin/dashboard (cho máy chiếu) và /judge/:id (cho giám khảo).  
* **Luồng dữ liệu Vòng 2:**  
  * **Person A (Logic):** Tạo một bảng scores\_queue. Khi giám khảo 1 nhấn gửi, data sẽ nằm chờ ở đó. Khi đủ 3 bản ghi cho 1 đội, logic backend sẽ tự động tính trung bình và đẩy kết quả sang bảng teams để Leaderboard cập nhật.  
  * **Person B (UI):** Thiết kế giao diện chấm điểm cho BGK thật đơn giản (nhấn chọn mức điểm 1-5) để họ không bị bối rối khi đang nghe sinh viên thuyết trình.

### **🛠️ Kịch bản thực tế tại giảng đường UEH**

1. **Mở đầu:** Admin bật máy chiếu, hiện màn hình chờ "Sinh Viên Thực Tập Sinh Tử".  
2. **Vòng 1:** Admin bấm nút trên máy để hiện câu hỏi. Sinh viên giơ bảng trắng, Admin check đúng/sai bằng cách click chuột trên máy chiếu.  
3. **Vòng 2:** Admin mời 3 giám khảo (có thể là thầy/cô) quét mã QR để vào trang chấm điểm. Khi sinh viên nói xong, 3 giám khảo bấm "Gửi", màn hình máy chiếu lập tức nổ hiệu ứng điểm số.

Cách chia này sẽ giúp nhóm tổ chức của bạn (Tech department của ET Club) trông cực kỳ chuyên nghiệp trong mắt giảng viên và bạn bè.

Nguyên có cần mình gợi ý chi tiết hơn về giao diện **Admin Control Panel** để MC dễ thao tác không?

Dưới đây là gợi ý thiết kế chi tiết cho **Person B (Frontend)** để xây dựng một trang Admin chuyên nghiệp:

---

## **🖥️ Bố cục Tổng quan (Admin Dashboard)**

Bạn nên sử dụng thiết kế **Split-Screen** hoặc **Tabbed Interface** để tách biệt giữa việc "Điều khiển" và "Theo dõi hệ thống".

### **1\. Thanh Trạng thái Hệ thống (Top Bar)**

* **Trạng thái Game:** Hiển thị Phase hiện tại (Lobby / Vòng 1 / Vòng 2 / Bonus / Kết quả) Kịch Bản Game.md\].  
* **Kết nối:** Hiển thị số lượng đội đã Online (Ví dụ: 9/9 Đội) và trạng thái của 3 BGK Kịch Bản Game.md\].  
* **Nút Khẩn cấp:** Nút "Reset Game" hoặc "Pause" đề phòng sự cố kỹ thuật.

---

## **⚙️ Chi tiết Giao diện theo từng Vòng**

### **Vòng 1: Xác thực & Quản lý Token**

Vì các đội ghi đáp án trên bảng trắng ngoài đời, Admin cần một bảng kiểm soát nhanh:

* **Bảng điều khiển câu hỏi:** Nút "Hiện câu hỏi" \-\> "Bắt đầu 30s" \-\> "Hết giờ (Khóa đặt cược)" Kịch Bản Game.md\].  
* **Grid Verification (Quan trọng nhất):** Một danh sách 9 đội. Bên cạnh mỗi đội là nút tích **\[Đúng\]** và **\[Sai\]**.  
  * *Logic:* Khi MC hô "Giơ bảng", Admin quan sát nhanh và click. Hệ thống sẽ tự động lấy số token đặt cược trong database của đội đó để cộng hoặc trừ ngay lập tức Kịch Bản Game.md\].  
  * **Nút "Cập nhật bảng xếp hạng":** Chỉ sau khi Admin xác nhận xong cho cả 9 đội, nút này mới hiện lên để đẩy dữ liệu mới nhất lên màn hình máy chiếu.

### **Vòng 2: Giám sát Ban giám khảo**

Admin đóng vai trò điều phối luồng chấm điểm:

* **Chọn đội thuyết trình:** Admin chọn Đội 1 \-\> Hệ thống tự gửi thông báo đến thiết bị của 3 BGK để họ bắt đầu chấm đội đó Kịch Bản Game.md\].  
* **Thanh Monitor BGK:** Hiển thị 3 biểu tượng icon (Judge 1, Judge 2, Judge 3).  
  * Icon chuyển sang màu xanh khi vị giám khảo đó đã nhấn "Submit" điểm Kịch Bản Game.md\].  
* **Review điểm:** Admin có thể xem nhanh điểm của 3 bên trước khi nhấn "Công bố" lên máy chiếu (để tránh trường hợp BGK nhập nhầm số quá lớn) Kịch Bản Game.md\].

---

## **📊 Màn hình Trình chiếu (Projector View)**

Đây là giao diện mà 78 sinh viên sẽ nhìn thấy. Nó nên được mở ở một **Tab/Cửa sổ riêng** để Admin có thể kéo sang màn hình máy chiếu.

* **Vòng 1:** Hiển thị Câu hỏi (Text lớn) \+ Đồng hồ đếm ngược \+ Leaderboard cột dọc bên phải Kịch Bản Game.md\].  
* **Vòng 2:** Hiển thị Tình huống SWOT của đội đang thi \+ Đồng hồ 1 phút thuyết trình Kịch Bản Game.md\].  
* **Hiệu ứng:** Sử dụng thư viện canvas-confetti để bắn pháo hoa mỗi khi có đội thăng hạng hoặc đạt điểm tuyệt đối.

---

## **💡 Tính năng "Cứu trợ" cho MC**

Vì MC tại UEH thường rất bận rộn, hãy thêm 2 tính năng này:

1. **Nút "Auto-Next":** Tự động chuyển trạng thái từ Hiện đáp án sang Câu hỏi tiếp theo sau 10 giây nếu Admin không bấm gì.  
2. **Chỉnh sửa điểm thủ công:** Một nút nhỏ "Edit" cạnh mỗi đội trên Leaderboard để Admin có thể sửa lỗi nhanh nếu lỡ tay bấm nhầm Đúng/Sai ở Vòng 1\.

### **🛠️ Gợi ý Tech-stack cho UI này:**

* **Person B:** Dùng **Radix UI** hoặc **Headless UI** để làm các Modal xác nhận (Confirm) trước khi thực hiện các hành động quan trọng như "Kết thúc vòng chơi".  
* **Person A:** Đảm bảo hàm calculateFinalScore có xử lý Math.floor() (làm tròn xuống) đúng như yêu cầu trong kịch bản Kịch Bản Game.md\].

