# SavorySync

SavorySync is a comprehensive Flutter application designed to revolutionize meal planning, grocery syncing, and recipe management. It seamlessly integrates a rich set of features leveraging Firebase services for real-time synchronization, user authentication, and cloud storage.

## ✨ Features

*   **Real-time Synchronization:** Powered by Firebase Realtime Database and Cloud Firestore, keeping your data synced across devices instantly.
*   **Authentication:** Secure login and sign-up flows using Firebase Auth.
*   **Cloud Storage:** Store and retrieve media, such as recipe images, with Firebase Storage.
*   **Voice Input Integration:** Utilize speech-to-text capabilities for hands-free recipe searches and grocery list additions.
*   **Calendar & Planning:** Built-in calendar views for interactive meal planning using `table_calendar`.
*   **Rich Media Experience:** Enhanced image handling with `cached_network_image` and `image_picker`.

## 🛠 Tech Stack

*   **Framework:** [Flutter](https://flutter.dev/)
*   **Backend & Services:**
    *   Firebase Core, Auth, Realtime Database, Firestore, Storage
*   **Key Packages:**
    *   `provider` for state management
    *   `speech_to_text` for voice capabilities
    *   `table_calendar` for meal scheduling
    *   `font_awesome_flutter` & `cupertino_icons` for UI elements

## 🚀 Getting Started

### Prerequisites

Ensure you have the following installed:
*   [Flutter SDK](https://flutter.dev/docs/get-started/install)
*   An IDE like Android Studio or VS Code
*   A connected physical device or emulator

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/Adinajs/SavorySync.git
    cd SavorySync
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Firebase Configuration:**
    *   This project uses Firebase. Ensure you have configured Firebase for this project using FlutterFire CLI or by adding the required config files for Android and iOS.

4.  **Run the app:**
    ```bash
    flutter run
    ```
