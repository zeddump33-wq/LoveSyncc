import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return web;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBkKiFWbjEi03GCY9L3pqzXeTe_weDkivE',
    appId: '1:728725943340:web:5b5855098a3229c2694d89',
    messagingSenderId: '728725943340',
    projectId: 'lovesync-c482a',
    authDomain: 'lovesync-c482a.firebaseapp.com',
    storageBucket: 'lovesync-c482a.firebasestorage.app',
    measurementId: 'G-EEKFP70EWH',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT.appspot.com',
    iosBundleId: 'com.lovesync.app',
  );
}
