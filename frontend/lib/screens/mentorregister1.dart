import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
// import 'package:permission_handler/permission_handler.dart';
import 'conf_ip.dart';

class MentorRegistrationAndAdditionalInfo extends StatefulWidget {
  const MentorRegistrationAndAdditionalInfo({super.key});

  @override
  MentorRegistrationAndAdditionalInfoState createState() =>
      MentorRegistrationAndAdditionalInfoState();
}

class MentorRegistrationAndAdditionalInfoState
    extends State<MentorRegistrationAndAdditionalInfo> {
  final _formKey = GlobalKey<FormState>();
  List<String> categories = ['Please Select'];
  List<String> fields = [];
  List<String> classLevels = [];
  List<String> subjects = [];
  List<String> selectedSubjects = [];

  File? _profileImage;
  List<File> _certificateFiles = []; // List to store selected certificate files
  final ImagePicker _picker = ImagePicker();

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController qualificationsController =
      TextEditingController();
  final TextEditingController skillsController = TextEditingController();
  final TextEditingController jobTitleController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  List<Map<String, TextEditingController>> socialLinksControllers = [];
  String selectedCategory = 'Please Select';
  String? selectedField;
  String? selectedClassLevel;
  String? selectedSubject;

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    fetchCategories();
    // requestPermissions();
  }

  // Future<void> requestPermissions() async {
  //   final status = await Permission.storage.request();
  //   if (status.isGranted) {
  //     print('Storage permission granted');
  //   } else if (status.isDenied) {
  //     print('Storage permission denied');
  //   } else if (status.isPermanentlyDenied) {
  //     print('Storage permission permanently denied');
  //     openAppSettings(); // Open app settings to allow the user to enable it
  //   }
  // }

  Future<void> fetchCategories() async {
    String apiUrl =
        '$baseUrl/api/mentorregister/categories';
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          categories = ['Please Select', ...data.keys];
        });
      } else {
        print('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  Future<void> fetchFields(String category) async {
    final String apiUrl =
        '$baseUrl/api/mentorregister/fields/$category';
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          fields = ['Please Select', ...data['fields'].keys];
        });
      } else {
        print('Failed to load fields: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching fields: $e');
    }
  }

  Future<void> fetchClassLevels(String category, {String? field}) async {
    if ((category == 'Bachelors' || category == 'Masters') && field == null) {
      // Don't fetch class levels if field is not selected for Bachelors/Masters
      setState(() {
        classLevels = [];
      });
      return;
    }
    final String apiUrl = field == null
        ? '$baseUrl/api/mentorregister/classlevels/$category'
        : '$baseUrl/api/mentorregister/classlevels/$category/$field';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          classLevels = [
            'Please Select',
            ...List<String>.from(data['classLevels'])
          ];
        });
      } else {
        print('Failed to load class levels: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching class levels: $e');
    }
  }

  Future<void> fetchSubjects(
      String category, String field, String classLevel) async {
    final url = Uri.parse(
        '$baseUrl/api/mentorregister/subjects/$category/$field/$classLevel');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          // Use only the subjects returned from the backend
          subjects = List<String>.from(data['subjects']);
          // Optionally, reset the selectedSubjects list if needed:
          selectedSubjects = [];
        });
      } else {
        print('Failed to fetch subjects');
      }
    } catch (e) {
      print('Error fetching subjects: $e');
    }
  }

  // Function to handle adding a new social media link input
  void addSocialLinkField() {
    setState(() {
      socialLinksControllers.add({
        'platform': TextEditingController(),
        'link': TextEditingController(),
      });
    });
  }

  // Function to pick a profile image
  Future<void> pickProfileImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> pickCertificates() async {
    print('Select Certificates button clicked');
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'], // Allowed file types
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
// Append the newly selected files to the existing list
          _certificateFiles
              .addAll(result.paths.map((path) => File(path!)).toList());
        });
        print('Selected certificates: ${result.paths}');
      } else {
        print('No certificates selected.');
      }
    } catch (e) {
      print('Error picking certificates: $e');
    }
  }

  Future<void> submitMentorData() async {
    final firstName = firstNameController.text;
    final lastName = lastNameController.text;
    final email = emailController.text;
    final password = passwordController.text;
    final location = locationController.text;
    final qualifications = qualificationsController.text;
    final skills = skillsController.text;
    final jobTitle = jobTitleController.text;
    final category = selectedCategory;
    final bio = bioController.text;
    final classLevel = selectedClassLevel ?? '';
    final subjectList = selectedSubjects;
    final field = selectedField ?? ''; // Ensure field is not null

    List<Map<String, String>> socialLinks = [];
    for (var controller in socialLinksControllers) {
      final platform = controller['platform']?.text ?? '';
      final link = controller['link']?.text ?? '';
      if (platform.isNotEmpty && link.isNotEmpty) {
        socialLinks.add({'platform': platform, 'link': link});
      }
    }

    var data = {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'password': password,
      'location': location,
      'qualifications': qualifications,
      'skills': skills,
      'jobTitle': jobTitle,
      'category': category,
      'bio': bio,
      'classLevel': classLevel,
      'subjects': jsonEncode(subjectList), // Send as JSON array
      'fieldOfStudy': field, // Add the field of study explicitly
      'socialLinks': jsonEncode(socialLinks), // Pass social links as JSON
    };

    print('Submitting data: $data');

    try {
      var uri = Uri.parse('$baseUrl/api/mentorregister/mentor');
      var request = http.MultipartRequest('POST', uri);
      data.forEach((key, value) {
        request.fields[key] = value;
      });

      // Add the profile picture if selected
      if (_profileImage != null) {
        var profileImageBytes = await _profileImage!.readAsBytes();
        String fileExtension =
            _profileImage!.path.split('.').last.toLowerCase();
        String mimeType = '';

        // Dynamically assign the mime type based on file extension
        if (fileExtension == 'png') {
          mimeType = 'image/png';
        } else if (fileExtension == 'jpeg' || fileExtension == 'jpg') {
          mimeType = 'image/jpeg';
        } else {
          // Default or error handling if unsupported file type is uploaded
          throw Exception(
              'Unsupported file type. Only PNG and JPEG are allowed.');
        }

        request.files.add(
          http.MultipartFile.fromBytes(
            'profilePicture', // This matches the backend key
            profileImageBytes,
            filename: _profileImage!.path.split('/').last,
            contentType: MediaType.parse(mimeType), // Dynamically set mime type
          ),
        );
      } else {
        print('No profile picture provided, using default');
        String defaultProfileImagePath = 'uploads/profilePictures/default.png';
        // Send the default image path to the backend (backend will handle this)
        request.fields['profilePicture'] = defaultProfileImagePath;
      }
      //Add certificates
      if (_certificateFiles.isNotEmpty) {
        for (var certificate in _certificateFiles) {
          var certificateBytes = await certificate.readAsBytes();
          String fileExtension = certificate.path.split('.').last.toLowerCase();
          String mimeType = fileExtension == 'pdf'
              ? 'application/pdf'
              : fileExtension == 'png'
                  ? 'image/png'
                  : 'image/jpeg';

          request.files.add(
            http.MultipartFile.fromBytes(
              'certificates', // Field name matches backend
              certificateBytes,
              filename: certificate.path.split('/').last,
              contentType: MediaType.parse(mimeType),
            ),
          );
        }
      }

      var response = await request.send();
      print('Response status: ${response.statusCode}');
      print('Response body: ${await response.stream.bytesToString()}');

      if (response.statusCode == 201) {
        Get.snackbar('Success', 'Your mentor registration has been submitted!');
      } else {
        Get.snackbar('Error', 'Failed to submit information. Try again later.');
      }
    } catch (e) {
      Get.snackbar('Error', 'An unexpected error occurred: $e');
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mentor Registration',
          style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              GestureDetector(
                onTap: pickProfileImage,
                child: _profileImage == null
                    ? Container(
                        height: 150,
                        width: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: const Icon(
                          Icons.add_a_photo,
                          color: Colors.grey,
                          size: 50,
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.file(
                          _profileImage!,
                          width: 150,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
              buildUniformGap(),
              buildTextFormField('First Name', firstNameController),
              buildUniformGap(),
              buildTextFormField('Last Name', lastNameController),
              buildUniformGap(),
              buildTextFormField('Email', emailController),
              buildUniformGap(),
              buildPasswordFormField(),
              buildUniformGap(),
              buildTextFormField('Location', locationController),
              buildUniformGap(),
              buildTextFormField('Qualification', qualificationsController),
              buildUniformGap(),
              buildTextFormField('Skills (comma-separated)', skillsController),
              buildUniformGap(),
              buildTextFormField('Job Title', jobTitleController),
              buildUniformGap(),
              buildCategoryDropdown(),
              buildUniformGap(),
              if (selectedCategory == 'Bachelors' ||
                  selectedCategory == 'Masters')
                buildFieldDropdown(),
              buildUniformGap(),
              buildClassLevelDropdown(),
              buildUniformGap(),
              if (selectedClassLevel != null) buildSubjectMultiSelect(),
              buildUniformGap(),

              buildBioField(),
              buildUniformGap(),
              // Display dynamic social media fields
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Social Media Links',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(
                      height:
                          8.0), // Space between the title and the first link
                  if (socialLinksControllers.isNotEmpty)
                    for (int i = 0; i < socialLinksControllers.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: socialLinksControllers[i]
                                    ['platform'],
                                decoration: const InputDecoration(
                                  labelText: 'Platform',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: socialLinksControllers[i]['link'],
                                decoration: const InputDecoration(
                                  labelText: 'Link',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  const SizedBox(
                      height: 8.0), // Add space after the last link field
                  TextButton(
                    onPressed: addSocialLinkField,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Text(
                      'Add Social Media Link',
                      style: TextStyle(
                        fontSize: 16.0,
                        color: Colors.teal,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
              // Profile image picker section

              buildUniformGap(),
              buildCertificateUploadSection(), // Certificates upload
              buildUniformGap(),

              buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildUniformGap({double height = 16.0}) => SizedBox(height: height);

  Widget buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedCategory,
      decoration: const InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.teal, width: 2.0),
        ),
      ),
      items: categories.map((value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            selectedCategory = newValue;
            selectedField = null;
            selectedClassLevel = null;
            classLevels = [];
            fields = [];
          });
          if (['Bachelors', 'Masters'].contains(newValue)) {
            fetchFields(newValue);
          } else {
            fetchClassLevels(newValue);
          }
        }
      },
      validator: (value) {
        if (value == null || value == 'Please Select') {
          return 'Please select a category';
        }
        return null;
      },
    );
  }

  Widget buildFieldDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedField,
      decoration: const InputDecoration(
        labelText: 'Field',
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.teal, width: 2.0),
        ),
      ),
      items: fields.map((value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          selectedField = newValue;
          selectedClassLevel = null;
          classLevels = [];
        });
        if (newValue != null) {
          fetchClassLevels(selectedCategory, field: newValue);
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a field';
        }
        return null;
      },
    );
  }

  Widget buildClassLevelDropdown() {
    final isBachelorsOrMasters =
        selectedCategory == 'Bachelors' || selectedCategory == 'Masters';

    return DropdownButtonFormField<String>(
      value: selectedClassLevel,
      decoration: const InputDecoration(
        labelText: 'Class Level',
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.teal, width: 2.0),
        ),
      ),
      items: classLevels.map((value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: isBachelorsOrMasters && selectedField == null
          ? null // Disable class level dropdown if field is not selected for Bachelors/Masters
          : (String? newValue) {
              setState(() {
                selectedClassLevel = newValue;
                selectedSubject =
                    null; // Reset subject when class level changes
                subjects = [];
              });
              if (newValue != null) {
                if (isBachelorsOrMasters) {
                  fetchSubjects(
                      selectedCategory, selectedField ?? '', newValue);
                } else {
                  fetchSubjects(selectedCategory, 'General', newValue);
                }
              }
            },
      validator: (value) {
        if (value == null || value == 'Please Select') {
          return 'Please select a class level';
        }
        return null;
      },
    );
  }

  Widget buildSubjectMultiSelect() {
    return MultiSelectDialogField(
      initialValue:
          selectedSubjects, // ensures previously selected subjects remain checked
      items:
          subjects.map((subject) => MultiSelectItem(subject, subject)).toList(),
      title: const Text("Subjects"),
      selectedColor: Colors.teal,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey,
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      buttonText: const Text(
        "Select Subjects",
        style: TextStyle(fontSize: 16),
      ),
      buttonIcon: const Icon(
        Icons.arrow_drop_down_circle,
        size: 24,
        color: Colors.grey,
      ),
      onConfirm: (values) {
        setState(() {
          selectedSubjects = List<String>.from(values);
        });
        // Optional: Print selected subjects for debugging
        print("Selected subjects: $selectedSubjects");
      },
      chipDisplay: MultiSelectChipDisplay(
        chipColor: Colors.teal,
        textStyle: const TextStyle(color: Colors.white),
        onTap: (value) {
          setState(() {
            selectedSubjects.remove(value);
          });
        },
      ),
      validator: (values) {
        if (values == null || values.isEmpty) {
          return 'Please select at least one subject';
        }
        return null;
      },
    );
  }

  // Function to build the certificate upload section
  Widget buildCertificateUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upload Certificates',
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12.0),
        GestureDetector(
          onTap: pickCertificates,
          child: Container(
            padding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey, width: 2.0),
              borderRadius: BorderRadius.circular(12.0),
              gradient: LinearGradient(
                colors: [Colors.grey.shade200, Colors.grey.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.file_upload,
                      color: Colors.black54,
                      size: 24.0,
                    ),
                    const SizedBox(width: 10.0),
                    const Text(
                      'Select Certificates',
                      style: TextStyle(
                        fontSize: 15.0,
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Icon(Icons.arrow_drop_down, size: 24, color: Colors.grey),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16.0),
        if (_certificateFiles.isNotEmpty)
          Container(
            padding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, width: 1.5),
              borderRadius: BorderRadius.circular(10.0),
              color: Colors.grey.shade100,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selected Files:',
                  style: TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const Divider(color: Colors.black54),
                const SizedBox(height: 8.0),
                ..._certificateFiles.map((file) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      children: [
                        Icon(
                          file.path.endsWith('.pdf')
                              ? Icons.picture_as_pdf
                              : Icons.image,
                          color: Colors.black54,
                          size: 24.0,
                        ),
                        const SizedBox(width: 10.0),
                        Expanded(
                          child: Text(
                            file.path.split('/').last,
                            style: const TextStyle(
                              fontSize: 14.0,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete,
                            color: Colors.red.shade300,
                            size: 20.0,
                          ),
                          onPressed: () {
                            setState(() {
                              _certificateFiles.remove(file);
                            });
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          )
        else
          const Text(
            'No certificates selected.',
            style: TextStyle(
              fontSize: 14.0,
              color: Colors.black54,
            ),
          ),
      ],
    );
  }

  Widget buildTextFormField(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.teal, width: 2.0),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }

  Widget buildPasswordFormField() {
    return TextFormField(
      controller: passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: 'Password',
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.teal, width: 2.0),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.teal,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a password';
        }
        return null;
      },
    );
  }

  Widget buildBioField() {
    return TextFormField(
      controller: bioController,
      minLines: 1,
      maxLines: null,
      decoration: const InputDecoration(
        labelText: 'Bio',
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.teal, width: 2.0),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a bio';
        }
        return null;
      },
    );
  }

  Widget buildSubmitButton() {
    return ElevatedButton(
      onPressed: () {
        if (_formKey.currentState!.validate()) {
          submitMentorData();
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal,
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      child: const Text(
        'Submit',
        style: TextStyle(fontSize: 18.0),
      ),
    );
  }
}