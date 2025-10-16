import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const LingoLeapApp());
}

class LingoLeapApp extends StatelessWidget {
  const LingoLeapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lingo Leap',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Arial',
      ),
      home: const GameWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Vocabulary data structure
class VocabWord {
  final String english;
  final String spanish;

  VocabWord(this.english, this.spanish);
}

// Game wrapper to manage screens and state
class GameWrapper extends StatefulWidget {
  const GameWrapper({super.key});

  @override
  State<GameWrapper> createState() => _GameWrapperState();
}

class _GameWrapperState extends State<GameWrapper> {
  GameScreen currentScreen = GameScreen.start;
  int currentScore = 0;
  int highScore = 0;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      highScore = prefs.getInt('highScore') ?? 0;
    });
  }

  Future<void> _saveHighScore(int score) async {
    if (score > highScore) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('highScore', score);
      setState(() {
        highScore = score;
      });
    }
  }

  void _startGame() {
    setState(() {
      currentScreen = GameScreen.playing;
      currentScore = 0;
    });
  }

  void _gameOver(int score) {
    _saveHighScore(score);
    setState(() {
      currentScore = score;
      currentScreen = GameScreen.gameOver;
    });
  }

  void _returnToStart() {
    setState(() {
      currentScreen = GameScreen.start;
    });
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
        );
      case GameScreen.gameOver:
        return GameOverScreen(
          score: currentScore,
          highScore: highScore,
          onPlayAgain: _startGame,
        );
    }
  }
}

enum GameScreen { start, playing, gameOver }

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
            colors: [Colors.blue.shade300, Colors.purple.shade300],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '🏃 Lingo Leap 🎮',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.black45,
                      offset: Offset(3, 3),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Learn Spanish While You Run!',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 60),
              ElevatedButton(
                onPressed: onPlay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 60,
                    vertical: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'PLAY',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    const Text(
                      'High Score',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$highScore',
                      style: const TextStyle(
                        fontSize: 36,
                        color: Colors.yellow,
                        fontWeight: FontWeight.bold,
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

// Game Over Screen
class GameOverScreen extends StatelessWidget {
  final int score;
  final int highScore;
  final VoidCallback onPlayAgain;

  const GameOverScreen({
    super.key,
    required this.score,
    required this.highScore,
    required this.onPlayAgain,
  });

  @override
  Widget build(BuildContext context) {
    final bool isNewHighScore = score >= highScore;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.red.shade300, Colors.orange.shade300],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'GAME OVER',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.black45,
                      offset: Offset(3, 3),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              if (isNewHighScore)
                const Text(
                  '🎉 NEW HIGH SCORE! 🎉',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.yellow,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Your Score',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$score',
                      style: const TextStyle(
                        fontSize: 48,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Colors.white),
                    const SizedBox(height: 10),
                    const Text(
                      'High Score',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$highScore',
                      style: const TextStyle(
                        fontSize: 32,
                        color: Colors.yellow,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: onPlayAgain,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'PLAY AGAIN',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Main Game Screen
class MainGameScreen extends StatefulWidget {
  final Function(int) onGameOver;

  const MainGameScreen({
    super.key,
    required this.onGameOver,
  });

  @override
  State<MainGameScreen> createState() => _MainGameScreenState();
}

class _MainGameScreenState extends State<MainGameScreen>
    with TickerProviderStateMixin {
  // Vocabulary list
  final List<VocabWord> vocabulary = [
    VocabWord('Hello', 'Hola'),
    VocabWord('Cat', 'Gato'),
    VocabWord('Dog', 'Perro'),
    VocabWord('Water', 'Agua'),
    VocabWord('House', 'Casa'),
    VocabWord('Book', 'Libro'),
    VocabWord('Car', 'Coche'),
    VocabWord('Tree', 'Árbol'),
    VocabWord('Sun', 'Sol'),
    VocabWord('Moon', 'Luna'),
    VocabWord('Friend', 'Amigo'),
    VocabWord('Food', 'Comida'),
    VocabWord('Love', 'Amor'),
    VocabWord('Time', 'Tiempo'),
    VocabWord('Day', 'Día'),
    VocabWord('Night', 'Noche'),
    VocabWord('Hand', 'Mano'),
    VocabWord('Eye', 'Ojo'),
    VocabWord('Heart', 'Corazón'),
    VocabWord('Door', 'Puerta'),
  ];

  // Game state
  late Timer gameTimer;
  double characterX = 100;
  double characterY = 300;
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
    // Start the game loop
    gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      _updateGame();
    });

    // Generate first challenge after a delay
    Future.delayed(const Duration(seconds: 2), () {
      _generateChallenge();
    });
  }

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

      // Ground collision
      if (characterY >= 300) {
        characterY = 300;
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

      // Update obstacle position (for sliding obstacle)
      if (currentChallenge == ChallengeType.slidingObstacle) {
        obstacleX -= gameSpeed;

        // Check collision with obstacle
        if (obstacleX < characterX + 40 &&
            obstacleX + 50 > characterX &&
            characterY >= 250) {
          _endGame();
        }

        // Obstacle passed successfully
        if (obstacleX < -50) {
          currentChallenge = null;
          waitingForAnswer = false;
        }
      }
    });
  }

  void _generateChallenge() {
    final challengeType = random.nextBool()
        ? ChallengeType.jumpingGap
        : ChallengeType.slidingObstacle;

    setState(() {
      currentChallenge = challengeType;
      challengeX = 800;
      waitingForAnswer = true;

      if (challengeType == ChallengeType.jumpingGap) {
        _generateJumpingGapChallenge();
      } else {
        _generateSlidingObstacleChallenge();
      }
    });
  }

  void _generateJumpingGapChallenge() {
    // Select a random word
    currentWord = vocabulary[random.nextInt(vocabulary.length)];

    // Generate options (correct answer + 2 wrong answers)
    options = [currentWord!.spanish];

    while (options.length < 3) {
      final wrongWord = vocabulary[random.nextInt(vocabulary.length)];
      if (!options.contains(wrongWord.spanish)) {
        options.add(wrongWord.spanish);
      }
    }

    // Shuffle options
    options.shuffle();
  }

  void _generateSlidingObstacleChallenge() {
    currentWord = vocabulary[random.nextInt(vocabulary.length)];
    obstacleX = 800;
    obstacleWord = currentWord!.spanish;
  }

  void _handlePlatformTap(String selectedOption) {
    if (!waitingForAnswer || currentChallenge != ChallengeType.jumpingGap) {
      return;
    }

    if (selectedOption == currentWord!.spanish) {
      // Correct answer - jump to platform
      setState(() {
        characterVelocityY = jumpForce * 1.2;
        isJumping = true;
        waitingForAnswer = false;
        score += 100; // Bonus points for correct answer
      });
    } else {
      // Wrong answer - game over
      _endGame();
    }
  }

  void _handleJumpButton() {
    if (currentChallenge == ChallengeType.slidingObstacle &&
        !isJumping &&
        characterY >= 300) {
      setState(() {
        characterVelocityY = jumpForce;
        isJumping = true;
        waitingForAnswer = false;
        score += 50; // Bonus points for successful jump
      });
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
    
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.lightBlue.shade200, Colors.lightBlue.shade50],
              ),
            ),
          ),

          // Game Canvas - Made responsive with LayoutBuilder
          LayoutBuilder(
            builder: (context, constraints) {
              return CustomPaint(
                painter: GamePainter(
                  characterX: characterX,
                  characterY: characterY * (constraints.maxHeight / 500),
                  challengeX: challengeX,
                  currentChallenge: currentChallenge,
                  options: options,
                  obstacleX: obstacleX,
                  obstacleWord: obstacleWord,
                  screenWidth: constraints.maxWidth,
                  screenHeight: constraints.maxHeight,
                ),
                size: Size(constraints.maxWidth, constraints.maxHeight),
              );
            },
          ),

          // Vocabulary Prompt - Made responsive positioning
          if (currentWord != null && waitingForAnswer)
            Positioned(
              top: screenHeight * 0.05,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.05,
                    vertical: screenHeight * 0.015,
                  ),
                  margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
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
                  child: Text(
                    currentChallenge == ChallengeType.jumpingGap
                        ? 'Translate: ${currentWord!.english}'
                        : 'Jump over: ${currentWord!.english}',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),

          // Score Display - Made responsive positioning and sizing
          Positioned(
            top: screenHeight * 0.05,
            left: screenWidth * 0.04,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.01,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Score: ${score ~/ 10}',
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Jump Button (for sliding obstacle) - Made responsive positioning and sizing
          if (currentChallenge == ChallengeType.slidingObstacle)
            Positioned(
              bottom: screenHeight * 0.05,
              right: screenWidth * 0.05,
              child: GestureDetector(
                onTap: _handleJumpButton,
                child: Container(
                  width: screenWidth * 0.15,
                  height: screenWidth * 0.15,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'JUMP',
                      style: TextStyle(
                        fontSize: screenWidth * 0.03,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Platform tap areas (for jumping gap)
          if (currentChallenge == ChallengeType.jumpingGap &&
              waitingForAnswer &&
              challengeX > 0 &&
              challengeX < screenWidth)
            ...List.generate(3, (index) {
              final platformX = challengeX + (index * 120);
              return Positioned(
                left: platformX,
                top: 200 + (index * 50.0),
                child: GestureDetector(
                  onTap: () => _handlePlatformTap(options[index]),
                  child: Container(
                    width: 100,
                    height: 40,
                    color: Colors.transparent,
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

enum ChallengeType { jumpingGap, slidingObstacle }

// Custom Painter for game elements - Added screen dimensions parameters
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
  });

  @override
  void paint(Canvas canvas, Size size) {
    final groundY = size.height * 0.7;
    
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
        Rect.fromLTWH(i, groundY, 20, 10),
        grassPaint,
      );
    }

    final characterWidth = size.width * 0.08;
    final characterHeight = size.height * 0.1;

    // Draw character
    final characterPaint = Paint()
      ..color = Colors.blue.shade700
      ..style = PaintingStyle.fill;

    // Character body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(characterX, characterY, characterWidth, characterHeight),
        Radius.circular(characterWidth * 0.25),
      ),
      characterPaint,
    );

    // Character head
    final headPaint = Paint()
      ..color = Colors.orange.shade300
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(characterX + characterWidth / 2, characterY - characterHeight * 0.2),
      characterWidth * 0.375,
      headPaint,
    );

    // Draw challenges
    if (currentChallenge == ChallengeType.jumpingGap) {
      _drawJumpingGap(canvas, size, groundY);
    } else if (currentChallenge == ChallengeType.slidingObstacle) {
      _drawSlidingObstacle(canvas, size, groundY);
    }
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
