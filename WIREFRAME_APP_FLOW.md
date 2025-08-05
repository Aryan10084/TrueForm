# 🏋️‍♀️ Formify App Development Plan

## 🧠 Overview
**TrueForm** is a fitness AI mobile app leveraging the phone's camera and pose estimation to track form in real-time. It gives users instant feedback, auto-logs sets/reps, and personalizes plans.

---

## 🗂️ Key Features

- Real-time form feedback (visual + audio)
- Exercise recognition: Push-ups, Pull-ups, Squats, Sit-ups, Planks, Lunges
- Workout plan selector (Beginner → Expert)
- Logging: Sets, reps, accuracy, calories
- Calendar-based history and session tracking
- Subscription/paywall system
- Clean UI (Blue/White, Inter/SF Pro)

---

## 🧱 App Screens Breakdown

| Screen Name            | Key Features |
|------------------------|--------------|
| 1. Splash / Login / Signup | Auth (Firebase), Onboarding setup |
| 2. Dashboard | Welcome UI, Start Workout, Calories, Progress Streak |
| 3. Plan Selector | Difficulty levels (Beginner/Intermediate/Expert/Custom) |
| 4. Workout Type | Choose exercise: Pushups, Pullups, Squats, etc. |
| 5. Live Workout UI | Camera view + pose estimation, accuracy %, reps/sets counters, feedback bars & audio |
| 6. Session Summary | Breakdown of workout (sets, reps, accuracy, time) |
| 7. Calendar History | Logs per day (visual trend, calories, per-exercise stats) |
| 8. Settings | Account info, subscription toggle, logout, tutorial |
| 9. Tutorials Page | Guidance on workouts and camera setup |
| 10. Subscription Screen | Plan details, free trial handling, Stripe/RevenueCat integration |

---

## 🛠️ Tech Stack

- **Frontend**: Flutter (recommended for rapid cross-platform UI)
- **Pose Estimation**: MediaPipe + TensorFlow Lite (TFLite)
- **Backend**: Firebase (Auth, Firestore, Storage, Analytics)
- **Payments**: Stripe / RevenueCat

---

## 🗓️ Development Timeline (Based on Sprint Chart)

### ✅ Stage 1: Initial Setup (June 21 – July 5)
- App Skeleton in Flutter
- Firebase Auth, Firestore integration
- Camera setup test screen
- Push-up detection logic (MediaPipe prototype)

### ✅ Stage 2: Real-time UI Feedback (July 6 – July 18)
- Feedback bar (red/green/%)
- Audio cues on correct rep
- Rep counter logic and overlay UI

### ✅ Stage 3: Additional Exercise Support (July 19 – August 01)
- Add pull-up logic + form detection
- Firebase logging of reps + form accuracy
- Workout screen audio + UI logging

### ✅ Stage 4: Plan Selection + Input UI (August 02 – August 15)
- UI for difficulty levels
- Manual input fields (weight, height, goal)
- Generate plan UI (custom or recommended)

### ✅ Stage 5: UI + Model Buffers (August 16 – August 29)
- Fix FPS issues, optimize pose tracking
- Handle edge UI cases (landscape, low-res)
- Responsive design polish

### ✅ Stage 6: Internal Beta & Fixes (August 30 – September 12)
- APK build & internal test distribution
- Collect early feedback and crash reports
- Fix broken flows and add tutorial pop-ups

### ✅ Stage 7: Expansion Prep (September 13 – September 26)
- Squats, Sit-ups, Lunges integration
- Hooks for future gamification/streaks
- Final polish, code refactor for scale

---

## ✅ Suggested Cursor AI Work Plan (by Stages)

### 🧩 Phase 1: Scaffolding with Cursor
- Scaffold each Flutter screen with basic routing
- Set up Firebase and test login/signup flow
- Build a camera test view with dummy overlay

### 🎯 Phase 2: Pose Estimation & Feedback UI
- Integrate MediaPipe and show real-time landmarks
- Add custom UI on top of camera: accuracy %, bars
- Connect rep detection logic

### 🗃️ Phase 3: State Management & Logging
- Add providers or BLoC for app state
- Store session logs in Firestore (sets, reps, calories)
- Connect timer and stat counters

### 📊 Phase 4: History & Analytics
- Build calendar screen with history pull from Firebase
- Add per-day stats (chart or list UI)
- Connect progress summary logic

### 💳 Phase 5: Monetization & Deployment
- Add subscription screen using RevenueCat/Stripe
- Limit access to some features for free users
- Set up Play Store / TestFlight deployment

---

## 📌 Notes
- All UI flows should match the wireframes in `True_Form_WireFrame_Revised_June042025_v2.pdf`
- Stick to the minimalist blue/white theme throughout
- Focus heavily on camera performance optimization

---

## 📦 Output Deliverables
- 📱 Flutter mobile app (.apk & .ipa ready)
- 🔥 Firebase backend (auth + data)
- 🧠 AI-based pose estimation with form scoring
- 💸 Integrated subscription model
- 📈 Analytics for user session tracking

---

