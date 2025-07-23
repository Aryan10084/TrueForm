const mongoose = require("mongoose")

const workoutSchema = new mongoose.Schema(
  {
    userId: {
      type: String,
      required: [true, "User ID is required"],
      trim: true,
    },
    exerciseType: {
      type: String,
      required: [true, "Exercise type is required"],
      enum: ["pushup", "pullup", "squat"],
      lowercase: true,
    },
    repCount: {
      type: Number,
      required: [true, "Rep count is required"],
      min: [0, "Rep count cannot be negative"],
    },
    accuracyScore: {
      type: Number,
      required: [true, "Accuracy score is required"],
      min: [0, "Accuracy cannot be negative"],
      max: [100, "Accuracy cannot exceed 100%"],
    },
    duration: {
      type: Number, // in seconds
      required: [true, "Duration is required"],
      min: [1, "Duration must be at least 1 second"],
    },
    repDetails: [
      {
        repNumber: {
          type: Number,
          required: true,
        },
        accuracy: {
          type: Number,
          required: true,
          min: 0,
          max: 100,
        },
        angles: {
          leftElbow: Number,
          rightElbow: Number,
          leftKnee: Number,
          rightKnee: Number,
          leftHip: Number,
          rightHip: Number,
        },
        timestamp: {
          type: Date,
          default: Date.now,
        },
      },
    ],
    sessionMetadata: {
      deviceInfo: {
        userAgent: String,
        screenResolution: String,
      },
      cameraResolution: {
        width: Number,
        height: Number,
      },
      averageConfidence: {
        type: Number,
        min: 0,
        max: 1,
      },
    },
  },
  {
    timestamps: true,
  },
)

// Indexes for better query performance
workoutSchema.index({ userId: 1, createdAt: -1 })
workoutSchema.index({ exerciseType: 1, createdAt: -1 })
workoutSchema.index({ userId: 1, exerciseType: 1, createdAt: -1 })

// Virtual for calories burned (rough estimate)
workoutSchema.virtual("caloriesBurned").get(function () {
  const caloriesPerRep = {
    pushup: 0.5,
    pullup: 1.0,
    squat: 0.4,
  }

  return Math.round(this.repCount * (caloriesPerRep[this.exerciseType] || 0.5))
})

// Virtual for workout intensity
workoutSchema.virtual("intensity").get(function () {
  const repsPerMinute = this.repCount / (this.duration / 60)

  if (repsPerMinute < 10) return "low"
  if (repsPerMinute < 20) return "moderate"
  if (repsPerMinute < 30) return "high"
  return "very_high"
})

// Static method to get user workout stats
workoutSchema.statics.getUserStats = async function (userId, timeframe = "all") {
  const matchStage = { userId: userId }

  // Add time filter if specified
  if (timeframe !== "all") {
    const now = new Date()
    let startDate

    switch (timeframe) {
      case "week":
        startDate = new Date(now.setDate(now.getDate() - 7))
        break
      case "month":
        startDate = new Date(now.setMonth(now.getMonth() - 1))
        break
      case "year":
        startDate = new Date(now.setFullYear(now.getFullYear() - 1))
        break
    }

    if (startDate) {
      matchStage.createdAt = { $gte: startDate }
    }
  }

  const stats = await this.aggregate([
    { $match: matchStage },
    {
      $group: {
        _id: null,
        totalWorkouts: { $sum: 1 },
        totalReps: { $sum: "$repCount" },
        totalDuration: { $sum: "$duration" },
        averageAccuracy: { $avg: "$accuracyScore" },
        exerciseBreakdown: {
          $push: {
            exerciseType: "$exerciseType",
            reps: "$repCount",
            accuracy: "$accuracyScore",
          },
        },
      },
    },
    {
      $project: {
        _id: 0,
        totalWorkouts: 1,
        totalReps: 1,
        totalDuration: 1,
        averageAccuracy: { $round: ["$averageAccuracy", 2] },
        exerciseBreakdown: 1,
      },
    },
  ])

  return (
    stats[0] || {
      totalWorkouts: 0,
      totalReps: 0,
      totalDuration: 0,
      averageAccuracy: 0,
      exerciseBreakdown: [],
    }
  )
}

module.exports = mongoose.model("Workout", workoutSchema)
