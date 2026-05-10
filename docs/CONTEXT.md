# **📝 KẾ HOẠCH TRIỂN KHAI DỰ ÁN: SINH VIÊN THỰC TẬP SINH TỬ (V3)**

**Bối cảnh:** Môn kỹ năng mềm UEH \- Định vị bản thân trong doanh nghiệp.  
**Đối tượng:** 78 sinh viên (10 nhóm, 9 đội thi đấu).

## **👥 PHÂN CHIA NHÂN SỰ & TRÁCH NHIỆM**

| Vai trò | Trách nhiệm chính   |
| :---- | :---- |
| **Person A (Backend & Logic)** | Hệ thống dữ liệu (Firebase/Supabase), Logic Token, Backend FastAPI (Testing), Tính điểm trung bình Vòng 2, Security & Anti-cheat. |
| **Person B (Frontend & UI/UX)** | Giao diện Admin/Judge/Student, Real-time Leaderboard, Animation (Framer Motion), Cross the Road Game, Responsive Design. |

## **🚀 LỘ TRÌNH PHÁT TRIỂN & GIẢI QUYẾT XUNG ĐỘT**

### **Giai đoạn 1: Thiết kế & Kiến trúc (Ngày 1-3)**

* **Person A:** Thiết lập Database Schema. Xây dựng logic Session/Cookie để định danh đội.  
* **Person B:** Thiết kế **2 View riêng biệt**: *Control Panel* (cho Admin thao tác) và *Public View* (chỉ hiện Leaderboard/Câu hỏi để trình chiếu).

### **Giai đoạn 2: Phát triển lõi (Ngày 4-9)**

* **Vòng 1 (Token Engine):**  
  * Admin nhìn bảng trắng ngoài đời và click **Đúng/Sai** thủ công trên Dashboard.  
  * Hệ thống tự động cộng/trừ số dư token dựa trên dữ liệu đặt cược trước đó.  
* **Vòng 2 (Scoring):**  
  * **Thời gian:** Sau khi bốc thăm, cả 9 đội sẽ có 2 phút thảo luận **đồng thời** để tiết kiệm thời gian.  
  * BGK chấm điểm 1-5; hệ thống tính trung bình và Math.floor kết quả.

## **📊 QUY ĐỔI ĐIỂM VÒNG 1 (CẬP NHẬT)**

Để tăng tính cạnh tranh và khuyến khích mạo hiểm, mốc điểm tối đa được điều chỉnh:

| Token còn lại | Điểm quy đổi   |
| :---- | :---- |
| 18+ | 5 điểm |
| 14–17 | 4 điểm |
| 9–13 | 3 điểm |
| 4–8 | 2 điểm |
| 0–3 | 1 điểm |

## **🛠️ QUY TRÌNH VẬN HÀNH TÀI KHOẢN**

* **Admin Account:** Chỉ dùng để điều khiển luồng game. Sử dụng Tab riêng tư để không hiện "hậu trường" lên máy chiếu.  
* **Judge Accounts (x3):** Dùng thiết bị cá nhân để chấm điểm độc lập.  
* **Student Accounts:** Dùng để đặt cược và nộp đáp án. Chấp nhận rủi ro "phá sản" (về 0-3 token) sẽ chỉ nhận 1 điểm.

## **⚠️ KỊCH BẢN XỬ LÝ SỰ CỐ (TROUBLESHOOTING)**

* **Rớt mạng:** Hệ thống khôi phục trạng thái qua Cookie/Session.  
* **Nhập sai điểm:** Admin có nút "Edit" thủ công trên Leaderboard để sửa lỗi nhanh.  
* **Hết token:** Đội chơi chấp nhận kết quả 1 điểm nếu không quản lý ngân sách nhân sự tốt.

