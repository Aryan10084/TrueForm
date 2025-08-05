// Global variables
let detector = null
const camera = null
let currentUserId = ""
let currentExercise = ""
let isWorkoutActive = false
let workoutStartTime = null
let repCount = 0
let accuracyScores = []
let repDetails = []
let currentState = "ready"
let lastState = "ready"
let stateTransitionTime = 0
let workoutTimer = null
let videoElement = null
let canvasElement = null
let canvasCtx = null

// API Configuration
const API_BASE_URL = "http://localhost:5000/api"

// Exercise configurations
const EXERCISE_CONFIG = {
  pushup: {
    name: "Push-ups",
    instructions:
      "Keep your body straight, lower until your chest nearly touches the ground, then push back up. Keep your core engaged and elbows close to your body.",
    keyPoints: [11, 12, 13, 14, 15, 16], // shoulders, elbows, wrists
    anglePoints: {
      leftElbow: [11, 13, 15], // left shoulder, elbow, wrist
      rightElbow: [12, 14, 16], // right shoulder, elbow, wrist
    },
    thresholds: {
      up: 160, // degrees
      down: 90, // degrees
    },
  },
  squat: {
    name: "Squats",
    instructions:
      "Stand with feet shoulder-width apart, lower your body as if sitting back into a chair, then stand back up. Keep your knees aligned with your toes.",
    keyPoints: [23, 24, 25, 26, 27, 28], // hips, knees, ankles
    anglePoints: {
      leftKnee: [23, 25, 27], // left hip, knee, ankle
      rightKnee: [24, 26, 28], // right hip, knee, ankle
    },
    thresholds: {
      up: 160, // degrees
      down: 90, // degrees
    },
  },
  pullup: {
    name: "Pull-ups",
    instructions:
      "Hang from the bar with arms extended, pull your body up until your chin is over the bar, then lower back down. Keep your core tight.",
    keyPoints: [11, 12, 13, 14, 15, 16], // shoulders, elbows, wrists
    anglePoints: {
      leftElbow: [11, 13, 15], // left shoulder, elbow, wrist
      rightElbow: [12, 14, 16], // right shoulder, elbow, wrist
    },
    thresholds: {
      up: 160, // degrees
      down: 90, // degrees
    },
  },
}

// Initialize the app
function startApp() {
  const userIdInput = document.getElementById("userId")
  currentUserId = userIdInput.value.trim()

  if (!currentUserId) {
    showError("Please enter a user ID")
    return
  }

  document.getElementById("userSetup").style.display = "none"
  document.getElementById("mainApp").style.display = "block"

  initializeCamera()
}

// Initialize camera and pose detection
async function initializeCamera() {
  showLoading(true)

  try {
    // Get video and canvas elements
    videoElement = document.getElementById("videoElement")
    canvasElement = document.getElementById("canvasElement")
    canvasCtx = canvasElement.getContext("2d")

    
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      throw new Error("Camera access is not supported in this browser")
    }

    // Request camera access
    const stream = await navigator.mediaDevices.getUserMedia({
      video: {
        width: { ideal: 640 },
        height: { ideal: 480 },
        facingMode: "user",
      },
      audio: false,
    })

    videoElement.srcObject = stream

    
    await new Promise((resolve) => {
      videoElement.onloadedmetadata = () => {
        videoElement.play()
        resolve()
      }
    })

   
    canvasElement.width = videoElement.videoWidth || 640
    canvasElement.height = videoElement.videoHeight || 480

    
    await initializePoseDetection()

    showLoading(false)
    console.log("Camera and pose detection initialized successfully")

    
    document.getElementById("feedbackText").textContent = "Camera ready! Select an exercise to begin."
  } catch (error) {
    console.error("Error initializing camera:", error)
    showLoading(false)

    if (error.name === "NotAllowedError") {
      showError("Camera access denied. Please allow camera access and refresh the page.")
    } else if (error.name === "NotFoundError") {
      showError("No camera found. Please connect a camera and refresh the page.")
    } else {
      showError(`Camera initialization failed: ${error.message}`)
    }
  }
}

// Initialize TensorFlow.js pose detection
async function initializePoseDetection() {
  try {
    
    const tf = window.tf 
    await tf.ready()

    //  pose detector
    const poseDetection = window.poseDetection 
    detector = await poseDetection.createDetector(poseDetection.SupportedModels.MoveNet, {
      modelType: poseDetection.movenet.modelType.SINGLEPOSE_LIGHTNING,
    })

    
    detectPose()

    console.log("Pose detection initialized")
  } catch (error) {
    console.error("Error initializing pose detection:", error)

    // Fallback to MediaPipe if TensorFlow.js fails
    try {
      await initializeMediaPipe()
    } catch (mpError) {
      console.error("MediaPipe fallback also failed:", mpError)
      showError("Pose detection initialization failed. Please refresh the page.")
    }
  }
}


async function initializeMediaPipe() {
  const Pose = window.Pose // Assuming Pose is available globally
  if (typeof Pose === "undefined") {
    throw new Error("MediaPipe not loaded")
  }

  const pose = new Pose({
    locateFile: (file) => {
      return `https://cdn.jsdelivr.net/npm/@mediapipe/pose@0.5.1675469404/${file}`
    },
  })

  pose.setOptions({
    modelComplexity: 1,
    smoothLandmarks: true,
    enableSegmentation: false,
    smoothSegmentation: false,
    minDetectionConfidence: 0.5,
    minTrackingConfidence: 0.5,
  })

  pose.onResults(onMediaPipeResults)

  
  const Camera = window.Camera 
  const camera = new Camera(videoElement, {
    onFrame: async () => {
      if (pose) {
        await pose.send({ image: videoElement })
      }
    },
    width: 640,
    height: 480,
  })

  await camera.start()
  console.log("MediaPipe fallback initialized")
}


async function detectPose() {
  if (!detector || !videoElement) return

  try {
    const poses = await detector.estimatePoses(videoElement)

    if (poses && poses.length > 0) {
      const pose = poses[0]

      // Converting TensorFlow.js format to MediaPipe-like format
      const landmarks = convertTFPoseToMediaPipe(pose.keypoints)

      
      onPoseResults({ poseLandmarks: landmarks })
    }
  } catch (error) {
    console.error("Error in pose detection:", error)
  }

  
  requestAnimationFrame(detectPose)
}


function convertTFPoseToMediaPipe(keypoints) {
  // TensorFlow.js MoveNet has 17 keypoints, we need to map to MediaPipe's 33
  const landmarks = new Array(33).fill(null)

  // Map TensorFlow.js keypoints to MediaPipe indices
  const keypointMap = {
    0: 0, // nose
    1: 2, // left_eye
    2: 5, // right_eye
    3: 7, // left_ear
    4: 8, // right_ear
    5: 11, // left_shoulder
    6: 12, // right_shoulder
    7: 13, // left_elbow
    8: 14, // right_elbow
    9: 15, // left_wrist
    10: 16, // right_wrist
    11: 23, // left_hip
    12: 24, // right_hip
    13: 25, // left_knee
    14: 26, // right_knee
    15: 27, // left_ankle
    16: 28, // right_ankle
  }

  keypoints.forEach((keypoint, index) => {
    const mpIndex = keypointMap[index]
    if (mpIndex !== undefined && keypoint.score > 0.3) {
      landmarks[mpIndex] = {
        x: keypoint.x / videoElement.videoWidth,
        y: keypoint.y / videoElement.videoHeight,
        z: keypoint.z || 0,
        visibility: keypoint.score,
      }
    }
  })

  return landmarks.filter((landmark) => landmark !== null)
}


function onMediaPipeResults(results) {
  onPoseResults(results)
}


function onPoseResults(results) {
  // Clear canvas
  canvasCtx.clearRect(0, 0, canvasElement.width, canvasElement.height)

  if (results.poseLandmarks && results.poseLandmarks.length > 0 && isWorkoutActive) {
    // Draw pose landmarks
    drawPose(results.poseLandmarks)

    // Analyze exercise
    analyzeExercise(results.poseLandmarks)
  }
}

// Draw pose landmarks on canvas
function drawPose(landmarks) {
  // Draw connections
  const connections = [
    [11, 12],
    [11, 13],
    [13, 15],
    [12, 14],
    [14, 16], // arms
    [11, 23],
    [12, 24],
    [23, 24], // torso
    [23, 25],
    [25, 27],
    [24, 26],
    [26, 28], // legs
  ]

  canvasCtx.strokeStyle = "#00FF00"
  canvasCtx.lineWidth = 2

  connections.forEach(([start, end]) => {
    const startPoint = landmarks[start]
    const endPoint = landmarks[end]

    if (startPoint && endPoint) {
      canvasCtx.beginPath()
      canvasCtx.moveTo(startPoint.x * canvasElement.width, startPoint.y * canvasElement.height)
      canvasCtx.lineTo(endPoint.x * canvasElement.width, endPoint.y * canvasElement.height)
      canvasCtx.stroke()
    }
  })

  
  canvasCtx.fillStyle = "#FF0000"
  landmarks.forEach((landmark, index) => {
    if (landmark && (landmark.visibility || 1) > 0.5) {
      canvasCtx.beginPath()
      canvasCtx.arc(landmark.x * canvasElement.width, landmark.y * canvasElement.height, 3, 0, 2 * Math.PI)
      canvasCtx.fill()
    }
  })
}

// Analyze exercise based on pose landmarks
function analyzeExercise(landmarks) {
  if (!currentExercise || !EXERCISE_CONFIG[currentExercise]) return

  const config = EXERCISE_CONFIG[currentExercise]
  const angles = calculateAngles(landmarks, config.anglePoints)

  if (Object.keys(angles).length === 0) {
    document.getElementById("feedbackText").textContent = "Position yourself better in the camera view"
    return
  }

  const avgAngle = Object.values(angles).reduce((sum, angle) => sum + angle, 0) / Object.values(angles).length

  // Determine current state
  let newState = "middle"
  if (avgAngle > config.thresholds.up) {
    newState = "up"
  } else if (avgAngle < config.thresholds.down) {
    newState = "down"
  }

  // Check for rep completion
  if (checkRepCompletion(newState)) {
    const accuracy = calculateAccuracy(angles, config)
    recordRep(accuracy, angles)
  }

  currentState = newState
  updateUI()

  // Update feedback
  updateFeedback(avgAngle, config)
}

// Calculate angles between three points
function calculateAngles(landmarks, anglePoints) {
  const angles = {}

  for (const [angleName, points] of Object.entries(anglePoints)) {
    const [p1Index, p2Index, p3Index] = points
    const p1 = landmarks[p1Index]
    const p2 = landmarks[p2Index]
    const p3 = landmarks[p3Index]

    if (p1 && p2 && p3 && (p1.visibility || 1) > 0.5 && (p2.visibility || 1) > 0.5 && (p3.visibility || 1) > 0.5) {
      angles[angleName] = calculateAngle(p1, p2, p3)
    }
  }

  return angles
}


function calculateAngle(a, b, c) {
  const radians = Math.atan2(c.y - b.y, c.x - b.x) - Math.atan2(a.y - b.y, a.x - b.x)
  let angle = Math.abs((radians * 180.0) / Math.PI)

  if (angle > 180.0) {
    angle = 360.0 - angle
  }

  return angle
}

// Check if a rep is completed
function checkRepCompletion(newState) {
  const now = Date.now()

  // Prevent rapid state changes
  if (now - stateTransitionTime < 800) {
    return false
  }

  // Check for down -> up transition (rep completion)
  if (lastState === "down" && newState === "up") {
    lastState = newState
    stateTransitionTime = now
    return true
  }

  if (newState !== currentState) {
    lastState = currentState
    stateTransitionTime = now
  }

  return false
}

// Calculate form accuracy
function calculateAccuracy(angles, config) {
  let accuracy = 100

  // Check angle consistency
  const angleValues = Object.values(angles)
  if (angleValues.length > 1) {
    const avgAngle = angleValues.reduce((sum, angle) => sum + angle, 0) / angleValues.length
    const variance = angleValues.reduce((sum, angle) => sum + Math.pow(angle - avgAngle, 2), 0) / angleValues.length

    // Penalize for asymmetry
    if (variance > 100) {
      accuracy -= 20
    } else if (variance > 50) {
      accuracy -= 10
    }
  }

  // Exercise-specific accuracy checks
  if (currentExercise === "pushup") {
    accuracy = calculatePushupAccuracy(angles, accuracy)
  } else if (currentExercise === "squat") {
    accuracy = calculateSquatAccuracy(angles, accuracy)
  } else if (currentExercise === "pullup") {
    accuracy = calculatePullupAccuracy(angles, accuracy)
  }

  return Math.max(0, Math.min(100, accuracy))
}

// Calculate pushup-specific accuracy
function calculatePushupAccuracy(angles, baseAccuracy) {
  let accuracy = baseAccuracy

  // Check elbow angles
  if (angles.leftElbow && angles.rightElbow) {
    const elbowDiff = Math.abs(angles.leftElbow - angles.rightElbow)
    if (elbowDiff > 20) {
      accuracy -= 15 // Penalize for uneven arm movement
    }
  }

  return accuracy
}

// Calculate squat-specific accuracy
function calculateSquatAccuracy(angles, baseAccuracy) {
  let accuracy = baseAccuracy

  // Check knee angles
  if (angles.leftKnee && angles.rightKnee) {
    const kneeDiff = Math.abs(angles.leftKnee - angles.rightKnee)
    if (kneeDiff > 15) {
      accuracy -= 15 // Penalize for uneven leg movement
    }
  }

  return accuracy
}

// Calculate pullup-specific accuracy
function calculatePullupAccuracy(angles, baseAccuracy) {
  let accuracy = baseAccuracy

  // Check elbow angles (similar to pushup)
  if (angles.leftElbow && angles.rightElbow) {
    const elbowDiff = Math.abs(angles.leftElbow - angles.rightElbow)
    if (elbowDiff > 25) {
      accuracy -= 20 // Penalize for uneven pull
    }
  }

  return accuracy
}

// Record a completed rep
function recordRep(accuracy, angles) {
  repCount++
  accuracyScores.push(accuracy)

  repDetails.push({
    repNumber: repCount,
    accuracy: accuracy,
    angles: angles,
    timestamp: new Date(),
  })

  // Update UI
  document.getElementById("repCount").textContent = repCount
  const avgAccuracy = accuracyScores.reduce((sum, acc) => sum + acc, 0) / accuracyScores.length
  document.getElementById("accuracyScore").textContent = `${Math.round(avgAccuracy)}%`

  console.log(`Rep ${repCount} completed with ${Math.round(accuracy)}% accuracy`)

  // Visual feedback
  document.getElementById("feedbackText").textContent = `Great! Rep ${repCount} completed!`
  document.getElementById("feedbackText").style.color = "#00FF00"

  setTimeout(() => {
    updateFeedback(null, EXERCISE_CONFIG[currentExercise])
  }, 1000)
}

// Update feedback text
function updateFeedback(avgAngle, config) {
  const feedbackElement = document.getElementById("feedbackText")

  if (currentState === "up") {
    feedbackElement.textContent = "Good position! Now go down"
    feedbackElement.style.color = "#00FF00"
  } else if (currentState === "down") {
    feedbackElement.textContent = "Perfect! Now push/pull up"
    feedbackElement.style.color = "#00FF00"
  } else {
    feedbackElement.textContent = "Keep going..."
    feedbackElement.style.color = "#FFFF00"
  }
}

// Update UI elements
function updateUI() {
  document.getElementById("currentState").textContent = currentState.toUpperCase()

  if (workoutStartTime) {
    const elapsed = Math.floor((Date.now() - workoutStartTime) / 1000)
    const minutes = Math.floor(elapsed / 60)
    const seconds = elapsed % 60
    document.getElementById("workoutTime").textContent =
      `${minutes.toString().padStart(2, "0")}:${seconds.toString().padStart(2, "0")}`
  }
}

// Exercise selection
function selectExercise(exercise) {
  currentExercise = exercise

  document.getElementById("exerciseSelection").style.display = "none"
  document.getElementById("workoutInterface").style.display = "block"

  // Update instructions
  const config = EXERCISE_CONFIG[exercise]
  document.getElementById("instructionText").textContent = config.instructions

  // Reset workout state
  resetWorkoutState()

  console.log(`Selected exercise: ${exercise}`)
}

// Start workout
function startWorkout() {
  if (!currentExercise) {
    showError("Please select an exercise first")
    return
  }

  if (!detector) {
    showError("Pose detection not initialized. Please refresh the page.")
    return
  }

  isWorkoutActive = true
  workoutStartTime = Date.now()

  // Update UI
  document.getElementById("startBtn").style.display = "none"
  document.getElementById("pauseBtn").style.display = "inline-block"
  document.getElementById("stopBtn").style.display = "inline-block"

  // Start timer
  workoutTimer = setInterval(updateUI, 1000)

  console.log(`Started ${currentExercise} workout`)
  document.getElementById("feedbackText").textContent = "Workout started! Begin your exercise."
}

// Pause workout
function pauseWorkout() {
  isWorkoutActive = false

  // Update UI
  document.getElementById("startBtn").style.display = "inline-block"
  document.getElementById("startBtn").textContent = "Resume"
  document.getElementById("pauseBtn").style.display = "none"

  clearInterval(workoutTimer)

  console.log("Workout paused")
  document.getElementById("feedbackText").textContent = "Workout paused. Click Resume to continue."
}

// Stop workout and save
async function stopWorkout() {
  if (repCount === 0) {
    showError("No reps recorded. Complete at least one rep before stopping.")
    return
  }

  isWorkoutActive = false
  clearInterval(workoutTimer)

  const duration = Math.floor((Date.now() - workoutStartTime) / 1000)
  const avgAccuracy = accuracyScores.reduce((sum, acc) => sum + acc, 0) / accuracyScores.length

  // Prepare workout data
  const workoutData = {
    userId: currentUserId,
    exerciseType: currentExercise,
    repCount: repCount,
    accuracyScore: Math.round(avgAccuracy * 100) / 100,
    duration: duration,
    repDetails: repDetails,
    sessionMetadata: {
      deviceInfo: {
        userAgent: navigator.userAgent,
        screenResolution: `${screen.width}x${screen.height}`,
      },
      cameraResolution: {
        width: videoElement.videoWidth,
        height: videoElement.videoHeight,
      },
      averageConfidence: 0.8, // Placeholder
    },
  }

  try {
    showLoading(true)
    const response = await saveWorkout(workoutData)
    showLoading(false)

    if (response.success) {
      showResults(workoutData, response.data)
    } else {
      showError("Failed to save workout: " + response.message)
    }
  } catch (error) {
    showLoading(false)
    console.error("Error saving workout:", error)
    showError("Failed to save workout. Please check if the backend server is running.")
  }
}

// Save workout to backend
async function saveWorkout(workoutData) {
  const response = await fetch(`${API_BASE_URL}/workout`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(workoutData),
  })

  if (!response.ok) {
    throw new Error(`HTTP error! status: ${response.status}`)
  }

  return await response.json()
}

// Show workout results
function showResults(workoutData, savedData) {
  document.getElementById("resultExercise").textContent = EXERCISE_CONFIG[workoutData.exerciseType].name
  document.getElementById("resultReps").textContent = workoutData.repCount
  document.getElementById("resultAccuracy").textContent = `${workoutData.accuracyScore}%`

  const minutes = Math.floor(workoutData.duration / 60)
  const seconds = workoutData.duration % 60
  document.getElementById("resultDuration").textContent = `${minutes}:${seconds.toString().padStart(2, "0")}`

  document.getElementById("resultCalories").textContent = `${savedData.caloriesBurned} cal`

  document.getElementById("resultsModal").style.display = "flex"
}

// Close results modal
function closeResults() {
  document.getElementById("resultsModal").style.display = "none"
  backToSelection()
}

// View user statistics
async function viewStats() {
  try {
    showLoading(true)
    const response = await fetch(`${API_BASE_URL}/workout/stats/${currentUserId}`)

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`)
    }

    const data = await response.json()
    showLoading(false)

    if (data.success) {
      displayStats(data.data)
    } else {
      showError("Failed to load statistics: " + data.message)
    }
  } catch (error) {
    showLoading(false)
    console.error("Error loading stats:", error)
    showError("Failed to load statistics. Please check if the backend server is running.")
  }
}

// Display statistics
function displayStats(statsData) {
  document.getElementById("resultsModal").style.display = "none"
  document.getElementById("workoutInterface").style.display = "none"
  document.getElementById("exerciseSelection").style.display = "none"
  document.getElementById("statsView").style.display = "block"

  const statsGrid = document.getElementById("statsGrid")
  statsGrid.innerHTML = ""

  // Overall stats
  const overallCard = createStatsCard("Overall Stats", [
    { label: "Total Workouts", value: statsData.overview.totalWorkouts },
    { label: "Total Reps", value: statsData.overview.totalReps },
    { label: "Avg Accuracy", value: `${statsData.overview.averageAccuracy}%` },
    { label: "Total Time", value: `${Math.floor(statsData.overview.totalDuration / 60)} min` },
  ])
  statsGrid.appendChild(overallCard)

  // Exercise breakdown
  statsData.exerciseBreakdown.forEach((exercise) => {
    const card = createStatsCard(EXERCISE_CONFIG[exercise.exerciseType].name, [
      { label: "Workouts", value: exercise.totalWorkouts },
      { label: "Total Reps", value: exercise.totalReps },
      { label: "Avg Accuracy", value: `${exercise.averageAccuracy}%` },
      { label: "Best Accuracy", value: `${exercise.bestAccuracy}%` },
    ])
    statsGrid.appendChild(card)
  })
}


function createStatsCard(title, stats) {
  const card = document.createElement("div")
  card.className = "stats-card"

  let html = `<h3>${title}</h3>`
  stats.forEach((stat) => {
    html += `
            <div class="stats-value">${stat.value}</div>
            <div class="stats-label">${stat.label}</div>
        `
  })

  card.innerHTML = html
  return card
}


function backToSelection() {
  
  document.getElementById("workoutInterface").style.display = "none"
  document.getElementById("statsView").style.display = "none"
  document.getElementById("resultsModal").style.display = "none"

  
  document.getElementById("exerciseSelection").style.display = "block"

  
  resetWorkoutState()
}


function resetWorkoutState() {
  isWorkoutActive = false
  workoutStartTime = null
  repCount = 0
  accuracyScores = []
  repDetails = []
  currentState = "ready"
  lastState = "ready"

  clearInterval(workoutTimer)

  
  document.getElementById("repCount").textContent = "0"
  document.getElementById("accuracyScore").textContent = "0%"
  document.getElementById("currentState").textContent = "Ready"
  document.getElementById("workoutTime").textContent = "00:00"
  document.getElementById("feedbackText").textContent = "Ready to start your workout!"

  document.getElementById("startBtn").style.display = "inline-block"
  document.getElementById("startBtn").textContent = "Start Workout"
  document.getElementById("pauseBtn").style.display = "none"
  document.getElementById("stopBtn").style.display = "none"
}


function showLoading(show) {
  document.getElementById("loading").style.display = show ? "flex" : "none"
}

function showError(message) {
  document.getElementById("errorText").textContent = message
  document.getElementById("errorMessage").style.display = "block"

  
  setTimeout(() => {
    hideError()
  }, 8000)
}

function hideError() {
  document.getElementById("errorMessage").style.display = "none"
}


document.addEventListener("DOMContentLoaded", () => {
  console.log("Fitness Tracker initialized")

  
  if (!navigator.mediaDevices) {
    showError("This browser doesn't support camera access. Please use Chrome, Firefox, or Safari.")
  }
})
