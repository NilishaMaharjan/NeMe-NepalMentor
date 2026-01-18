import 'package:flutter/material.dart';
import 'common_bottom_navigation.dart';
import 'mentor_search_page.dart'; // Ensure MentorSearchPage is defined

/// DiplomaLevelHome displays a list of Diploma courses.
/// Tapping on a course navigates to DiplomaGradeSubjectsNavigationPage.
class DiplomaLevelHome extends StatelessWidget {
  const DiplomaLevelHome({Key? key}) : super(key: key);

  // Map of Diploma courses to their subjects.
  static const Map<String, List<String>> gradeSubjects = {
    'Diploma 1': [
      'English',
      'Mathematics',
      'Engineering Graphics',
      'Fundamentals of Engineering',
      'Workshop Practices'
    ],
    'Diploma 2': [
      'Mathematics',
      'Physics',
      'Thermodynamics',
      'Materials Science',
      'Electrical Fundamentals'
    ],
    'Diploma 3': [
      'Mathematics',
      'Control Systems',
      'Mechanics of Machines',
      'Electronics',
      'Project Management'
    ],
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
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: Colors.teal,
            ),
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
          itemCount: gradeSubjects.keys.length,
          itemBuilder: (context, index) {
            String course = gradeSubjects.keys.elementAt(index);
            return Column(
              children: [
                GestureDetector(
                  onTap: () {
                    // Navigate to the DiplomaGradeSubjectsNavigationPage,
                    // which uses CommonBottomNavigation in section mode.
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            DiplomaGradeSubjectsNavigationPage(
                          grade: course,
                          subjects: gradeSubjects[course]!,
                        ),
                      ),
                    );
                  },
                  child: buildCard(course),
                ),
                if (index < gradeSubjects.keys.length - 1)
                  Divider(color: Colors.grey[300]),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// DiplomaGradeSubjectsContent displays the list of subjects for a selected Diploma course.
class DiplomaGradeSubjectsContent extends StatelessWidget {
  final String grade;
  final List<String> subjects;

  const DiplomaGradeSubjectsContent({
    Key? key,
    required this.grade,
    required this.subjects,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // You might not need to convert "Diploma" to "Class" here,
    // so we simply use the grade as provided.
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
                  // Navigate to MentorSearchPage for the selected subject.
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MentorSearchPage(
                        category: "Diploma",
                        classLevel: grade, // Pass the diploma course as is.
                        subject: subject,
                      ),
                    ),
                  );
                },
                child: DiplomaLevelHome.buildCard(subject),
              ),
              if (index < subjects.length - 1) Divider(color: Colors.grey[300]),
            ],
          );
        },
      ),
    );
  }
}

/// DiplomaGradeSubjectsNavigationPage wraps the Diploma subjects content in CommonBottomNavigation
/// using section mode. It displays a custom title (e.g. "Diploma 1 Subjects") along with the subjects list.
/// Once the user taps any bottom navigation item, section mode is disabled.
class DiplomaGradeSubjectsNavigationPage extends StatelessWidget {
  final String grade;
  final List<String> subjects;

  const DiplomaGradeSubjectsNavigationPage({
    Key? key,
    required this.grade,
    required this.subjects,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CommonBottomNavigation(
      sectionContent:
          DiplomaGradeSubjectsContent(grade: grade, subjects: subjects),
      sectionTitle: '$grade Subjects',
      startWithSectionContent: true,
    );
  }
}

/// DiplomaLevelPage wraps the DiplomaLevelHome in CommonBottomNavigation in section mode.
/// This displays the Diploma course list with the custom title "Diploma Level".
class DiplomaLevelPage extends StatelessWidget {
  const DiplomaLevelPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CommonBottomNavigation(
      sectionContent: const DiplomaLevelHome(),
      sectionTitle: 'Diploma Level',
      startWithSectionContent: true,
    );
  }
}