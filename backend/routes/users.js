const express = require('express');
const { body, validationResult } = require('express-validator');
const User = require('../models/User');
const Session = require('../models/Session');
const auth = require('../middleware/auth');

const router = express.Router();

// Get user profile
router.get('/profile', auth, async (req, res) => {
  try {
    const user = await User.findById(req.userId).select('-password');
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    res.json(user);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Update user profile
router.put('/profile', auth, [
  body('profile.name').optional().isLength({ min: 1 }),
  body('profile.height').optional().isNumeric(),
  body('profile.weight').optional().isNumeric(),
  body('profile.goal').optional().isIn(['Slim', 'Bulk', 'Fit']),
  body('profile.fitnessLevel').optional().isIn(['Beginner', 'Intermediate', 'Expert'])
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const user = await User.findById(req.userId);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Update profile fields
    if (req.body.profile) {
      Object.keys(req.body.profile).forEach(key => {
        user.profile[key] = req.body.profile[key];
      });
    }

    user.updatedAt = Date.now();
    await user.save();

    res.json({
      message: 'Profile updated successfully',
      user: {
        id: user._id,
        email: user.email,
        profile: user.profile,
        stats: user.stats
      }
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Get user stats/dashboard data
router.get('/dashboard', auth, async (req, res) => {
  try {
    const user = await User.findById(req.userId).select('-password');
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Get recent sessions for additional stats
    const recentSessions = await Session.find({ 
      userId: req.userId,
      status: 'completed'
    })
    .sort({ createdAt: -1 })
    .limit(30);

    // Calculate streak
    let currentStreak = 0;
    let lastWorkoutDate = null;
    
    if (recentSessions.length > 0) {
      const today = new Date();
      const sessions = recentSessions.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
      
      for (let i = 0; i < sessions.length; i++) {
        const sessionDate = new Date(sessions[i].createdAt);
        const daysDiff = Math.floor((today - sessionDate) / (1000 * 60 * 60 * 24));
        
        if (i === 0 && daysDiff <= 1) {
          currentStreak = 1;
          lastWorkoutDate = sessionDate;
        } else if (daysDiff === currentStreak) {
          currentStreak++;
        } else {
          break;
        }
      }
    }

    // Calculate weekly stats
    const weekAgo = new Date();
    weekAgo.setDate(weekAgo.getDate() - 7);
    
    const weekSessions = recentSessions.filter(session => 
      new Date(session.createdAt) >= weekAgo
    );

    const weeklyCalories = weekSessions.reduce((total, session) => 
      total + (session.caloriesBurned || 0), 0
    );

    const weeklyMinutes = weekSessions.reduce((total, session) => 
      total + (session.duration || 0), 0
    );

    const dashboardData = {
      user: {
        name: user.profile.name || 'User',
        email: user.email,
        avatar: user.profile.avatar,
        goal: user.profile.goal
      },
      stats: {
        currentStreak: currentStreak,
        totalWorkouts: user.stats.totalWorkouts,
        totalCalories: user.stats.totalCalories,
        weeklyCalories: weeklyCalories,
        weeklyMinutes: weeklyMinutes,
        lastWorkoutDate: lastWorkoutDate
      },
      cards: [
        {
          title: 'Calories',
          value: `${weeklyCalories}`,
          subtitle: `${Math.round(weeklyCalories/7)}/day avg`,
          period: '7d',
          color: '#FF6B9D',
          icon: 'fire'
        },
        {
          title: 'Streak Breaks',
          value: `${currentStreak}'0"`,
          subtitle: `Current streak: ${currentStreak} days`,
          period: '',
          color: '#FFE66D',
          icon: 'shield'
        },
        {
          title: 'Sessions',
          value: `${weeklyMinutes}min`,
          subtitle: `${weekSessions.length} workouts`,
          period: '7d',
          color: '#4ECDC4',
          icon: 'clock'
        },
        {
          title: 'Posture Accuracy',
          value: `${weeklyMinutes}min`,
          subtitle: 'Form tracking',
          period: '7d',
          color: '#A8E6CF',
          icon: 'activity'
        }
      ]
    };

    res.json(dashboardData);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Update user stats (called after workout completion)
router.put('/stats', auth, async (req, res) => {
  try {
    const { caloriesBurned, workoutCompleted } = req.body;
    
    const user = await User.findById(req.userId);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    if (workoutCompleted) {
      user.stats.totalWorkouts += 1;
      user.stats.lastWorkoutDate = new Date();
    }

    if (caloriesBurned) {
      user.stats.totalCalories += caloriesBurned;
    }

    await user.save();
    res.json({ message: 'Stats updated successfully', stats: user.stats });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Delete user account
router.delete('/account', auth, async (req, res) => {
  try {
    await User.findByIdAndDelete(req.userId);
    await Session.deleteMany({ userId: req.userId });
    res.json({ message: 'Account deleted successfully' });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

module.exports = router;