const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const User = require('../models/User');
const Subscription = require('../models/Subscription');

const generateToken = (userId) => {
  return jwt.sign({ userId }, process.env.JWT_SECRET, { expiresIn: '7d' });
};

const authController = {
  // Register user
  register: async (req, res) => {
    try {
      const { email, password, name } = req.body;

      // Check if user exists
      const existingUser = await User.findOne({ email });
      if (existingUser) {
        return res.status(400).json({ message: 'User already exists' });
      }

      // Create user
      const user = new User({
        email,
        password,
        'profile.name': name || ''
      });

      await user.save();

      // Create default subscription
      const subscription = new Subscription({
        userId: user._id,
        plan: 'free'
      });
      await subscription.save();

      // Generate token
      const token = generateToken(user._id);

      res.status(201).json({
        message: 'User registered successfully',
        token,
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

  // Login user
  login: async (req, res) => {
    try {
      const { email, password } = req.body;

      // Find user
      const user = await User.findOne({ email });
      if (!user) {
        return res.status(400).json({ message: 'Invalid credentials' });
      }

      // Check password
      const isMatch = await user.comparePassword(password);
      if (!isMatch) {
        return res.status(400).json({ message: 'Invalid credentials' });
      }

      // Generate token
      const token = generateToken(user._id);

      res.json({
        message: 'Login successful',
        token,
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
  },

  // Get current user
  getCurrentUser: async (req, res) => {
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

  // Refresh token
  refreshToken: async (req, res) => {
    try {
      const user = await User.findById(req.userId);
      if (!user) {
        return res.status(404).json({ message: 'User not found' });
      }

      const token = generateToken(user._id);
      res.json({ token });
    } catch (error) {
      res.status(500).json({ message: 'Server error', error: error.message });
    }
  }
};

module.exports = authController;