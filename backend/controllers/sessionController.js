const Session = require('../models/Session');
const WorkoutPlan = require('../models/Workout');
const User = require('../models/User');

const sessionController = {
  // Start workout session
  startSession: async (req, res) => {
    try {
      const { workoutPlanId } = req.body;

      // Verify workout plan exists
      const workoutPlan = await WorkoutPlan.findById(workoutPlanId);
      if (!workoutPlan) {
        return res.status(404).json({ message: 'Workout plan not found' });
      }

      // Check for active session
      const activeSession = await Session.findOne({
        userId: req.userId,
        status: 'in-progress'
      });

      if (activeSession) {
        return res.status(400).json({ message: 'Active session already exists' });
      }

      // Create session
      const session = new Session({
        userId: req.userId,
        workoutPlan: workoutPlanId,
        startTime: new Date(),
        exercises: workoutPlan.exercises.map(exercise => ({
          exerciseId: exercise._id,
          name: exercise.name,
          setsCompleted: 0,
          repsCompleted: 0
        }))
      });

      await session.save();
      await session.populate('workoutPlan');

      res.status(201).json({
        message: 'Session started successfully',
        session
      });
    } catch (error) {
      res.status(500).json({ message: 'Server error', error: error.message });
    }
  },

  // Get active session
  getActiveSession: async (req, res) => {
    try {
      const session = await Session.findOne({
        userId: req.userId,
        status: 'in-progress'
      }).populate('workoutPlan');

      if (!session) {
        return res.status(404).json({ message: 'No active session found' });
      }

      res.json(session);
    } catch (error) {
      res.status(500).json({ message: 'Server error', error: error.message });
    }
  },

  // Complete session
  completeSession: async (req, res) => {
    try {
      const { sessionId } = req.params;
      const { caloriesBurned, rating, notes } = req.body;

      const session = await Session.findOne({
        _id: sessionId,
        userId: req.userId,
        status: 'in-progress'
      });

      if (!session) {
        return res.status(404).json({ message: 'Active session not found' });
      }

      // Complete session
      session.endTime = new Date();
      session.duration = Math.round((session.endTime - session.startTime) / (1000 * 60));
      session.status = 'completed';
      session.caloriesBurned = caloriesBurned || 0;
      session.rating = rating;
      session.notes = notes;

      await session.save();

      // Update user stats
      const user = await User.findById(req.userId);
      user.stats.totalWorkouts += 1;
      user.stats.totalCalories += session.caloriesBurned;
      user.stats.lastWorkoutDate = new Date();
      await user.save();

      res.json({
        message: 'Session completed successfully',
        session,
        summary: {
          duration: session.duration,
          caloriesBurned: session.caloriesBurned,
          exercisesCompleted: session.exercises.length
        }
      });
    } catch (error) {
      res.status(500).json({ message: 'Server error', error: error.message });
    }
  },

  // Get session history
  getSessionHistory: async (req, res) => {
    try {
      const { page = 1, limit = 10 } = req.query;

      const sessions = await Session.find({ userId: req.userId })
        .populate('workoutPlan', 'name difficulty')
        .sort({ createdAt: -1 })
        .limit(limit * 1)
        .skip((page - 1) * limit);

      const total = await Session.countDocuments({ userId: req.userId });

      res.json({
        sessions,
        totalPages: Math.ceil(total / limit),
        currentPage: parseInt(page),
        total
      });
    } catch (error) {
      res.status(500).json({ message: 'Server error', error: error.message });
    }
  }
};

module.exports = sessionController;