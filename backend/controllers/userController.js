const User = require('../models/User');
const Session = require('../models/Session');

const userController = {
  // Get user profile
  getProfile: async (req, res) => {
    try {
      const user = await User.findById(req.userId).select('-password');
      if (!user) {
        return res.status(404).json({ message: 'User not found' });
      }
      res.json(user);
    } catch (error) {
      res.status(500).json({ message: 'Server error', error: error.message });
    }
  },

  // Update user profile
  updateProfile: async (req, res) => {
    try {
      const updates = req.body;
      const user = await User.findById(req.userId);
      
      if (!user) {
        return res.status(404).json({ message: 'User not found' });
      }

      // Update profile fields
      if (updates.profile) {
        Object.keys(updates.profile).forEach(key => {
          user.profile[key] = updates.profile[key];
        });
      }

      user.updatedAt = Date.now();
      await user.save();

      res.json({
        message: 'Profile updated successfully',
        user: {
          id: user._id,
          email: user.email,
          profile: user.profile
        }
      });
    } catch (error) {
      res.status(500).json({ message: 'Server error', error: error.message });
    }
  },

  // Get user statistics
  getStats: async (req, res) => {
    try {
      const user = await User.findById(req.userId).select('stats');
      if (!user) {
        return res.status(404).json({ message: 'User not found' });
      }

      // Get additional stats from sessions
      const sessions = await Session.find({ 
        userId: req.userId, 
        status: 'completed' 
      });

      const totalSessions = sessions.length;
      const totalDuration = sessions.reduce((sum, session) => sum + (session.duration || 0), 0);
      const averageDuration = totalSessions > 0 ? Math.round(totalDuration / totalSessions) : 0;

      res.json({
        ...user.stats.toObject(),
        totalSessions,
        totalDuration,
        averageDuration
      });
    } catch (error) {
      res.status(500).json({ message: 'Server error', error: error.message });
    }
  },

  // Update user stats
  updateStats: async (req, res) => {
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
  }
};

module.exports = userController;