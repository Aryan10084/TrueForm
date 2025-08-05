const { validationResult } = require("express-validator")
const Workout = require("../models/Workout")

const workoutController = {
  // Save workout session
  async saveWorkout(req, res) {
    try {
      // Check validation errors
      const errors = validationResult(req)
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          message: "Validation failed",
          errors: errors.array(),
        })
      }

      const { userId, exerciseType, repCount, accuracyScore, duration, repDetails, sessionMetadata } = req.body

      // Create new workout
      const workout = new Workout({
        userId,
        exerciseType: exerciseType.toLowerCase(),
        repCount,
        accuracyScore,
        duration,
        repDetails: repDetails || [],
        sessionMetadata: sessionMetadata || {},
      })

      await workout.save()

      res.status(201).json({
        success: true,
        message: "Workout saved successfully",
        data: {
          workoutId: workout._id,
          exerciseType: workout.exerciseType,
          repCount: workout.repCount,
          accuracyScore: workout.accuracyScore,
          duration: workout.duration,
          caloriesBurned: workout.caloriesBurned,
          intensity: workout.intensity,
          createdAt: workout.createdAt,
        },
      })
    } catch (error) {
      console.error("Save workout error:", error)
      res.status(500).json({
        success: false,
        message: "Internal server error while saving workout",
        error: process.env.NODE_ENV === "development" ? error.message : undefined,
      })
    }
  },

  // Get workout statistics
  async getWorkoutStats(req, res) {
    try {
      const { userId } = req.params
      const { timeframe = "all" } = req.query

      if (!userId) {
        return res.status(400).json({
          success: false,
          message: "User ID is required",
        })
      }

      const stats = await Workout.getUserStats(userId, timeframe)

      // Get exercise breakdown
      const exerciseStats = await Workout.aggregate([
        { $match: { userId: userId } },
        {
          $group: {
            _id: "$exerciseType",
            totalReps: { $sum: "$repCount" },
            totalWorkouts: { $sum: 1 },
            averageAccuracy: { $avg: "$accuracyScore" },
            bestAccuracy: { $max: "$accuracyScore" },
            totalDuration: { $sum: "$duration" },
          },
        },
        {
          $project: {
            exerciseType: "$_id",
            totalReps: 1,
            totalWorkouts: 1,
            averageAccuracy: { $round: ["$averageAccuracy", 2] },
            bestAccuracy: { $round: ["$bestAccuracy", 2] },
            totalDuration: 1,
            _id: 0,
          },
        },
      ])

      res.json({
        success: true,
        data: {
          overview: stats,
          exerciseBreakdown: exerciseStats,
          timeframe,
        },
      })
    } catch (error) {
      console.error("Get workout stats error:", error)
      res.status(500).json({
        success: false,
        message: "Internal server error while fetching workout statistics",
        error: process.env.NODE_ENV === "development" ? error.message : undefined,
      })
    }
  },

  // Get workout history
  async getWorkoutHistory(req, res) {
    try {
      const { userId } = req.params
      const page = Number.parseInt(req.query.page) || 1
      const limit = Number.parseInt(req.query.limit) || 20
      const exerciseType = req.query.exerciseType
      const sortBy = req.query.sortBy || "createdAt"
      const sortOrder = req.query.sortOrder === "asc" ? 1 : -1

      if (!userId) {
        return res.status(400).json({
          success: false,
          message: "User ID is required",
        })
      }

      // Build query
      const query = { userId: userId }
      if (exerciseType && exerciseType !== "all") {
        query.exerciseType = exerciseType.toLowerCase()
      }

      // Build sort object
      const sort = {}
      sort[sortBy] = sortOrder

      const skip = (page - 1) * limit

      const [workouts, totalCount] = await Promise.all([
        Workout.find(query).sort(sort).skip(skip).limit(limit).lean(),
        Workout.countDocuments(query),
      ])

      // Add virtual fields manually since we're using lean()
      const workoutsWithVirtuals = workouts.map((workout) => ({
        ...workout,
        caloriesBurned: Math.round(
          workout.repCount * (workout.exerciseType === "pushup" ? 0.5 : workout.exerciseType === "pullup" ? 1.0 : 0.4),
        ),
        intensity: (() => {
          const repsPerMinute = workout.repCount / (workout.duration / 60)
          if (repsPerMinute < 10) return "low"
          if (repsPerMinute < 20) return "moderate"
          if (repsPerMinute < 30) return "high"
          return "very_high"
        })(),
      }))

      const totalPages = Math.ceil(totalCount / limit)

      res.json({
        success: true,
        data: {
          workouts: workoutsWithVirtuals,
          pagination: {
            currentPage: page,
            totalPages,
            totalCount,
            hasNextPage: page < totalPages,
            hasPrevPage: page > 1,
          },
        },
      })
    } catch (error) {
      console.error("Get workout history error:", error)
      res.status(500).json({
        success: false,
        message: "Internal server error while fetching workout history",
        error: process.env.NODE_ENV === "development" ? error.message : undefined,
      })
    }
  },

  // Delete workout
  async deleteWorkout(req, res) {
    try {
      const { workoutId } = req.params

      if (!workoutId) {
        return res.status(400).json({
          success: false,
          message: "Workout ID is required",
        })
      }

      const workout = await Workout.findByIdAndDelete(workoutId)

      if (!workout) {
        return res.status(404).json({
          success: false,
          message: "Workout not found",
        })
      }

      res.json({
        success: true,
        message: "Workout deleted successfully",
        data: {
          deletedWorkout: {
            id: workout._id,
            exerciseType: workout.exerciseType,
            repCount: workout.repCount,
            createdAt: workout.createdAt,
          },
        },
      })
    } catch (error) {
      console.error("Delete workout error:", error)
      res.status(500).json({
        success: false,
        message: "Internal server error while deleting workout",
        error: process.env.NODE_ENV === "development" ? error.message : undefined,
      })
    }
  },
}

module.exports = workoutController
