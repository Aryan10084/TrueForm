const express = require('express');
const { body, validationResult } = require('express-validator');
const Subscription = require('../models/Subscription');
const User = require('../models/User');
const auth = require('../middleware/auth');

const router = express.Router();

// Get user's subscription
router.get('/', auth, async (req, res) => {
  try {
    let subscription = await Subscription.findOne({ userId: req.userId });
    
    if (!subscription) {
      // Create default free subscription
      subscription = new Subscription({
        userId: req.userId,
        plan: 'free'
      });
      await subscription.save();
    }

    res.json(subscription);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Get subscription plans
router.get('/plans', async (req, res) => {
  try {
    const plans = [
      {
        id: 'free',
        name: 'Free',
        price: 0,
        currency: 'USD',
        interval: 'forever',
        features: [
          '3 workouts per day',
          'Basic workout plans',
          'Progress tracking',
          'Community support'
        ],
        limitations: [
          'Limited workout variety',
          'No custom workouts',
          'Basic analytics only'
        ]
      },
      {
        id: 'premium',
        name: 'Premium',
        price: 9.99,
        currency: 'USD',
        interval: 'month',
        features: [
          'Unlimited workouts',
          'Custom workout builder',
          'Advanced analytics',
          'Nutrition plans',
          'Priority support',
          'Offline mode'
        ],
        popular: true
      },
      {
        id: 'premium_plus',
        name: 'Premium Plus',
        price: 19.99,
        currency: 'USD',
        interval: 'month',
        features: [
          'Everything in Premium',
          'Personal trainer chat',
          '1-on-1 video sessions',
          'Meal planning',
          'Advanced form analysis',
          'Custom meal plans'
        ]
      }
    ];

    res.json(plans);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Subscribe to a plan
router.post('/subscribe', auth, [
  body('plan').isIn(['premium', 'premium_plus']),
  body('paymentMethod').isIn(['credit_card', 'paypal', 'google_pay', 'apple_pay']),
  body('transactionId').isString()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { plan, paymentMethod, transactionId } = req.body;

    // Calculate end date (30 days from now)
    const endDate = new Date();
    endDate.setDate(endDate.getDate() + 30);

    // Calculate amount based on plan
    const amounts = {
      premium: 9.99,
      premium_plus: 19.99
    };

    let subscription = await Subscription.findOne({ userId: req.userId });
    
    if (subscription) {
      // Update existing subscription
      subscription.plan = plan;
      subscription.status = 'active';
      subscription.endDate = endDate;
      subscription.paymentMethod = paymentMethod;
      subscription.amount = amounts[plan];
      subscription.transactionId = transactionId;
    } else {
      // Create new subscription
      subscription = new Subscription({
        userId: req.userId,
        plan,
        status: 'active',
        endDate,
        paymentMethod,
        amount: amounts[plan],
        transactionId
      });
    }

    await subscription.save();

    // Update user subscription info
    await User.findByIdAndUpdate(req.userId, {
      'subscription.type': plan,
      'subscription.expiresAt': endDate
    });

    res.json({
      message: 'Subscription activated successfully',
      subscription
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Cancel subscription
router.put('/cancel', auth, async (req, res) => {
  try {
    const subscription = await Subscription.findOne({ userId: req.userId });
    
    if (!subscription) {
      return res.status(404).json({ message: 'No subscription found' });
    }

    if (subscription.plan === 'free') {
      return res.status(400).json({ message: 'Cannot cancel free plan' });
    }

    subscription.status = 'cancelled';
    subscription.autoRenew = false;
    await subscription.save();

    res.json({
      message: 'Subscription cancelled successfully',
      subscription
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Check subscription status
router.get('/status', auth, async (req, res) => {
  try {
    const subscription = await Subscription.findOne({ userId: req.userId });
    
    if (!subscription) {
      return res.json({
        plan: 'free',
        status: 'active',
        features: {
          maxWorkouts: 3,
          customWorkouts: false,
          advancedAnalytics: false,
          personalTrainer: false,
          nutritionPlans: false
        }
      });
    }

    // Check if subscription is expired
    if (subscription.endDate && new Date() > subscription.endDate) {
      subscription.status = 'expired';
      subscription.plan = 'free';
      await subscription.save();
    }

    res.json({
      plan: subscription.plan,
      status: subscription.status,
      endDate: subscription.endDate,
      features: subscription.features,
      autoRenew: subscription.autoRenew
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

module.exports = router;