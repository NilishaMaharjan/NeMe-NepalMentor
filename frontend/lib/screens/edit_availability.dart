import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'conf_ip.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ViewAvailabilityScreen extends StatefulWidget {
  const ViewAvailabilityScreen({super.key});

  @override
  State<ViewAvailabilityScreen> createState() => _ViewAvailabilityScreenState();
}

class _ViewAvailabilityScreenState extends State<ViewAvailabilityScreen> {
  // Store slots as objects with _id, time, price, and type.
  List<dynamic> slots = [];
  bool isLoading = true;
  String? userId;

  // Values for adding new slots.
  String? selectedStartTime;
  String? selectedStartPeriod = "AM";
  String? selectedEndTime;
  String? selectedEndPeriod = "AM";
  final TextEditingController priceController = TextEditingController();
  String selectedSlotType = "Online"; // New attribute for slot type.

  // Fetch userId from SharedPreferences.
  Future<void> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');
    });
    print("Fetched userId: $userId");
  }

  // Fetch availability from the backend.
  Future<void> getAvailability() async {
    if (userId == null) await getUserId();
    if (userId == null) {
      print("Error: userId is null, cannot fetch availability.");
      return;
    }
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/availability/$userId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          slots = data['slots'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Converts a time string and period into minutes since midnight.
  int _convertToMinutes(String time, String period) {
    final parts = time.split(":");
    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]);
    if (period == "AM") {
      if (hour == 12) hour = 0;
    } else {
      if (hour != 12) hour += 12;
    }
    return hour * 60 + minute;
  }

  // Parses the time range from a slot's time string.
  Map<String, int> _parseSlot(String timeString) {
    // Expects a format like "9:00 PM - 10:00 PM"
    List<String> parts = timeString.split('-');
    if (parts.length != 2) return {'start': 0, 'end': 0};
    String startPart = parts[0].trim();
    String endPart = parts[1].trim();
    List<String> startComponents = startPart.split(' ');
    List<String> endComponents = endPart.split(' ');
    if (startComponents.length < 2 || endComponents.length < 2)
      return {'start': 0, 'end': 0};
    int startMinutes =
        _convertToMinutes(startComponents[0], startComponents[1]);
    int endMinutes = _convertToMinutes(endComponents[0], endComponents[1]);
    return {'start': startMinutes, 'end': endMinutes};
  }

  // Add a new slot.
  Future<void> addSlot() async {
    if (userId == null) await getUserId();
    if (userId == null ||
        selectedStartTime == null ||
        selectedEndTime == null ||
        priceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select times and enter a price')),
      );
      return;
    }
    int newStart = _convertToMinutes(selectedStartTime!, selectedStartPeriod!);
    int newEnd = _convertToMinutes(selectedEndTime!, selectedEndPeriod!);

    if (newEnd <= newStart) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time.')),
      );
      return;
    }
    int diff = newEnd - newStart;
    if (diff < 60) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Time slot should be at least one hour long.')),
      );
      return;
    }
    if (diff > 180) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Time slot should not exceed three hours.')),
      );
      return;
    }

    // Check for overlapping slots.
    for (var slot in slots) {
      Map<String, int> existing = _parseSlot(slot['time'] ?? "");
      int existStart = existing['start']!;
      int existEnd = existing['end']!;
      if (newStart < existEnd && existStart < newEnd) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'New slot overlaps with existing slot: ${slot['time']}')),
        );
        return;
      }
    }
    final newSlotTime =
        "$selectedStartTime $selectedStartPeriod - $selectedEndTime $selectedEndPeriod";
    final newSlotPrice = int.tryParse(priceController.text.trim());
    if (newSlotPrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Price must be a valid number')),
      );
      return;
    }
    final newSlot = {
      "time": newSlotTime,
      "price": newSlotPrice,
      "type": selectedSlotType, // New attribute sent to backend.
    };

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/availability/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'slots': [newSlot]
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New slot added successfully')),
        );
        setState(() {
          // Update slots with the server response.
          slots = responseData['availability']['slots'];
          selectedStartTime = null;
          selectedEndTime = null;
          selectedStartPeriod = "AM";
          selectedEndPeriod = "AM";
          priceController.clear();
          selectedSlotType = "Online";
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to add slot, please try again.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error adding slot')),
      );
    }
  }

  // Update an existing slot.
  Future<void> updateSlot(
      Map slot, String newTime, int newPrice, String newType) async {
    if (userId == null || newTime.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Slot is empty')),
      );
      return;
    }
    String slotId = slot['_id'].toString();
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/availability/$userId/edit-slot/$slotId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(
            {'newTime': newTime, 'newPrice': newPrice, 'newType': newType}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          int index = slots.indexWhere((s) => s['_id'].toString() == slotId);
          if (index != -1) {
            slots[index]['time'] = newTime;
            slots[index]['price'] = newPrice;
            slots[index]['type'] = newType;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Slot updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update slot')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating slot')),
      );
    }
  }

  // Delete a slot.
  Future<void> deleteSlot(Map slot) async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid user')),
      );
      return;
    }
    String slotId = slot['_id'].toString();
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/availability/$userId/delete-slot/$slotId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        setState(() {
          slots.removeWhere((s) => s['_id'].toString() == slotId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Slot deleted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete slot')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error deleting slot')),
      );
    }
  }

  // Show delete confirmation dialog.
  Future<void> _showDeleteConfirmationDialog(Map slot) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this slot?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                deleteSlot(slot);
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // Show edit dialog with the SlotPicker, price field, and slot type dropdown.
  void _showEditDialog(Map slot) {
    String oldTime = slot['time'] ?? "";
    int oldPrice = slot['price'] ?? 0;
    String oldType = slot['type'] ?? "Online";
    // Split the time string into start and end parts.
    List<String> parts = oldTime.split('-');
    if (parts.length != 2) return;
    final startParts = parts[0].trim().split(' ');
    final endParts = parts[1].trim().split(' ');
    if (startParts.length < 2 || endParts.length < 2) return;
    String initialStartTime = startParts[0];
    String initialStartPeriod = startParts[1];
    String initialEndTime = endParts[0];
    String initialEndPeriod = endParts[1];

    String? editedStartTime = initialStartTime;
    String editedStartPeriod = initialStartPeriod;
    String? editedEndTime = initialEndTime;
    String editedEndPeriod = initialEndPeriod;
    String editedSlotType = oldType;
    final TextEditingController editPriceController =
        TextEditingController(text: oldPrice.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Slot', style: TextStyle(color: Colors.teal)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SlotPicker(
                  initialStartTime: initialStartTime,
                  initialStartPeriod: initialStartPeriod,
                  initialEndTime: initialEndTime,
                  initialEndPeriod: initialEndPeriod,
                  onChanged: (startTime, startPeriod, endTime, endPeriod) {
                    editedStartTime = startTime;
                    editedStartPeriod = startPeriod;
                    editedEndTime = endTime;
                    editedEndPeriod = endPeriod;
                  },
                ),
                const SizedBox(height: 16),
                // New dropdown for slot type.
                DropdownButtonFormField<String>(
                  value: editedSlotType,
                  decoration: const InputDecoration(
                    labelText: 'Slot Type',
                    border: UnderlineInputBorder(),
                  ),
                  items: <String>["Online", "Home Tuition"]
                      .map((type) => DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      editedSlotType = value ?? "Online";
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: editPriceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    hintText: 'Enter slot price',
                    suffixText: '/month',
                    border: UnderlineInputBorder(),
                    helperText: 'Enter the monthly price',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                int newStart =
                    _convertToMinutes(editedStartTime!, editedStartPeriod);
                int newEnd = _convertToMinutes(editedEndTime!, editedEndPeriod);
                if (newEnd <= newStart) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('End time must be after start time.')),
                  );
                  return;
                }
                int diff = newEnd - newStart;
                if (diff < 60) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Time slot should be at least one hour long.')),
                  );
                  return;
                }
                if (diff > 180) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Time slot should not exceed three hours.')),
                  );
                  return;
                }
                // Check for overlapping slots.
                for (var s in slots) {
                  if (s['time'] == oldTime) continue;
                  Map<String, int> existing = _parseSlot(s['time'] ?? "");
                  int existStart = existing['start']!;
                  int existEnd = existing['end']!;
                  if (newStart < existEnd && existStart < newEnd) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'New slot overlaps with existing slot: ${s['time']}')),
                    );
                    return;
                  }
                }
                final newTime =
                    "$editedStartTime $editedStartPeriod - $editedEndTime $editedEndPeriod";
                int? newPrice = int.tryParse(editPriceController.text.trim());
                if (newPrice == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Price must be a valid number')),
                  );
                  return;
                }
                updateSlot(slot, newTime, newPrice, editedSlotType);
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.teal),
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.teal),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    getUserId().then((_) {
      getAvailability();
    });
  }

  @override
  void dispose() {
    priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('View Availability',
            style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Title for adding a new slot.
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text("Add New Slot",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal)),
              ),
              // SlotPicker for time selection.
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SlotPicker(
                  initialStartTime: selectedStartTime,
                  initialStartPeriod: selectedStartPeriod,
                  initialEndTime: selectedEndTime,
                  initialEndPeriod: selectedEndPeriod,
                  onChanged: (startTime, startPeriod, endTime, endPeriod) {
                    setState(() {
                      selectedStartTime = startTime;
                      selectedStartPeriod = startPeriod;
                      selectedEndTime = endTime;
                      selectedEndPeriod = endPeriod;
                    });
                  },
                ),
              ),
              // Price input field.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    hintText: 'Enter slot price',
                    suffixText: '/month',
                    border: UnderlineInputBorder(),
                    helperText: 'Enter the monthly price',
                  ),
                ),
              ),
              // New dropdown for slot type.
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: DropdownButtonFormField<String>(
                  value: selectedSlotType,
                  decoration: const InputDecoration(
                    labelText: 'Slot Type',
                    border: UnderlineInputBorder(),
                  ),
                  items: <String>["Online", "Home Tuition"]
                      .map((type) => DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedSlotType = value ?? "Online";
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: addSlot,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                child: const Text("Add Slot"),
              ),
              // Title for current slots.
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text("Current Slots",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal)),
              ),
              if (isLoading) const Center(child: CircularProgressIndicator()),
              if (!isLoading)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: slots.length,
                  itemBuilder: (context, index) {
                    final slot = slots[index];
                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        title: Text(
                          "${slot['time']}\nPrice: Rs.${slot['price']} /month\nType: ${slot['type']}",
                          style: const TextStyle(
                              color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.teal),
                              onPressed: () => _showEditDialog(slot),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  _showDeleteConfirmationDialog(slot),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A reusable widget that displays two dropdown rows for time selection.
class SlotPicker extends StatefulWidget {
  final String? initialStartTime;
  final String? initialStartPeriod;
  final String? initialEndTime;
  final String? initialEndPeriod;
  final Function(String startTime, String startPeriod, String endTime,
      String endPeriod) onChanged;

  const SlotPicker({
    Key? key,
    this.initialStartTime,
    this.initialStartPeriod = "AM",
    this.initialEndTime,
    this.initialEndPeriod = "AM",
    required this.onChanged,
  }) : super(key: key);

  @override
  _SlotPickerState createState() => _SlotPickerState();
}

class _SlotPickerState extends State<SlotPicker> {
  String? startTime;
  String? startPeriod;
  String? endTime;
  String? endPeriod;

  final List<String> timeOptions = [
    "12:00",
    "12:30",
    "1:00",
    "1:30",
    "2:00",
    "2:30",
    "3:00",
    "3:30",
    "4:00",
    "4:30",
    "5:00",
    "5:30",
    "6:00",
    "6:30",
    "7:00",
    "7:30",
    "8:00",
    "8:30",
    "9:00",
    "9:30",
    "10:00",
    "10:30",
    "11:00",
    "11:30"
  ];

  @override
  void initState() {
    super.initState();
    startTime = widget.initialStartTime;
    startPeriod = widget.initialStartPeriod;
    endTime = widget.initialEndTime;
    endPeriod = widget.initialEndPeriod;
  }

  void _notifyChange() {
    widget.onChanged(
        startTime ?? "", startPeriod ?? "AM", endTime ?? "", endPeriod ?? "AM");
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Start time row.
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: startTime,
                hint: const Text("Start Time"),
                items: timeOptions.map((time) {
                  return DropdownMenuItem<String>(
                    value: time,
                    child: Text(time),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    startTime = value;
                  });
                  _notifyChange();
                },
              ),
            ),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: startPeriod,
              items: ["AM", "PM"].map((period) {
                return DropdownMenuItem<String>(
                  value: period,
                  child: Text(period),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  startPeriod = value;
                });
                _notifyChange();
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        // End time row.
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: endTime,
                hint: const Text("End Time"),
                items: timeOptions.map((time) {
                  return DropdownMenuItem<String>(
                    value: time,
                    child: Text(time),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    endTime = value;
                  });
                  _notifyChange();
                },
              ),
            ),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: endPeriod,
              items: ["AM", "PM"].map((period) {
                return DropdownMenuItem<String>(
                  value: period,
                  child: Text(period),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  endPeriod = value;
                });
                _notifyChange();
              },
            ),
          ],
        ),
      ],
    );
  }
}