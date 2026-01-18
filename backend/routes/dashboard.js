const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const User = require('../models/users');

// Middleware for authentication
const authMiddleware = (req, res, next) => {
    const token = req.header('x-auth-token');
    if (!token) {
        return res.status(401).json({ msg: 'No token, authorization denied' });
    }

    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        req.user = decoded;
        next();
    } catch (err) {
        res.status(401).json({ msg: 'Token is not valid' });
    }
};

// Mentor Dashboard
router.get('/mentor', authMiddleware, async (req, res) => {
    if (req.user.role !== 'mentor') {
        return res.status(403).json({ msg: 'Access denied, mentor only' });
    }

    try {
        const mentor = await User.findById(req.user.id).select('-password');
        res.json({ msg: 'Welcome to the Mentor Dashboard', mentor });
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server error');
    }
});

// Mentee Dashboard
router.get('/mentee', authMiddleware, async (req, res) => {
    if (req.user.role !== 'mentee') {
        return res.status(403).json({ msg: 'Access denied, mentee only' });
    }

    try {
        const mentee = await User.findById(req.user.id).select('-password');
        res.json({ msg: 'Welcome to the Mentee Dashboard', mentee });
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server error');
    }
});

module.exports = router;


