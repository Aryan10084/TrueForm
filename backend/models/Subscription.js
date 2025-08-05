const mongoose = require('mongoose');

const subscriptionSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    unique: true
  },
  plan: {
    type: String,
    enum: ['free', 'premium', 'premium_plus'],
    default: 'free'
  },
  status: {
    type: String,
    enum: ['active', 'cancelled', 'expired', 'pending'],
    default: 'active'
  },
  startDate: {
    type: Date,
    default: Date.now
  },
  endDate: {
    type: Date
  },
  paymentMethod: {
    type: String,
    enum: ['credit_card', 'paypal', 'google_pay', 'apple_pay']
  },
  amount: {
    type: Number,
    default: 0
  },
  currency: {
    type: String,
    default: 'USD'
  },
  features: {
    maxWorkouts: { type: Number, default: 3 }, // per day for free users
    customWorkouts: { type: Boolean, default: false },
    advancedAnalytics: { type: Boolean, default: false },
    personalTrainer: { type: Boolean, default: false },
    nutritionPlans: { type: Boolean, default: false }
  },
  transactionId: String,
  autoRenew: {
    type: Boolean,
    default: true
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
});

subscriptionSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  
  // Set features based on plan
  if (this.plan === 'free') {
    this.features = {
      maxWorkouts: 3,
      customWorkouts: false,
      advancedAnalytics: false,
      personalTrainer: false,
      nutritionPlans: false
    };
  } else if (this.plan === 'premium') {
    this.features = {
      maxWorkouts: -1, // unlimited
      customWorkouts: true,
      advancedAnalytics: true,
      personalTrainer: false,
      nutritionPlans: true
    };
  } else if (this.plan === 'premium_plus') {
    this.features = {
      maxWorkouts: -1, // unlimited
      customWorkouts: true,
      advancedAnalytics: true,
      personalTrainer: true,
      nutritionPlans: true
    };
  }
  
  next();
});

module.exports = mongoose.model('Subscription', subscriptionSchema);