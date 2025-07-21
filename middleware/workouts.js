const express = require('express');
const WorkoutPlan = require('../models/WorkoutPlan');
const auth = require('../middleware/auth');

const router = express.Router();

// Get all workout plans
router.get('/', auth, async (req, res) => {
  try {
    const workouts = await WorkoutPlan.find();
    res.json(workouts);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Get workout plans by difficulty
router.get('/difficulty/:level', auth, async (req, res) => {
  try {
    const { level } = req.params;
    const workouts = await WorkoutPlan.find({ difficulty: level });
    res.json(workouts);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Create custom workout
router.post('/custom', auth, async (req, res) => {
  try {
    const workout = new WorkoutPlan({
      ...req.body,
      isCustom: true,
      createdBy: req.userId
    });
    await workout.save();
    res.status(201).json(workout);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

module.exports = router;