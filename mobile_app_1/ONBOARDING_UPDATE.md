# Onboarding และ Profile Settings Update

## การเปลี่ยนแปลงที่ทำ

### 1. หน้า Welcome/Onboarding (welcome_page.dart)
- สร้างหน้า Welcome ที่เป็นหน้าแรกของแอป
- ตรวจสอบสถานะการ login และความสมบูรณ์ของโปรไฟล์
- ถ้าผู้ใช้ login แล้วและมีโปรไฟล์ครบถ้วน → ไปหน้า CommunityHome
- ถ้าผู้ใช้ login แล้วแต่ยังไม่มีโปรไฟล์ครบถ้วน → ไปหน้า Profile Setup
- ถ้ายังไม่ได้ login → แสดงหน้า Welcome พร้อมปุ่ม Login/Sign Up

### 2. หน้า Profile Settings (profile_settings_page.dart)
- สร้างหน้า Profile Settings ที่รวมการจัดการข้อมูลส่วนตัว
- แบ่งเป็น 4 ส่วน:
  - Personal Information (หน้า SignUp)
  - Disability Information (หน้า Disability)
  - Interests (หน้า Interests)
  - Profile Details (หน้า Final Profile)
- มี progress indicator และการเลือกหน้า

### 3. การแก้ไข main.dart
- เปลี่ยน initial route จาก CommunityHome เป็น WelcomePage
- เพิ่ม routes สำหรับหน้าใหม่:
  - `/` → WelcomePage
  - `/home` → CommunityHome
  - `/profileSettings` → ProfileSettingsPage
  - เพิ่ม routes สำหรับหน้า signup, login, interests, disability, final profile

### 4. การแก้ไข CommunityHome
- เพิ่ม GestureDetector ที่ไอคอนรูปคน
- เมื่อกดไอคอนรูปคนจะไปหน้า Profile Settings

### 5. การแก้ไข Navigation Flow
- Login สำเร็จ → ไปหน้า home
- Interests บันทึกเสร็จ → ไปหน้า home
- Final Profile บันทึกเสร็จ → ไปหน้า home

## การใช้งาน

### สำหรับผู้ใช้ใหม่:
1. เปิดแอป → หน้า Welcome
2. กด Sign Up → กรอกข้อมูลส่วนตัว
3. เลือก Disability → เลือก Interests
4. กรอก Bio และบันทึก → ไปหน้า CommunityHome

### สำหรับผู้ใช้ที่ login แล้ว:
1. เปิดแอป → ตรวจสอบโปรไฟล์
2. ถ้าโปรไฟล์ครบ → ไปหน้า CommunityHome
3. ถ้าโปรไฟล์ไม่ครบ → ไปหน้า Profile Setup

### สำหรับการแก้ไขโปรไฟล์:
1. อยู่ในหน้า CommunityHome
2. กดไอคอนรูปคน → หน้า Profile Settings
3. เลือกส่วนที่ต้องการแก้ไข
4. กด Edit → ไปหน้าแก้ไข
5. บันทึกเสร็จ → กลับหน้า CommunityHome

## ไฟล์ที่สร้างใหม่:
- `lib/screens/welcome_page.dart`
- `lib/screens/profile_settings_page.dart`

## ไฟล์ที่แก้ไข:
- `lib/main.dart`
- `lib/screens/community_home.dart`
- `lib/screens/login_page.dart`
- `lib/screens/interests_page.dart`
- `lib/screens/final_profile_page.dart`
