const mongoose = require('mongoose');

const sessionSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  workoutPlan: { type: mongoose.Schema.Types.ObjectId, ref: 'WorkoutPlan', required: true },
  startTime: { type: Date, required: true },
  endTime: { type: Date },
  duration: { type: Number }, // in minutes
  caloriesBurned: { type: Number, default: 0 },
  exercises: [{
    exerciseId: { type: mongoose.Schema.Types.ObjectId },
    name: { type: String, required: true },
    setsCompleted: { type: Number, default: 0 },
    repsCompleted: { type: Number, default: 0 },
    weight: { type: Number, default: 0 }, // if applicable
    notes: { type: String }
  }],
  status: { type: String, enum: ['in-progress', 'completed', 'cancelled'], default: 'in-progress' },
  rating: { type: Number, min: 1, max: 5 },
  notes: { type: String },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Session', sessionSchema);