const express = require('express');
const bcrypt = require('bcryptjs');
const path = require('path');
const fs = require('fs');
const nodemailer = require('nodemailer');
const router = express.Router();
const User = require('../models/users');
const MentorProfile = require('../models/mentorProfile');
const upload = require('../middleware/upload');


// Static data for dynamic dropdowns
const data = {
    categories: {
        'Primary Level': ['Class 4', 'Class 5', 'Class 6', 'Class 7', 'Class 8'],
        'Secondary Level': ['Class 9', 'Class 10', 'Class 11', 'Class 12'],
        Diploma: ['Diploma 1', 'Diploma 2', 'Diploma 3'],
        Bachelors: [
            'Computer Engineering',
            'Civil Engineering',
            'MBBS',
            'Architecture'
        ],
        Masters: ['Computer Science', 'Medicine', 'Law', 'Psychology']
    },
    fields: {
        Bachelors: {
            'Computer Engineering': [
                'Semester 1',
                'Semester 2',
                'Semester 3',
                'Semester 4',
                'Semester 5',
                'Semester 6',
                'Semester 7',
                'Semester 8'
            ],
            'Civil Engineering': [
                'Semester 1',
                'Semester 2',
                'Semester 3',
                'Semester 4',
                'Semester 5',
                'Semester 6',
                'Semester 7',
                'Semester 8'
            ],
            MBBS: ['Year 1', 'Year 2', 'Year 3', 'Year 4', 'Year 5'],
            Architecture: ['Year 1', 'Year 2', 'Year 3', 'Year 4', 'Year 5']
        },
        Masters: {
            'Computer Science': ['Year 1', 'Year 2'],
            Medicine: ['Year 1','Year 2'],
            Law: ['Year1','Year2'],
            Psychology: ['Year1','Year2']
        },
    },
    subjects: {
        "Primary Level": {
          "General": {
            "Class 4": [
              "English", "Mathematics", "Science", "Social Studies", "Nepali", "Computer"
            ],
            "Class 5": [
              "English", "Mathematics", "Science", "Social Studies", "Nepali", "Computer"
            ],
            "Class 6": ["Math", "Science", "Social Studies"],
            "Class 7": [
              "English", "Mathematics", "Science", "Social Studies", "Nepali", "Computer"
            ],
            "Class 8": [
              "English", "Mathematics", "Science", "Social Studies", "Nepali", "Computer", 
              "Optional Mathematics", "Account"
            ]
          }
        },
        "Secondary Level": {
          "General": {
            "Class 9": [
              "English", "Mathematics", "Science", "Social Studies", "Nepali", "Computer", 
              "Optional Mathematics", "Account"
            ],
            "Class 10": [
              "English", "Mathematics", "Science", "Social Studies", "Nepali", "Computer", 
              "Optional Mathematics", "Account"
            ],
            "Class 11": [
              "English", "Mathematics", "Science", "Nepali", "Computer", "Optional Mathematics", 
              "Account", "Economics", "Political Science", "Business Studies"
            ],
            "Class 12": [
              "English", "Mathematics", "Science", "Nepali", "Computer", "Optional Mathematics", 
              "Account", "Economics", "Political Science", "Business Studies"
            ]
          }
        },
        "Bachelors": {
          "Computer Engineering": {
            "Semester 1": ["Programming Basics", "Mathematics", "Physics", "Engineering Drawing", "Basic Electronics"],
            "Semester 2": ["Data Structures", "Algorithms", "Electronics", "Discrete Mathematics", "Digital Logic"],
            "Semester 3": ["Operating Systems", "Database Systems", "Networks", "Object-Oriented Programming", "Linear Algebra"],
            "Semester 4": ["Computer Architecture", "Software Engineering", "Computer Networks", "Microprocessors", "Database Management Systems"],
            "Semester 5": ["Web Development", "Data Structures and Algorithms", "Software Development", "Networking Protocols", "Computer Graphics"],
            "Semester 6": ["Artificial Intelligence", "Information Security", "Software Testing", "Mobile Computing", "Cloud Computing"],
            "Semester 7": ["Machine Learning", "Computer Vision", "Embedded Systems", "Data Science", "Big Data"],
            "Semester 8": ["Project Work", "Internship", "Ethical Hacking", "Cyber Security", "Data Analytics"]
          },
          "Civil Engineering": {
            "Semester 1": ["Engineering Drawing", "Mathematics", "Physics", "Chemistry", "Surveying"],
            "Semester 2": ["Mechanics", "Surveying", "Material Science", "Fluid Mechanics", "Strength of Materials"],
            "Semester 3": ["Geotechnical Engineering", "Building Materials", "Structural Analysis", "Concrete Technology", "Soil Mechanics"],
            "Semester 4": ["Transportation Engineering", "Hydrology", "Construction Management", "Reinforced Concrete Structures", "Structural Design"],
            "Semester 5": ["Building Construction", "Environmental Engineering", "Earthquake Engineering", "Foundation Engineering", "Advanced Surveying"],
            "Semester 6": ["Advanced Structural Analysis", "Water Resources Engineering", "Pavement Design", "Bridge Engineering", "Geotechnical Engineering"],
            "Semester 7": ["Urban Planning", "Transportation Systems", "Project Management", "Hydraulic Structures", "Coastal Engineering"],
            "Semester 8": ["Project Work", "Internship", "Construction Planning", "Sustainable Development", "Disaster Management"]
          },
          "MBBS": {
            "Year 1": ["Anatomy", "Physiology", "Biochemistry", "Histology", "Microbiology"],
            "Year 2": ["Pathology", "Pharmacology", "Microbiology", "Forensic Medicine", "Community Medicine"],
            "Year 3": ["Surgery", "Internal Medicine", "Pediatrics", "Obstetrics and Gynecology", "Ophthalmology"],
            "Year 4": ["Orthopedics", "Anesthesia", "Emergency Medicine", "Radiology", "Dermatology"],
            "Year 5": ["Psychiatry", "Neurology", "Pediatrics Surgery", "Cardiology", "Gastroenterology"]
          },
          "Architecture": {
            "Year 1": ["Design Basics", "History of Architecture", "Construction Technology", "Environmental Design", "Graphics and Drawing"],
            "Year 2": ["Urban Planning", "Building Materials", "Structural Design", "Construction Management", "Theory of Architecture"],
            "Year 3": ["Building Construction", "Sustainability in Architecture", "Architectural Design", "Structures for Architecture", "Interior Design"],
            "Year 4": ["Building Systems", "Lighting Design", "Public Buildings", "Landscape Design", "Smart Cities"],
            "Year 5": ["Professional Practice", "Architectural Theory", "Construction Documentation", "Urban Design", "Final Project"]
          }
        },
        "Masters": {
  "Computer Science": {
    "Year 1": [
      "Machine Learning",
      "Artificial Intelligence",
      "Data Mining"
    ],
    "Year 2": [
      "Big Data Analytics",
      "Cloud Computing"
    ]
  },
  "Medicine": {
    "Year 1": [
      "Clinical Practice",
      "Pharmacology",
      "Pathophysiology"
    ],
    "Year 2": [
      "Medical Ethics",
      "Community Medicine"
    ]
  },
  "Law": {
    "Year 1": [
      "Judicial Review",
      "International Law",
      "Legal Theory"
    ],
    "Year 2": [
      "Constitutional Rights",
      "Human Rights Law"
    ]
  },
  "Psychology": {
    "Year 1": [
      "Behavioral Therapy",
      "Cognitive Science",
      "Psychopathology"
    ],
    "Year 2": [
      "Clinical Neuropsychology",
      "Psychological Assessment"
    ]
  }
}
}
};


// Dynamic data routes
router.get('/categories', (req, res) => {
    res.json(data.categories);
});

router.get('/fields/:category', (req, res) => {
    const category = req.params.category;
    if (data.fields[category]) {
        res.json({ fields: data.fields[category] });
    } else {
        res.status(404).json({ msg: 'Fields not found for this category' });
    }
});

router.get('/classLevels/:category/:field?', (req, res) => {
    const { category, field } = req.params;

    // Check if the category exists in the static data
    if (data.categories[category]) {
        // If it's a category like Bachelors or Masters, and a field is provided
        if (category === 'Bachelors' || category === 'Masters') {
            if (field && data.fields[category] && data.fields[category][field]) {
                const levels = data.fields[category][field];
                res.json({ classLevels: levels });
            } else {
                res.status(404).json({ msg: 'Field or class levels not found for this category and field' });
            }
        } else {
            // For categories like Primary Level, Secondary Level, etc.
            const levels = data.categories[category];
            if (levels) {
                res.json({ classLevels: levels });
            } else {
                res.status(404).json({ msg: 'Class levels not found for this category' });
            }
        }
    } else {
        res.status(404).json({ msg: 'Category not found' });
    }
});


router.get('/subjects/:category/:field?/:classLevel', (req, res) => {
    const { category, field, classLevel } = req.params;
    
    console.log(`Category: ${category}, Field: ${field}, Class Level: ${classLevel}`);

    // Check if the category exists in the data
    if (!data.subjects[category]) {
        return res.status(404).json({ msg: 'Category not found' });
    }
    
    // Check if the field exists within the category
    if (field && !data.subjects[category][field]) {
        return res.status(404).json({ msg: 'Field not found in the category' });
    }
    
    // Check if the classLevel exists for the specific field within the category
    if (classLevel && !data.subjects[category][field]?.[classLevel]) {
        return res.status(404).json({ msg: 'Class level not found for this field' });
    }

    // If all checks pass, return the subjects for the specific class level
    const subjects = data.subjects[category][field]?.[classLevel];
    if (subjects) {
        return res.json({ subjects });
    } else {
        return res.status(404).json({ msg: 'Subjects not found for this class level' });
    }
});

router.post('/mentor', upload.fields([
    { name: 'profilePicture', maxCount: 1 },
    { name: 'certificates', maxCount: 5 }
  ]), async (req, res) => {
    console.log('Files received:', req.files);
    console.log('Request body:', req.body);
    console.log('Profile picture path:', req.files?.profilePicture?.[0]?.path);
  
    // Use Cloudinary URL if available; else use default image
    const profilePictureUrl = req.files?.profilePicture?.[0]?.path || 'uploads/profilePictures/default.png';
  
    if (!profilePictureUrl) {
      return res.status(400).json({ msg: 'Profile picture is required' });
    }
    if (!req.body) {
      return res.status(400).json({ msg: 'No data received' });
    }
    const { 
        firstName, 
        lastName, 
        email, 
        password, 
        location, 
        qualifications, 
        skills, 
        jobTitle, 
        category, 
        bio, 
        classLevel, 
        subjects, 
        socialLinks,
        fieldOfStudy 
      } = req.body;
    
      if (!firstName || !lastName || !email || !password || !location || !qualifications || !skills || !jobTitle || !category || !classLevel || !subjects ||
          (['Bachelors', 'Masters'].includes(category) && !fieldOfStudy)) {
        return res.status(400).json({ msg: 'Please enter all required fields' });
      }
    
      try {
        let user = await User.findOne({ email });
        if (user) {
          return res.status(400).json({ msg: 'User already exists' });
        }

        const hashedPassword = await bcrypt.hash(password, 10);
        const certificateUrls = req.files?.certificates ? req.files.certificates.map(file => file.path) : [];
        const socialLinksObj = socialLinks ? JSON.parse(socialLinks) : {};
        const subjectsArray = Array.isArray(subjects) ? subjects : JSON.parse(subjects);
    
        const newUser = new User({
          firstName,
          lastName,
          email,
          password: hashedPassword,
          role: 'mentor',
          location,
          qualifications,
          skills,
          jobTitle,
          category,
          bio,
          classLevel,
          subjects: subjectsArray,
          fieldOfStudy,
          profilePicture: profilePictureUrl,
          socialLinks: socialLinksObj,
          certificates: certificateUrls,
          verified: false
        });
        await newUser.save();

         // Send waiting for verification email
    sendEmail(email, 'Mentor Registration Pending', 
      `Hello ${firstName},\n\nYour mentor registration has been received. Please wait for admin verification. We will notify you once your account is activated.\n\nThanks,\nNepal Mentors Team`
    );

    res.status(201).json({ msg: 'Mentor registered successfully. Waiting for admin verification.' });
  } catch (err) {
    console.error('Error during registration:', err.message);
    res.status(500).send('Server error');
  }
});

// Admin verification route: verifies mentor and creates MentorProfile
router.put('/verify-mentor/:id', async (req, res) => {
  try {
    const mentorId = req.params.id;
    const user = await User.findById(mentorId);

    if (!user || user.role !== 'mentor') {
      return res.status(404).json({ msg: 'Mentor not found' });
    }

    if (user.verified) {
      return res.status(400).json({ msg: 'Mentor is already verified' });
    }

    user.verified = true;
    await user.save();

     // Create MentorProfile
     const mentorProfile = new MentorProfile({
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
    
    // Send verification success email
    sendEmail(user.email, 'Mentor Verification Successful', 
      `Hello ${user.firstName},\n\nYour mentor profile has been verified successfully. Mentees can now view your profile.\n\nThanks,\nNepal Mentors Team`
    );

    res.json({ msg: 'Mentor verified successfully', mentorProfile });
  } catch (error) {
    console.error('Error verifying mentor:', error);
    res.status(500).json({ msg: 'Server error' });
  }
});

// Ensure necessary folders exist
function ensureFolderExists(folderPath) {
    if (!fs.existsSync(folderPath)) {
        fs.mkdirSync(folderPath, { recursive: true });
    }
}

router.get('/certificates/:filename', (req, res) => {
    const filePath = path.join(__dirname, '../uploads/certificates', req.params.filename);
    if (fs.existsSync(filePath)) {
      const extName = path.extname(filePath).toLowerCase();
      if (extName === '.pdf') {
        res.setHeader('Content-Type', 'application/pdf');
        res.setHeader('Content-Disposition', 'attachment; filename="' + req.params.filename + '"');
      } else if (['.jpg', '.jpeg', '.png'].includes(extName)) {
        res.setHeader('Content-Type', 'image/jpeg');
        res.setHeader('Content-Disposition', 'attachment; filename="' + req.params.filename + '"');
      }
      res.sendFile(filePath);
    } else {
      res.status(404).send('File not found');
    }
  });

  router.get('/view-certificate/:filename', (req, res) => {
    const filePath = path.join(__dirname, '../uploads/certificates', req.params.filename);
    if (fs.existsSync(filePath)) {
      const extName = path.extname(filePath).toLowerCase();
      if (extName === '.pdf') {
        res.setHeader('Content-Type', 'application/pdf');
        res.setHeader('Content-Disposition', 'inline; filename="' + req.params.filename + '"');
        return res.sendFile(filePath);
      } else if (['.jpg', '.jpeg', '.png'].includes(extName)) {
        res.setHeader('Content-Type', 'image/jpeg');
        res.setHeader('Content-Disposition', 'inline; filename="' + req.params.filename + '"');
        return res.sendFile(filePath);
      }
    } else {
      res.status(404).send('File not found');
    }
  });

  router.use((err, req, res, next) => {
    if (err.name === 'MulterError') {
      return res.status(400).json({ msg: err.message });
    }
    if (err) {
      return res.status(500).json({ msg: err.message });
    }
    next();
  });

  function sendEmail(to, subject, text) {
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
    transporter.sendMail(mailOptions, (error, info) => {
      if (error) {
        console.error('Error sending email:', error);
      } else {
        console.log('Email sent:', info.response);
      }
    });
  }
  
  
  
  module.exports = router;
