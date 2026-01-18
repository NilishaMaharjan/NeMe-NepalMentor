const express = require('express');
const User = require('../models/users');
const MentorProfile = require('../models/mentorProfile'); 
const Request = require('../models/request');
const Notification = require('../models/notification');
const Review = require('../models/review');
const nodemailer = require('nodemailer');
const router = express.Router();

// Route to get all mentors
router.get('/mentors', async (req, res) => {
    try {
        const mentors = await User.find({ role: 'mentor' });
        res.json(mentors);
    } catch (error) {
        console.error("Error retrieving mentors:", error);
        res.status(500).send("Error retrieving mentors");
    }
});

// Route to get all mentees
router.get('/mentees', async (req, res) => {
    try {
        const mentees = await User.find({ role: 'mentee' });
        res.json(mentees);
    } catch (error) {
        console.error("Error retrieving mentees:", error);
        res.status(500).send("Error retrieving mentees");
    }
});

// Route to delete a mentor and remove associated data
router.delete('/users/:id', async (req, res) => {
    try {
        const userId = req.params.id;

        // Find the user first
        const user = await User.findById(userId);
        if (!user) {
            return res.status(404).json({ msg: "User not found" });
        }

        // If the user is a mentor, delete related data
        if (user.role === 'mentor') {
            // Delete mentor profile
            await MentorProfile.findOneAndDelete({ user: userId });

            // Delete all requests related to the mentor
            await Request.deleteMany({ mentor: userId });

            // Delete all notifications related to the mentor
            await Notification.deleteMany({ mentor: userId });

            // Delete all reviews related to the mentor
            await Review.deleteMany({ mentor: userId });

            console.log(`Mentor-related data deleted for mentor ID: ${userId}`);
        }

        // Delete user from the User collection
        await User.findByIdAndDelete(userId);

        res.json({ msg: "Mentor and related profile deleted successfully" });
    } catch (error) {
        console.error("Error deleting mentor:", error);
        res.status(500).json({ msg: "Error deleting mentor" });
    }
});

// Route to verify a mentor by ID
router.put('/verify-mentor/:id', async (req, res) => {
    try {
        const mentorId = req.params.id;
        console.log("🔍 Received Mentor Verification Request for ID:", mentorId);

        // Find the user first (not the MentorProfile)
        const user = await User.findById(mentorId);
        if (!user || user.role !== 'mentor') {
            console.log("❌ Mentor User Not Found:", mentorId);
            return res.status(404).json({ msg: "Mentor user not found" });
        }

        // If already verified, log and continue to resend the email
        if (user.verified) {
            console.log("Mentor is already verified. Resending verification email.");
        } else {
            // Mark the user as verified
            user.verified = true;
            await user.save();
        }

        // Check if MentorProfile already exists
        let mentorProfile = await MentorProfile.findOne({ user: mentorId });
        if (!mentorProfile) {
            // Create a new MentorProfile
            mentorProfile = new MentorProfile({
                user: user._id,
                firstName: user.firstName,
                lastName: user.lastName,
                location: user.location,
                qualifications: user.qualifications,
                skills: user.skills,
                jobTitle: user.jobTitle,
                category: user.category,
                bio: user.bio,
                classLevel: user.classLevel,
                subjects: user.subjects,
                fieldOfStudy: user.fieldOfStudy,
                profilePicture: user.profilePicture,
                socialLinks: user.socialLinks,
                certificates: user.certificates,
                verified: true
            });
            await mentorProfile.save();
        }

        // Send verification success email (await the email sending)
        await sendEmail(
          user.email,
          'Mentor Verification Successful',
          `Hello ${user.firstName},\n\nYour mentor profile has been verified successfully. Mentees can now view your profile.\n\nThanks,\nNepal Mentors Team`
        );

        console.log("✅ Mentor Verified Successfully:", mentorProfile);
        res.json({ msg: "Mentor verified successfully", mentorProfile });
    } catch (error) {
        console.error("❌ Error verifying mentor:", error);
        res.status(500).json({ msg: "Server error" });
    }
});

// Route to get user details by ID
router.get('/users/:id', async (req, res) => {
    try {
        const user = await User.findById(req.params.id);
        if (!user) {
            return res.status(404).send("User not found");
        }
        res.json(user);
    } catch (error) {
        console.error("Error retrieving user:", error);
        res.status(500).send("Error retrieving user");
    }
});

// Route to update user by ID
router.put('/users/:id', async (req, res) => {
    try {
        const updatedUser = await User.findByIdAndUpdate(req.params.id, req.body, { new: true });

        if (!updatedUser) {
            return res.status(404).send("User not found");
        }

        res.json(updatedUser);
    } catch (error) {
        console.error("Error updating user:", error);
        res.status(500).send("Error updating user");
    }
});

// Route to search for users
router.get('/search', async (req, res) => {
    const { query } = req.query;
    try {
        const users = await User.find({
            $or: [
                { firstName: { $regex: query, $options: 'i' } },
                { lastName: { $regex: query, $options: 'i' } },
                { email: { $regex: query, $options: 'i' } }
            ]
        });
        res.json(users);
    } catch (error) {
        console.error("Error searching for users:", error);
        res.status(500).send("Error searching for users");
    }
});

// Route to get all requests
router.get('/requests', async (req, res) => {
    try {
        const requests = await Request.find()
            .populate('mentee', 'firstName lastName email')
            .populate('mentor', 'firstName lastName email');
        res.json(requests);
    } catch (error) {
        console.error("Error retrieving requests:", error);
        res.status(500).send("Error retrieving requests");
    }
});

// Route to delete a request
router.delete('/requests/:id', async (req, res) => {
    try {
        const deletedRequest = await Request.findByIdAndDelete(req.params.id);
        if (!deletedRequest) {
            return res.status(404).send("Request not found");
        }
        res.send("Request deleted successfully");
    } catch (error) {
        console.error("Error deleting request:", error);
        res.status(500).send("Error deleting request");
    }
});

// Route to get all notifications
router.get('/notifications', async (req, res) => {
    try {
        const notifications = await Notification.find();
        res.json(notifications);
    } catch (error) {
        console.error("Error retrieving notifications:", error);
        res.status(500).send("Error retrieving notifications");
    }
});

// Route to delete a notification
router.delete('/notifications/:id', async (req, res) => {
    try {
        const deletedNotification = await Notification.findByIdAndDelete(req.params.id);
        if (!deletedNotification) {
            return res.status(404).send("Notification not found");
        }
        res.send("Notification deleted successfully");
    } catch (error) {
        console.error("Error deleting notification:", error);
        res.status(500).send("Error deleting notification");
    }
});

// Route to get all reviews
router.get('/reviews', async (req, res) => {
    try {
        const reviews = await Review.find()
            .populate('mentor', 'firstName lastName email')
            .populate('mentee', 'firstName lastName email');
        res.json(reviews);
    } catch (error) {
        console.error("Error retrieving reviews:", error);
        res.status(500).send("Error retrieving reviews");
    }
});

// Route to delete a review
router.delete('/reviews/:id', async (req, res) => {
    try {
        const deletedReview = await Review.findByIdAndDelete(req.params.id);
        if (!deletedReview) {
            return res.status(404).send("Review not found");
        }
        res.send("Review deleted successfully");
    } catch (error) {
        console.error("Error deleting review:", error);
        res.status(500).send("Error deleting review");
    }
});

// Route to get the count of mentors and mentees
router.get('/user-count', async (req, res) => {
    try {
        const mentorCount = await User.countDocuments({ role: 'mentor' });
        const menteeCount = await User.countDocuments({ role: 'mentee' });

        res.json({ mentorCount, menteeCount });
    } catch (error) {
        console.error("Error retrieving user counts:", error);
        res.status(500).send("Error retrieving user counts");
    }
});

// Email Sending Function (updated to use async/await)
async function sendEmail(to, subject, text) {
    const transporter = nodemailer.createTransport({
        host: 'smtp.gmail.com',
        port: 587,
        secure: false,
        auth: {
            user: 'nepalmentors1@gmail.com',
            pass: 'cydhqbwotkocyuyz'
        }
    });

    const mailOptions = {
        from: 'nepalmentors1@gmail.com',
        to,
        subject,
        text
    };

    try {
        let info = await transporter.sendMail(mailOptions);
        console.log('📩 Email sent successfully:', info.response);
    } catch (error) {
        console.error('❌ Error sending email:', error);
    }
}

module.exports = router;
