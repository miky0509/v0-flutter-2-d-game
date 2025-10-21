import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const LingoLeapApp());
}

class LingoLeapApp extends StatelessWidget {
  const LingoLeapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LingoLeap',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const GameWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Data Models
class VocabWord {
  final String english;
  final String spanish;
  final String emoji;
  final String section;

  VocabWord(this.english, this.spanish, this.emoji, this.section);
}

enum GameScreen { menu, start, playing, gameOver, admin }
enum ChallengeType { jumpingGap, slidingObstacle }

class GameLevel {
  final int level;
  final String name;
  final int requiredScore;
  final double speed;

  GameLevel(this.level, this.name, this.requiredScore, this.speed);
}

class LevelProgress {
  final int currentLevel;
  final int totalScore;
  final Map<int, bool> unlockedLevels;

  LevelProgress(this.currentLevel, this.totalScore, this.unlockedLevels);
}

// Default vocabulary with emojis and sections
final List<VocabWord> defaultVocabulary = [
  VocabWord('Hello', 'Hola', '👋', 'Greetings'),
  VocabWord('Cat', 'Gato', '🐱', 'Animals'),
  VocabWord('Dog', 'Perro', '🐶', 'Animals'),
  VocabWord('Water', 'Agua', '💧', 'Food & Drink'),
  VocabWord('House', 'Casa', '🏠', 'Places'),
  VocabWord('Book', 'Libro', '📚', 'Objects'),
  VocabWord('Car', 'Coche', '🚗', 'Transportation'),
  VocabWord('Tree', 'Árbol', '🌳', 'Nature'),
  VocabWord('Sun', 'Sol', '☀️', 'Nature'),
  VocabWord('Moon', 'Luna', '🌙', 'Nature'),
  VocabWord('Friend', 'Amigo', '👫', 'People'),
  VocabWord('Food', 'Comida', '🍽️', 'Food & Drink'),
  VocabWord('Love', 'Amor', '❤️', 'Emotions'),
  VocabWord('Time', 'Tiempo', '⏰', 'Abstract'),
  VocabWord('Day', 'Día', '🌅', 'Time'),
  VocabWord('Night', 'Noche', '🌃', 'Time'),
  VocabWord('Hand', 'Mano', '✋', 'Body'),
  VocabWord('Eye', 'Ojo', '👁️', 'Body'),
  VocabWord('Heart', 'Corazón', '💖', 'Body'),
  VocabWord('Door', 'Puerta', '🚪', 'Objects'),
];

// Game levels
final List<GameLevel> gameLevels = [
  GameLevel(1, 'Beginner', 0, 3.0),
  GameLevel(2, 'Intermediate', 500, 4.0),
  GameLevel(3, 'Advanced', 1500, 5.5),
  GameLevel(4, 'Expert', 3000, 7.0),
  GameLevel(5, 'Master', 5000, 8.5),
];

class GameWrapper extends StatefulWidget {
  const GameWrapper({super.key});

  @override
  State<GameWrapper> createState() => _GameWrapperState();
}

class _GameWrapperState extends State<GameWrapper> {
  GameScreen currentScreen = GameScreen.menu;
  int currentScore = 0;
  int highScore = 0;
  LevelProgress levelProgress = LevelProgress(1, 0, {1: true});
  List<VocabWord> vocabulary = [];

  @override
  void initState() {
    super.initState();
    _loadGameData();
  }

  Future<void> _loadGameData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      highScore = prefs.getInt('high_score') ?? 0;
      vocabulary = defaultVocabulary; // Use default vocabulary for now
      
      // Load level progress
      final currentLevel = prefs.getInt('current_level') ?? 1;
      final totalScore = prefs.getInt('total_score') ?? 0;
      final unlockedLevelsString = prefs.getStringList('unlocked_levels') ?? ['1'];
      final unlockedLevels = <int, bool>{};
      for (String level in unlockedLevelsString) {
        unlockedLevels[int.parse(level)] = true;
      }
      levelProgress = LevelProgress(currentLevel, totalScore, unlockedLevels);
    });
  }

  void _startGame() {
    setState(() {
      currentScreen = GameScreen.playing;
    });
  }

  void _gameOver(int score) {
    _saveHighScore(score);
    setState(() {
      currentScore = score;
      currentScreen = GameScreen.gameOver;
    });
  }

  void _returnToMenu() {
    setState(() {
      currentScreen = GameScreen.menu;
    });
  }

  void _showMenu() {
    setState(() {
      currentScreen = GameScreen.menu;
    });
  }

  Future<void> _saveHighScore(int score) async {
    if (score > highScore) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('high_score', score);
      setState(() {
        highScore = score;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (currentScreen) {
      case GameScreen.start:
        return StartScreen(
          highScore: highScore,
          onPlay: _startGame,
        );
      case GameScreen.playing:
        return MainGameScreen(
          onGameOver: _gameOver,
          vocabulary: vocabulary,
          currentLevel: levelProgress.currentLevel,
        );
      case GameScreen.gameOver:
        return GameOverScreen(
          score: currentScore,
          highScore: highScore,
          onPlayAgain: _startGame,
          onMenu: _returnToMenu,
        );
      case GameScreen.admin:
        return AdminScreen(
          vocabulary: vocabulary,
          onBack: _returnToMenu,
          onVocabularyUpdate: (newVocab) => setState(() => vocabulary = newVocab),
        );
      default:
        return MenuScreen(
          highScore: highScore,
          levelProgress: levelProgress,
          onPlay: _startGame,
          onAdmin: () => setState(() => currentScreen = GameScreen.admin),
        );
    }
  }
}

// Menu Screen Widget
class MenuScreen extends StatelessWidget {
  final int highScore;
  final LevelProgress levelProgress;
  final VoidCallback onPlay;
  final VoidCallback onAdmin;

  const MenuScreen({
    Key? key,
    required this.highScore,
    required this.levelProgress,
    required this.onPlay,
    required this.onAdmin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF87CEEB), Color(0xFF98FB98)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Game Title
                const Text(
                  '🦘 LingoLeap',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black26,
                        offset: Offset(2.0, 2.0),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Subtitle
                const Text(
                  'Jump & Learn Spanish!',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 40),
                
                // High Score Display
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'High Score',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '$highScore',
                        style: const TextStyle(
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                
                // Level Progress
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Current Level',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${levelProgress.currentLevel}',
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
                
                // Play Button
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: onPlay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shadowColor: Colors.black26,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'PLAY',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Manage Vocabulary Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: onAdmin,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'Manage Vocabulary',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Start Screen
class StartScreen extends StatelessWidget {
  final int highScore;
  final VoidCallback onPlay;

  const StartScreen({
    super.key,
    required this.highScore,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.lightBlue.shade200, Colors.lightBlue.shade50],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '🦘 LingoLeap',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.black26,
                      offset: Offset(2.0, 2.0),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: onPlay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                child: const Text('PLAY', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 30),
              Text(
                'High Score: $highScore',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Game Over Screen
class GameOverScreen extends StatelessWidget {
  final int score;
  final int highScore;
  final VoidCallback onPlayAgain;
  final VoidCallback onMenu;

  const GameOverScreen({
    super.key,
    required this.score,
    required this.highScore,
    required this.onPlayAgain,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final isNewHighScore = score >= highScore;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.red.shade300, Colors.orange.shade200],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isNewHighScore ? '🎉 NEW HIGH SCORE! 🎉' : '💥 GAME OVER 💥',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.black26,
                      offset: Offset(2.0, 2.0),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Text(
                'Score: $score',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'High Score: $highScore',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: onPlayAgain,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                child: const Text('Play Again', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onMenu,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                child: const Text('Menu', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Admin Screen for managing vocabulary
class AdminScreen extends StatefulWidget {
  final List<VocabWord> vocabulary;
  final VoidCallback onBack;
  final Function(List<VocabWord>) onVocabularyUpdate;

  const AdminScreen({
    Key? key,
    required this.vocabulary,
    required this.onBack,
    required this.onVocabularyUpdate,
  }) : super(key: key);

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _englishController = TextEditingController();
  final _spanishController = TextEditingController();
  final _emojiController = TextEditingController();
  final _sectionController = TextEditingController();
  List<VocabWord> _vocabulary = [];

  @override
  void initState() {
    super.initState();
    _vocabulary = List.from(widget.vocabulary);
  }

  void _addWord() {
    if (_englishController.text.isNotEmpty && _spanishController.text.isNotEmpty) {
      setState(() {
        _vocabulary.add(VocabWord(
          _englishController.text,
          _spanishController.text,
          _emojiController.text.isNotEmpty ? _emojiController.text : '📝',
          _sectionController.text.isNotEmpty ? _sectionController.text : 'Custom',
        ));
      });
      _englishController.clear();
      _spanishController.clear();
      _emojiController.clear();
      _sectionController.clear();
      widget.onVocabularyUpdate(_vocabulary);
    }
  }

  void _removeWord(int index) {
    setState(() {
      _vocabulary.removeAt(index);
    });
    widget.onVocabularyUpdate(_vocabulary);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Vocabulary'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Add new word form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _englishController,
                      decoration: const InputDecoration(labelText: 'English'),
                    ),
                    TextField(
                      controller: _spanishController,
                      decoration: const InputDecoration(labelText: 'Spanish'),
                    ),
                    TextField(
                      controller: _emojiController,
                      decoration: const InputDecoration(labelText: 'Emoji (optional)'),
                    ),
                    TextField(
                      controller: _sectionController,
                      decoration: const InputDecoration(labelText: 'Section (optional)'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _addWord,
                      child: const Text('Add Word'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Vocabulary list
            Expanded(
              child: ListView.builder(
                itemCount: _vocabulary.length,
                itemBuilder: (context, index) {
                  final word = _vocabulary[index];
                  return Card(
                    child: ListTile(
                      leading: Text(
                        word.emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text('${word.english} → ${word.spanish}'),
                      subtitle: Text(word.section),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _removeWord(index),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Main Game Screen - Mobile Optimized
class MainGameScreen extends StatefulWidget {
  final Function(int) onGameOver;
  final List<VocabWord> vocabulary;
  final int currentLevel;

  const MainGameScreen({
    super.key,
    required this.onGameOver,
    required this.vocabulary,
    required this.currentLevel,
  });

  @override
  State<MainGameScreen> createState() => _MainGameScreenState();
}

class _MainGameScreenState extends State<MainGameScreen>
    with TickerProviderStateMixin {
  
  // Game state
  late Timer gameTimer;
  double characterX = 100;
  double characterY = 0; // Will be set dynamically based on screen size
  double characterVelocityY = 0;
  bool isJumping = false;
  int score = 0;
  double gameSpeed = 3.0;
  final double gravity = 0.8;
  final double jumpForce = -15.0;

  // Challenge state
  ChallengeType? currentChallenge;
  VocabWord? currentWord;
  List<String> options = [];
  double challengeX = 800;
  bool waitingForAnswer = false;

  // Obstacle state
  double obstacleX = 800;
  String obstacleWord = '';

  final Random random = Random();

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  void _startGame() {
    score = 0;
    gameSpeed = 3.0;
    characterX = 100;
    characterY = 0;
    characterVelocityY = 0;
    isJumping = false;
    currentChallenge = null;
    waitingForAnswer = false;
    
    _generateChallenge();
    
    gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      _updateGame();
    });
  }

  void _generateChallenge() {
    if (widget.vocabulary.isEmpty) return;
    
    final challengeTypes = [ChallengeType.jumpingGap, ChallengeType.slidingObstacle];
    final selectedType = challengeTypes[random.nextInt(challengeTypes.length)];
    
    currentWord = widget.vocabulary[random.nextInt(widget.vocabulary.length)];
    
    setState(() {
      currentChallenge = selectedType;
      challengeX = 800; // Use fixed value instead of MediaQuery during init
      waitingForAnswer = true;
      
      // Generate options for multiple choice
      options = [currentWord!.spanish];
      while (options.length < 3) {
        final randomWord = widget.vocabulary[random.nextInt(widget.vocabulary.length)];
        if (!options.contains(randomWord.spanish)) {
          options.add(randomWord.spanish);
        }
      }
      options.shuffle();
      
      if (selectedType == ChallengeType.slidingObstacle) {
        obstacleX = challengeX;
        obstacleWord = currentWord!.english;
      }
    });
  }

  // Use fixed ground position to avoid MediaQuery context issues
  double get groundY => 280.0;

  void _updateGame() {
    if (!mounted) return;

    setState(() {
      // Update score based on time survived
      score = (score + 1);

      // Increase game speed gradually
      if (score % 500 == 0 && gameSpeed < 8.0) {
        gameSpeed += 0.3;
      }

      // Apply gravity to character
      characterVelocityY += gravity;
      characterY += characterVelocityY;

      // Ground collision - use fixed value to avoid context issues
      final currentGroundY = 280.0; // Fixed ground position
      if (characterY >= currentGroundY) {
        characterY = currentGroundY;
        characterVelocityY = 0;
        isJumping = false;
      }

      // Update challenge position
      if (currentChallenge != null) {
        challengeX -= gameSpeed;

        // Check if challenge passed without answer (for jumping gap)
        if (currentChallenge == ChallengeType.jumpingGap &&
            challengeX < -200 &&
            waitingForAnswer) {
          _endGame();
        }

        // Generate new challenge when current one is off screen
        if (challengeX < -200 && !waitingForAnswer) {
          _generateChallenge();
        }
      }

      // Update obstacle position
      if (currentChallenge == ChallengeType.slidingObstacle) {
        obstacleX -= gameSpeed;
        
        // Check collision with obstacle
        if (obstacleX < characterX + 50 && 
            obstacleX + 60 > characterX &&
            characterY > currentGroundY - 60) {
          _endGame();
        }
      }
    });
  }

  void _handleJumpButton() {
    final currentGroundY = 280.0; // Fixed ground position
    
    if (characterY >= currentGroundY && !isJumping) {
      setState(() {
        characterVelocityY = jumpForce;
        isJumping = true;
      });
      
      // Add haptic feedback for mobile
      HapticFeedback.lightImpact();
    }
  }

  void _handlePlatformTap(String selectedAnswer) {
    if (currentWord != null && selectedAnswer == currentWord!.spanish) {
      // Correct answer
      setState(() {
        waitingForAnswer = false;
        score += 100; // Bonus points for correct answer
      });
      
      // Add haptic feedback for correct answer
      HapticFeedback.mediumImpact();
      
      // Generate next challenge after delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _generateChallenge();
        }
      });
    } else {
      // Wrong answer - end game
      HapticFeedback.heavyImpact();
      _endGame();
    }
  }

  void _endGame() {
    gameTimer.cancel();
    widget.onGameOver(score ~/ 10); // Convert to reasonable score
  }

  @override
  void dispose() {
    gameTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    // Calculate responsive dimensions
    final gameHeight = screenHeight * 0.6; // 60% of screen height
    final groundY = gameHeight * 0.7; // Ground at 70% of game height
    
    // Initialize character Y position if not set
    if (characterY == 0) {
      characterY = 280.0; // Use fixed ground position
    }
    
    // Update challengeX to use screen width if needed
    if (challengeX == 800 && currentChallenge != null) {
      challengeX = screenWidth + 100;
    }
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF87CEEB), Color(0xFF98FB98)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Game Info Bar
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Score Display
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Score: ${score ~/ 10}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    
                    // Level Display
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Level ${widget.currentLevel}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Game Canvas
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Stack(
                      children: [
                        // Game Canvas
                        CustomPaint(
                          painter: GamePainter(
                            characterX: characterX,
                            characterY: characterY,
                            challengeX: challengeX,
                            currentChallenge: currentChallenge,
                            options: options,
                            obstacleX: obstacleX,
                            obstacleWord: obstacleWord,
                            screenWidth: screenWidth,
                            screenHeight: gameHeight,
                            currentWord: currentWord,
                          ),
                          size: Size(screenWidth, gameHeight),
                        ),
                        
                        // Touch areas for jumping gap platforms
                        if (currentChallenge == ChallengeType.jumpingGap &&
                            waitingForAnswer &&
                            challengeX > 0 &&
                            challengeX < screenWidth)
                          ...List.generate(3, (index) {
                            final platformX = challengeX + (index * 120);
                            return Positioned(
                              left: platformX,
                              top: 150 + (index * 60.0),
                              child: GestureDetector(
                                onTap: () => _handlePlatformTap(options[index]),
                                child: Container(
                                  width: 100,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.blue, width: 2),
                                  ),
                                  child: Center(
                                    child: Text(
                                      options[index],
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Control Panel
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Jump Button (always visible for better UX)
                    GestureDetector(
                      onTap: _handleJumpButton,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'JUMP',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Current Challenge Display
                    if (currentWord != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currentChallenge == ChallengeType.jumpingGap 
                                  ? 'Translate:' 
                                  : 'Jump over:',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  currentWord!.emoji,
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  currentWord!.english,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4CAF50),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Game Painter for drawing the game elements
class GamePainter extends CustomPainter {
  final double characterX;
  final double characterY;
  final double challengeX;
  final ChallengeType? currentChallenge;
  final List<String> options;
  final double obstacleX;
  final String obstacleWord;
  final double screenWidth;
  final double screenHeight;
  final VocabWord? currentWord;

  GamePainter({
    required this.characterX,
    required this.characterY,
    required this.challengeX,
    required this.currentChallenge,
    required this.options,
    required this.obstacleX,
    required this.obstacleWord,
    required this.screenWidth,
    required this.screenHeight,
    required this.currentWord,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final groundY = size.height * 0.7;
    
    // Draw sky gradient background
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF87CEEB), Color(0xFFE0F6FF)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, groundY));
    
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, groundY),
      skyPaint,
    );
    
    // Draw clouds
    final cloudPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < 3; i++) {
      final cloudX = (i * size.width / 2.5) + 50;
      final cloudY = size.height * 0.15 + (i * 30);
      _drawCloud(canvas, cloudX, cloudY, cloudPaint);
    }
    
    // Draw ground
    final groundPaint = Paint()
      ..color = Colors.green.shade700
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(0, groundY, size.width, size.height - groundY),
      groundPaint,
    );

    // Draw grass details
    final grassPaint = Paint()
      ..color = Colors.green.shade600
      ..style = PaintingStyle.fill;

    for (int i = 0; i < size.width; i += 30) {
      canvas.drawRect(
        Rect.fromLTWH(i.toDouble(), groundY, 20, 10),
        grassPaint,
      );
    }
    
    // Draw trees in background
    for (int i = 0; i < 4; i++) {
      final treeX = (i * size.width / 3) + 200;
      _drawTree(canvas, treeX, groundY, size.height * 0.15);
    }

    final characterWidth = size.width * 0.08;
    final characterHeight = size.height * 0.1;

    // Draw character shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    canvas.drawOval(
      Rect.fromLTWH(
        characterX + 5, 
        groundY + 5, 
        characterWidth - 10, 
        characterHeight * 0.3
      ),
      shadowPaint,
    );

    // Draw character
    final characterPaint = Paint()
      ..color = Colors.blue.shade700
      ..style = PaintingStyle.fill;

    // Character body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(characterX, characterY - characterHeight, characterWidth, characterHeight),
        Radius.circular(characterWidth * 0.25),
      ),
      characterPaint,
    );

    // Character head
    final headPaint = Paint()
      ..color = Colors.orange.shade300
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(characterX + characterWidth / 2, characterY - characterHeight * 1.2),
      characterWidth * 0.375,
      headPaint,
    );
    
    // Character eyes
    final eyePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(characterX + characterWidth * 0.3, characterY - characterHeight * 1.3),
      2,
      eyePaint,
    );
    
    canvas.drawCircle(
      Offset(characterX + characterWidth * 0.7, characterY - characterHeight * 1.3),
      2,
      eyePaint,
    );

    // Draw challenges
    if (currentChallenge == ChallengeType.jumpingGap) {
      _drawJumpingGap(canvas, size, groundY);
    } else if (currentChallenge == ChallengeType.slidingObstacle) {
      _drawSlidingObstacle(canvas, size, groundY);
    }
  }
  
  void _drawCloud(Canvas canvas, double x, double y, Paint paint) {
    canvas.drawCircle(Offset(x, y), 20, paint);
    canvas.drawCircle(Offset(x + 25, y), 25, paint);
    canvas.drawCircle(Offset(x + 50, y), 20, paint);
    canvas.drawCircle(Offset(x + 25, y - 15), 18, paint);
  }
  
  void _drawTree(Canvas canvas, double x, double groundY, double height) {
    // Tree trunk
    final trunkPaint = Paint()
      ..color = Colors.brown.shade600
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(
      Rect.fromLTWH(x - 8, groundY - height * 0.4, 16, height * 0.4),
      trunkPaint,
    );
    
    // Tree leaves
    final leavesPaint = Paint()
      ..color = Colors.green.shade800
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(x, groundY - height * 0.7),
      height * 0.4,
      leavesPaint,
    );
  }

  void _drawJumpingGap(Canvas canvas, Size size, double groundY) {
    final gapWidth = size.width * 0.15;
    
    // Draw gap
    final gapPaint = Paint()
      ..color = Colors.brown.shade800
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(challengeX - 50, groundY, gapWidth + 100, 100),
      gapPaint,
    );

    final platformWidth = size.width * 0.2;
    final platformHeight = size.height * 0.08;
    final platformSpacing = size.width * 0.25;

    // Draw three platforms with options
    for (int i = 0; i < 3; i++) {
      final platformX = challengeX + (i * platformSpacing);
      final platformY = size.height * 0.4 + (i * platformHeight * 1.2);

      // Platform shadow
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(platformX + 3, platformY + 3, platformWidth, platformHeight),
          const Radius.circular(5),
        ),
        shadowPaint,
      );

      // Platform
      final platformPaint = Paint()
        ..color = Colors.brown.shade400
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(platformX, platformY, platformWidth, platformHeight),
          const Radius.circular(5),
        ),
        platformPaint,
      );

      // Platform border
      final borderPaint = Paint()
        ..color = Colors.brown.shade700
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(platformX, platformY, platformWidth, platformHeight),
          const Radius.circular(5),
        ),
        borderPaint,
      );

      // Draw text on platform - Responsive font size
      if (i < options.length) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: options[i],
            style: TextStyle(
              color: Colors.white,
              fontSize: size.width * 0.03,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  blurRadius: 2.0,
                  color: Colors.black.withOpacity(0.7),
                  offset: const Offset(1.0, 1.0),
                ),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        );

        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            platformX + platformWidth / 2 - textPainter.width / 2,
            platformY + platformHeight / 2 - textPainter.height / 2,
          ),
        );
      }
    }
  }

  void _drawSlidingObstacle(Canvas canvas, Size size, double groundY) {
    final obstacleWidth = size.width * 0.1;
    final obstacleHeight = size.height * 0.12;
    
    // Draw obstacle shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(obstacleX + 3, groundY - obstacleHeight + 3, obstacleWidth, obstacleHeight),
        Radius.circular(obstacleWidth * 0.2),
      ),
      shadowPaint,
    );
    
    // Draw obstacle (rock)
    final obstaclePaint = Paint()
      ..color = Colors.grey.shade700
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(obstacleX, groundY - obstacleHeight, obstacleWidth, obstacleHeight),
        Radius.circular(obstacleWidth * 0.2),
      ),
      obstaclePaint,
    );

    // Draw obstacle border
    final borderPaint = Paint()
      ..color = Colors.grey.shade900
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(obstacleX, groundY - obstacleHeight, obstacleWidth, obstacleHeight),
        Radius.circular(obstacleWidth * 0.2),
      ),
      borderPaint,
    );

    // Draw word on obstacle - Responsive font size
    final textPainter = TextPainter(
      text: TextSpan(
        text: obstacleWord,
        style: TextStyle(
          color: Colors.white,
          fontSize: size.width * 0.025,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              blurRadius: 2.0,
              color: Colors.black.withOpacity(0.8),
              offset: const Offset(1.0, 1.0),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        obstacleX + obstacleWidth / 2 - textPainter.width / 2,
        obstacleX < 200 ? groundY - obstacleHeight - 30 : groundY - obstacleHeight / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(GamePainter oldDelegate) => true;
}
