import 'package:flutter/material.dart';
import 'common_bottom_navigation.dart';
import 'mentor_search_page.dart'; // Ensure MentorSearchPage is defined in this file.

/// PrimaryLevelHome displays a list of Primary level grades.
/// Tapping a grade navigates to GradeSubjectsNavigationPage.
class PrimaryLevelHome extends StatelessWidget {
  const PrimaryLevelHome({Key? key}) : super(key: key);

  // Map of grades to their subjects.
  static const Map<String, List<String>> gradeSubjects = {
    'Grade 4': [
      'English',
      'Mathematics',
      'Science',
      'Social Studies',
      'Nepali',
      'Computer'
    ],
    'Grade 5': [
      'English',
      'Mathematics',
      'Science',
      'Social Studies',
      'Nepali',
      'Computer'
    ],
    'Grade 6': [
      'English',
      'Mathematics',
      'Science',
      'Social Studies',
      'Nepali',
      'Computer'
    ],
    'Grade 7': [
      'English',
      'Mathematics',
      'Science',
      'Social Studies',
      'Nepali',
      'Computer'
    ],
    'Grade 8': [
      'English',
      'Mathematics',
      'Science',
      'Social Studies',
      'Nepali',
      'Computer',
      'Optional Mathematics',
      'Account'
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
          itemCount: gradeSubjects.keys.length,
          itemBuilder: (context, index) {
            String grade = gradeSubjects.keys.elementAt(index);
            return Column(
              children: [
                GestureDetector(
                  onTap: () {
                    // Navigate to the GradeSubjectsNavigationPage,
                    // which uses CommonBottomNavigation in section mode.
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GradeSubjectsNavigationPage(
                          grade: grade,
                          subjects: gradeSubjects[grade]!,
                        ),
                      ),
                    );
                  },
                  child: buildCard(grade),
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

/// GradeSubjectsContent displays the list of subjects for a selected grade.
class GradeSubjectsContent extends StatelessWidget {
  final String grade;
  final List<String> subjects;

  const GradeSubjectsContent({
    Key? key,
    required this.grade,
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
          // Convert "Grade" to "Class" if needed.
          String apiClassLevel = grade.startsWith("Grade")
              ? grade.replaceFirst("Grade", "Class").trim()
              : grade;
          return Column(
            children: [
              GestureDetector(
                onTap: () {
                  // Navigate to MentorSearchPage for the selected subject.
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MentorSearchPage(
                        category: "Primary Level",
                        classLevel: apiClassLevel,
                        subject: subject,
                      ),
                    ),
                  );
                },
                child: PrimaryLevelHome.buildCard(subject),
              ),
              if (index < subjects.length - 1) Divider(color: Colors.grey[300]),
            ],
          );
        },
      ),
    );
  }
}

/// GradeSubjectsNavigationPage wraps the grade subjects content in CommonBottomNavigation
/// using section mode. The bottom navigation remains the same global set of 4 items.
/// Initially, the body displays the custom section content (grade subjects) with the custom title.
/// Once the user taps any bottom navigation item, section mode is disabled.
class GradeSubjectsNavigationPage extends StatelessWidget {
  final String grade;
  final List<String> subjects;

  const GradeSubjectsNavigationPage({
    Key? key,
    required this.grade,
    required this.subjects,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CommonBottomNavigation(
      sectionContent: GradeSubjectsContent(grade: grade, subjects: subjects),
      sectionTitle: '$grade Subjects',
      startWithSectionContent: true,
    );
  }
}

/// PrimaryLevelPage uses CommonBottomNavigation in section mode so that by default
/// the Primary Level content (grade list) is shown with a custom title.
/// The bottom navigation always remains the same global set of 4 items.
class PrimaryLevelPage extends StatelessWidget {
  const PrimaryLevelPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CommonBottomNavigation(
      sectionContent: const PrimaryLevelHome(),
      sectionTitle: 'Primary Level',
      startWithSectionContent: true,
    );
  }
}