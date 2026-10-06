# Sushi Match — สิ่งที่ยังไม่ได้ทำ

อ้างอิงจาก `Sushi Match — GDD.md` เทียบกับโค้ดล่าสุด (60 ด่าน, อุปสรรค, booster, ร้านค้า, restaurant meta, เสียงชั่วคราว ทำเสร็จแล้ว)

## 1. ค้างจากงานเสียง

- [ ] ฟังเสียงจริงบนเครื่อง/simulator: ตอนนี้ยังไม่เคยฟัง ตรวจได้แค่ว่าไฟล์ถูกต้องและ test ผ่าน
- [ ] แก้ `IPHONEOS_DEPLOYMENT_TARGET` จาก 13.0 เป็น 15.0 ใน `ios/Runner.xcodeproj/project.pbxproj` (ตอนนี้ build บน simulator ไม่ผ่าน และเป็นปัญหาที่มีอยู่ก่อนแล้ว)
- [ ] ปรับระดับเสียง: ความดัง SFX กับ BGM ยังเป็นค่าเดา (`_sfxVolume`, `_bgmVolume` ใน `lib/services/audio.dart`)
- [ ] BGM ร้านละ 1 เพลง ตาม GDD (ตอนนี้ทุกร้านใช้ `bgm.wav` เพลงเดียว)
- [ ] เปลี่ยนเสียงชั่วคราวเป็นเสียงจริง โดยวางไฟล์ชื่อเดิมใน `assets/audio/` (ไฟล์ต้องเป็น `.wav` หรือแก้ `lib/services/audio.dart`)
- [ ] เสียงปุ่มและเสียงเมนู (ตอนนี้มีแต่เสียงในเกมและตอนซื้อของ)

## 2. Gameplay ที่ GDD ระบุ

- [ ] Starter booster ก่อนเริ่มด่าน (Starter Knife / Wasabi): วางชิ้นพิเศษบนกระดานตั้งแต่เริ่ม
- [ ] ร้านที่ตกแต่งครบให้รางวัลเหรียญ + booster (ตอนนี้มีเฉพาะเหรียญ `completeCoins`; ยังไม่ให้ booster)
- [ ] ด่านเพิ่ม: ตอนนี้มี 60 ด่าน (4 ร้าน ร้านละ 15 ด่าน)

## 3. Daily และ live ops

- [ ] Daily reward 7 วันวนรอบ (ของรางวัลวันที่ 7 ใหญ่สุด) ทำในเครื่องด้วย `shared_preferences` ได้
- [ ] Daily challenge 1 ด่านต่อวัน ใช้ seed เดียวกันทุกคน + leaderboard (leaderboard ต้องมี backend)
- [ ] Event รายสัปดาห์ (เช่น "Salmon Week") ตั้งค่าผ่าน Remote Config

## 4. Monetization (ต้องมีบัญชี AdMob และ store ก่อน)

- [ ] Rewarded ad: +5 moves ตอนแพ้, เติมชีวิต, x2 daily reward
- [ ] Interstitial ad: หลังจบด่าน ไม่เกิน 1 ครั้งต่อ 3 ด่าน และปิดเมื่อซื้ออะไรก็ได้ 1 ครั้ง
- [ ] IAP: แพ็กเหรียญหลายขนาด, Starter pack (แสดงครั้งเดียวหลังด่าน 10), Remove ads
- [ ] Season pass (v2)
- ข้อห้าม: ไม่ทำ loot box สุ่ม และไม่บล็อกด่านด้วย paywall

## 5. Analytics และ backend

- [ ] Firebase Analytics: `level_start`, `level_win`, `level_fail` (level_id, moves_left, goal_progress, attempt_no), `booster_used`, `ad_rewarded_shown`, `ad_rewarded_completed`, `iap_purchase`, `tutorial_step`, `shuffle_triggered`, `session_start`
- [ ] Firebase Remote Config สำหรับ tuning ความยากโดยไม่ต้องออกอัปเดต
- [ ] Sync progress ขึ้น Firestore (v2)

## 6. เครื่องมือและโครงสร้างโปรเจกต์

- [ ] CI: GitHub Actions รัน `flutter analyze` + `flutter test` ทุก PR (ยังไม่มี `.github/`)
- [ ] Deploy ผ่าน Fastlane
- [ ] Level editor บนเว็บ (Flutter web) แก้ layout แล้ว export JSON
- [ ] GDD ระบุ Riverpod + Hive ไว้ ตอนนี้ใช้ `ValueNotifier` + `shared_preferences` ตัดสินใจว่าจะย้ายหรือแก้ GDD ให้ตรงกับของจริง
- [ ] Lint ที่ค้างอยู่: `lib/game/board_component.dart:144` ชื่อพารามิเตอร์ `gameSize` ไม่ตรงกับ `size` ของ method ที่ override

## 7. คำถามที่ยังต้องตัดสินใจ

- [ ] Soft launch ไทยอย่างเดียว หรือเพิ่มตลาด SEA อีก 1 ประเทศ
- [x] Restaurant meta ทำตั้งแต่ v1 (ทำเสร็จแล้ว ควรติ๊กใน GDD)

## ลำดับที่แนะนำ

1. ปิดงานเสียง: แก้ deployment target → ฟังเสียงจริง → ปรับระดับเสียง
2. Starter booster ก่อนเริ่มด่าน
3. Daily reward 7 วัน
4. GitHub Actions CI
5. Analytics + Remote Config
6. Ads / IAP ก่อน soft launch
