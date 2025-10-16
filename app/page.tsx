"use client"

import { useState, useEffect, useRef, useCallback } from "react"
import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"
import { Lock, Settings, ShoppingCart, Plus, Trash2, Edit2, ArrowLeft, Save } from "lucide-react"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"

// Default vocabulary data
const DEFAULT_VOCABULARY = [
  { english: "hello", spanish: "hola", emoji: "👋", section: "Greetings" },
  { english: "goodbye", spanish: "adiós", emoji: "👋", section: "Greetings" },
  { english: "please", spanish: "por favor", emoji: "🙏", section: "Greetings" },
  { english: "thank you", spanish: "gracias", emoji: "🙏", section: "Greetings" },
  { english: "yes", spanish: "sí", emoji: "✅", section: "Basic" },
  { english: "no", spanish: "no", emoji: "❌", section: "Basic" },
  { english: "water", spanish: "agua", emoji: "💧", section: "Food & Drink" },
  { english: "food", spanish: "comida", emoji: "🍔", section: "Food & Drink" },
  { english: "house", spanish: "casa", emoji: "🏠", section: "Places" },
  { english: "friend", spanish: "amigo", emoji: "👥", section: "People" },
  { english: "family", spanish: "familia", emoji: "👨‍👩‍👧‍👦", section: "People" },
  { english: "love", spanish: "amor", emoji: "❤️", section: "Emotions" },
  { english: "time", spanish: "tiempo", emoji: "⏰", section: "Time" },
  { english: "day", spanish: "día", emoji: "☀️", section: "Time" },
  { english: "night", spanish: "noche", emoji: "🌙", section: "Time" },
  { english: "sun", spanish: "sol", emoji: "☀️", section: "Nature" },
  { english: "moon", spanish: "luna", emoji: "🌙", section: "Nature" },
  { english: "star", spanish: "estrella", emoji: "⭐", section: "Nature" },
  { english: "book", spanish: "libro", emoji: "📖", section: "School" },
  { english: "school", spanish: "escuela", emoji: "🏫", section: "School" },
]

const LEVELS = [
  { id: 1, name: "Level 1", icon: "🌳", pointsRequired: 2500, color: "#4ade80" },
  { id: 2, name: "Level 2", icon: "🌊", pointsRequired: 3500, color: "#60a5fa" },
  { id: 3, name: "Level 3", icon: "🏠", pointsRequired: 4500, color: "#fb923c" },
  { id: 4, name: "Level 4", icon: "🔒", pointsRequired: 5500, color: "#60a5fa" },
]

type GameState = "menu" | "start" | "playing" | "gameOver" | "levelComplete" | "admin"
type ChallengeType = "jump" | "slide"

interface VocabularyWord {
  english: string
  spanish: string
  emoji: string
  section: string
}

interface Challenge {
  type: ChallengeType
  word: string
  correctAnswer: string
  options: string[]
  x: number
  passed: boolean
  cleared: boolean
  readyToAvoid: boolean
  emoji: string
}

interface LevelProgress {
  unlockedLevels: number[]
  currentLevel: number
  totalCoins: number
}

export default function LingoLeapGame() {
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const [gameState, setGameState] = useState<GameState>("menu")
  const [score, setScore] = useState(0)
  const [highScore, setHighScore] = useState(0)
  const [currentChallenge, setCurrentChallenge] = useState<Challenge | null>(null)

  const [vocabulary, setVocabulary] = useState<VocabularyWord[]>(DEFAULT_VOCABULARY)
  const [selectedSection, setSelectedSection] = useState<string>("Greetings")
  const [editingWord, setEditingWord] = useState<VocabularyWord | null>(null)
  const [newWord, setNewWord] = useState<VocabularyWord>({
    english: "",
    spanish: "",
    emoji: "",
    section: "Greetings",
  })

  const [levelProgress, setLevelProgress] = useState<LevelProgress>({
    unlockedLevels: [1],
    currentLevel: 1,
    totalCoins: 0,
  })

  const cloudsRef = useRef<{ x: number; y: number; size: number }[]>([])
  const treesRef = useRef<{ x: number; type: number }[]>([])

  // Game physics
  const gameStateRef = useRef({
    playerY: 300,
    playerVelocityY: 0,
    playerX: 100,
    isJumping: false,
    isSliding: false,
    gameSpeed: 4,
    platforms: [] as { x: number; width: number }[],
    obstacles: [] as { x: number; height: number }[],
    lastChallengeX: 0,
  })

  const CANVAS_WIDTH = 800
  const CANVAS_HEIGHT = 500
  const PLAYER_WIDTH = 40
  const PLAYER_HEIGHT = 50
  const GROUND_Y = 350
  const GRAVITY = 0.6
  const JUMP_FORCE = -15

  useEffect(() => {
    const saved = localStorage.getItem("lingoLeapHighScore")
    if (saved) setHighScore(Number.parseInt(saved))

    const savedProgress = localStorage.getItem("lingoLeapProgress")
    if (savedProgress) {
      setLevelProgress(JSON.parse(savedProgress))
    }

    const savedVocabulary = localStorage.getItem("lingoLeapVocabulary")
    if (savedVocabulary) {
      const loadedVocab = JSON.parse(savedVocabulary)
      console.log("[v0] Loaded vocabulary from localStorage:", loadedVocab.length, "words")
      setVocabulary(loadedVocab)
    } else {
      console.log("[v0] No saved vocabulary, using default:", DEFAULT_VOCABULARY.length, "words")
    }
  }, [])

  const saveVocabulary = useCallback((vocab: VocabularyWord[]) => {
    console.log("[v0] Saving vocabulary to localStorage:", vocab.length, "words")
    localStorage.setItem("lingoLeapVocabulary", JSON.stringify(vocab))
    setVocabulary(vocab)
  }, [])

  const addWord = useCallback(() => {
    console.log("[v0] Add Word button clicked")
    console.log("[v0] Current newWord state:", newWord)
    console.log(
      "[v0] Validation check - english:",
      !!newWord.english,
      "spanish:",
      !!newWord.spanish,
      "emoji:",
      !!newWord.emoji,
    )

    if (newWord.english && newWord.spanish && newWord.emoji) {
      const trimmedWord = {
        english: newWord.english.trim(),
        spanish: newWord.spanish.trim(),
        emoji: newWord.emoji.trim(),
        section: newWord.section.trim() || "Uncategorized", // Default to "Uncategorized" if section is empty
      }

      console.log("[v0] Validation passed, adding word:", trimmedWord)
      const updatedVocab = [...vocabulary, trimmedWord]
      console.log("[v0] Adding new word:", trimmedWord)
      saveVocabulary(updatedVocab)

      setSelectedSection(trimmedWord.section)

      setNewWord({ english: "", spanish: "", emoji: "", section: trimmedWord.section })
    } else {
      console.log("[v0] Validation failed - missing required fields")
      if (!newWord.english) console.log("[v0] Missing: English")
      if (!newWord.spanish) console.log("[v0] Missing: Spanish")
      if (!newWord.emoji) console.log("[v0] Missing: Emoji")
    }
  }, [newWord, vocabulary, saveVocabulary])

  const updateWord = useCallback(
    (oldWord: VocabularyWord, updatedWord: VocabularyWord) => {
      const updatedVocab = vocabulary.map((word) =>
        word.english === oldWord.english && word.spanish === oldWord.spanish ? updatedWord : word,
      )
      saveVocabulary(updatedVocab)
      setEditingWord(null)
    },
    [vocabulary, saveVocabulary],
  )

  const deleteWord = useCallback(
    (wordToDelete: VocabularyWord) => {
      const updatedVocab = vocabulary.filter(
        (word) => !(word.english === wordToDelete.english && word.spanish === wordToDelete.spanish),
      )
      saveVocabulary(updatedVocab)
    },
    [vocabulary, saveVocabulary],
  )

  const sections = Array.from(new Set(vocabulary.map((word) => word.section)))

  const saveLevelProgress = useCallback((progress: LevelProgress) => {
    localStorage.setItem("lingoLeapProgress", JSON.stringify(progress))
    setLevelProgress(progress)
  }, [])

  const generateChallenge = useCallback(
    (x: number, level: number): Challenge => {
      console.log("[v0] Generating challenge from vocabulary pool of", vocabulary.length, "words")
      const vocab = vocabulary[Math.floor(Math.random() * vocabulary.length)]
      console.log("[v0] Selected word:", vocab.english, "→", vocab.spanish, vocab.emoji)
      const type: ChallengeType = Math.random() > 0.5 ? "jump" : "slide"

      // Level 1: English word → Spanish translations
      // Level 2: Emoji → English words
      if (level === 1) {
        if (type === "jump") {
          const wrongAnswers = vocabulary
            .filter((v) => v.spanish !== vocab.spanish)
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
            emoji: vocab.emoji,
          }
        } else {
          const wrongAnswers = vocabulary
            .filter((v) => v.english !== vocab.english)
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
            emoji: vocab.emoji,
          }
        }
      } else {
        // Level 2+: Emoji → English words
        if (type === "jump") {
          const wrongAnswers = vocabulary
            .filter((v) => v.english !== vocab.english)
            .sort(() => Math.random() - 0.5)
            .slice(0, 2)
            .map((v) => v.english)

          const options = [vocab.english, ...wrongAnswers].sort(() => Math.random() - 0.5)

          return {
            type: "jump",
            word: vocab.emoji,
            correctAnswer: vocab.english,
            options,
            x,
            passed: false,
            cleared: false,
            readyToAvoid: false,
            emoji: vocab.emoji,
          }
        } else {
          const wrongAnswers = vocabulary
            .filter((v) => v.english !== vocab.english)
            .sort(() => Math.random() - 0.5)
            .slice(0, 2)
            .map((v) => v.english)

          const options = [vocab.english, ...wrongAnswers].sort(() => Math.random() - 0.5)

          return {
            type: "slide",
            word: vocab.emoji,
            correctAnswer: vocab.english,
            options,
            x,
            passed: false,
            cleared: false,
            readyToAvoid: false,
            emoji: vocab.emoji,
          }
        }
      }
    },
    [vocabulary],
  )

  const startGame = useCallback(() => {
    setGameState("playing")
    setScore(0)

    const initialSpeed = levelProgress.currentLevel === 1 ? 3 : 5

    gameStateRef.current = {
      playerY: GROUND_Y,
      playerVelocityY: 0,
      playerX: 100,
      isJumping: false,
      isSliding: false,
      gameSpeed: initialSpeed,
      platforms: [],
      obstacles: [],
      lastChallengeX: CANVAS_WIDTH,
    }
    setCurrentChallenge(generateChallenge(CANVAS_WIDTH + 200, levelProgress.currentLevel))

    cloudsRef.current = [
      { x: 100, y: 50, size: 60 },
      { x: 300, y: 80, size: 50 },
      { x: 500, y: 40, size: 70 },
      { x: 700, y: 90, size: 55 },
    ]

    treesRef.current = [
      { x: 200, type: 0 },
      { x: 400, type: 1 },
      { x: 600, type: 0 },
      { x: 800, type: 1 },
    ]
  }, [generateChallenge, CANVAS_WIDTH, GROUND_Y, levelProgress.currentLevel])

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

  const endGame = useCallback(() => {
    const currentLevelData = LEVELS.find((l) => l.id === levelProgress.currentLevel)

    if (currentLevelData && score >= currentLevelData.pointsRequired) {
      // Level completed!
      setGameState("levelComplete")

      // Unlock next level
      const nextLevelId = levelProgress.currentLevel + 1
      if (nextLevelId <= LEVELS.length && !levelProgress.unlockedLevels.includes(nextLevelId)) {
        const newProgress = {
          ...levelProgress,
          unlockedLevels: [...levelProgress.unlockedLevels, nextLevelId],
          totalCoins: levelProgress.totalCoins + Math.floor(score / 10),
        }
        saveLevelProgress(newProgress)
      }
    } else {
      setGameState("gameOver")
    }

    if (score > highScore) {
      setHighScore(score)
      localStorage.setItem("lingoLeapHighScore", score.toString())
    }
  }, [score, highScore, levelProgress, saveLevelProgress])

  useEffect(() => {
    if (gameState === "playing") {
      const currentLevelData = LEVELS.find((l) => l.id === levelProgress.currentLevel)
      if (currentLevelData && score >= currentLevelData.pointsRequired) {
        endGame()
      }
    }
  }, [score, gameState, levelProgress.currentLevel, endGame])

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

      const skyGradient = ctx.createLinearGradient(0, 0, 0, CANVAS_HEIGHT)
      skyGradient.addColorStop(0, "#87CEEB")
      skyGradient.addColorStop(0.7, "#B0E0E6")
      skyGradient.addColorStop(1, "#E0F6FF")
      ctx.fillStyle = skyGradient
      ctx.fillRect(0, 0, CANVAS_WIDTH, CANVAS_HEIGHT)

      cloudsRef.current.forEach((cloud) => {
        cloud.x -= state.gameSpeed * 0.3 // Clouds move slower (parallax effect)

        // Wrap clouds around
        if (cloud.x + cloud.size < 0) {
          cloud.x = CANVAS_WIDTH + 50
        }

        // Draw cloud
        ctx.fillStyle = "rgba(255, 255, 255, 0.8)"
        ctx.beginPath()
        ctx.arc(cloud.x, cloud.y, cloud.size * 0.5, 0, Math.PI * 2)
        ctx.arc(cloud.x + cloud.size * 0.4, cloud.y, cloud.size * 0.4, 0, Math.PI * 2)
        ctx.arc(cloud.x + cloud.size * 0.7, cloud.y, cloud.size * 0.35, 0, Math.PI * 2)
        ctx.arc(cloud.x - cloud.size * 0.3, cloud.y, cloud.size * 0.35, 0, Math.PI * 2)
        ctx.fill()
      })

      ctx.fillStyle = "#90EE90"
      ctx.beginPath()
      ctx.moveTo(0, GROUND_Y + 20)
      for (let i = 0; i <= CANVAS_WIDTH; i += 50) {
        const offset = Math.sin((i + state.gameSpeed * 2) * 0.02) * 20
        ctx.lineTo(i, GROUND_Y + 20 + offset)
      }
      ctx.lineTo(CANVAS_WIDTH, CANVAS_HEIGHT)
      ctx.lineTo(0, CANVAS_HEIGHT)
      ctx.closePath()
      ctx.fill()

      ctx.fillStyle = "#8B4513"
      ctx.fillRect(0, GROUND_Y + PLAYER_HEIGHT, CANVAS_WIDTH, CANVAS_HEIGHT - GROUND_Y - PLAYER_HEIGHT)

      // Draw grass on top of ground
      ctx.fillStyle = "#228B22"
      ctx.fillRect(0, GROUND_Y + PLAYER_HEIGHT, CANVAS_WIDTH, 10)

      // Draw grass blades
      ctx.strokeStyle = "#2F8B2F"
      ctx.lineWidth = 2
      for (let i = 0; i < CANVAS_WIDTH; i += 8) {
        const grassX = i + ((state.gameSpeed * 2) % 8)
        ctx.beginPath()
        ctx.moveTo(grassX, GROUND_Y + PLAYER_HEIGHT + 10)
        ctx.lineTo(grassX - 2, GROUND_Y + PLAYER_HEIGHT + 3)
        ctx.stroke()
      }

      treesRef.current.forEach((tree) => {
        tree.x -= state.gameSpeed * 0.5 // Trees move at medium speed

        // Wrap trees around
        if (tree.x < -50) {
          tree.x = CANVAS_WIDTH + 50
          tree.type = Math.floor(Math.random() * 2)
        }

        // Draw tree trunk
        ctx.fillStyle = "#654321"
        ctx.fillRect(tree.x - 8, GROUND_Y + PLAYER_HEIGHT - 40, 16, 40)

        // Draw tree foliage
        if (tree.type === 0) {
          // Round tree
          ctx.fillStyle = "#228B22"
          ctx.beginPath()
          ctx.arc(tree.x, GROUND_Y + PLAYER_HEIGHT - 50, 30, 0, Math.PI * 2)
          ctx.fill()

          // Darker shade for depth
          ctx.fillStyle = "#1a6b1a"
          ctx.beginPath()
          ctx.arc(tree.x - 10, GROUND_Y + PLAYER_HEIGHT - 55, 20, 0, Math.PI * 2)
          ctx.fill()
        } else {
          // Triangle tree
          ctx.fillStyle = "#228B22"
          ctx.beginPath()
          ctx.moveTo(tree.x, GROUND_Y + PLAYER_HEIGHT - 70)
          ctx.lineTo(tree.x - 25, GROUND_Y + PLAYER_HEIGHT - 30)
          ctx.lineTo(tree.x + 25, GROUND_Y + PLAYER_HEIGHT - 30)
          ctx.closePath()
          ctx.fill()

          // Second layer
          ctx.beginPath()
          ctx.moveTo(tree.x, GROUND_Y + PLAYER_HEIGHT - 55)
          ctx.lineTo(tree.x - 20, GROUND_Y + PLAYER_HEIGHT - 25)
          ctx.lineTo(tree.x + 20, GROUND_Y + PLAYER_HEIGHT - 25)
          ctx.closePath()
          ctx.fill()
        }
      })

      if (state.isJumping) {
        state.playerVelocityY += GRAVITY
        state.playerY += state.playerVelocityY

        if (state.playerY >= GROUND_Y) {
          state.playerY = GROUND_Y
          state.playerVelocityY = 0
          state.isJumping = false
        }
      }

      const playerHeight = state.isSliding ? PLAYER_HEIGHT / 2 : PLAYER_HEIGHT
      const playerY = state.isSliding ? state.playerY + PLAYER_HEIGHT / 2 : state.playerY

      ctx.fillStyle = "#FF6B6B"
      ctx.fillRect(state.playerX, playerY, PLAYER_WIDTH, playerHeight)

      ctx.fillStyle = "#000"
      ctx.fillRect(state.playerX + 10, playerY + 10, 5, 5)
      ctx.fillRect(state.playerX + 25, playerY + 10, 5, 5)

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
          const gapWidth = 80
          const gapDepth = 100

          // Draw the pit/chasm with depth
          // Top edge highlight
          ctx.fillStyle = "#654321"
          ctx.fillRect(currentChallenge.x - 5, GROUND_Y + PLAYER_HEIGHT, gapWidth + 10, 5)

          // Main pit - gradient from dark at bottom to lighter at top
          const pitGradient = ctx.createLinearGradient(
            currentChallenge.x,
            GROUND_Y + PLAYER_HEIGHT,
            currentChallenge.x,
            GROUND_Y + PLAYER_HEIGHT + gapDepth,
          )
          pitGradient.addColorStop(0, "#1a1a1a")
          pitGradient.addColorStop(0.3, "#0d0d0d")
          pitGradient.addColorStop(1, "#000000")
          ctx.fillStyle = pitGradient
          ctx.fillRect(currentChallenge.x, GROUND_Y + PLAYER_HEIGHT, gapWidth, gapDepth)

          // Left wall shadow (darker)
          const leftWallGradient = ctx.createLinearGradient(
            currentChallenge.x,
            GROUND_Y + PLAYER_HEIGHT,
            currentChallenge.x + 15,
            GROUND_Y + PLAYER_HEIGHT,
          )
          leftWallGradient.addColorStop(0, "#2a1810")
          leftWallGradient.addColorStop(1, "rgba(42, 24, 16, 0)")
          ctx.fillStyle = leftWallGradient
          ctx.fillRect(currentChallenge.x, GROUND_Y + PLAYER_HEIGHT, 15, gapDepth)

          // Right wall shadow
          const rightWallGradient = ctx.createLinearGradient(
            currentChallenge.x + gapWidth - 15,
            GROUND_Y + PLAYER_HEIGHT,
            currentChallenge.x + gapWidth,
            GROUND_Y + PLAYER_HEIGHT,
          )
          rightWallGradient.addColorStop(0, "rgba(42, 24, 16, 0)")
          rightWallGradient.addColorStop(1, "#2a1810")
          ctx.fillStyle = rightWallGradient
          ctx.fillRect(currentChallenge.x + gapWidth - 15, GROUND_Y + PLAYER_HEIGHT, 15, gapDepth)

          // Add some cracks on the edges
          ctx.strokeStyle = "#4a3020"
          ctx.lineWidth = 2
          ctx.beginPath()
          ctx.moveTo(currentChallenge.x - 3, GROUND_Y + PLAYER_HEIGHT)
          ctx.lineTo(currentChallenge.x + 5, GROUND_Y + PLAYER_HEIGHT + 15)
          ctx.stroke()

          ctx.beginPath()
          ctx.moveTo(currentChallenge.x + gapWidth + 3, GROUND_Y + PLAYER_HEIGHT)
          ctx.lineTo(currentChallenge.x + gapWidth - 5, GROUND_Y + PLAYER_HEIGHT + 15)
          ctx.stroke()

          // Bottom of pit (very dark with some detail)
          ctx.fillStyle = "#050505"
          ctx.fillRect(currentChallenge.x + 10, GROUND_Y + PLAYER_HEIGHT + gapDepth - 20, gapWidth - 20, 20)

          // Add some spikes or rocks at the bottom for danger
          ctx.fillStyle = "#1a1a1a"
          for (let i = 0; i < 4; i++) {
            const spikeX = currentChallenge.x + 15 + i * 15
            ctx.beginPath()
            ctx.moveTo(spikeX, GROUND_Y + PLAYER_HEIGHT + gapDepth - 5)
            ctx.lineTo(spikeX + 5, GROUND_Y + PLAYER_HEIGHT + gapDepth - 20)
            ctx.lineTo(spikeX + 10, GROUND_Y + PLAYER_HEIGHT + gapDepth - 5)
            ctx.fill()
          }

          // Collision detection
          if (
            !currentChallenge.cleared &&
            state.playerX + PLAYER_WIDTH > currentChallenge.x &&
            state.playerX < currentChallenge.x + gapWidth &&
            state.playerY >= GROUND_Y &&
            !state.isJumping
          ) {
            endGame()
          }
        } else {
          const obstacleHeight = 60
          const obstacleWidth = 45
          const obstacleX = currentChallenge.x
          const obstacleY = GROUND_Y + PLAYER_HEIGHT - obstacleHeight

          // Log shadow on ground
          ctx.fillStyle = "rgba(0, 0, 0, 0.3)"
          ctx.ellipse(
            obstacleX + obstacleWidth / 2,
            GROUND_Y + PLAYER_HEIGHT + 5,
            obstacleWidth / 2 + 5,
            8,
            0,
            0,
            Math.PI * 2,
          )
          ctx.fill()

          // Main log body with wood texture gradient
          const logGradient = ctx.createLinearGradient(obstacleX, obstacleY, obstacleX + obstacleWidth, obstacleY)
          logGradient.addColorStop(0, "#4a2511")
          logGradient.addColorStop(0.3, "#6b3410")
          logGradient.addColorStop(0.5, "#8b4513")
          logGradient.addColorStop(0.7, "#6b3410")
          logGradient.addColorStop(1, "#4a2511")
          ctx.fillStyle = logGradient
          ctx.fillRect(obstacleX, obstacleY, obstacleWidth, obstacleHeight)

          // Left side darker (3D effect)
          ctx.fillStyle = "rgba(30, 15, 5, 0.5)"
          ctx.fillRect(obstacleX, obstacleY, 8, obstacleHeight)

          // Right side highlight
          ctx.fillStyle = "rgba(139, 90, 43, 0.4)"
          ctx.fillRect(obstacleX + obstacleWidth - 8, obstacleY, 8, obstacleHeight)

          // Wood rings/texture
          ctx.strokeStyle = "#3a1d0d"
          ctx.lineWidth = 2
          for (let i = 0; i < 3; i++) {
            const ringY = obstacleY + 15 + i * 15
            ctx.beginPath()
            ctx.moveTo(obstacleX + 5, ringY)
            ctx.quadraticCurveTo(obstacleX + obstacleWidth / 2, ringY + 3, obstacleX + obstacleWidth - 5, ringY)
            ctx.stroke()
          }

          // Top of log (circular end view)
          ctx.fillStyle = "#6b3410"
          ctx.beginPath()
          ctx.ellipse(obstacleX + obstacleWidth / 2, obstacleY, obstacleWidth / 2, 10, 0, 0, Math.PI * 2)
          ctx.fill()

          // Inner ring on top
          ctx.fillStyle = "#4a2511"
          ctx.beginPath()
          ctx.ellipse(obstacleX + obstacleWidth / 2, obstacleY, obstacleWidth / 3, 7, 0, 0, Math.PI * 2)
          ctx.fill()

          // Center dot
          ctx.fillStyle = "#2a1508"
          ctx.beginPath()
          ctx.arc(obstacleX + obstacleWidth / 2, obstacleY, 4, 0, Math.PI * 2)
          ctx.fill()

          // Highlight on top edge
          ctx.strokeStyle = "rgba(139, 90, 43, 0.6)"
          ctx.lineWidth = 2
          ctx.beginPath()
          ctx.ellipse(obstacleX + obstacleWidth / 2, obstacleY - 1, obstacleWidth / 2 - 3, 8, 0, Math.PI, 0)
          ctx.stroke()

          // Collision detection
          if (
            !currentChallenge.cleared &&
            state.playerX + PLAYER_WIDTH > obstacleX &&
            state.playerX < obstacleX + obstacleWidth &&
            state.playerY + PLAYER_HEIGHT > obstacleY &&
            !state.isSliding
          ) {
            endGame()
          }
        }

        if (currentChallenge.x < -200 && !currentChallenge.passed) {
          currentChallenge.passed = true
          setCurrentChallenge(generateChallenge(CANVAS_WIDTH + 300, levelProgress.currentLevel))
          setScore((prev) => prev + 10)

          const speedIncrease = levelProgress.currentLevel === 1 ? 0.1 : 0.2
          const maxSpeed = levelProgress.currentLevel === 1 ? 8 : 12
          state.gameSpeed = Math.min(state.gameSpeed + speedIncrease, maxSpeed)
        }
      }

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
    levelProgress.currentLevel,
  ])

  const selectLevel = useCallback(
    (levelId: number) => {
      if (levelProgress.unlockedLevels.includes(levelId)) {
        setLevelProgress({ ...levelProgress, currentLevel: levelId })
        setGameState("start")
      }
    },
    [levelProgress],
  )

  return (
    <div className="min-h-screen bg-gradient-to-b from-cyan-400 to-blue-500 flex items-center justify-center p-4">
      <div className="w-full max-w-4xl">
        {gameState === "menu" && (
          <Card className="p-8 bg-gradient-to-b from-cyan-300 to-blue-400 border-4 border-gray-700 relative overflow-hidden">
            {/* Header */}
            <div className="flex justify-between items-start mb-8">
              <h1 className="text-5xl font-bold text-white drop-shadow-lg" style={{ textShadow: "3px 3px 0 #8B4513" }}>
                LINGO LEAP
              </h1>
              <div className="flex gap-4 items-center">
                <div className="bg-orange-400 rounded-full p-3 border-4 border-orange-600 relative">
                  <span className="text-3xl">🎒</span>
                  <div className="absolute -bottom-1 -right-1 bg-white rounded-full w-7 h-7 flex items-center justify-center border-2 border-orange-600 text-sm font-bold">
                    7
                  </div>
                </div>
                <div className="bg-yellow-400 rounded-full px-4 py-2 border-4 border-yellow-600 flex items-center gap-2">
                  <span className="text-2xl">🪙</span>
                  <span className="text-xl font-bold text-white">{levelProgress.totalCoins}</span>
                </div>
              </div>
            </div>

            {/* Level badges */}
            <div className="relative min-h-[400px] mb-8">
              {LEVELS.map((level, index) => {
                const isUnlocked = levelProgress.unlockedLevels.includes(level.id)
                const yPosition = 50 + index * 100
                const xPosition = index % 2 === 0 ? 150 : 450

                return (
                  <div
                    key={level.id}
                    className="absolute transition-all duration-300 hover:scale-110"
                    style={{ top: `${yPosition}px`, left: `${xPosition}px` }}
                  >
                    <button onClick={() => selectLevel(level.id)} disabled={!isUnlocked} className="relative group">
                      {/* Badge circle */}
                      <div
                        className={`w-24 h-24 rounded-full border-8 flex items-center justify-center text-5xl transition-all ${
                          isUnlocked
                            ? "border-white shadow-lg cursor-pointer hover:shadow-2xl"
                            : "border-gray-400 opacity-60 cursor-not-allowed"
                        }`}
                        style={{ backgroundColor: isUnlocked ? level.color : "#94a3b8" }}
                      >
                        {isUnlocked ? level.icon : <Lock className="w-10 h-10 text-white" />}
                      </div>

                      {/* Level label */}
                      <div className="absolute -bottom-8 left-1/2 -translate-x-1/2 bg-orange-400 px-4 py-1 rounded border-2 border-orange-600 whitespace-nowrap">
                        <span className="text-sm font-bold text-white drop-shadow">{level.name}</span>
                      </div>
                    </button>
                  </div>
                )
              })}
            </div>

            {/* Bottom navigation */}
            <div className="flex justify-center gap-4 mt-16">
              <Button
                size="lg"
                onClick={() => selectLevel(levelProgress.currentLevel)}
                className="bg-blue-500 hover:bg-blue-600 text-white font-bold text-xl px-8 py-6 rounded-full border-4 border-blue-700 shadow-lg"
              >
                PLAY
              </Button>
              <Button
                size="lg"
                className="bg-orange-500 hover:bg-orange-600 text-white font-bold text-xl px-8 py-6 rounded-full border-4 border-orange-700 shadow-lg"
              >
                <ShoppingCart className="w-6 h-6 mr-2" />
                STORE
              </Button>
              <Button
                size="lg"
                onClick={() => setGameState("admin")}
                className="bg-blue-500 hover:bg-blue-600 text-white font-bold text-xl p-6 rounded-full border-4 border-blue-700 shadow-lg"
              >
                <Settings className="w-6 h-6" />
              </Button>
            </div>
          </Card>
        )}

        {gameState === "admin" && (
          <Card className="p-8 max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-3xl font-bold">Vocabulary Manager</h2>
              <Button onClick={() => setGameState("menu")} variant="outline" size="lg">
                <ArrowLeft className="w-5 h-5 mr-2" />
                Back to Menu
              </Button>
            </div>

            {/* Section tabs */}
            <div className="flex gap-2 mb-6 flex-wrap">
              {sections.map((section) => (
                <Button
                  key={section}
                  onClick={() => setSelectedSection(section)}
                  variant={selectedSection === section ? "default" : "outline"}
                  size="sm"
                >
                  {section}
                </Button>
              ))}
            </div>

            {/* Add new word form */}
            <Card className="p-6 mb-6 bg-green-50">
              <h3 className="text-xl font-bold mb-4">Add New Word</h3>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <Label htmlFor="new-english">English</Label>
                  <Input
                    id="new-english"
                    value={newWord.english}
                    onChange={(e) => setNewWord({ ...newWord, english: e.target.value })}
                    placeholder="hello"
                  />
                </div>
                <div>
                  <Label htmlFor="new-spanish">Spanish</Label>
                  <Input
                    id="new-spanish"
                    value={newWord.spanish}
                    onChange={(e) => setNewWord({ ...newWord, spanish: e.target.value })}
                    placeholder="hola"
                  />
                </div>
                <div>
                  <Label htmlFor="new-emoji">Emoji</Label>
                  <Input
                    id="new-emoji"
                    value={newWord.emoji}
                    onChange={(e) => setNewWord({ ...newWord, emoji: e.target.value })}
                    placeholder="👋"
                  />
                </div>
                <div>
                  <Label htmlFor="new-section">Section</Label>
                  <Input
                    id="new-section"
                    value={newWord.section}
                    onChange={(e) => setNewWord({ ...newWord, section: e.target.value })}
                    placeholder="Greetings"
                  />
                </div>
              </div>
              <Button onClick={addWord} className="mt-4" size="lg">
                <Plus className="w-5 h-5 mr-2" />
                Add Word
              </Button>
            </Card>

            {/* Words list for selected section */}
            <div className="space-y-4">
              <h3 className="text-2xl font-bold">{selectedSection} Words</h3>
              {vocabulary
                .filter((word) => word.section === selectedSection)
                .map((word, index) => (
                  <Card key={index} className="p-4">
                    {editingWord?.english === word.english && editingWord?.spanish === word.spanish ? (
                      <div className="space-y-4">
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                          <div>
                            <Label>English</Label>
                            <Input
                              value={editingWord.english}
                              onChange={(e) => setEditingWord({ ...editingWord, english: e.target.value })}
                            />
                          </div>
                          <div>
                            <Label>Spanish</Label>
                            <Input
                              value={editingWord.spanish}
                              onChange={(e) => setEditingWord({ ...editingWord, spanish: e.target.value })}
                            />
                          </div>
                          <div>
                            <Label>Emoji</Label>
                            <Input
                              value={editingWord.emoji}
                              onChange={(e) => setEditingWord({ ...editingWord, emoji: e.target.value })}
                            />
                          </div>
                          <div>
                            <Label>Section</Label>
                            <Input
                              value={editingWord.section}
                              onChange={(e) => setEditingWord({ ...editingWord, section: e.target.value })}
                            />
                          </div>
                        </div>
                        <div className="flex gap-2">
                          <Button onClick={() => updateWord(word, editingWord)} size="sm">
                            <Save className="w-4 h-4 mr-2" />
                            Save
                          </Button>
                          <Button onClick={() => setEditingWord(null)} variant="outline" size="sm">
                            Cancel
                          </Button>
                        </div>
                      </div>
                    ) : (
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-4">
                          <span className="text-3xl">{word.emoji}</span>
                          <div>
                            <div className="font-bold text-lg">{word.english}</div>
                            <div className="text-muted-foreground">{word.spanish}</div>
                          </div>
                        </div>
                        <div className="flex gap-2">
                          <Button onClick={() => setEditingWord(word)} variant="outline" size="sm">
                            <Edit2 className="w-4 h-4" />
                          </Button>
                          <Button onClick={() => deleteWord(word)} variant="destructive" size="sm">
                            <Trash2 className="w-4 h-4" />
                          </Button>
                        </div>
                      </div>
                    )}
                  </Card>
                ))}
            </div>
          </Card>
        )}

        {gameState === "start" && (
          <Card className="p-8 text-center space-y-6">
            <h1 className="text-5xl font-bold text-primary">
              {LEVELS.find((l) => l.id === levelProgress.currentLevel)?.name}
            </h1>
            <p className="text-xl text-muted-foreground">Learn Spanish while you play!</p>
            <div className="space-y-2">
              <p className="text-lg">Jump over gaps by selecting the correct translation</p>
              <p className="text-lg">Slide under obstacles by recognizing the word</p>
              <p className="text-2xl font-bold text-primary mt-4">
                Goal: {LEVELS.find((l) => l.id === levelProgress.currentLevel)?.pointsRequired} points
              </p>
            </div>
            <div className="text-2xl font-semibold">High Score: {highScore}</div>
            <div className="flex gap-4 justify-center">
              <Button size="lg" onClick={() => setGameState("menu")} variant="outline" className="text-xl px-8 py-6">
                Back to Menu
              </Button>
              <Button size="lg" onClick={startGame} className="text-xl px-8 py-6">
                Start Game
              </Button>
            </div>
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
                    {levelProgress.currentLevel === 1
                      ? currentChallenge.type === "jump"
                        ? "Translate:"
                        : "Recognize:"
                      : "Recognize:"}
                  </div>
                  <div className="text-4xl font-bold text-primary">
                    <span className={currentChallenge.word.length <= 3 ? "text-7xl" : ""}>{currentChallenge.word}</span>
                  </div>
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

        {gameState === "levelComplete" && (
          <Card className="p-8 text-center space-y-6 bg-gradient-to-b from-yellow-100 to-orange-100">
            <div className="text-8xl mb-4">🎉</div>
            <h2 className="text-5xl font-bold text-green-600">Congratulations!</h2>
            <p className="text-3xl font-semibold">
              {LEVELS.find((l) => l.id === levelProgress.currentLevel)?.name} Complete!
            </p>
            <div className="space-y-2">
              <div className="text-3xl font-semibold">Final Score: {score}</div>
              <div className="text-xl text-muted-foreground">You earned {Math.floor(score / 10)} coins!</div>
            </div>
            {levelProgress.currentLevel < LEVELS.length && (
              <div className="text-2xl font-bold text-primary">🔓 Level {levelProgress.currentLevel + 1} Unlocked!</div>
            )}
            <div className="flex gap-4 justify-center">
              <Button size="lg" onClick={() => setGameState("menu")} className="text-xl px-8 py-6">
                Back to Menu
              </Button>
              {levelProgress.currentLevel < LEVELS.length && (
                <Button
                  size="lg"
                  onClick={() => {
                    setLevelProgress({ ...levelProgress, currentLevel: levelProgress.currentLevel + 1 })
                    setGameState("start")
                  }}
                  className="text-xl px-8 py-6 bg-green-600 hover:bg-green-700"
                >
                  Next Level
                </Button>
              )}
            </div>
          </Card>
        )}

        {gameState === "gameOver" && (
          <Card className="p-8 text-center space-y-6">
            <h2 className="text-4xl font-bold text-destructive">Game Over!</h2>
            <div className="space-y-2">
              <div className="text-3xl font-semibold">Final Score: {score}</div>
              <div className="text-2xl">High Score: {highScore}</div>
              <div className="text-xl text-muted-foreground">
                Goal: {LEVELS.find((l) => l.id === levelProgress.currentLevel)?.pointsRequired} points
              </div>
            </div>
            <div className="flex gap-4 justify-center">
              <Button size="lg" onClick={() => setGameState("menu")} variant="outline" className="text-xl px-8 py-6">
                Back to Menu
              </Button>
              <Button size="lg" onClick={startGame} className="text-xl px-8 py-6">
                Try Again
              </Button>
            </div>
          </Card>
        )}
      </div>
    </div>
  )
}
