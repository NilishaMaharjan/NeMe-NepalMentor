const express = require('express');
const router = express.Router();
const MenteeProfile = require('../models/menteeProfile');
const User = require('../models/users');

// Route to fetch mentee profile by userId
router.get('/:userId', async (req, res) => {
    try {
        // Find the user by userId
        const user = await User.findById(req.params.userId);

        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        // Find the mentee profile based on the user's userId
        const mentee = await MenteeProfile.findOne({ user: req.params.userId });

        if (!mentee) {
            return res.status(404).json({ message: 'Mentee profile not found' });
        }

        // Return the mentee profile
        res.json(mentee);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Error fetching mentee profile' });
    }
});
router.put('/:userId', async (req, res) => {
    try {
        console.log("Updating Mentee ID:", req.params.userId);
        
        // Check if user exists
        const user = await User.findById(req.params.userId);
        if (!user) return res.status(404).json({ message: 'User not found' });

        // Find and update the mentee profile
        const updatedMentee = await MenteeProfile.findOneAndUpdate(
            { user: req.params.userId }, // Find by userId
            req.body, // New data
            { new: true, runValidators: true } // Return updated document
        );

        if (!updatedMentee) {
            return res.status(404).json({ message: 'Mentee profile not found' });
        }

        res.json({ message: 'Profile updated successfully', updatedMentee });
    } catch (error) {
        console.error("Error updating mentee profile:", error);
        res.status(500).json({ message: 'Server error' });
    }
});


module.exports = router;
