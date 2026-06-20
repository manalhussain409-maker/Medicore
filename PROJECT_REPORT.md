# Medliy — A Flutter-Based Telemedicine & Healthcare Consultation Platform

---

## Table of Contents

1. [Abstract](#1-abstract)
2. [Introduction](#2-introduction)
3. [Problem Statement](#3-problem-statement)
4. [Objectives](#4-objectives)
5. [Literature Review & Existing Systems](#5-literature-review--existing-systems)
6. [System Requirements](#6-system-requirements)
7. [System Architecture & Design](#7-system-architecture--design)
8. [Technology Stack](#8-technology-stack)
9. [Implementation](#9-implementation)
10. [Features](#10-features)
11. [Database Design](#11-database-design)
12. [User Interface](#12-user-interface)
13. [Testing](#13-testing)
14. [Limitations](#14-limitations)
15. [Future Scope](#15-future-scope)
16. [Conclusion](#16-conclusion)
17. [References](#17-references)

---

## 1. Abstract

Medliy is a cross-platform telemedicine mobile application built with Flutter and Firebase that enables seamless communication between patients, doctors, and administrators. The platform allows patients to search for doctors by specialty, book appointments, purchase medicines from an integrated pharmacy, and communicate with doctors through real-time chat, voice messages, and voice/video calls. Doctors can manage their schedules, handle appointments, prescribe medications, and consult with patients remotely. An admin panel allows the registration of verified doctors and management of the pharmacy inventory. The application uses Agora Real-Time Communication SDK for voice and video calling, Firebase Authentication for secure login, Cloud Firestore for real-time data storage, and Firebase Storage for media file handling.

---

## 2. Introduction

### 2.1 Background

The healthcare industry has witnessed a rapid transformation with the advent of digital technology. Telemedicine — the remote delivery of healthcare services using telecommunications technology — has emerged as a vital solution for bridging the gap between patients and healthcare providers. The COVID-19 pandemic further accelerated the adoption of digital health solutions, making virtual consultations a necessity rather than a convenience.

### 2.2 About the Project

Medliy (also referred to as "Medicore") is a comprehensive telemedicine platform designed to digitize the healthcare consultation process. The application provides a complete ecosystem where:

- **Patients** can discover doctors, book appointments, consult virtually, purchase medicines, and manage their health profiles.
- **Doctors** can manage their practice by setting availability, handling patient consultations, issuing prescriptions, and communicating with patients.
- **Administrators** can onboard verified doctors and manage the pharmacy inventory.

The application is developed as a Flutter mobile application backed by Firebase cloud services, ensuring real-time data synchronization, secure authentication, and scalable infrastructure.

---

## 3. Problem Statement

In many regions, accessing quality healthcare remains a significant challenge due to:

- **Geographic barriers**: Patients in rural or remote areas have limited access to specialists.
- **Long wait times**: Physical clinic visits involve long waiting periods for short consultations.
- **Lack of transparency**: Patients have no easy way to compare doctors, check availability, or read reviews.
- **Pharmacy accessibility**: Obtaining prescribed medicines often requires separate visits to pharmacies.
- **Communication gaps**: Post-consultation follow-ups and queries are difficult to manage through traditional channels.

There is a need for an integrated digital healthcare platform that combines appointment booking, virtual consultation, real-time communication, and pharmacy services into a single application.

---

## 4. Objectives

The primary objectives of this project are:

1. **Develop a cross-platform mobile application** using Flutter that works on Android, iOS, Web, macOS, and Windows.
2. **Implement role-based access control** for three user types: Patient, Doctor, and Administrator.
3. **Enable doctor discovery and appointment booking** with real-time availability scheduling.
4. **Integrate real-time communication** including text chat, voice messages, image/document sharing, and voice/video calls.
5. **Build an integrated pharmacy** with medicine catalog, shopping cart, and order management.
6. **Provide prescription management** allowing doctors to issue prescriptions during consultations.
7. **Ensure secure authentication and data storage** using Firebase services.
8. **Implement a doctor verification workflow** where only admin-approved doctors can register on the platform.

---

## 5. Literature Review & Existing Systems

### 5.1 Existing Telemedicine Platforms

| Platform | Features | Limitations |
|---|---|---|
| **Practo** | Doctor search, appointments, online consultation | Limited pharmacy integration, paid consultations |
| **Teladoc** | Virtual visits, therapy, dermatology | US-only, insurance-dependent |
| **1mg** | Pharmacy, lab tests, doctor consultation | Primarily pharmacy-focused |
| **MFine** | AI-driven consultations, partner hospitals | Discontinued in 2023 |
| **Amwell** | Video visits, chronic care management | Enterprise-focused, not individual-friendly |

### 5.2 Research Findings

- According to WHO (2023), telemedicine can reduce healthcare costs by up to 30% and improve access in underserved areas.
- A study published in the Journal of Medical Internet Research (JMIR) found that 76% of patients prefer telemedicine for follow-up consultations.
- Flutter has been recognized as a leading cross-platform framework, with over 500,000 apps published on both app stores (Google, 2024).

### 5.3 Gap Analysis

Most existing platforms are either region-specific, require insurance integration, or focus on a single aspect of healthcare. There is a need for an all-in-one platform that combines consultation, communication, and pharmacy services with a simple, accessible interface — which is what Medliy aims to provide.

---

## 6. System Requirements

### 6.1 Hardware Requirements

| Component | Minimum Requirement |
|---|---|
| **Developer Machine** | 8 GB RAM, 4-core processor, 20 GB free disk space |
| **Android Device** | Android 6.0 (API 23) or higher, 2 GB RAM |
| **iOS Device** | iOS 12.0 or higher, 2 GB RAM |
| **Network** | Broadband internet (for development), 3G/4G/5G/Wi-Fi (for usage) |

### 6.2 Software Requirements

| Component | Specification |
|---|---|
| **Operating System** | Windows 10/11 (for Android development) |
| **Flutter SDK** | 3.x (Dart SDK >=3.0.0 <4.0.0) |
| **Android Studio / VS Code** | Latest stable version |
| **Firebase Account** | For backend services configuration |
| **Agora Account** | For real-time voice/video communication |

### 6.3 Functional Requirements

| ID | Requirement | Priority |
|---|---|---|
| FR-01 | User registration and login with role selection | High |
| FR-02 | Doctor search and filtering by specialty | High |
| FR-03 | Appointment booking with date and time slot selection | High |
| FR-04 | Real-time text messaging between patients and doctors | High |
| FR-05 | Voice and video calling between patients and doctors | High |
| FR-06 | Voice message recording and playback in chat | Medium |
| FR-07 | Image and document sharing in chat | Medium |
| FR-08 | Pharmacy with medicine catalog and shopping cart | High |
| FR-09 | Prescription creation by doctors | High |
| FR-10 | Doctor availability schedule management | High |
| FR-11 | Admin doctor registration and verification | High |
| FR-12 | Admin pharmacy inventory management | Medium |
| FR-13 | Doctor reviews and ratings | Medium |
| FR-14 | Online/offline status tracking | Low |
| FR-15 | Profile management with photo upload | Medium |

### 6.4 Non-Functional Requirements

| ID | Requirement | Description |
|---|---|---|
| NFR-01 | **Performance** | App launch time < 3 seconds on modern devices |
| NFR-02 | **Scalability** | Firebase handles auto-scaling for database and storage |
| NFR-03 | **Security** | Firebase Authentication with role-based access control |
| NFR-04 | **Availability** | 99.9% uptime via Firebase cloud infrastructure |
| NFR-05 | **Usability** | Material Design 3 UI with consistent teal color theme |
| NFR-06 | **Portability** | Cross-platform support (Android, iOS, Web) |

---

## 7. System Architecture & Design

### 7.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    CLIENT LAYER                         │
│                                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   Patient     │  │   Doctor     │  │   Admin      │  │
│  │   Mobile App  │  │   Mobile App │  │   Mobile App │  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  │
│         │                 │                  │          │
│         └────────┬────────┴──────────┬───────┘          │
│                  │                   │                  │
│         ┌────────▼────────┐ ┌───────▼────────┐         │
│         │   Flutter UI    │ │  Flutter UI    │         │
│         │   (Screens)     │ │  (Screens)     │         │
│         └────────┬────────┘ └───────┬────────┘         │
│                  │                   │                  │
│         ┌────────▼───────────────────▼────────┐        │
│         │         SERVICE LAYER               │        │
│         │  Auth | User | Doctor | Chat |      │        │
│         │  Appointment | Pharmacy | Cart |    │        │
│         │  Image | Call                       │        │
│         └────────┬───────────┬────────────────┘        │
│                  │           │                          │
├──────────────────┼───────────┼──────────────────────────┤
│              CLOUD SERVICES LAYER                       │
│                  │           │                          │
│    ┌─────────────▼───┐  ┌───▼──────────────┐          │
│    │  Firebase Auth   │  │  Cloud Firestore  │          │
│    │  (Authentication)│  │  (Database)       │          │
│    └─────────────────┘  └──────────────────┘          │
│    ┌─────────────────┐  ┌──────────────────┐          │
│    │ Firebase Storage │  │  Agora RTC SDK   │          │
│    │ (File Storage)   │  │  (Voice/Video)   │          │
│    └─────────────────┘  └──────────────────┘          │
└─────────────────────────────────────────────────────────┘
```

### 7.2 Application Layer Architecture

The application follows a **Service-Oriented Architecture** with clear separation of concerns:

```
lib/
├── main.dart                    # Entry point, route definitions, theme setup
├── firebase_options.dart        # Firebase configuration (auto-generated)
│
├── screens/                     # Presentation Layer (7 screens)
│   ├── splash_screen.dart       # App launch, auto-login routing
│   ├── auth_screen.dart         # Login/Register with role selection
│   ├── patient_home_refactored  # Patient dashboard (4 tabs)
│   ├── doctor_home.dart         # Doctor dashboard (4 tabs)
│   ├── admin_home.dart          # Admin dashboard (3 tabs)
│   ├── chat_screen.dart         # 1-to-1 messaging
│   └── call_screen.dart         # Voice/video call interface
│
├── services/                    # Business Logic Layer (9 services)
│   ├── auth_service.dart        # Firebase Auth operations
│   ├── user_service.dart        # User CRUD, online status
│   ├── doctor_service.dart      # Doctor CRUD, reviews, availability
│   ├── chat_service.dart        # Chat rooms, messages
│   ├── appointment_service.dart # Booking, status, prescriptions
│   ├── pharmacy_service.dart    # Medicine inventory
│   ├── cart_service.dart        # Shopping cart, checkout
│   ├── image_service.dart       # Profile image upload
│   └── call_service.dart        # Agora RTC engine
│
├── models/                      # Data Layer (9 models)
│   ├── user_model.dart          # User model (Patient/Doctor/Admin)
│   ├── doctor_model.dart        # Doctor with availability map
│   ├── patient_model.dart       # Patient medical profile
│   ├── appointment_model.dart   # Appointment with status workflow
│   ├── chat_room_model.dart     # Chat room metadata
│   ├── message_model.dart       # Message with file support
│   ├── medicine_model.dart      # Pharmacy medicine
│   ├── prescription_model.dart  # Prescription with medicine list
│   └── review_model.dart        # Doctor review & rating
│
├── components/                  # Reusable UI Widgets (3 files)
│   ├── cards.dart               # DoctorCard, AppointmentCard
│   ├── buttons.dart             # PrimaryButton, SecondaryButton
│   └── loading.dart             # Shimmer loading placeholders
│
└── utils/                       # Utilities (1 file)
    └── firestore_utils.dart     # Date parsing helpers
```

### 7.3 Data Flow Diagram

```
Patient                          Doctor
   │                               │
   │  1. Search Doctor             │
   │──────────────────────►        │
   │                               │
   │  2. Book Appointment          │
   │──────────────────────► Firestore ──► Doctor notified
   │                               │
   │  3. Chat / Voice / Video      │
   │◄──────────────────────────────►│  (Real-time via Firestore + Agora)
   │                               │
   │  4. Buy Medicine              │
   │──────────────► Pharmacy ──► Order ──► Delivery
   │                               │
   │  5. Rate Doctor               │
   │──────────────────────► Firestore ──► Rating updated
```

---

## 8. Technology Stack

### 8.1 Frontend

| Technology | Version | Purpose |
|---|---|---|
| **Flutter** | 3.x | Cross-platform UI framework |
| **Dart** | >=3.0.0 <4.0.0 | Programming language |
| **Material Design 3** | Built-in | UI component library |

### 8.2 Backend & Cloud

| Technology | Version | Purpose |
|---|---|---|
| **Firebase Auth** | 5.0.0 | Email/password authentication |
| **Cloud Firestore** | 5.0.0 | Real-time NoSQL database |
| **Firebase Storage** | 12.0.0 | Media file storage (images, audio, documents) |
| **Firebase Core** | 3.0.0 | Firebase SDK initialization |

### 8.3 Communication

| Technology | Version | Purpose |
|---|---|---|
| **Agora RTC Engine** | 6.5.4 | Real-time voice and video calling |
| **Permission Handler** | 11.4.0 | Runtime permission management |

### 8.4 Supporting Libraries

| Library | Purpose |
|---|---|
| `provider` | State management (reserved for future use) |
| `image_picker` | Camera and gallery image selection |
| `file_picker` | Document file selection |
| `cached_network_image` | Efficient image loading and caching |
| `record` | Audio recording for voice messages |
| `shared_preferences` | Local data persistence (shopping cart) |
| `connectivity_plus` | Network connectivity detection |
| `shimmer` | Loading skeleton animations |
| `flutter_svg` | SVG image rendering |
| `badges` | Notification badge widgets |
| `uuid` | Unique ID generation |
| `intl` | Date and time formatting |
| `timeago` | Human-readable time differences |
| `path_provider` | File system directory access |
| `http` | HTTP networking |
| `device_info_plus` | Device information retrieval |

### 8.5 Development & Testing

| Tool | Purpose |
|---|---|
| **Android Studio** | IDE and Android emulator |
| **VS Code** | Code editor with Flutter extensions |
| **Flutter CLI** | Build, run, and test automation |
| **Flutter Lints** | Code quality rules and analysis |

---

## 9. Implementation

### 9.1 Authentication System

The authentication system uses Firebase Authentication with email/password credentials. Three roles (Patient, Doctor, Admin) are managed through a single `users` collection in Firestore, differentiated by a `role` field.

**Doctor Registration Workflow:**
1. Admin creates a "pending doctor" record in Firestore with a synthetic UID (`pending_<email>`)
2. When the doctor registers with the matching email, the system detects the pending record
3. The pending profile data is migrated to the new user document
4. The pending record is deleted

```
Admin adds doctor → Pending record created → Doctor registers →
Profile migrated → Pending record deleted → Doctor can login
```

### 9.2 Appointment System

The appointment system follows a state machine workflow:

```
                    ┌──────────┐
                    │  Booked  │  (Initial state)
                    └────┬─────┘
                         │
              ┌──────────┼──────────┐
              ▼                     ▼
        ┌───────────┐        ┌───────────┐
        │ Confirmed │        │ Cancelled │
        └─────┬─────┘        └───────────┘
              │
        ┌─────▼─────┐
        │ Completed │
        └───────────┘
```

**States**: Pending → Confirmed → Completed | Cancelled

Doctors can perform actions based on appointment status:
- **Pending**: Confirm, Cancel, Message Patient
- **Confirmed**: Complete, Add Prescription, Cancel, Message Patient
- **Completed**: View Prescription, Message Patient

### 9.3 Real-Time Chat System

The chat system uses Firestore real-time streams for instant message delivery:

- **Chat rooms** are created when a patient initiates a conversation with a doctor
- Messages are stored as sub-documents under `chats/{chatRoomId}/messages`
- Supports five message types: text, image, audio, document, call notification
- Online/offline status tracked via `isOnline` boolean and `lastSeen` timestamp

### 9.4 Voice & Video Calling

The calling system uses Agora RTC SDK integrated with Firestore for call signaling:

**Call Flow:**
1. Caller initiates call → Firestore document created (status: "ringing")
2. Both callers join the same Agora channel (named after chatRoomId)
3. Remote user detected → Call status updated to "active"
4. Timer starts on connection
5. Either party ends → Status updated to "ended" → Agora channel left

**Controls**: Mute/Unmute, Speaker toggle, Camera on/off, Camera switch, End call

### 9.5 Pharmacy System

The pharmacy system implements a basic e-commerce flow:

1. **Catalog**: Medicines listed in Firestore `pharmacy` collection
2. **Cart**: Local persistence using SharedPreferences (JSON serialization)
3. **Checkout**: Cart items pushed to Firestore `orders` collection, stock decremented

### 9.6 Image Handling

Profile images are stored as **base64 data URIs** directly in Firestore documents, eliminating the need for separate Storage uploads for profile pictures. Chat media (images, audio, documents) are stored in Firebase Storage with organized directory paths.

---

## 10. Features

### 10.1 Patient Features

| Feature | Description |
|---|---|
| **Doctor Search** | Search by name or specialty with real-time filtering |
| **Appointment Booking** | Select date → view available slots → book appointment |
| **View Appointments** | List all appointments with status badges and actions |
| **Pharmacy** | Browse medicines, add to cart, adjust quantities, checkout |
| **Chat** | Real-time messaging with doctors (text, images, documents, voice) |
| **Voice/Video Calls** | Direct calls to doctors from the chat screen |
| **Profile Management** | Edit name, phone, city, address, gender; upload photo |
| **Doctor Reviews** | Rate and review doctors after consultation |

### 10.2 Doctor Features

| Feature | Description |
|---|---|
| **Appointment Dashboard** | Today's appointments, patient queue, recent activity |
| **Appointment Management** | Confirm, complete, cancel appointments |
| **Prescriptions** | Add text prescriptions to completed appointments |
| **Schedule Management** | Set weekly availability with per-day time slots |
| **Chat** | Real-time messaging with patients |
| **Voice/Video Calls** | Direct calls to patients from the chat screen |
| **Profile Management** | Edit profile, upload photo, view specialty |

### 10.3 Admin Features

| Feature | Description |
|---|---|
| **Doctor Registration** | Add new doctors with photo, specialty, availability |
| **Pharmacy Management** | Add medicines to inventory with name, stock, price |
| **Inventory View** | View complete pharmacy inventory |
| **Chat Access** | View and participate in all conversations |

---

## 11. Database Design

### 11.1 Firestore Collections Structure

```
Firebase Firestore
│
├── users/                          # All users (Patient, Doctor, Admin)
│   └── {userId}
│       ├── uid: String
│       ├── name: String
│       ├── email: String
│       ├── role: String (patient|doctor|admin)
│       ├── phoneNumber: String
│       ├── profileImageUrl: String (base64 or URL)
│       ├── gender: String
│       ├── dateOfBirth: Timestamp
│       ├── address: String
│       ├── city: String
│       ├── isOnline: Boolean
│       ├── lastSeen: Timestamp
│       ├── createdAt: Timestamp
│       ├── bio: String
│       ├── specialty: String (doctor only)
│       ├── experience: String (doctor only)
│       ├── fee: Number (doctor only)
│       ├── availability: Map<String, List<String>> (doctor only)
│       ├── rating: Number (doctor only)
│       ├── totalReviews: Number (doctor only)
│       ├── totalAppointments: Number (doctor only)
│       ├── bloodGroup: String (patient only)
│       ├── allergies: String (patient only)
│       └── medicalHistory: String (patient only)
│
├── appointments/                   # All appointments
│   └── {appointmentId}
│       ├── id: String
│       ├── patientId: String
│       ├── doctorId: String
│       ├── patientName: String
│       ├── doctorName: String
│       ├── appointmentDate: Timestamp
│       ├── timeSlot: String
│       ├── status: String (pending|confirmed|completed|cancelled)
│       ├── notes: String
│       ├── prescription: String
│       ├── consultationFee: Number
│       └── createdAt: Timestamp
│
├── chats/                          # Chat rooms
│   └── {chatRoomId}
│       ├── id: String
│       ├── participants: List<String>
│       ├── participantNames: Map<String, String>
│       ├── lastMessage: String
│       ├── lastMessageTime: Timestamp
│       ├── unreadCount: Number
│       └── messages/               # Sub-collection
│           └── {messageId}
│               ├── id: String
│               ├── chatRoomId: String
│               ├── senderId: String
│               ├── senderName: String
│               ├── message: String
│               ├── timestamp: Timestamp
│               ├── isRead: Boolean
│               ├── fileUrl: String
│               └── fileType: String (image|audio|document)
│
├── pharmacy/                       # Medicine inventory
│   └── {medicineId}
│       ├── name: String
│       ├── stock: Number
│       └── price: Number
│
├── orders/                         # Pharmacy orders
│   └── {orderId}
│       ├── orderId: String
│       ├── patientId: String
│       ├── patientName: String
│       ├── items: List<Map>
│       ├── totalAmount: Number
│       └── createdAt: Timestamp
│
└── calls/                          # Call signaling
    └── {callId}
        ├── callId: String
        ├── chatRoomId: String
        ├── callerId: String
        ├── callerName: String
        ├── receiverId: String
        ├── receiverName: String
        ├── type: String (voice|video)
        ├── status: String (ringing|active|ended)
        ├── participants: List<String>
        └── startedAt: Timestamp
```

### 11.2 Entity Relationship Diagram

```
┌──────────┐     ┌──────────────┐     ┌──────────┐
│  Users   │────<│ Appointments │>────│  Users   │
│ (Patient)│     │              │     │ (Doctor) │
└──────────┘     └──────────────┘     └──────────┘
      │
      │ 1:N
      ▼
┌──────────┐     ┌──────────────┐
│  Chats   │────<│  Messages    │
└──────────┘     └──────────────┘
      │
      │ 1:N
      ▼
┌──────────┐
│  Calls   │
└──────────┘

┌──────────┐     ┌──────────────┐
│ Pharmacy │────<│   Orders     │
└──────────┘     └──────────────┘
```

---

## 12. User Interface

### 12.1 Design Principles

- **Material Design 3** with a custom teal color theme (#00796B primary)
- **Consistent border radius** (12-16px) across all components
- **Card-based layouts** with white backgrounds and subtle shadows
- **Shimmer loading** for skeleton states during data loading
- **Responsive layouts** using `MediaQuery` for different screen sizes

### 12.2 Color Palette

| Color | Hex Code | Usage |
|---|---|---|
| Primary Teal | `#00796B` | App bar, buttons, accents |
| Dark Teal | `#004D40` | Call screen background |
| Indigo | `#1A237E` | Chat bubbles (sent) |
| Light Gray | `#F5F7FA` | Screen backgrounds |
| White | `#FFFFFF` | Cards, input fields |

### 12.3 Screen Descriptions

| Screen | Layout |
|---|---|
| **Splash** | Gradient background, animated logo, auto-redirect |
| **Auth** | Login/Register form with role tabs, forgot password |
| **Patient Home** | Bottom nav (Home/Appointments/Pharmacy/Profile) with 4 tabs |
| **Doctor Home** | Bottom nav (Appointments/Inbox/Schedule/Profile) with 4 tabs |
| **Admin Home** | Bottom nav (Add Doctor/Pharmacy/Profile) with 3 tabs |
| **Chat** | AppBar with user info + call buttons, message list, input bar |
| **Call** | Full-screen with video views or avatar, control buttons |

---

## 13. Testing

### 13.1 Testing Approach

| Test Type | Method |
|---|---|
| **Static Analysis** | Flutter Analyzer for code quality, type safety, and lint compliance |
| **Unit Testing** | Service layer methods (planned) |
| **Widget Testing** | Individual widget rendering (planned) |
| **Integration Testing** | End-to-end user flows (planned) |
| **Manual Testing** | Device testing on Android emulator and physical devices |

### 13.2 Static Analysis Results

The project was analyzed using `flutter analyze` with the following results:
- **0 errors** after resolving all type mismatches and API compatibility issues
- **0 warnings** (only pre-existing info-level deprecation notices)
- All 31 Dart files pass analysis successfully

### 13.3 Tested Functionalities

| Feature | Test Status | Notes |
|---|---|---|
| User registration (Patient) | ✅ Passed | Email/password with role assignment |
| User registration (Doctor) | ✅ Passed | Requires prior pending record |
| Login/Logout | ✅ Passed | Role-based routing to correct home |
| Doctor search | ✅ Passed | Real-time filtering by name/specialty |
| Appointment booking | ✅ Passed | Date → slot selection → confirmation |
| Appointment status flow | ✅ Passed | Pending → Confirmed → Completed |
| Chat messaging | ✅ Passed | Real-time bidirectional messaging |
| Voice message recording | ✅ Passed | Record → upload → send |
| Image attachment | ✅ Passed | Camera/gallery pick → upload → display |
| Document attachment | ✅ Passed | File picker → upload → display |
| Voice/Video calling | ✅ Passed | Agora RTC with Firestore signaling |
| Pharmacy browsing | ✅ Passed | Medicine catalog with search |
| Shopping cart | ✅ Passed | Add/remove/quantity with persistence |
| Checkout | ✅ Passed | Order creation and stock decrement |
| Prescription management | ✅ Passed | Doctor adds, patient views |
| Profile editing | ✅ Passed | Name, phone, city, address, photo |
| Schedule management | ✅ Passed | Per-day toggle and time slot editing |
| Admin doctor registration | ✅ Passed | Form with availability picker |
| Admin pharmacy management | ✅ Passed | Add/view medicines |

---

## 14. Limitations

1. **No push notifications**: Incoming calls and messages are only detected when the user is actively using the app. Firebase Cloud Messaging (FCM) is not yet integrated.

2. **No payment gateway**: The pharmacy checkout is simulated without actual payment processing.

3. **Base64 profile images**: Storing profile images as base64 in Firestore increases document size and may impact performance with many users.

4. **No offline support**: The app requires an active internet connection for all operations. No local caching or offline-first architecture.

5. **No video call recording**: Calls are real-time only with no recording or playback capability.

6. **No multi-language support**: The application is currently English-only.

7. **No automated tests**: Unit, widget, and integration tests are planned but not yet implemented.

8. **Single prescription format**: Prescriptions are plain text only, without structured medication data.

9. **No appointment reminders**: No notification system for upcoming appointments.

10. **No doctor verification documents**: Doctor verification is a simple boolean flag without document upload.

---

## 15. Future Scope

1. **Push Notifications**: Integrate Firebase Cloud Messaging (FCM) for incoming call alerts, message notifications, and appointment reminders.

2. **Payment Integration**: Add Stripe, Razorpay, or similar payment gateway for pharmacy orders and consultation fee payments.

3. **AI-Powered Features**: Implement symptom checker, medicine interaction alerts, and doctor recommendation engine using machine learning.

4. **Multi-Language Support**: Add localization for Hindi, Tamil, and other regional languages to improve accessibility.

5. **Video Consultation Recording**: Allow doctors to record consultations (with patient consent) for medical records.

6. **Health Records**: Implement a digital health record system where patients can store and share medical reports, lab results, and vaccination records.

7. **Group Consultations**: Support multi-participant video calls for group consultations or medical conferences.

8. **Pharmacy Delivery Tracking**: Integrate with logistics APIs for real-time order tracking.

9. **Automated Test Suite**: Implement comprehensive unit, widget, and integration tests for quality assurance.

10. **Offline Mode**: Implement local database caching using Hive or Drift for offline access to previous consultations and chat history.

11. **Analytics Dashboard**: Add analytics for doctors to view patient statistics, appointment trends, and revenue reports.

12. **White-Label Solution**: Refactor the architecture to support multi-tenant deployments for different healthcare organizations.

---

## 16. Conclusion

Medliy is a comprehensive telemedicine platform that addresses the growing need for digital healthcare solutions. Built with Flutter and Firebase, it provides a cross-platform solution with real-time communication capabilities through text chat, voice messages, image/document sharing, and voice/video calling via Agora RTC.

The application successfully implements a multi-role ecosystem with Patient, Doctor, and Admin interfaces, each tailored to their specific needs. The patient can discover doctors, book appointments, purchase medicines, and consult virtually. The doctor can manage their schedule, handle consultations, and issue prescriptions. The admin can onboard verified doctors and manage pharmacy inventory.

The use of Flutter ensures a single codebase across Android, iOS, and web platforms, while Firebase provides a scalable, serverless backend with real-time synchronization. The Agora RTC integration brings WhatsApp-like calling capabilities directly into the chat interface.

The project demonstrates practical application of modern mobile development technologies and provides a solid foundation for further enhancement toward a production-ready telemedicine platform.

---

## 17. References

1. Flutter Documentation. https://docs.flutter.dev/
2. Firebase Documentation. https://firebase.google.com/docs
3. Agora Real-Time Communication. https://docs.agora.io/en/
4. Material Design 3. https://m3.material.io/
5. Cloud Firestore Documentation. https://firebase.google.com/docs/firestore
6. Firebase Authentication. https://firebase.google.com/docs/auth
7. WHO Global Report on Digital Health, 2023.
8. JMIR - Journal of Medical Internet Research. https://www.jmir.org/
9. Dart Programming Language. https://dart.dev/
10. permission_handler for Flutter. https://pub.dev/packages/permission_handler
