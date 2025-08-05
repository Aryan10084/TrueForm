const mongoose = require('mongoose');

const exerciseSchema = new mongoose.Schema({
  name: { type: String, required: true },
  type: { type: String, required: true }, // 'Pullups', 'Pushups', 'Squats', 'Others'
  icon: { type: String, required: true },
  description: { type: String },
  instructions: [{ type: String }],
  difficulty: { type: String, enum: ['Beginner', 'Intermediate', 'Expert'], required: true },
  targetMuscles: [{ type: String }],
  equipment: [{ type: String }]
});

const workoutPlanSchema = new mongoose.Schema({
  name: { type: String, required: true },
  difficulty: { type: String, enum: ['Beginner', 'Intermediate', 'Expert'], required: true },
  sets: { type: Number, required: true },
  reps: { type: Number, required: true },
  duration: { type: Number }, // in minutes
  calories: { type: Number }, // estimated calories burned
  exercises: [exerciseSchema],
  isCustom: { type: Boolean, default: false },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('WorkoutPlan', workoutPlanSchema);