const WorkoutPlan = require('../models/Workout');

const workoutController = {
  // Get all workout plans
  getAllWorkouts: async (req, res) => {
    try {
      const { difficulty, type } = req.query;
      let query = {};
      
      if (difficulty) query.difficulty = difficulty;
      if (type) query['exercises.type'] = type;

      const workouts = await WorkoutPlan.find(query);
      res.json(workouts);
    } catch (error) {
      res.status(500).json({ message: 'Server error', error: error.message });
    }
  },

  // Get workout by ID
  getWorkoutById: async (req, res) => {
    try {
      const workout = await WorkoutPlan.findById(req.params.id);
      if (!workout) {
        return res.status(404).json({ message: 'Workout not found' });
      }
      res.json(workout);
    } catch (error) {
      res.status(500).json({ message: 'Server error', error: error.message });
    }
  },

  // Get workouts by difficulty
  getWorkoutsByDifficulty: async (req, res) => {
    try {
      const { difficulty } = req.params;
      const workouts = await WorkoutPlan.find({ difficulty });
      res.json(workouts);
    } catch (error) {
      res.status(500).json({ message: 'Server error', error: error.message });
    }
  },

  // Create custom workout
  createCustomWorkout: async (req, res) => {
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
  },

  // Get user's custom workouts
  getUserCustomWorkouts: async (req, res) => {
    try {
      const workouts = await WorkoutPlan.find({ 
        createdBy: req.userId,
        isCustom: true 
      });
      res.json(workouts);
    } catch (error) {
      res.status(500).json({ message: 'Server error', error: error.message });
    }
  },

  // Update custom workout
  updateCustomWorkout: async (req, res) => {
    try {
      const workout = await WorkoutPlan.findOne({
        _id: req.params.id,
        createdBy: req.userId,
        isCustom: true
      });

      if (!workout) {
        return res.status(404).json({ message: 'Custom workout not found' });
      }

      Object.keys(req.body).forEach(key => {
        workout[key] = req.body[key];
      });

      await workout.save();
      res.json(workout);
    } catch (error) {
      res.status(500).json({ message: 'Server error', error: error.message });
    }
  },

  // Delete custom workout
  deleteCustomWorkout: async (req, res) => {
    try {
      const workout = await WorkoutPlan.findOneAndDelete({
        _id: req.params.id,
        createdBy: req.userId,
        isCustom: true
      });

      if (!workout) {
        return res.status(404).json({ message: 'Custom workout not found' });
      }

      res.json({ message: 'Workout deleted successfully' });
    } catch (error) {
      res.status(500).json({ message: 'Server error', error: error.message });
    }
  }
};

module.exports = workoutController;