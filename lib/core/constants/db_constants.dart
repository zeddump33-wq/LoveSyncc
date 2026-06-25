class DbConstants {
  static const String tableUsers = 'users';
  static const String tableCouples = 'couples';
  static const String tableMessages = 'messages';
  static const String tableMemories = 'memories';
  static const String tableMemoryAlbums = 'memory_albums';
  static const String tableEvents = 'events';
  static const String tableGoals = 'goals';
  static const String tableGoalSteps = 'goal_steps';
  static const String tableWishlist = 'wishlist';
  static const String tableLoveNotes = 'love_notes';
  static const String tableMoods = 'moods';
  static const String tableCheckIns = 'check_ins';
  static const String tableGames = 'games';
  static const String tableMilestones = 'milestones';
  static const String tableNotifications = 'notifications';

  static const String createUsersTable = '''
    CREATE TABLE $tableUsers (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      email TEXT,
      photoPath TEXT,
      partnerId TEXT,
      coupleId TEXT,
      inviteCode TEXT,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL
    )
  ''';

  static const String createCouplesTable = '''
    CREATE TABLE $tableCouples (
      id TEXT PRIMARY KEY,
      partner1Id TEXT NOT NULL,
      partner2Id TEXT,
      anniversaryDate TEXT,
      status TEXT NOT NULL DEFAULT 'pending',
      inviteCode TEXT UNIQUE,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL
    )
  ''';

  static const String createMessagesTable = '''
    CREATE TABLE $tableMessages (
      id TEXT PRIMARY KEY,
      coupleId TEXT NOT NULL,
      senderId TEXT NOT NULL,
      text TEXT,
      imagePath TEXT,
      voicePath TEXT,
      voiceDuration INTEGER,
      emoji TEXT,
      type TEXT NOT NULL DEFAULT 'text',
      createdAt TEXT NOT NULL,
      isRead INTEGER NOT NULL DEFAULT 0
    )
  ''';

  static const String createMemoriesTable = '''
    CREATE TABLE $tableMemories (
      id TEXT PRIMARY KEY,
      coupleId TEXT NOT NULL,
      albumId TEXT,
      imagePath TEXT,
      caption TEXT,
      date TEXT NOT NULL,
      isFavorite INTEGER NOT NULL DEFAULT 0,
      createdAt TEXT NOT NULL
    )
  ''';

  static const String createMemoryAlbumsTable = '''
    CREATE TABLE $tableMemoryAlbums (
      id TEXT PRIMARY KEY,
      coupleId TEXT NOT NULL,
      name TEXT NOT NULL,
      coverImagePath TEXT,
      createdAt TEXT NOT NULL
    )
  ''';

  static const String createEventsTable = '''
    CREATE TABLE $tableEvents (
      id TEXT PRIMARY KEY,
      coupleId TEXT NOT NULL,
      title TEXT NOT NULL,
      description TEXT,
      date TEXT NOT NULL,
      endDate TEXT,
      type TEXT NOT NULL DEFAULT 'custom',
      reminderEnabled INTEGER NOT NULL DEFAULT 1,
      createdAt TEXT NOT NULL,
      createdBy TEXT NOT NULL
    )
  ''';

  static const String createGoalsTable = '''
    CREATE TABLE $tableGoals (
      id TEXT PRIMARY KEY,
      coupleId TEXT NOT NULL,
      title TEXT NOT NULL,
      description TEXT,
      type TEXT NOT NULL DEFAULT 'savings',
      targetValue REAL,
      currentValue REAL NOT NULL DEFAULT 0,
      targetDate TEXT,
      isCompleted INTEGER NOT NULL DEFAULT 0,
      createdAt TEXT NOT NULL,
      createdBy TEXT NOT NULL
    )
  ''';

  static const String createGoalStepsTable = '''
    CREATE TABLE $tableGoalSteps (
      id TEXT PRIMARY KEY,
      goalId TEXT NOT NULL,
      title TEXT NOT NULL,
      isCompleted INTEGER NOT NULL DEFAULT 0,
      createdAt TEXT NOT NULL
    )
  ''';

  static const String createWishlistTable = '''
    CREATE TABLE $tableWishlist (
      id TEXT PRIMARY KEY,
      coupleId TEXT NOT NULL,
      title TEXT NOT NULL,
      description TEXT,
      price REAL,
      imagePath TEXT,
      link TEXT,
      isReserved INTEGER NOT NULL DEFAULT 0,
      reservedBy TEXT,
      isPurchased INTEGER NOT NULL DEFAULT 0,
      createdAt TEXT NOT NULL,
      createdBy TEXT NOT NULL
    )
  ''';

  static const String createLoveNotesTable = '''
    CREATE TABLE $tableLoveNotes (
      id TEXT PRIMARY KEY,
      coupleId TEXT NOT NULL,
      senderId TEXT NOT NULL,
      title TEXT NOT NULL,
      content TEXT NOT NULL,
      type TEXT NOT NULL DEFAULT 'note',
      scheduledDate TEXT,
      isDelivered INTEGER NOT NULL DEFAULT 1,
      isFavorite INTEGER NOT NULL DEFAULT 0,
      createdAt TEXT NOT NULL
    )
  ''';

  static const String createMoodsTable = '''
    CREATE TABLE $tableMoods (
      id TEXT PRIMARY KEY,
      userId TEXT NOT NULL,
      mood TEXT NOT NULL,
      note TEXT,
      date TEXT NOT NULL,
      createdAt TEXT NOT NULL
    )
  ''';

  static const String createCheckInsTable = '''
    CREATE TABLE $tableCheckIns (
      id TEXT PRIMARY KEY,
      coupleId TEXT NOT NULL,
      question TEXT NOT NULL,
      answer TEXT,
      userId TEXT NOT NULL,
      date TEXT NOT NULL,
      createdAt TEXT NOT NULL
    )
  ''';

  static const String createGamesTable = '''
    CREATE TABLE $tableGames (
      id TEXT PRIMARY KEY,
      coupleId TEXT NOT NULL,
      gameType TEXT NOT NULL,
      player1Id TEXT,
      player2Id TEXT,
      score1 INTEGER DEFAULT 0,
      score2 INTEGER DEFAULT 0,
      data TEXT,
      isCompleted INTEGER NOT NULL DEFAULT 0,
      createdAt TEXT NOT NULL
    )
  ''';

  static const String createMilestonesTable = '''
    CREATE TABLE $tableMilestones (
      id TEXT PRIMARY KEY,
      coupleId TEXT NOT NULL,
      title TEXT NOT NULL,
      description TEXT,
      date TEXT NOT NULL,
      icon TEXT,
      createdAt TEXT NOT NULL
    )
  ''';

  static const String createNotificationsTable = '''
    CREATE TABLE $tableNotifications (
      id TEXT PRIMARY KEY,
      userId TEXT NOT NULL,
      title TEXT NOT NULL,
      body TEXT,
      type TEXT NOT NULL,
      isRead INTEGER NOT NULL DEFAULT 0,
      scheduledDate TEXT,
      createdAt TEXT NOT NULL
    )
  ''';
}
