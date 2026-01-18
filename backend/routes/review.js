const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');

// Import models
const Review = require('../models/review');
const User = require('../models/users');

// Get reviews for a mentor with pagination and average rating
router.get('/:userId', async (req, res) => {
  const { page = 1, limit = 10 } = req.query;

  try {
    const userId = req.params.userId;
    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({ error: 'Invalid mentor ID.' });
    }

    const mentorObjectId = new mongoose.Types.ObjectId(userId);

    // Fetch reviews for the mentor
    const reviews = await Review.find({ mentorId: mentorObjectId })
      .populate('userId', 'firstName lastName')
      .limit(parseInt(limit))
      .skip((parseInt(page) - 1) * parseInt(limit));

    const total = await Review.countDocuments({ mentorId: mentorObjectId });

    if (!reviews.length) {
      return res.status(200).json({
        reviews: [],
        averageRating: 0.00,
        totalPages: 1,
        currentPage: 1,
      });
    }

    // Calculate the average rating
    const averageRatingResult = await Review.aggregate([
      { $match: { mentorId: mentorObjectId } },
      { $group: { _id: null, averageRating: { $avg: '$rating' } } }
    ]);

    const averageRating = averageRatingResult.length > 0 
      ? averageRatingResult[0].averageRating.toFixed(2)
      : 0.00;

    res.status(200).json({
      reviews,
      averageRating,
      totalPages: Math.ceil(total / parseInt(limit)),
      currentPage: parseInt(page),
    });
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch reviews.', details: err.message });
  }
});

// POST - Add a new review
router.post('/', async (req, res) => {
  const { mentorId, userId, review, rating } = req.body;

  if (!mentorId || !userId || rating === undefined) {
    return res.status(400).json({ error: 'Mentor ID, User ID, and rating are required.' });
  }

  if (!mongoose.Types.ObjectId.isValid(mentorId) || !mongoose.Types.ObjectId.isValid(userId)) {
    return res.status(400).json({ error: 'Invalid mentor or user ID.' });
  }

  if (rating < 0 || rating > 5) {
    return res.status(400).json({ error: 'Rating must be between 0 and 5.' });
  }

  try {
    const mentor = await User.findOne({ _id: mentorId, role: 'mentor' });
    if (!mentor) return res.status(404).json({ error: 'Mentor not found.' });

    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ error: 'User not found.' });

    const newReview = new Review({ mentorId, userId, review, rating });
    await newReview.save();

    res.status(201).json(newReview);
  } catch (err) {
    res.status(500).json({ error: 'Failed to submit review.', details: err.message });
  }
});

// PUT - Update an existing review
router.put('/:reviewId', async (req, res) => {
  const { review, rating } = req.body;
  if (!mongoose.Types.ObjectId.isValid(req.params.reviewId)) {
    return res.status(400).json({ error: 'Invalid review ID.' });
  }

  try {
    const updatedReview = await Review.findByIdAndUpdate(
      req.params.reviewId,
      { review, rating },
      { new: true }
    );

    if (!updatedReview) return res.status(404).json({ error: 'Review not found.' });

    res.status(200).json({ updatedReview });
  } catch (err) {
    res.status(500).json({ error: 'Failed to update review.', details: err.message });
  }
});

// DELETE - Remove a review
router.delete('/:reviewId', async (req, res) => {
  if (!mongoose.Types.ObjectId.isValid(req.params.reviewId)) {
    return res.status(400).json({ error: 'Invalid review ID.' });
  }

  try {
    const deletedReview = await Review.findByIdAndDelete(req.params.reviewId);
    if (!deletedReview) return res.status(404).json({ error: 'Review not found.' });

    res.status(200).json({ message: 'Review deleted successfully.' });
  } catch (err) {
    res.status(500).json({ error: 'Failed to delete review.', details: err.message });
  }
});

module.exports = router;