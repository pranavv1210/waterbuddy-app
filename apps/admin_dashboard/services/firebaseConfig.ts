export const firebaseConfig = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY || "AIzaSyBXsoGgKfgBnAbu4v5c3lnURt2ijnvRED4",
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN || "waterbuddy-edcf7.firebaseapp.com",
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID || "waterbuddy-edcf7",
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET || "waterbuddy-edcf7.firebasestorage.app",
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID || "979686341816",
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID || "1:979686341816:web:7de25746f6066955fec84d",
} as const;