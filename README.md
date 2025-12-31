# AI Resume Builder (UI Demo)

This is a **demonstration version** of a production Flutter application built for generating professional resumes using AI.

## ⚠️ Disclaimer
**This repository contains the Frontend UI and Logic structure only.**
To protect Intellectual Property and security:
* **Backend Removed:** Firebase Auth and Firestore implementations have been replaced with an in-memory mock database.
* **AI Logic Removed:** The Google Gemini API integration has been replaced with a mock service that simulates AI responses.
* **API Keys Removed:** No production keys are included.

## 🛒 Get the Complete Production Code
If you are interested in the **full production source code**, which includes:
* ✅ Full Firebase Backend Integration (Auth & Firestore)
* ✅ Live Google Gemini AI Integration (Logic & Prompts included; **you utilize your own API Key**)
* ✅ Persistent Data Storage
* ✅ Complete Source Code Ownership

**Price: $100 USD**

**Contact:** [sajeelsahil8@gmail.com](mailto:sajeelsahil8@gmail.com)

---

## Features Showcase
* **State Management:** Built using `Provider` for efficient state handling.
* **PDF Generation:** Distinct resume templates generated using the `pdf` and `printing` packages.
* **Dynamic Forms:** Modular UI for handling complex user input (Experience, Education, Skills).
* **Mock AI Integration:** Demonstrates how async AI operations are handled in the UI (loading states, error handling).

## How to Run
1.  Clone the repository.
2.  Run `flutter pub get`.
3.  Run `flutter run`.
    * *Note: Data will not persist after restarting the app as it uses local memory for this demo.*

## Tech Stack (Production Version)
* **Framework:** Flutter
* **Backend:** Firebase (Auth, Firestore)
* **AI:** Google Gemini (Generative AI)
* **PDF:** pdf package
