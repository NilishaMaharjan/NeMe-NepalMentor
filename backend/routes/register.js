const express = require('express');
const bcrypt = require('bcryptjs');
const router = express.Router();
const User = require('../models/users');
const MenteeProfile = require('../models/menteeProfile');
const nodemailer = require('nodemailer');
require('dotenv').config();  // Load environment variables

// Nodemailer transporter
const transporter = nodemailer.createTransport({
    host: 'smtp.gmail.com', 
    port: 587,
    secure: false,
    auth: {
        user: process.env.EMAIL_USER, 
        pass: process.env.EMAIL_PASS
    }
});

// Send registration email
function sendRegistrationEmail(userEmail, firstName) {
    const mailOptions = {
        from: process.env.EMAIL_USER || 'nepalmentors1@gmail.com',
        to: userEmail,
        subject: 'Registration Successful',
        text: `Hello ${firstName},\n\nYou have successfully registered. Now you can log in using your credentials.\n\nThanks,\nNepal Mentors Team`
    };

    transporter.sendMail(mailOptions).catch(error => {
        console.error('Email sending failed:', error);
    });
}

// Mentee Registration
router.post('/mentee', async (req, res) => {
    const { firstName, lastName, email, password, age, institution, location } = req.body;

    // Validate required fields
    if (!firstName || !lastName || !email || !password || !age || !institution || !location) {
        return res.status(400).json({ msg: 'Please enter all required fields' });
    }

    // Improved email validation (must be Gmail and start with an alphabet)
    const emailRegex = /^[a-zA-Z][a-zA-Z0-9._%+-]*@gmail\.com$/;
    if (!emailRegex.test(email)) {
        return res.status(400).json({ msg: 'Email must be a valid Gmail address starting with an alphabet' });
    }

    try {
        // Check if user already exists
        let user = await User.findOne({ email });
        if (user) {
            return res.status(400).json({ msg: 'User already exists' });
        }

        // Hash password
        const hashedPassword = await bcrypt.hash(password, 10);

        // Create new user
        const newUser = new User({
            firstName,
            lastName,
            email,
            password: hashedPassword,
            role: 'mentee',
            age,
            institution,
            location,
        });

        await newUser.save();

        // Create Mentee Profile
        const menteeProfile = new MenteeProfile({
            user: newUser._id,
            firstName,
            lastName,
            email,
            age,
            institution,
            location,
        });

        await menteeProfile.save();

        // Send email asynchronously
        sendRegistrationEmail(email, firstName);

        res.status(201).json({ msg: 'Mentee registered successfully' });
    } catch (err) {
        console.error('Error in registration:', err);
        res.status(500).json({ msg: 'Unexpected error occurred' });
    }
});

module.exports = router;