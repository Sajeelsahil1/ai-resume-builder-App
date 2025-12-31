# AI Resume Builder

A modern **AI-powered Resume / CV Builder** built with **Flutter**, **Firebase**, and **Google Generative AI (Gemini)**.  
Create, manage, customize, and export professional resumes as **high-quality PDFs** using multiple templates and real-time cloud storage.

---

## 🚀 Features

- Create and manage multiple resumes
- 6 professionally designed resume templates
- AI-powered content generation (summary & cover letter)
- Resume strength score (0–100%)
- Custom resume sections (Projects, Achievements, etc.)
- Real-time auto-save with Firestore
- Anonymous authentication (no signup required)
- PDF export with print support
- QR code for portfolio links
- Duplicate and delete resumes
- Responsive UI (Mobile & Web)

---

## 🎨 Available Templates

- Modern Blue  
- Classic Green  
- Professional Red  
- Elegant Orange  
- Creative Violet  
- Clean Grey  

Each template supports:
- Sidebar or header layouts
- Dynamic colors
- Automatic content scaling

---

## 🛠 Tech Stack

- **Flutter (Dart)**
- **Firebase Authentication**
- **Cloud Firestore**
- **Google Generative AI (Gemini)**
- **Provider (State Management)**
- **PDF & Printing**
- **Shared Preferences**
- **Google Fonts**

---

yaml
---

## ⚙️ Setup & Installation

### Prerequisites
- Flutter SDK (latest stable)
- Firebase project
- Google Gemini API key

### Clone Repository

```bash
git clone https://github.com/your-username/ai-resume-builder.git
cd airesumebuilder

Install Dependencies
flutter pub get

🔥 Firebase Configuration

Create a Firebase project

Enable:

Authentication → Anonymous

Cloud Firestore

Add Firebase config files:

Android: google-services.json

iOS: GoogleService-Info.plist

Web: FirebaseOptions (already wired in main.dart)

🤖 AI Configuration

Add your Gemini API key:

const String kGeminiApiKey = "YOUR_GEMINI_API_KEY";


⚠️ Do not expose production API keys in public repositories.

▶️ Run the App
flutter run


For web:

flutter run -d chrome

🔐 Authentication

Uses Firebase Anonymous Authentication

Each user has isolated cloud data

Resumes stored per user securely in Firestore

📊 Resume Scoring

Resume completeness is automatically evaluated based on:

Personal information

Summary and objective

Experience and education

Skills and languages

Portfolio and references

Score range: 0 – 100%

📄 PDF Export

High-quality A4 PDF output

Multiple layout styles

Color-based themes

QR code support

Print & share ready

🌍 Platform Support

Android ✅

iOS ✅

Web ✅

Desktop ⚠️ (Experimental)

📌 Roadmap

Email / Google authentication

AI resume optimization per job role

Shareable resume links

DOCX export

Advanced analytics

📜 License

MIT License
