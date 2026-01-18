import 'package:flutter/material.dart';
import 'common_bottom_navigation.dart';
import 'mentor_search_page.dart'; // Ensure MentorSearchPage is defined in your project

/// BachelorLevelHome displays a list of bachelor programs.
class BachelorLevelHome extends StatelessWidget {
  const BachelorLevelHome({Key? key}) : super(key: key);

  // Bachelor programs with their semester-subject mappings.
  static const bachelorPrograms = {
    'Computer Engineering': {
      'Semester 1': [
        "Programming Basics",
        "Mathematics",
        "Physics",
        "Engineering Drawing",
        "Basic Electronics"
      ],
      'Semester 2': [
        "Data Structures",
        "Algorithms",
        "Electronics",
        "Discrete Mathematics",
        "Digital Logic"
      ],
      'Semester 3': [
        "Operating Systems",
        "Database Systems",
        "Networks",
        "Object-Oriented Programming",
        "Linear Algebra"
      ],
      'Semester 4': [
        "Computer Architecture",
        "Software Engineering",
        "Computer Networks",
        "Microprocessors",
        "Database Management Systems"
      ],
      'Semester 5': [
        "Web Development",
        "Data Structures and Algorithms",
        "Software Development",
        "Networking Protocols",
        "Computer Graphics"
      ],
      'Semester 6': [
        "Artificial Intelligence",
        "Information Security",
        "Software Testing",
        "Mobile Computing",
        "Cloud Computing"
      ],
      'Semester 7': [
        "Machine Learning",
        "Computer Vision",
        "Embedded Systems",
        "Data Science",
        "Big Data"
      ],
      'Semester 8': [
        "Project Work",
        "Internship",
        "Ethical Hacking",
        "Cyber Security",
        "Data Analytics"
      ]
    },
    'Civil Engineering': {
      'Semester 1': [
        "Engineering Drawing",
        "Mathematics",
        "Physics",
        "Chemistry",
        "Surveying"
      ],
      'Semester 2': [
        "Mechanics",
        "Surveying",
        "Material Science",
        "Fluid Mechanics",
        "Strength of Materials"
      ],
      'Semester 3': [
        "Geotechnical Engineering",
        "Building Materials",
        "Structural Analysis",
        "Concrete Technology",
        "Soil Mechanics"
      ],
      'Semester 4': [
        "Transportation Engineering",
        "Hydrology",
        "Construction Management",
        "Reinforced Concrete Structures",
        "Structural Design"
      ],
      'Semester 5': [
        "Building Construction",
        "Environmental Engineering",
        "Earthquake Engineering",
        "Foundation Engineering",
        "Advanced Surveying"
      ],
      'Semester 6': [
        "Advanced Structural Analysis",
        "Water Resources Engineering",
        "Pavement Design",
        "Bridge Engineering",
        "Geotechnical Engineering"
      ],
      'Semester 7': [
        "Urban Planning",
        "Transportation Systems",
        "Project Management",
        "Hydraulic Structures",
        "Coastal Engineering"
      ],
      'Semester 8': [
        "Project Work",
        "Internship",
        "Construction Planning",
        "Sustainable Development",
        "Disaster Management"
      ]
    },
    'MBBS': {
      'Year 1': [
        "Anatomy",
        "Physiology",
        "Biochemistry",
        "Histology",
        "Microbiology"
      ],
      'Year 2': [
        "Pathology",
        "Pharmacology",
        "Microbiology",
        "Forensic Medicine",
        "Community Medicine"
      ],
      'Year 3': [
        "Surgery",
        "Internal Medicine",
        "Pediatrics",
        "Obstetrics and Gynecology",
        "Ophthalmology"
      ],
      'Year 4': [
        "Orthopedics",
        "Anesthesia",
        "Emergency Medicine",
        "Radiology",
        "Dermatology"
      ],
      'Year 5': [
        "Psychiatry",
        "Neurology",
        "Pediatrics Surgery",
        "Cardiology",
        "Gastroenterology"
      ]
    },
    'Architecture': {
      'Year 1': [
        "Design Basics",
        "History of Architecture",
        "Construction Technology",
        "Environmental Design",
        "Graphics and Drawing"
      ],
      'Year 2': [
        "Urban Planning",
        "Building Materials",
        "Structural Design",
        "Construction Management",
        "Theory of Architecture"
      ],
      'Year 3': [
        "Building Construction",
        "Sustainability in Architecture",
        "Architectural Design",
        "Structures for Architecture",
        "Interior Design"
      ],
      'Year 4': [
        "Building Systems",
        "Lighting Design",
        "Public Buildings",
        "Landscape Design",
        "Smart Cities"
      ],
      'Year 5': [
        "Professional Practice",
        "Architectural Theory",
        "Construction Documentation",
        "Urban Design",
        "Final Project"
      ]
    },
  };

  /// Helper method to build a row-styled card.
  static Widget buildCard(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w400, color: Colors.teal),
          ),
          const Icon(Icons.arrow_forward_ios, size: 20, color: Colors.teal),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The AppBar is provided by CommonBottomNavigation.
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: bachelorPrograms.keys.length,
          itemBuilder: (context, index) {
            String program = bachelorPrograms.keys.elementAt(index);
            return Column(
              children: [
                GestureDetector(
                  onTap: () {
                    // Navigate to the BachelorProgramPage,
                    // which shows the list of semesters.
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BachelorProgramPage(
                          program: program,
                          semesters: bachelorPrograms[program]!,
                        ),
                      ),
                    );
                  },
                  child: buildCard(program),
                ),
                if (index < bachelorPrograms.keys.length - 1)
                  Divider(color: Colors.grey[300]),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// BachelorProgramPage displays the list of semesters for the selected bachelor program.
/// It wraps its content in CommonBottomNavigation in section mode.
class BachelorProgramPage extends StatelessWidget {
  final String program;
  final Map<String, List<String>> semesters;

  const BachelorProgramPage({
    Key? key,
    required this.program,
    required this.semesters,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CommonBottomNavigation(
      sectionContent:
          BachelorProgramContent(program: program, semesters: semesters),
      sectionTitle: '$program - Semesters',
      startWithSectionContent: true,
    );
  }
}

/// BachelorProgramContent displays a list of semesters for a selected program.
class BachelorProgramContent extends StatelessWidget {
  final String program;
  final Map<String, List<String>> semesters;

  const BachelorProgramContent({
    Key? key,
    required this.program,
    required this.semesters,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        itemCount: semesters.keys.length,
        itemBuilder: (context, index) {
          String semester = semesters.keys.elementAt(index);
          return Column(
            children: [
              GestureDetector(
                onTap: () {
                  // Navigate to the BachelorSemesterSubjectsPage.
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BachelorSemesterSubjectsPage(
                        program: program,
                        semester: semester,
                        subjects: semesters[semester]!,
                      ),
                    ),
                  );
                },
                child: BachelorLevelHome.buildCard(semester),
              ),
              if (index < semesters.keys.length - 1)
                Divider(color: Colors.grey[300]),
            ],
          );
        },
      ),
    );
  }
}

/// BachelorSemesterSubjectsPage displays the list of subjects for a selected semester.
/// It wraps its content in CommonBottomNavigation in section mode.
class BachelorSemesterSubjectsPage extends StatelessWidget {
  final String program;
  final String semester;
  final List<String> subjects;

  const BachelorSemesterSubjectsPage({
    Key? key,
    required this.program,
    required this.semester,
    required this.subjects,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CommonBottomNavigation(
      sectionContent: BachelorSemesterSubjectsContent(
        program: program,
        semester: semester,
        subjects: subjects,
      ),
      sectionTitle: '$semester Subjects',
      startWithSectionContent: true,
    );
  }
}

/// BachelorSemesterSubjectsContent displays the list of subjects for the selected semester.
/// Tapping a subject navigates to MentorSearchPage.
class BachelorSemesterSubjectsContent extends StatelessWidget {
  final String program;
  final String semester;
  final List<String> subjects;

  const BachelorSemesterSubjectsContent({
    Key? key,
    required this.program,
    required this.semester,
    required this.subjects,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        itemCount: subjects.length,
        itemBuilder: (context, index) {
          String subject = subjects[index];
          return Column(
            children: [
              GestureDetector(
                onTap: () {
                  // Navigate to MentorSearchPage with parameters:
                  // category: 'Bachelors'
                  // fieldOfStudy: program (e.g., "Computer Engineering")
                  // classLevel: semester (e.g., "Semester 1")
                  // subject: subject
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MentorSearchPage(
                        category: 'Bachelors',
                        fieldOfStudy: program,
                        classLevel: semester,
                        subject: subject,
                      ),
                    ),
                  );
                },
                child: BachelorLevelHome.buildCard(subject),
              ),
              if (index < subjects.length - 1) Divider(color: Colors.grey[300]),
            ],
          );
        },
      ),
    );
  }
}

/// BachelorLevelPage is the entry point for the Bachelor section.
/// It wraps the BachelorLevelHome in CommonBottomNavigation using section mode.
class BachelorLevelPage extends StatelessWidget {
  const BachelorLevelPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CommonBottomNavigation(
      sectionContent: const BachelorLevelHome(),
      sectionTitle: 'Bachelor Level',
      startWithSectionContent: true,
    );
  }
}