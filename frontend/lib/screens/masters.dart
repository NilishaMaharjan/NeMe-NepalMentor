import 'package:flutter/material.dart';
import 'common_bottom_navigation.dart';
import 'mentor_search_page.dart'; // Ensure MentorSearchPage is defined

/// MastersLevelHome displays a list of Masters programs.
class MastersLevelHome extends StatelessWidget {
  const MastersLevelHome({Key? key}) : super(key: key);

  // Data structure for Masters programs.
  static const mastersPrograms = {
    "Computer Science": {
      "Year 1": ["Machine Learning", "Artificial Intelligence", "Data Mining"],
      "Year 2": ["Big Data Analytics", "Cloud Computing"]
    },
    "Medicine": {
      "Year 1": ["Clinical Practice", "Pharmacology", "Pathophysiology"],
      "Year 2": ["Medical Ethics", "Community Medicine"]
    },
    "Law": {
      "Year 1": ["Judicial Review", "International Law", "Legal Theory"],
      "Year 2": ["Constitutional Rights", "Human Rights Law"]
    },
    "Psychology": {
      "Year 1": ["Behavioral Therapy", "Cognitive Science", "Psychopathology"],
      "Year 2": ["Clinical Neuropsychology", "Psychological Assessment"]
    },
  };

  /// Reusable card widget.
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
          itemCount: mastersPrograms.keys.length,
          itemBuilder: (context, index) {
            String program = mastersPrograms.keys.elementAt(index);
            return Column(
              children: [
                GestureDetector(
                  onTap: () {
                    // Navigate to MastersProgramPage.
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MastersProgramPage(
                          program: program,
                          years: mastersPrograms[program]!,
                        ),
                      ),
                    );
                  },
                  child: buildCard(program),
                ),
                if (index < mastersPrograms.keys.length - 1)
                  Divider(color: Colors.grey[300]),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// MastersProgramPage displays the list of academic years for the selected Masters program.
/// It wraps its content in CommonBottomNavigation using section mode.
class MastersProgramPage extends StatelessWidget {
  final String program;
  final Map<String, List<String>> years;

  const MastersProgramPage({
    Key? key,
    required this.program,
    required this.years,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CommonBottomNavigation(
      sectionContent: MastersProgramContent(program: program, years: years),
      sectionTitle: '$program - Academic Years',
      startWithSectionContent: true,
    );
  }
}

/// MastersProgramContent displays the list of academic years for a selected program.
class MastersProgramContent extends StatelessWidget {
  final String program;
  final Map<String, List<String>> years;

  const MastersProgramContent({
    Key? key,
    required this.program,
    required this.years,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        itemCount: years.keys.length,
        itemBuilder: (context, index) {
          String year = years.keys.elementAt(index);
          return Column(
            children: [
              GestureDetector(
                onTap: () {
                  // Navigate to the subjects page for the selected academic year.
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MastersYearSubjectsPage(
                        program: program,
                        year: year,
                        subjects: years[year]!,
                      ),
                    ),
                  );
                },
                child: MastersLevelHome.buildCard(year),
              ),
              if (index < years.keys.length - 1)
                Divider(color: Colors.grey[300]),
            ],
          );
        },
      ),
    );
  }
}

/// MastersYearSubjectsPage displays the list of subjects for the selected academic year.
/// It wraps its content in CommonBottomNavigation using section mode.
class MastersYearSubjectsPage extends StatelessWidget {
  final String program;
  final String year;
  final List<String> subjects;

  const MastersYearSubjectsPage({
    Key? key,
    required this.program,
    required this.year,
    required this.subjects,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CommonBottomNavigation(
      sectionContent: MastersYearSubjectsContent(
        program: program,
        year: year,
        subjects: subjects,
      ),
      sectionTitle: '$year Subjects',
      startWithSectionContent: true,
    );
  }
}

/// MastersYearSubjectsContent displays the list of subjects for the selected academic year.
/// Tapping a subject navigates to MentorSearchPage.
class MastersYearSubjectsContent extends StatelessWidget {
  final String program;
  final String year;
  final List<String> subjects;

  const MastersYearSubjectsContent({
    Key? key,
    required this.program,
    required this.year,
    required this.subjects,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // For API purposes, we use "Masters" as the classLevel.
    String apiClassLevel = "Masters";
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MentorSearchPage(
                        category: program, // using program as fieldOfStudy
                        fieldOfStudy: program,
                        classLevel: year,
                        subject: subject,
                      ),
                    ),
                  );
                },
                child: MastersLevelHome.buildCard(subject),
              ),
              if (index < subjects.length - 1) Divider(color: Colors.grey[300]),
            ],
          );
        },
      ),
    );
  }
}

/// MastersLevelPage is the entry point for the Masters section.
/// It wraps MastersLevelHome in CommonBottomNavigation using section mode.
class MastersLevelPage extends StatelessWidget {
  const MastersLevelPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CommonBottomNavigation(
      sectionContent: const MastersLevelHome(),
      sectionTitle: 'Masters Level',
      startWithSectionContent: true,
    );
  }
}