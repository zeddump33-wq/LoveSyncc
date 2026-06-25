class AppConstants {
  static const String appName = 'LoveSync';
  static const String appVersion = '1.0.0';
  static const String dbName = 'lovesync.db';
  static const int dbVersion = 1;

  static const String hiveBoxName = 'lovesync_cache';
  static const String prefsKey = 'lovesync_prefs';

  static const String dateFormat = 'yyyy-MM-dd';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';

  static const int maxImageSize = 20;
  static const int maxChatMessageLength = 1000;
  static const int maxNoteLength = 5000;

  static const List<String> moods = [
    'amazing', 'happy', 'good', 'neutral', 'sad', 'angry', 'loved'
  ];

  static const List<String> dailyQuestions = [
    'What made you smile today?',
    'How are you feeling right now?',
    'What is one thing you appreciate about your partner?',
    'What was the best moment of your day?',
    'How can I support you today?',
    'What is a memory we made together that you cherish?',
    'What are you looking forward to?',
  ];

  static const List<String> truthQuestions = [
    'What was your first impression of me?',
    'What is something you have never told anyone?',
    'What is your biggest fear in our relationship?',
    'What do you think about when you see me?',
    'What is your favorite memory of us?',
    'What is something you want to try with me?',
    'What do you love most about me?',
  ];

  static const List<String> dareChallenges = [
    'Send a romantic text to your partner right now.',
    'Give your partner a compliment without using the word "nice".',
    'Recreate your first date right now.',
    'Write a short poem for your partner.',
    'Share your favorite photo of us and explain why.',
    'Plan a surprise date for this weekend.',
    'Tell your partner something you love about them in a funny voice.',
  ];

  static const List<String> wouldYouRather = [
    'Would you rather have a romantic dinner at home or a fancy restaurant?',
    'Would you rather travel to the mountains or the beach?',
    'Would you rather give up sweets or give up social media for a month?',
    'Would you rather have more date nights or more adventures?',
    'Would you rather be able to read minds or be invisible?',
    'Would you rather live in the city or the countryside?',
    'Would you rather have a love letter every day or a surprise gift every week?',
  ];
}
