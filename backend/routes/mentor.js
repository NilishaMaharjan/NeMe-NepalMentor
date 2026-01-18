const express = require('express');
const router = express.Router();
const MentorProfile = require('../models/mentorProfile');
const User = require('../models/users');
const auth = require('../middleware/auth');

// Mentor Profile Completion or Update API (including availability)
router.post('/complete', auth, async (req, res) => {
  console.log('Received Request Body:', req.body);// new line added
  const { firstName, lastName, location, jobTitle, company, category, skills, bio, linkedin, availability, qualification } = req.body;

  if (!firstName || !lastName || !location || !jobTitle || !category || !skills || !bio || !availability || !qualification) {
    return res.status(400).json({ msg: 'Please enter all required fields' });
  }

  try {
    const user = await User.findById(req.user.id);
    if (user.role !== 'mentor') {
      return res.status(400).json({ msg: 'Only mentors can complete this action' });
    }

    // Check if mentor profile already exists
    let mentorProfile = await MentorProfile.findOne({ user: req.user.id });
    if (mentorProfile) {
      return res.status(400).json({ msg: 'Mentor profile already exists' });
    }

    // Create a new mentor profile with availability
    mentorProfile = new MentorProfile({
      user: req.user.id,
      firstName,
      lastName,
      location,
      jobTitle,
      company,
      category,
      skills: skills.split(',').map(skill => skill.trim()), // Convert comma-separated skills to array
      bio,
      linkedin,
      availability, 
      qualification, 
    });

    await mentorProfile.save();
    res.status(201).json({ msg: 'Mentor profile created successfully', mentorProfile });
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error');
  }
});

// Mentor Profile Update API (including availability)
router.put('/profile/:id', auth, async (req, res) => {
  const { firstName, lastName, location, jobTitle, company, category, skills, bio, linkedin, availability, qualifications } = req.body;

  const mentorFields = {};
  if (firstName) mentorFields.firstName = firstName;
  if (lastName) mentorFields.lastName = lastName;
  if (location) mentorFields.location = location;
  if (jobTitle) mentorFields.jobTitle = jobTitle;
  if (company) mentorFields.company = company;
  if (category) mentorFields.category = category;
  if (skills) mentorFields.skills = skills.split(',').map(skill => skill.trim());
  if (bio) mentorFields.bio = bio;
  if (linkedin) mentorFields.linkedin = linkedin;
  if (availability) mentorFields.availability = availability;
  if (qualification) mentorFields.qualification = qualification;  

  try {
    const user = await User.findById(req.user.id);
    if (user.role !== 'mentor') {
      return res.status(400).json({ msg: 'Only mentors can update their profiles' });
    }

    let mentorProfile = await MentorProfile.findOne({ user: req.params.id });
    if (!mentorProfile) {
      return res.status(404).json({ msg: 'Mentor profile not found' });
    }

    if (mentorProfile.user.toString() !== req.user.id) {
      return res.status(401).json({ msg: 'User not authorized' });
    }

    mentorProfile = await MentorProfile.findOneAndUpdate(
      { user: req.params.id },
      { $set: mentorFields },
      { new: true }
    );

    res.json({ msg: 'Mentor profile updated successfully', mentorProfile });
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error');
  }
});

module.exports = router;

