import 'package:flutter/material.dart';
import 'common_bottom_navigation.dart';
import 'mentor_search_page.dart'; // Ensure MentorSearchPage is defined in your project.

/// SecondaryLevelHome displays a list of Secondary level grades.
/// Tapping on a grade navigates to SecondaryGradeSubjectsNavigationPage.
class SecondaryLevelHome extends StatelessWidget {
  const SecondaryLevelHome({Key? key}) : super(key: key);

  // Map of secondary grades to their subjects.
  static const Map<String, List<String>> gradeSubjects = {
    'Grade 9': [
      'English',
      'Mathematics',
      'Science',
      'Social Studies',
      'Nepali',
      'Computer',
      'Optional Mathematics',
      'Account',
      'Biology',
      'Physics'
    ],
    'Grade 10': [
      'English',
      'Mathematics',
      'Science',
      'Social Studies',
      'Nepali',
      'Computer',
      'Optional Mathematics',
      'Account',
      'Biology',
      'Physics'
    ],
    'Grade 11': [
      'English',
      'Mathematics',
      'Science',
      'Nepali',
      'Computer',
      'Optional Mathematics',
      'Account',
      'Economics',
      'Political Science',
      'Business Studies'
    ],
    'Grade 12': [
      'English',
      'Mathematics',
      'Science',
      'Nepali',
      'Computer',
      'Optional Mathematics',
      'Account',
      'Economics',
      'Political Science',
      'Business Studies'
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
                    // Navigate to the SecondaryGradeSubjectsNavigationPage,
                    // which uses CommonBottomNavigation in section mode.
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SecondaryGradeSubjectsNavigationPage(
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

/// SecondaryGradeSubjectsContent displays the list of subjects for a selected secondary grade.
class SecondaryGradeSubjectsContent extends StatelessWidget {
  final String grade;
  final List<String> subjects;

  const SecondaryGradeSubjectsContent({
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
                        category: "Secondary Level",
                        classLevel: apiClassLevel,
                        subject: subject,
                      ),
                    ),
                  );
                },
                child: SecondaryLevelHome.buildCard(subject),
              ),
              if (index < subjects.length - 1) Divider(color: Colors.grey[300]),
            ],
          );
        },
      ),
    );
  }
}

/// SecondaryGradeSubjectsNavigationPage wraps the grade subjects content in CommonBottomNavigation
/// using section mode. The bottom navigation always remains the same global set of 4 items.
/// Initially, the body displays the custom section content (subjects list) with the custom title.
/// Once the user taps any bottom navigation item, section mode is disabled.
class SecondaryGradeSubjectsNavigationPage extends StatelessWidget {
  final String grade;
  final List<String> subjects;

  const SecondaryGradeSubjectsNavigationPage({
    Key? key,
    required this.grade,
    required this.subjects,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CommonBottomNavigation(
      sectionContent:
          SecondaryGradeSubjectsContent(grade: grade, subjects: subjects),
      sectionTitle: '$grade Subjects',
      startWithSectionContent: true,
    );
  }
}

/// SecondaryLevelPage uses CommonBottomNavigation in section mode so that by default
/// the Secondary Level content (grade list) is shown with a custom title.
/// The bottom navigation always remains the same global set of 4 items.
class SecondaryLevelPage extends StatelessWidget {
  const SecondaryLevelPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CommonBottomNavigation(
      sectionContent: const SecondaryLevelHome(),
      sectionTitle: 'Secondary Level',
      startWithSectionContent: true,
    );
  }
}
