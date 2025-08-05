const express = require('express');
const { body, validationResult } = require('express-validator');
const Session = require('../models/Session');
const User = require('../models/User');
const WorkoutPlan = require('../models/Workout');
const auth = require('../middleware/auth');

const router = express.Router();

// Start a new workout session
router.post('/start', auth, [
  body('workoutPlanId').isMongoId(),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { workoutPlanId } = req.body;

    // Verify workout plan exists
    const workoutPlan = await WorkoutPlan.findById(workoutPlanId);
    if (!workoutPlan) {
      return res.status(404).json({ message: 'Workout plan not found' });
    }

    // Check if user has an active session
    const activeSession = await Session.findOne({
      userId: req.userId,
      status: 'in-progress'
    });

    if (activeSession) {
      return res.status(400).json({ message: 'You already have an active workout session' });
    }

    // Create new session
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
      message: 'Workout session started',
      session
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Get active session
router.get('/active', auth, async (req, res) => {
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
});

// Update session progress
router.put('/:sessionId/progress', auth, [
  body('exerciseId').isMongoId(),
  body('setsCompleted').isNumeric(),
  body('repsCompleted').isNumeric()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { sessionId } = req.params;
    const { exerciseId, setsCompleted, repsCompleted, weight, notes } = req.body;

    const session = await Session.findOne({
      _id: sessionId,
      userId: req.userId,
      status: 'in-progress'
    });

    if (!session) {
      return res.status(404).json({ message: 'Active session not found' });
    }

    // Update exercise progress
    const exerciseIndex = session.exercises.findIndex(
      ex => ex.exerciseId.toString() === exerciseId
    );

    if (exerciseIndex === -1) {
      return res.status(404).json({ message: 'Exercise not found in session' });
    }

    session.exercises[exerciseIndex].setsCompleted = setsCompleted;
    session.exercises[exerciseIndex].repsCompleted = repsCompleted;
    if (weight) session.exercises[exerciseIndex].weight = weight;
    if (notes) session.exercises[exerciseIndex].notes = notes;

    await session.save();

    res.json({
      message: 'Progress updated',
      session
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Complete workout session
router.put('/:sessionId/complete', auth, [
  body('caloriesBurned').optional().isNumeric(),
  body('rating').optional().isInt({ min: 1, max: 5 }),
  body('notes').optional().isString()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

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

    // Complete the session
    session.endTime = new Date();
    session.duration = Math.round((session.endTime - session.startTime) / (1000 * 60)); // minutes
    session.status = 'completed';
    
    if (caloriesBurned) session.caloriesBurned = caloriesBurned;
    if (rating) session.rating = rating;
    if (notes) session.notes = notes;

    await session.save();

    // Update user stats
    const user = await User.findById(req.userId);
    user.stats.totalWorkouts += 1;
    user.stats.totalCalories += session.caloriesBurned || 0;
    user.stats.lastWorkoutDate = new Date();
    await user.save();

    res.json({
      message: 'Workout completed successfully',
      session,
      summary: {
        duration: session.duration,
        caloriesBurned: session.caloriesBurned,
        exercisesCompleted: session.exercises.length,
        totalSets: session.exercises.reduce((total, ex) => total + ex.setsCompleted, 0),
        totalReps: session.exercises.reduce((total, ex) => total + ex.repsCompleted, 0)
      }
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Cancel workout session
router.put('/:sessionId/cancel', auth, async (req, res) => {
  try {
    const { sessionId } = req.params;

    const session = await Session.findOne({
      _id: sessionId,
      userId: req.userId,
      status: 'in-progress'
    });

    if (!session) {
      return res.status(404).json({ message: 'Active session not found' });
    }

    session.status = 'cancelled';
    session.endTime = new Date();
    await session.save();

    res.json({ message: 'Workout session cancelled' });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Get session history
router.get('/history', auth, async (req, res) => {
  try {
    const { page = 1, limit = 10, status } = req.query;
    
    const query = { userId: req.userId };
    if (status) query.status = status;

    const sessions = await Session.find(query)
      .populate('workoutPlan', 'name difficulty')
      .sort({ createdAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);

    const total = await Session.countDocuments(query);

    res.json({
      sessions,
      totalPages: Math.ceil(total / limit),
      currentPage: page,
      total
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Get session by ID
router.get('/:sessionId', auth, async (req, res) => {
  try {
    const session = await Session.findOne({
      _id: req.params.sessionId,
      userId: req.userId
    }).populate('workoutPlan');

    if (!session) {
      return res.status(404).json({ message: 'Session not found' });
    }

    res.json(session);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

module.exports = router;