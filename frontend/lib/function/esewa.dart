/*import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:esewa_flutter_sdk/esewa_flutter_sdk.dart';
import 'package:esewa_flutter_sdk/esewa_config.dart';
import 'package:esewa_flutter_sdk/esewa_payment.dart';
import 'package:esewa_flutter_sdk/esewa_payment_success_result.dart';
import 'package:nepalmentors/constant/esewa.dart';
import 'package:flutter/material.dart';

class Esewa {
  pay() {
    try {
      EsewaFlutterSdk.initPayment(
        esewaConfig: EsewaConfig(
          environment: Environment.test,
          clientId: kEsewaClientId,
          secretId: kEsewaSecretKey,
        ),
        esewaPayment: EsewaPayment(
          productId: "MentorID",
          productName: "Course per Month",
          productPrice: "3000",
        ),
        onPaymentSuccess: (EsewaPaymentSuccessResult result) {
          debugPrint('SUCCESS');
          verify(result);
        },
        onPaymentFailure: () {
          debugPrint('FAILURE');
        },
        onPaymentCancellation: () {
          debugPrint('CANCEL');
        },
      );
    } catch (e, stackTrace) {
      debugPrint('Exception: $e');
      debugPrint('StackTrace: $stackTrace');
    }
  }

  verify(EsewaPaymentSuccessResult result) async {
    try {
      Dio dio = Dio();
      String basic = 'Basic ${base64.encode(utf8.encode('...'))}';
      Response response = await dio.get(
        'https://esewa.com.np/mobile/transaction',
        queryParameters: {'txnRefId': result.refId},
        options: Options(headers: {'Authorization': basic}),
      );
      print(response.data);
    } catch (e) {
      debugPrint('Error verifying payment: $e');
    }
  }
}*/