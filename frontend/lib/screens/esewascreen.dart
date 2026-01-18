/*import 'package:nepalmentors/function/esewa.dart';
import 'package:flutter/material.dart';

class EsewaScreen extends StatelessWidget {
  const EsewaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Gateway'),
        backgroundColor: Colors.teal,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center, // Center content
          children: [
            const SizedBox(height: 50), // Moves content slightly up
            // Centered Heading
            Center(
              child: Text(
                'E-Sewa Payment',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade700, // Softer teal
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Payment Description (Centered & in 3 lines)
            const Center(
              child: Text(
                'To confirm your participation in the selected community time slot,\n'
                'please complete the payment first. \n'
                'Proceed securely with E-Sewa by clicking the button below.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  height: 1.5, // Adjusts line spacing
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Payment Button
            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade600, // Softer teal
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2, // Slight shadow for better UI
                ),
                icon: const Icon(Icons.payment, size: 26),
                label: const Text('Proceed to Payment'),
                onPressed: () {
                  Esewa esewa = Esewa();
                  esewa.pay();
                },
              ),
            ),
            const SizedBox(height: 16),
            // Screenshot Reminder
            Center(
              child: Text(
                '⚠️ Please take a screenshot after payment for reference.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}*/