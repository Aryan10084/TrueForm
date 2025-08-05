const express = require('express');
const { body, validationResult } = require('express-validator');
const WorkoutPlan = require('../models/Workout');
const auth = require('../middleware/auth');

const router = express.Router();

// Get all workout plans
router.get('/', auth, async (req, res) => {
  try {
    const { difficulty, type, search } = req.query;
    let query = {};
    
    if (difficulty) query.difficulty = difficulty;
    if (type) query['exercises.type'] = type;
    if (search) {
      query.$or = [
        { name: { $regex: search, $options: 'i' } },
        { 'exercises.name': { $regex: search, $options: 'i' } }
      ];
    }

    const workouts = await WorkoutPlan.find(query).sort({ createdAt: -1 });
    res.json(workouts);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Get workout plans by difficulty (for intensity screen)
router.get('/difficulty/:level', auth, async (req, res) => {
  try {
    const { level } = req.params;
    const validLevels = ['Beginner', 'Intermediate', 'Expert'];
    
    if (!validLevels.includes(level)) {
      return res.status(400).json({ message: 'Invalid difficulty level' });
    }

    const workouts = await WorkoutPlan.find({ difficulty: level });
    
    // Format response to match your Flutter app structure
    const formattedWorkouts = workouts.map(workout => ({
      id: workout._id,
      title: workout.name,
      sets: workout.sets,
      reps: workout.reps,
      duration: workout.duration,
      calories: workout.calories,
      difficulty: workout.difficulty,
      exercises: workout.exercises,
      color: getColorByDifficulty(workout.difficulty),
      icon: getIconByDifficulty(workout.difficulty)
    }));

    res.json(formattedWorkouts);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Get workout plan by ID
router.get('/:id', auth, async (req, res) => {
  try {
    const workout = await WorkoutPlan.findById(req.params.id);
    if (!workout) {
      return res.status(404).json({ message: 'Workout plan not found' });
    }
    res.json(workout);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Get exercises by type (for workout type screen)
router.get('/exercises/:type', auth, async (req, res) => {
  try {
    const { type } = req.params;
    const validTypes = ['Pullups', 'Pushups', 'Squats', 'Others'];
    
    if (!validTypes.includes(type)) {
      return res.status(400).json({ message: 'Invalid exercise type' });
    }

    // Find all workout plans that contain exercises of this type
    const workouts = await WorkoutPlan.find({
      'exercises.type': type
    });

    // Extract exercises of the specified type
    let exercises = [];
    workouts.forEach(workout => {
      const typeExercises = workout.exercises.filter(ex => ex.type === type);
      exercises = exercises.concat(typeExercises.map(ex => ({
        ...ex.toObject(),
        workoutPlanId: workout._id,
        workoutPlanName: workout.name,
        difficulty: workout.difficulty
      })));
    });

    // Remove duplicates based on exercise name
    const uniqueExercises = exercises.filter((exercise, index, self) =>
      index === self.findIndex(ex => ex.name === exercise.name)
    );

    res.json({
      type,
      exercises: uniqueExercises,
      count: uniqueExercises.length
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Get intensity levels (for intensity selector screen)
router.get('/intensity/levels', auth, async (req, res) => {
  try {
    // Get workout counts by difficulty
    const beginnerCount = await WorkoutPlan.countDocuments({ difficulty: 'Beginner' });
    const intermediateCount = await WorkoutPlan.countDocuments({ difficulty: 'Intermediate' });
    const expertCount = await WorkoutPlan.countDocuments({ difficulty: 'Expert' });

    const intensityLevels = [
      {
        id: 'beginner',
        title: 'Beginner',
        subtitle: '4 Sets x 6 Reps',
        description: 'Perfect for getting started',
        color: '#4ECDC4', // Teal
        icon: 'beginner',
        workoutCount: beginnerCount,
        difficulty: 'Beginner',
        estimatedDuration: '15-20 mins',
        caloriesBurn: '100-150 kcal'
      },
      {
        id: 'intermediate',
        title: 'Intermediate',
        subtitle: '5 Sets x 10 Reps',
        description: 'Step up your fitness game',
        color: '#FF6B9D', // Pink
        icon: 'intermediate',
        workoutCount: intermediateCount,
        difficulty: 'Intermediate',
        estimatedDuration: '25-30 mins',
        caloriesBurn: '200-300 kcal'
      },
      {
        id: 'expert',
        title: 'Expert',
        subtitle: '5 Sets x 15 Reps',
        description: 'Challenge yourself',
        color: '#FFA726', // Orange
        icon: 'expert',
        workoutCount: expertCount,
        difficulty: 'Expert',
        estimatedDuration: '35-45 mins',
        caloriesBurn: '350-500 kcal'
      },
      {
        id: 'customize',
        title: 'Customize',
        subtitle: '3 Sets x 7 Reps',
        description: 'Create your own workout',
        color: '#42A5F5', // Blue
        icon: 'customize',
        workoutCount: 0,
        difficulty: 'Custom',
        estimatedDuration: 'Variable',
        caloriesBurn: 'Variable'
      },
      {
        id: 'opengoal',
        title: 'Opengoal',
        subtitle: '4,200 steps | 32 mins',
        description: 'Flexible goal-based training',
        color: '#AB47BC', // Purple
        icon: 'opengoal',
        workoutCount: 1,
        difficulty: 'Variable',
        estimatedDuration: '30+ mins',
        caloriesBurn: '200+ kcal'
      }
    ];

    res.json(intensityLevels);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Create custom workout plan
router.post('/custom', auth, [
  body('name').isLength({ min: 1 }).withMessage('Workout name is required'),
  body('difficulty').isIn(['Beginner', 'Intermediate', 'Expert']).withMessage('Invalid difficulty'),
  body('sets').isInt({ min: 1 }).withMessage('Sets must be a positive integer'),
  body('reps').isInt({ min: 1 }).withMessage('Reps must be a positive integer'),
  body('exercises').isArray({ min: 1 }).withMessage('At least one exercise is required')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const workout = new WorkoutPlan({
      ...req.body,
      isCustom: true,
      createdBy: req.userId
    });

    await workout.save();
    res.status(201).json({
      message: 'Custom workout created successfully',
      workout
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Get user's custom workouts
router.get('/user/custom', auth, async (req, res) => {
  try {
    const customWorkouts = await WorkoutPlan.find({
      createdBy: req.userId,
      isCustom: true
    }).sort({ createdAt: -1 });

    res.json(customWorkouts);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Update custom workout
router.put('/custom/:id', auth, [
  body('name').optional().isLength({ min: 1 }),
  body('difficulty').optional().isIn(['Beginner', 'Intermediate', 'Expert']),
  body('sets').optional().isInt({ min: 1 }),
  body('reps').optional().isInt({ min: 1 })
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const workout = await WorkoutPlan.findOne({
      _id: req.params.id,
      createdBy: req.userId,
      isCustom: true
    });

    if (!workout) {
      return res.status(404).json({ message: 'Custom workout not found' });
    }

    Object.keys(req.body).forEach(key => {
      if (req.body[key] !== undefined) {
        workout[key] = req.body[key];
      }
    });

    await workout.save();
    res.json({
      message: 'Workout updated successfully',
      workout
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Delete custom workout
router.delete('/custom/:id', auth, async (req, res) => {
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
});

// Get popular workouts
router.get('/popular/trending', auth, async (req, res) => {
  try {
    // This would typically be based on usage statistics
    // For now, we'll return workouts sorted by creation date
    const popularWorkouts = await WorkoutPlan.find({ isCustom: false })
      .sort({ createdAt: -1 })
      .limit(10);

    res.json(popularWorkouts);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Search workouts
router.get('/search/:query', auth, async (req, res) => {
  try {
    const { query } = req.params;
    const { difficulty, type } = req.query;

    let searchQuery = {
      $or: [
        { name: { $regex: query, $options: 'i' } },
        { 'exercises.name': { $regex: query, $options: 'i' } },
        { 'exercises.description': { $regex: query, $options: 'i' } }
      ]
    };

    if (difficulty) searchQuery.difficulty = difficulty;
    if (type) searchQuery['exercises.type'] = type;

    const workouts = await WorkoutPlan.find(searchQuery)
      .sort({ createdAt: -1 })
      .limit(20);

    res.json({
      query,
      results: workouts,
      count: workouts.length
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Helper functions
function getColorByDifficulty(difficulty) {
  const colors = {
    'Beginner': '#4ECDC4',
    'Intermediate': '#FF6B9D',
    'Expert': '#FFA726'
  };
  return colors[difficulty] || '#42A5F5';
}

function getIconByDifficulty(difficulty) {
  const icons = {
    'Beginner': 'beginner',
    'Intermediate': 'intermediate',
    'Expert': 'expert'
  };
  return icons[difficulty] || 'workout';
}

module.exports = router;