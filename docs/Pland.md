# Sushi Trio — สิ่งที่ยังไม่ได้ทำ

อ้างอิงจาก `GDD.md` เทียบกับโค้ดล่าสุด (100 ด่าน, อุปสรรค, booster, ร้านค้า, restaurant meta, เสียงชั่วคราว ทำเสร็จแล้ว)

## 1. ค้างจากงานเสียง

- [x] ฟังเสียงจริงบนเครื่อง/simulator: ตอนนี้ยังไม่เคยฟัง ตรวจได้แค่ว่าไฟล์ถูกต้องและ test ผ่าน
- [x] แก้ `IPHONEOS_DEPLOYMENT_TARGET` จาก 13.0 เป็น 15.0 ใน `ios/Runner.xcodeproj/project.pbxproj` (ตอนนี้ build บน simulator ไม่ผ่าน และเป็นปัญหาที่มีอยู่ก่อนแล้ว)
- [ ] ปรับระดับเสียง: ความดัง SFX กับ BGM ยังเป็นค่าเดา (`_sfxVolume`, `_bgmVolume` ใน `lib/services/audio.dart`)
- [x] BGM ร้านละ 1 เพลง ตาม GDD (`bgm_<shop>.wav` 4 เพลง สร้างด้วย `tool/gen_sounds.dart`)
- [ ] เปลี่ยนเสียงชั่วคราวเป็นเสียงจริง โดยวางไฟล์ชื่อเดิมใน `assets/audio/` (ไฟล์ต้องเป็น `.wav` หรือแก้ `lib/services/audio.dart`)
- [x] เสียงปุ่มและเสียงเมนู (ตอนนี้มีแต่เสียงในเกมและตอนซื้อของ)

## 2. Gameplay ที่ GDD ระบุ

- [x] Starter booster ก่อนเริ่มด่าน (Starter Knife / Wasabi): วางชิ้นพิเศษบนกระดานตั้งแต่เริ่ม
- [x] ร้านที่ตกแต่งครบให้รางวัลเหรียญ + booster (ตอนนี้มีเฉพาะเหรียญ `completeCoins`; ยังไม่ให้ booster)
- [x] ด่านเพิ่ม: ตอนนี้มี 100 ด่าน (7 ร้าน) ด่าน 61+ สร้างด้วย `tool/gen_levels.dart`

## 3. Daily และ live ops

- [x] Daily reward 7 วันวนรอบ (ของรางวัลวันที่ 7 ใหญ่สุด) ทำในเครื่องด้วย `shared_preferences` ได้
- [ ] Daily challenge 1 ด่านต่อวัน ใช้ seed เดียวกันทุกคน + leaderboard (leaderboard ต้องมี backend)
- [x] Event รายสัปดาห์ (เช่น "Salmon Week"): หมุนเวียนทุกสัปดาห์จาก `assets/events/events.json` (`lib/core/event.dart`, `lib/services/events.dart`)
- [x] ย้ายตาราง event ไปตั้งค่าผ่าน Remote Config (เขียน `EventConfigSource` ตัวใหม่ แล้ว override `eventScheduleProvider`)

## 4. Monetization (ต้องมีบัญชี AdMob และ store ก่อน)

- [ ] Rewarded ad: +5 moves ตอนแพ้, เติมชีวิต, x2 daily reward
- [ ] Interstitial ad: หลังจบด่าน ไม่เกิน 1 ครั้งต่อ 3 ด่าน และปิดเมื่อซื้ออะไรก็ได้ 1 ครั้ง
- [ ] IAP: แพ็กเหรียญหลายขนาด, Starter pack (แสดงครั้งเดียวหลังด่าน 10), Remove ads
- [ ] Season pass (v2)
- ข้อห้าม: ไม่ทำ loot box สุ่ม และไม่บล็อกด่านด้วย paywall

## 5. Analytics และ backend

- [x] Firebase Analytics ในเกม: `level_start`, `level_win`, `level_fail` (level_id, moves_left, goal_progress, attempt_no), `booster_used`, `shuffle_triggered` (`lib/services/analytics.dart`; `session_start` SDK ส่งให้เอง)
- [ ] Analytics ที่ยังไม่มีฟีเจอร์รองรับ: `ad_rewarded_shown`, `ad_rewarded_completed`, `iap_purchase`, `tutorial_step`
- [x] Firebase Remote Config สำหรับ tuning ความยากโดยไม่ต้องออกอัปเดต
- [ ] Sync progress ขึ้น Firestore (v2)

## 6. เครื่องมือและโครงสร้างโปรเจกต์

- [x] CI: GitHub Actions รัน `flutter analyze` + `flutter test` ทุก PR (ยังไม่มี `.github/`)
- [ ] Deploy ผ่าน Fastlane
- [ ] Level editor บนเว็บ (Flutter web) แก้ layout แล้ว export JSON
- [x] ย้ายไป Riverpod + Hive แล้ว (state เป็น `NotifierProvider`, save ผ่าน `Store` บน Hive; ไม่ได้ย้ายข้อมูลจาก `shared_preferences` เดิม)
- [x] Lint ที่ค้างอยู่: `lib/game/board_component.dart:144` ชื่อพารามิเตอร์ `gameSize` ไม่ตรงกับ `size` ของ method ที่ override

## 7. คำถามที่ยังต้องตัดสินใจ

- [x] Soft launch ไทยอย่างเดียว (ตัดสินใจแล้ว)
- [x] Restaurant meta ทำตั้งแต่ v1 (ทำเสร็จแล้ว ควรติ๊กใน GDD)

## ลำดับที่แนะนำ

1. ปิดงานเสียง: แก้ deployment target → ฟังเสียงจริง → ปรับระดับเสียง
2. Starter booster ก่อนเริ่มด่าน
3. Daily reward 7 วัน
4. GitHub Actions CI
5. Analytics + Remote Config
6. Ads / IAP ก่อน soft launch
