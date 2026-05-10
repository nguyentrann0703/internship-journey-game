begin;

insert into public.round2_cases (case_number, title, prompt, expected_swot, suggested_plan)
values
  (
    1,
    'An - Tai chinh',
    'An, 22 tuoi, sinh vien nam 4 nganh Tai chinh. GPA 3.6, xu ly so lieu tot, ngai thuyet trinh, chua tung di thuc tap. Cong ty fintech dang tuyen manh nhung yeu cau ung vien co it nhat 6 thang thuc tap.',
    jsonb_build_object(
      'strengths', jsonb_build_array('Gioi xu ly va phan tich so lieu', 'GPA cao'),
      'weaknesses', jsonb_build_array('Ngai thuyet trinh', 'Thieu tu tin giao tiep', 'Chua co kinh nghiem thuc tap'),
      'opportunities', jsonb_build_array('Fintech dang tuyen manh', 'Nhu cau phu hop the manh phan tich du lieu'),
      'threats', jsonb_build_array('Yeu cau toi thieu 6 thang thuc tap')
    ),
    'Tim thuc tap fintech ngay hoc ky cuoi va tham gia workshop de luyen thuyet trinh.'
  ),
  (
    2,
    'Bao - Quan tri kinh doanh',
    'Bao, 23 tuoi, vua tot nghiep nganh Quan tri kinh doanh. Bao giao tiep tot, hay phan cong cong viec cho nhom, nhung hay tre deadline va yeu phan tich so lieu. Startup dang tuyen Business Development Executive va yeu cau tu quan ly tien do.',
    jsonb_build_object(
      'strengths', jsonb_build_array('Giao tiep tot', 'Thuyet phuc gioi', 'Co kinh nghiem leadership nhom'),
      'weaknesses', jsonb_build_array('Hay tre deadline', 'Yeu phan tich so lieu'),
      'opportunities', jsonb_build_array('Startup dang tuyen Business Development Executive'),
      'threats', jsonb_build_array('Vi tri doi hoi tu quan ly tien do va lam viec doc lap')
    ),
    'Ung tuyen Business Development Executive va dung Notion hoac Trello de quan ly deadline.'
  ),
  (
    3,
    'Chi - Marketing',
    'Chi, 21 tuoi, sinh vien nam 3 nganh Marketing. Co trang lifestyle 5000 followers, gioi quay edit video, nhung tieng Anh yeu va khong co chung chi. Agency nuoc ngoai dang mo van phong o Viet Nam va tuyen Digital Marketer yeu cau giao tiep tieng Anh luu loat.',
    jsonb_build_object(
      'strengths', jsonb_build_array('Gioi lam content', 'Co personal brand thuc te voi 5000 followers'),
      'weaknesses', jsonb_build_array('Tieng Anh yeu', 'Khong co chung chi'),
      'opportunities', jsonb_build_array('Agency nuoc ngoai dang tuyen Digital Marketer gap'),
      'threats', jsonb_build_array('Yeu cau giao tiep tieng Anh luu loat')
    ),
    'Luyen tieng Anh giao tiep va dung trang 5000 followers lam portfolio khi apply.'
  ),
  (
    4,
    'Dung - Logistics',
    'Dung, 24 tuoi, da di lam 1 nam tai cong ty logistics nho. Dang tin cay va dung gio nhung thu dong, it de xuat cai tien va ngai hoc he thong moi. Nganh logistics dang chuyen doi so manh me.',
    jsonb_build_object(
      'strengths', jsonb_build_array('Dang tin cay', 'Dung gio', 'Duoc sep tin tuong'),
      'weaknesses', jsonb_build_array('Thu dong', 'It de xuat', 'Ngai hoc cong nghe moi'),
      'opportunities', jsonb_build_array('Chuyen doi so mo ra co hoi thang tien'),
      'threats', jsonb_build_array('Nguoi khong thich nghi se bi danh gia thieu nang dong')
    ),
    'Chu dong xin tham gia trien khai he thong moi va de xuat it nhat 1 cai tien nho moi thang.'
  ),
  (
    5,
    'Emm - CNTT',
    'Emm, 22 tuoi, sinh vien nam 4 nganh CNTT. Code gioi, co 2 du an GitHub va giai ba hackathon, nhung kho lam viec nhom va hay ap dat. Startup cong nghe rat can developer nhung teamwork la tieu chi hang dau.',
    jsonb_build_object(
      'strengths', jsonb_build_array('Code gioi', 'Co portfolio thuc te', 'Tung dat giai hackathon'),
      'weaknesses', jsonb_build_array('Kho lam viec nhom', 'Khong chiu nhan gop y', 'Hay ap dat'),
      'opportunities', jsonb_build_array('Startup cong nghe bung no', 'Nhu cau developer cao'),
      'threats', jsonb_build_array('Teamwork la tieu chi tuyen dung hang dau')
    ),
    'Tham gia du an nhom va luyen lang nghe, tiep nhan gop y truoc khi phan bac.'
  ),
  (
    6,
    'Phong - Ke toan',
    'Phong, 23 tuoi, vua tot nghiep nganh Ke toan. Chuyen mon vung va can than nhung khong co LinkedIn, khong networking. Doanh nghiep dang tuyen gap nhung thuong yeu cau phong van nhieu vong va gioi thieu trong nganh.',
    jsonb_build_object(
      'strengths', jsonb_build_array('Chuyen mon vung', 'Ti mi', 'Can than'),
      'weaknesses', jsonb_build_array('Khong co network', 'Khong co LinkedIn', 'Tu duy khep kin'),
      'opportunities', jsonb_build_array('Doanh nghiep tuyen gap', 'Chap nhan sinh vien moi neu co thai do cau thi'),
      'threats', jsonb_build_array('Tuyen qua gioi thieu va phong van nhieu vong')
    ),
    'Lap LinkedIn ngay va tham gia hoi nhom ke toan chuyen nghiep de xay network.'
  ),
  (
    7,
    'Giang - Luat',
    'Giang, 21 tuoi, sinh vien nam 3 nganh Luat. Hùng bien tot, phan tich sac ben nhung thieu dinh huong va hay so sanh ban than. Luat cong nghe va so huu tri tue dang thieu nhan luc.',
    jsonb_build_object(
      'strengths', jsonb_build_array('Tu duy phap ly sac ben', 'Ky nang hung bien tot'),
      'weaknesses', jsonb_build_array('Thieu dinh huong', 'Hay so sanh ban than'),
      'opportunities', jsonb_build_array('Luat cong nghe thieu nhan luc', 'Luat so huu tri tue it nguoi biet'),
      'threats', jsonb_build_array('Khong co dinh huong se bo lo co hoi ngach')
    ),
    'Tim hieu va thu thuc tap o van phong luat cong nghe hoac so huu tri tue.'
  ),
  (
    8,
    'Huy - Truyen thong',
    'Huy, 25 tuoi, da di lam 2 nam trong nganh truyen thong. Manh ve network va to chuc su kien, nhung viet content yeu. Thuong hieu dang cat giam ngan sach event truc tiep va dau tu vao content digital.',
    jsonb_build_object(
      'strengths', jsonb_build_array('Network rong', 'Co kinh nghiem to chuc su kien thuc te'),
      'weaknesses', jsonb_build_array('Viet lach yeu', 'Khong co bang cap chuyen nganh'),
      'opportunities', jsonb_build_array('Thuong hieu dau tu manh vao content digital'),
      'threats', jsonb_build_array('Ngan sach su kien bi cat giam')
    ),
    'Tan dung network de hoc content va viet portfolio tu cac su kien da to chuc.'
  ),
  (
    9,
    'Ivy - Ngoai thuong',
    'Ivy, 22 tuoi, sinh vien nam 4 nganh Ngoai thuong. IELTS 7.5, tung trao doi 1 hoc ky tai Singapore nhung thieu quyet doan va ngai xung dot. Chuong trinh Management Trainee uu tien profile quoc te nhung rat ap luc.',
    jsonb_build_object(
      'strengths', jsonb_build_array('Tieng Anh xuat sac', 'Co kinh nghiem quoc te'),
      'weaknesses', jsonb_build_array('Thieu quyet doan', 'Hay lo lang', 'Tranh xung dot'),
      'opportunities', jsonb_build_array('Management Trainee uu tien dung profile'),
      'threats', jsonb_build_array('Ap luc cao va doi hoi ra quyet dinh nhanh')
    ),
    'Luyen ra quyet dinh nhanh qua mock interview va apply Management Trainee co mentor tot.'
  );

insert into public.teams (name, team_code, sort_key)
values
  ('Phong Ban 1', 'TEAM-01', 1),
  ('Phong Ban 2', 'TEAM-02', 2),
  ('Phong Ban 3', 'TEAM-03', 3),
  ('Phong Ban 4', 'TEAM-04', 4),
  ('Phong Ban 5', 'TEAM-05', 5),
  ('Phong Ban 6', 'TEAM-06', 6),
  ('Phong Ban 7', 'TEAM-07', 7),
  ('Phong Ban 8', 'TEAM-08', 8),
  ('Phong Ban 9', 'TEAM-09', 9);

update public.teams as teams
set round2_case_id = cases.id
from public.round2_cases as cases
where teams.sort_key = cases.case_number;

insert into public.round1_questions (question_number, prompt, answer_key, difficulty)
values
  (
    1,
    'Quy trinh dinh vi ban than co may buoc? Ke ten?',
    '3 buoc: Xac dinh muc tieu -> SWOT -> Ke hoach hanh dong',
    'de'
  ),
  (
    2,
    'Trong mo hinh ASK, kien thuc chiem 85% su thanh cong - Dung hay Sai?',
    'Sai - Thai do va ky nang chiem 85%, kien thuc chi 15%',
    'de-co-bay'
  ),
  (
    3,
    'Jeff Bezos noi: Thuong hieu cua ban la nhung gi ban noi ve chinh minh - Dung hay Sai?',
    'Sai - thuong hieu la nhung gi nguoi khac noi ve ban khi ban khong co mat',
    'trung-binh-co-bay'
  ),
  (
    4,
    'Trong SWOT ban than, yeu to nao thuoc moi truong ben ngoai?',
    'Opportunities va Threats',
    'trung-binh'
  ),
  (
    5,
    'Ke hoach hanh dong la buoc thu 2 trong quy trinh dinh vi ban than - Dung hay Sai?',
    'Sai - day la buoc thu 3',
    'kho-co-bay'
  );

insert into public.admin_accounts (display_name, admin_code)
values ('Main Admin', 'ADMIN-UEH');

insert into public.judge_accounts (display_name, judge_code, sort_order)
values
  ('Judge 1', 'JUDGE-01', 1),
  ('Judge 2', 'JUDGE-02', 2),
  ('Judge 3', 'JUDGE-03', 3);

insert into public.game_state (
  singleton,
  phase,
  round_number,
  question_number,
  active_team_id,
  countdown_ends_at,
  is_submission_locked,
  projector_message
)
values
  (
    true,
    'lobby',
    1,
    1,
    null,
    null,
    false,
    'San sang cho Hanh Trinh Thuc Tap Sinh'
  );

select public.refresh_team_points();
select public.refresh_leaderboard();

commit;

