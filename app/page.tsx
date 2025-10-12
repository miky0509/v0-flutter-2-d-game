"use client"

import { useState, useEffect, useRef, useCallback } from "react"
import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"

// Vocabulary data
const VOCABULARY = [
  { english: "hello", spanish: "hola" },
  { english: "goodbye", spanish: "adiós" },
  { english: "please", spanish: "por favor" },
  { english: "thank you", spanish: "gracias" },
  { english: "yes", spanish: "sí" },
  { english: "no", spanish: "no" },
  { english: "water", spanish: "agua" },
  { english: "food", spanish: "comida" },
  { english: "house", spanish: "casa" },
  { english: "friend", spanish: "amigo" },
  { english: "family", spanish: "familia" },
  { english: "love", spanish: "amor" },
  { english: "time", spanish: "tiempo" },
  { english: "day", spanish: "día" },
  { english: "night", spanish: "noche" },
  { english: "sun", spanish: "sol" },
  { english: "moon", spanish: "luna" },
  { english: "star", spanish: "estrella" },
  { english: "book", spanish: "libro" },
  { english: "school", spanish: "escuela" },
]

type GameState = "start" | "playing" | "gameOver"
type ChallengeType = "jump" | "slide"

interface Challenge {
  type: ChallengeType
  word: string
  correctAnswer: string
  options: string[]
  x: number
  passed: boolean
  cleared: boolean
  readyToAvoid: boolean
}

export default function LingoLeapGame() {
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const [gameState, setGameState] = useState<GameState>("start")
  const [score, setScore] = useState(0)
  const [highScore, setHighScore] = useState(0)
  const [currentChallenge, setCurrentChallenge] = useState<Challenge | null>(null)

  // Game physics
  const gameStateRef = useRef({
    playerY: 300,
    playerVelocityY: 0,
    playerX: 100,
    isJumping: false,
    isSliding: false,
    gameSpeed: 5,
    platforms: [] as { x: number; width: number }[],
    obstacles: [] as { x: number; height: number }[],
    lastChallengeX: 0,
  })

  const CANVAS_WIDTH = 800
  const CANVAS_HEIGHT = 500
  const PLAYER_WIDTH = 40
  const PLAYER_HEIGHT = 50
  const GROUND_Y = 350
  const GRAVITY = 1.2
  const JUMP_FORCE = -12

  // Load high score
  useEffect(() => {
    const saved = localStorage.getItem("lingoLeapHighScore")
    if (saved) setHighScore(Number.parseInt(saved))
  }, [])

  // Generate random challenge
  const generateChallenge = useCallback((x: number): Challenge => {
    const vocab = VOCABULARY[Math.floor(Math.random() * VOCABULARY.length)]
    const type: ChallengeType = Math.random() > 0.5 ? "jump" : "slide"

    if (type === "jump") {
      // Translation challenge for jumping gaps
      const wrongAnswers = VOCABULARY.filter((v) => v.spanish !== vocab.spanish)
        .sort(() => Math.random() - 0.5)
        .slice(0, 2)
        .map((v) => v.spanish)

      const options = [vocab.spanish, ...wrongAnswers].sort(() => Math.random() - 0.5)

      return {
        type: "jump",
        word: vocab.english,
        correctAnswer: vocab.spanish,
        options,
        x,
        passed: false,
        cleared: false,
        readyToAvoid: false,
      }
    } else {
      // Word recognition for sliding obstacles
      const wrongAnswers = VOCABULARY.filter((v) => v.english !== vocab.english)
        .sort(() => Math.random() - 0.5)
        .slice(0, 2)
        .map((v) => v.english)

      const options = [vocab.english, ...wrongAnswers].sort(() => Math.random() - 0.5)

      return {
        type: "slide",
        word: vocab.spanish,
        correctAnswer: vocab.english,
        options,
        x,
        passed: false,
        cleared: false,
        readyToAvoid: false,
      }
    }
  }, [])

  // Start game
  const startGame = useCallback(() => {
    setGameState("playing")
    setScore(0)
    gameStateRef.current = {
      playerY: GROUND_Y,
      playerVelocityY: 0,
      playerX: 100,
      isJumping: false,
      isSliding: false,
      gameSpeed: 5,
      platforms: [],
      obstacles: [],
      lastChallengeX: CANVAS_WIDTH,
    }
    setCurrentChallenge(generateChallenge(CANVAS_WIDTH + 200))
  }, [generateChallenge, CANVAS_WIDTH, GROUND_Y])

  // Handle jump
  const handleJump = useCallback(
    (answer: string) => {
      if (gameState !== "playing" || gameStateRef.current.isJumping) return

      if (currentChallenge && currentChallenge.type === "jump") {
        if (answer === currentChallenge.correctAnswer) {
          setScore((prev) => prev + 100)
          currentChallenge.readyToAvoid = true
          currentChallenge.cleared = true
        } else {
          endGame()
        }
      }
    },
    [gameState, currentChallenge],
  )

  // Handle slide
  const handleSlide = useCallback(
    (answer: string) => {
      if (gameState !== "playing" || gameStateRef.current.isSliding) return

      if (currentChallenge && currentChallenge.type === "slide") {
        if (answer === currentChallenge.correctAnswer) {
          setScore((prev) => prev + 50)
          currentChallenge.readyToAvoid = true
          currentChallenge.cleared = true
        } else {
          endGame()
        }
      }
    },
    [gameState, currentChallenge],
  )

  // End game
  const endGame = useCallback(() => {
    setGameState("gameOver")
    if (score > highScore) {
      setHighScore(score)
      localStorage.setItem("lingoLeapHighScore", score.toString())
    }
  }, [score, highScore])

  // Game loop
  useEffect(() => {
    if (gameState !== "playing") return

    const canvas = canvasRef.current
    if (!canvas) return
    const ctx = canvas.getContext("2d")
    if (!ctx) return

    let animationFrameId: number

    const gameLoop = () => {
      const state = gameStateRef.current

      // Clear canvas
      ctx.fillStyle = "#87CEEB"
      ctx.fillRect(0, 0, CANVAS_WIDTH, CANVAS_HEIGHT)

      // Draw ground
      ctx.fillStyle = "#8B4513"
      ctx.fillRect(0, GROUND_Y + PLAYER_HEIGHT, CANVAS_WIDTH, CANVAS_HEIGHT - GROUND_Y - PLAYER_HEIGHT)

      // Update player physics
      if (state.isJumping) {
        state.playerVelocityY += GRAVITY
        state.playerY += state.playerVelocityY

        if (state.playerY >= GROUND_Y) {
          state.playerY = GROUND_Y
          state.playerVelocityY = 0
          state.isJumping = false
        }
      }

      // Draw player
      const playerHeight = state.isSliding ? PLAYER_HEIGHT / 2 : PLAYER_HEIGHT
      const playerY = state.isSliding ? state.playerY + PLAYER_HEIGHT / 2 : state.playerY

      ctx.fillStyle = "#FF6B6B"
      ctx.fillRect(state.playerX, playerY, PLAYER_WIDTH, playerHeight)

      // Draw player face
      ctx.fillStyle = "#000"
      ctx.fillRect(state.playerX + 10, playerY + 10, 5, 5)
      ctx.fillRect(state.playerX + 25, playerY + 10, 5, 5)

      // Update and draw challenge
      if (currentChallenge) {
        currentChallenge.x -= state.gameSpeed

        if (
          currentChallenge.readyToAvoid &&
          !state.isJumping &&
          !state.isSliding &&
          currentChallenge.x - state.playerX < 150 &&
          currentChallenge.x - state.playerX > 0
        ) {
          if (currentChallenge.type === "jump") {
            state.isJumping = true
            state.playerVelocityY = JUMP_FORCE
          } else {
            state.isSliding = true
            setTimeout(() => {
              state.isSliding = false
            }, 800)
          }
          currentChallenge.readyToAvoid = false
        }

        if (currentChallenge.type === "jump") {
          ctx.fillStyle = "#000"
          ctx.fillRect(currentChallenge.x, GROUND_Y + PLAYER_HEIGHT, 50, 20)

          // Check if player fell in gap
          if (
            !currentChallenge.cleared &&
            state.playerX + PLAYER_WIDTH > currentChallenge.x &&
            state.playerX < currentChallenge.x + 50 &&
            state.playerY >= GROUND_Y &&
            !state.isJumping
          ) {
            endGame()
          }
        } else {
          // Draw obstacle
          const obstacleHeight = 60
          ctx.fillStyle = "#FF4444"
          ctx.fillRect(currentChallenge.x, GROUND_Y + PLAYER_HEIGHT - obstacleHeight, 40, obstacleHeight)

          // Check collision with obstacle
          if (
            !currentChallenge.cleared &&
            state.playerX + PLAYER_WIDTH > currentChallenge.x &&
            state.playerX < currentChallenge.x + 40 &&
            playerY + playerHeight > GROUND_Y + PLAYER_HEIGHT - obstacleHeight &&
            !state.isSliding
          ) {
            endGame()
          }
        }

        // Generate new challenge when current one passes
        if (currentChallenge.x < -200 && !currentChallenge.passed) {
          currentChallenge.passed = true
          setCurrentChallenge(generateChallenge(CANVAS_WIDTH + 300))
          setScore((prev) => prev + 10)

          // Increase difficulty
          state.gameSpeed = Math.min(state.gameSpeed + 0.2, 12)
        }
      }

      // Draw score
      ctx.fillStyle = "#000"
      ctx.font = "bold 24px sans-serif"
      ctx.fillText(`Score: ${score}`, 20, 40)

      animationFrameId = requestAnimationFrame(gameLoop)
    }

    gameLoop()

    return () => {
      cancelAnimationFrame(animationFrameId)
    }
  }, [
    gameState,
    score,
    currentChallenge,
    generateChallenge,
    endGame,
    CANVAS_WIDTH,
    CANVAS_HEIGHT,
    GROUND_Y,
    PLAYER_WIDTH,
    PLAYER_HEIGHT,
    GRAVITY,
    JUMP_FORCE,
  ])

  return (
    <div className="min-h-screen bg-gradient-to-b from-blue-400 to-purple-500 flex items-center justify-center p-4">
      <div className="w-full max-w-4xl">
        {gameState === "start" && (
          <Card className="p-8 text-center space-y-6">
            <h1 className="text-5xl font-bold text-primary">LingoLeap</h1>
            <p className="text-xl text-muted-foreground">Learn Spanish while you play!</p>
            <div className="space-y-2">
              <p className="text-lg">Jump over gaps by selecting the correct translation</p>
              <p className="text-lg">Slide under obstacles by recognizing the word</p>
            </div>
            <div className="text-2xl font-semibold">High Score: {highScore}</div>
            <Button size="lg" onClick={startGame} className="text-xl px-8 py-6">
              Start Game
            </Button>
          </Card>
        )}

        {gameState === "playing" && (
          <div className="space-y-4">
            <Card className="p-6">
              <div className="flex justify-center">
                <canvas
                  ref={canvasRef}
                  width={CANVAS_WIDTH}
                  height={CANVAS_HEIGHT}
                  className="border-4 border-primary rounded-lg"
                />
              </div>
            </Card>

            {currentChallenge && (
              <Card className="p-6">
                <div className="text-center space-y-4">
                  <div className="text-2xl font-bold">
                    {currentChallenge.type === "jump" ? "Translate:" : "Recognize:"}
                  </div>
                  <div className="text-4xl font-bold text-primary">{currentChallenge.word}</div>
                  <div className="flex gap-4 justify-center">
                    {currentChallenge.options.map((option, index) => (
                      <Button
                        key={index}
                        size="lg"
                        onClick={() => (currentChallenge.type === "jump" ? handleJump(option) : handleSlide(option))}
                        className="text-xl px-6 py-6"
                      >
                        {option}
                      </Button>
                    ))}
                  </div>
                  <div className="text-sm text-muted-foreground">
                    {currentChallenge.type === "jump" ? "Click to JUMP" : "Click to SLIDE"}
                  </div>
                </div>
              </Card>
            )}
          </div>
        )}

        {gameState === "gameOver" && (
          <Card className="p-8 text-center space-y-6">
            <h2 className="text-4xl font-bold text-destructive">Game Over!</h2>
            <div className="space-y-2">
              <div className="text-3xl font-semibold">Final Score: {score}</div>
              <div className="text-2xl">High Score: {highScore}</div>
            </div>
            <Button size="lg" onClick={startGame} className="text-xl px-8 py-6">
              Play Again
            </Button>
          </Card>
        )}
      </div>
    </div>
  )
}
