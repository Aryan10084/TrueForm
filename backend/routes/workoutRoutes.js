const express = require("express")
const { body } = require("express-validator")
const workoutController = require("../controllers/workoutController")

const router = express.Router()

// Validation rules
const workoutValidation = [
  body("userId").notEmpty().withMessage("User ID is required").trim(),
  body("exerciseType").isIn(["pushup", "pullup", "squat"]).withMessage("Invalid exercise type"),
  body("repCount").isInt({ min: 0 }).withMessage("Rep count must be a non-negative integer"),
  body("accuracyScore").isFloat({ min: 0, max: 100 }).withMessage("Accuracy score must be between 0 and 100"),
  body("duration").isInt({ min: 1 }).withMessage("Duration must be at least 1 second"),
]

const statsValidation = [body("userId").notEmpty().withMessage("User ID is required").trim()]

// Routes
router.post("/", workoutValidation, workoutController.saveWorkout)
router.get("/stats/:userId", workoutController.getWorkoutStats)
router.get("/history/:userId", workoutController.getWorkoutHistory)
router.delete("/:workoutId", workoutController.deleteWorkout)

module.exports = router
