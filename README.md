# KaffeePOS - ระบบขายหน้าร้านสำหรับร้านกาแฟและธุรกิจขนาดเล็ก

**KaffeePOS** เป็นแอปพลิเคชันระบบ Point of Sale (POS) ที่พัฒนาด้วย Flutter โดยเฉพาะสำหรับร้านกาแฟและธุรกิจขนาดเล็ก แอปนี้ออกแบบมาเพื่อช่วยให้เจ้าของร้านสามารถจัดการการขาย รับออร์เดอร์ และพิมพ์ใบเสร็จได้อย่างรวดเร็วและมีประสิทธิภาพ ด้วยระบบจัดการสินค้าตามหมวดหมู่ที่ยืดหยุ่น การสแกน QR Code เพื่อค้นหาใบเสร็จ การพิมพ์ใบเสร็จแบบ thermal printer และระบบ Smart Sync สำหรับนำเข้าข้อมูลสินค้าจาก URL หรือ JSON ทำให้ KaffeePOS เป็นโซลูชันที่สมบูรณ์แบบสำหรับร้านที่ต้องการระบบ POS ที่ทันสมัย ใช้งานง่าย ปรับแต่งได้ และรองรับการทำงานในสภาพแวดล้อมที่มีความเร็วสูง

## 🚀 คุณสมบัติหลัก

### 📱 ระบบจัดการสินค้าและหมวดหมู่
- **จัดการหมวดหมู่สินค้า**: เพิ่ม แก้ไข ลบหมวดหมู่พร้อมกำหนดสี รหัสประจำหมวดหมู่ และความสัมพันธ์กับสินค้า
- **จัดการสินค้าแบบครบครัน**: เพิ่ม แก้ไข ลบสินค้าพร้อมระบุราคา หมวดหมู่ และการตรวจสอบข้อมูล
- **ระบบ Tab แยกตามหมวดหมู่**: แสดงสินค้าแยกตามหมวดหมู่พร้อมแสดงรหัสสีประจำหมวดหมู่และการเลื่อนแท็บได้
- **Grid Layout ที่ปรับได้**: รองรับการแสดงปุ่มสินค้าใน 4 รูปแบบ (3x2, 3x3, 4x2, 4x3) พร้อมการปรับขนาดฟอนต์และ aspect ratio อัตโนมัติ
- **ระบบ Pagination**: แบ่งหน้าสินค้าอัตโนมัติตามจำนวนที่แสดงต่อหน้า พร้อมปุ่มเลื่อนหน้า

### 🛒 ระบบตะกร้าสินค้าและการขาย
- **เพิ่มสินค้าเข้าตะกร้า**: คลิกเพื่อเพิ่มสินค้า ระบบจะรวมจำนวนอัตโนมัติสำหรับสินค้าชนิดเดียวกัน
- **แก้ไขจำนวนสินค้า**: แตะที่รายการในตะกร้าเพื่อปรับจำนวน หรือลบออกด้วย dialog ที่มีปุ่มเพิ่ม/ลด และปุ่มลบ
- **ระบบ Quick Add**: เมื่อซ่อนปุ่มสินค้า สามารถเพิ่มสินค้าผ่าน dialog แบบเร็วที่แสดงสินค้าทั้งหมดในหมวดหมู่
- **การแสดงผล Responsive**: สามารถซ่อน/แสดงปุ่มสินค้าเพื่อขยายพื้นที่ตะกร้า พร้อมระบบจัดการพื้นที่แบบ dynamic

### 🖨️ ระบบพิมพ์ใบเสร็จ
- **พิมพ์ด้วย Sunmi Thermal Printer**: รองรับเครื่องพิมพ์ thermal ของ Sunmi พร้อม Mock Service สำหรับการทดสอบ
- **ใบเสร็จครบถ้วน**: แสดงเลขที่บิล QR Code ชื่อร้าน วันที่-เวลา Transaction ID รายการสินค้า และยอดรวม
- **QR Code บนใบเสร็จ**: สำหรับการติดตาม reference และค้นหาใบเสร็จผ่านระบบสแกน
- **การจัดรูปแบบที่แม่นยำ**: ใช้ monospace font และระบบคำนวณความกว้างพิเศษสำหรับภาษาไทย
- **ระบบพิมพ์ขั้นสูง**: รองรับการแปลงข้อความเป็นรูปภาพสำหรับการจัดวางที่แม่นยำ

### 📋 ระบบจัดการออร์เดอร์และประวัติ
- **บันทึกประวัติการขาย**: เก็บข้อมูลออร์เดอร์ทั้งหมดพร้อมรายละเอียดสินค้า ราคา และข้อมูลร้าน
- **ค้นหาออร์เดอร์ขั้นสูง**: ค้นหาด้วยเลขที่บิล รองรับการค้นหาแบบ partial match และการกรองข้อมูล
- **แก้ไขออร์เดอร์**: สามารถโหลดออร์เดอร์เก่ามาแก้ไขและอัปเดทได้ พร้อมระบบแจ้งเตือนการแก้ไข
- **พิมพ์ใบเสร็จซ้ำ**: พิมพ์ใบเสร็จซ้ำจากประวัติออร์เดอร์ด้วยข้อมูลเดิม
- **หน้ารายละเอียดออร์เดอร์**: แสดงข้อมูลออร์เดอร์แบบใบเสร็จพร้อมปุ่มจัดการและการแสดงผลแบบ responsive

### 📸 ระบบสแกน QR Code ด้วย Mobile Scanner
- **สแกนด้วยกล้อง**: ใช้ Mobile Scanner สแกน QR Code บนใบเสร็จ พร้อมระบบ Permission Management
- **ฟีเจอร์ครบครัน**: เปิด/ปิดแฟลช สลับกล้องหน้า/หลัง overlay สำหรับการเล็ง และระบบป้องกันการสแกนซ้ำ
- **ค้นหาอัตโนมัติ**: หลังสแกนจะค้นหาและเปิดรายละเอียดออร์เดอร์ทันที หรือแจ้งเตือนหากไม่พบ
- **หน้า Debug Scanner**: เครื่องมือทดสอบการทำงานของสแกนเนอร์ พร้อมประวัติการสแกนและ timeout control
- **การจัดการ Permission**: ระบบขอและจัดการ permission กล้องอัตโนมัติ พร้อม dialog แนะนำการตั้งค่า

### 💾 ระบบ Smart Sync ขั้นสูง
- **นำเข้าจาก URL**: รองรับการดาวน์โหลดข้อมูลสินค้าจาก URL ที่เป็นไฟล์ JSON
- **นำเข้าจาก JSON**: วางข้อความ JSON โดยตรงเพื่อนำเข้าข้อมูลสินค้า
- **สร้างหมวดหมู่อัตโนมัติ**: หากหมวดหมู่ไม่มีอยู่ ระบบจะสร้างหมวดหมู่ใหม่พร้อมสีแบบสุ่ม
- **ตรวจสอบข้อมูลซ้ำ**: ป้องกันการเพิ่มสินค้าซ้ำและแสดงสถิติการ sync
- **ตัวอย่างและวิธีใช้**: มี dialog ช่วยเหลือและตัวอย่าง JSON format

### ⚙️ ระบบการตั้งค่าขั้นสูง
- **การตั้งค่าร้าน**: กำหนดชื่อร้านที่จะแสดงบนใบเสร็จ พร้อมตัวอย่างใบเสร็จ
- **การตั้งค่า Grid Layout**: เลือกรูปแบบการแสดงปุ่มสินค้า (3x2, 3x3, 4x2, 4x3) พร้อมตัวอย่าง visual
- **ตัวอย่าง Grid**: แสดงตัวอย่างการจัดวางปุ่มตามการตั้งค่าแบบ real-time
- **ตัวอย่างใบเสร็จ**: แสดงตัวอย่างใบเสร็จพร้อมชื่อร้านที่ตั้งค่า และข้อมูลจำลอง
- **จัดการหมวดหมู่**: เข้าถึงหน้าจัดการหมวดหมู่จากหน้าตั้งค่า
- **Debug Tools**: เครื่องมือทดสอบ Mobile Scanner สำหรับนักพัฒนา

### 💾 ระบบฐานข้อมูล SQLite
- **SQLite Database**: เก็บข้อมูลในเครื่องด้วย SQLite พร้อมการจัดการ transactions
- **Auto Migration**: ระบบอัปเกรดฐานข้อมูลอัตโนมัติจากเวอร์ชัน 1 ถึง 4
- **ข้อมูลเริ่มต้น**: มีหมวดหมู่และการตั้งค่าเริ่มต้นให้ (ทั่วไป, เครื่องดื่ม, อาหาร)
- **Foreign Key Relations**: ความสัมพันธ์ที่ถูกต้องระหว่างตาราง products, categories, orders
- **การจัดการ Settings**: ระบบเก็บค่าตั้งค่าต่างๆ เช่น ชื่อร้าน และ grid layout

### 🎨 User Interface และ UX
- **Dark Theme**: ใช้ธีมสีเข้มที่เหมาะกับการใช้งานร้านอาหาร และสภาพแสงต่างๆ
- **Responsive Design**: ปรับขนาดตามหน้าจอและการใช้งาน รองรับ tablet และ mobile
- **Visual Feedback**: แสดงสถานะการโหลด animations การแจ้งเตือน และสี coding ตามหมวดหมู่
- **Compact Mode**: โหมดแสดงผลแบบกะทัดรัดสำหรับพื้นที่จำกัด
- **Permission Management**: ระบบจัดการ permission ที่เป็นมิตรกับผู้ใช้ พร้อม dialog แนะนำ

## 🛠️ Technical Stack

- **Frontend**: Flutter (Dart) 
- **Database**: SQLite (sqflite) with auto-migration
- **Printer**: Sunmi Printer Plus with mock service
- **Scanner**: Mobile Scanner with permission management
- **HTTP Client**: HTTP package for Smart Sync
- **Permissions**: Permission Handler
- **Date Formatting**: Intl package
- **Architecture**: Clean Architecture with Services and Models

## 📱 ความต้องการระบบ

- **Platform**: Android (เครื่อง Sunmi หรือ Android ทั่วไป)
- **Printer**: Sunmi Thermal Printer (สำหรับการพิมพ์) หรือ Mock Service สำหรับทดสอบ
- **Camera**: กล้องสำหรับสแกน QR Code พร้อม permission
- **Storage**: พื้นที่เก็บข้อมูลสำหรับฐานข้อมูล SQLite
- **Network**: เชื่อมต่ออินเทอร์เน็ตสำหรับ Smart Sync (ไม่บังคับ)

## 🎯 กลุ่มเป้าหมาย

KaffeePOS เหมาะสำหรับ:
- ร้านกาแฟขนาดเล็กถึงกลาง ที่ต้องการระบบที่ใช้งานง่าย
- ร้านอาหารและเครื่องดื่ม ที่ต้องการระบบ POS ที่รวดเร็ว
- ธุรกิจ retail ขนาดเล็ก ที่ต้องการความยืดหยุ่น
- ร้านที่ต้องการระบบ POS ที่ทันสมัยและสามารถปรับแต่งได้
- ผู้ประกอบการที่ต้องการนำเข้าข้อมูลสินค้าแบบ batch

## ✨ จุดเด่นของแอป

1. **ใช้งานง่าย**: UI ที่ออกแบบมาเพื่อความรวดเร็วในการรับออร์เดอร์
2. **ปรับแต่งได้**: สามารถปรับ grid layout จัดการสินค้า และหมวดหมู่ได้อย่างยืดหยุ่น
3. **รองรับฮาร์ดแวร์**: ทำงานร่วมกับเครื่องพิมพ์ thermal และกล้องสแกน QR Code
4. **ครบครัน**: มีครบทุกฟีเจอร์ที่ร้านต้องการ ตั้งแต่การขายไปจนถึงการจัดการข้อมูล
5. **ทันสมัย**: ใช้เทคโนโลยี Flutter ที่ทันสมัยและมีประสิทธิภาพ
6. **Smart Sync**: ระบบนำเข้าข้อมูลที่ทันสมัย รองรับ URL และ JSON
7. **Mobile Scanner**: ระบบสแกน QR Code ที่ทันสมัย พร้อมการจัดการ permission ที่ดี
8. **Offline-First**: ทำงานได้โดยไม่ต้องพึ่งพาระบบออนไลน์หรือค่าธรรมเนียมรายเดือน

KaffeePOS เป็นโซลูชันที่สมบูรณ์แบบสำหรับร้านที่ต้องการระบบ POS ที่ทันสมัย มีประสิทธิภาพ และใช้งานง่าย พร้อมด้วยคุณสมบัติขั้นสูงอย่าง Smart Sync และ Mobile Scanner ที่ช่วยให้การจัดการร้านเป็นเรื่องง่าย

**By Uncle Engineer**
