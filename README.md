# Social Connect

A complete, modern Flutter social media application built as a final internship task. It features a complete authentication flow, real-time feed, profile management, post creation with images, comments, likes, and a notification system.

## Features

*   **Authentication**: Full Firebase Auth with Email/Password, display name, and username handling. Includes "Forgot Password" flow.
*   **Feed**: Infinite scrolling feed with pull-to-refresh, animated double-tap likes (Lottie/Flutter Animate), and skeleton loaders.
*   **Create Post**: Image picker integration with Firebase Storage to upload post images, character limit, and real-time UI updates.
*   **Interactions**: Real-time comments stream (bottom sheet overlay) and immediate like counting.
*   **Profile Management**: Edit profile, upload avatar, bio, and a custom user profile grid to show a user's content.
*   **Notifications**: In-app notifications when users like or comment on your posts.
*   **Search**: Discover users in the database by searching for their username.
*   **UI/UX**: Custom deep indigo/slate theme using Material 3, custom fonts (`GoogleFonts.outfit` and `GoogleFonts.inter`), and smooth micro-animations.

## Tech Stack

*   **Framework:** Flutter (Latest)
*   **State Management:** Provider
*   **Backend:** Firebase (Auth, Firestore, Storage)
*   **UI Animations:** Flutter Animate, Lottie
*   **Images:** Cached Network Image, Image Picker
*   **Fonts:** Google Fonts

## Setup

1. Make sure Flutter is installed.
2. Run `flutter pub get`
3. Firebase is already initialized via `firebase_options.dart`. 
4. Ensure the Firebase Storage bucket is enabled in the Firebase Console (click "Get Started" in Storage).
5. Run the app on macOS, Web, iOS, or Android using `flutter run`.

## Security Rules

Firebase Firestore and Storage rules are configured to ensure that only authenticated users can read/write data, and users can only edit their own profiles/posts.
