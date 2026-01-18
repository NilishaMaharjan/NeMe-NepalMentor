const express = require('express');
const MentorProfile = require('../models/mentorProfile');
const User = require('../models/users');
const router = express.Router();

// @route   GET /api/mentors
// @access  Public
router.get('/', async (req, res) => {
  console.log("Received request with query:", req.query);

  const { category, classLevel, subject, fieldOfStudy } = req.query;
  console.log("Received query parameters:", { category, classLevel, subject, fieldOfStudy });

  try {
    let query = {};

    // Ensure category is provided
    if (!category) {
      return res.status(400).json({ msg: 'Category is required.' });
    }

    // Handle Primary and Secondary categories
    if (['Primary Level', 'Secondary Level', 'Diploma'].includes(category)) {
      if (!classLevel || !subject) {
        return res.status(400).json({
          msg: 'Class Level and Subject are required for Primary, Secondary, or Diploma categories.',
        });
      }

      // Validating class level based on category
      if (category === 'Primary Level' && !['Class 4', 'Class 5', 'Class 6', 'Class 7', 'Class 8'].includes(classLevel)) {
        return res.status(400).json({ msg: 'Invalid class level for Primary category.' });
      }
      if (category === 'Secondary Level' && !['Class 9', 'Class 10', 'Class 11', 'Class 12'].includes(classLevel)) {
        return res.status(400).json({ msg: 'Invalid class level for Secondary category.' });
      }
      if (category === 'Diploma' && !['Diploma 1', 'Diploma 2', 'Diploma 3'].includes(classLevel)) {
        return res.status(400).json({ msg: 'Invalid class level for Diploma category.' });
      }

      // Build query for Primary/Secondary
      query.category = category;
      query.classLevel = classLevel;
      query.subjects = { $in: [subject] }; 
    }

    // Handle Bachelors and Masters categories
    if (['Bachelors', 'Masters'].includes(category)) {
      if (!fieldOfStudy || !classLevel || !subject) {
        return res.status(400).json({
          msg: 'Field of Study, Class Level, and Subject are required for Bachelors and Masters categories.',
        });
      }

      // Build query for Bachelors/Masters
      query.category = category;
      query.fieldOfStudy = fieldOfStudy;
      query.classLevel = classLevel;
      query.subjects = { $in: [subject] };
    }

    // Debugging: Check the query object before execution
    console.log("Constructed query object:", query);

    // Fetch mentors based on the query and include profilePicture and certificates
    const mentors = await MentorProfile.find(query)
      .populate('user', ['email', 'role'])
      .select('firstName lastName profilePicture certificates category classLevel subjects jobTitle');
    // If no mentors are found
    if (!mentors.length) {
      return res.status(404).json({ msg: 'No mentors found matching the criteria.' });
    }

    res.json(mentors);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error');
  }
});

// @route   GET /api/mentors/:userId
// @desc    Get a specific mentor profile by userId
// @access  Public
router.get('/:userId', async (req, res) => {
  try {
    // Try finding the mentor using the 'user' field (userId)
    let mentor = await MentorProfile.findOne({ user: req.params.userId }).populate('user', [
      'email',
      'role',
      'classLevel'
    ]);

    // If not found, try finding by mentor's _id field
    if (!mentor) {
      mentor = await MentorProfile.findOne({ _id: req.params.userId }).populate('user', [
        'email',
        'role',
        'classLevel'
      ]);
    }

    if (!mentor) {
      return res.status(404).json({ msg: 'Mentor not found' });
    }

    res.json(mentor);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error');
  }
});

// @route   PUT /api/mentors/:userId
// @desc    Update a specific mentor's profile
// @access  Public (No authentication required)
router.put('/:userId', async (req, res) => {
  try {
    // Extract the mentor profile to be updated from the request body
    const {
      firstName,
      lastName,
      email,
      location,
      qualifications,
      skills,
      jobTitle,
      category,
      bio,
      classLevel,
      subjects,
    } = req.body;

    // Find the mentor by their userId
    let mentor = await MentorProfile.findOne({ user: req.params.userId });

    // If the mentor is not found, send a 404 error
    if (!mentor) {
      return res.status(404).json({ msg: 'Mentor profile not found' });
    }

    // Update mentor profile fields
    mentor.firstName = firstName || mentor.firstName;
    mentor.lastName = lastName || mentor.lastName;
    mentor.email = email || mentor.email;
    mentor.location = location || mentor.location;
    mentor.qualifications = qualifications || mentor.qualifications;
    mentor.skills = skills || mentor.skills;
    mentor.jobTitle = jobTitle || mentor.jobTitle;
    mentor.category = category || mentor.category;
    mentor.bio = bio || mentor.bio;
    mentor.classLevel = classLevel || mentor.classLevel;
    mentor.subjects = subjects || mentor.subjects;
   

    // Save the updated mentor profile
    await mentor.save();

    // Return a success response with the updated mentor profile
    res.json({ msg: 'Mentor profile updated successfully', mentorProfile: mentor });
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error');
  }
});

module.exports = router;
