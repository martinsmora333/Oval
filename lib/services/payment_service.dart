import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/booking_model.dart';
import 'supabase_service.dart';

class PaymentService {
  // Singleton pattern
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  SupabaseClient get _client => SupabaseService.client;

  // Initialize Stripe with your publishable key
  Future<void> initialize(String publishableKey) async {
    if (publishableKey.trim().isEmpty) {
      throw Exception('Stripe publishable key is missing');
    }

    Stripe.publishableKey = publishableKey;
    await Stripe.instance.applySettings();
  }
  
  // Create a payment method
  Future<PaymentMethod> createPaymentMethod({
    required String number,
    required int expiryMonth,
    required int expiryYear,
    required String cvc,
  }) async {
    try {
      if (number.trim().isEmpty || cvc.trim().isEmpty) {
        throw Exception('Missing card details');
      }
      if (expiryMonth < 1 || expiryMonth > 12 || expiryYear < DateTime.now().year) {
        throw Exception('Invalid card expiry');
      }

      // In Stripe 11.5.0, we need to first create a payment method with Card params
      final paymentMethod = await Stripe.instance.createPaymentMethod(
        params: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: const BillingDetails(),
          ),
        ),
      );
      
      // Alternatively, we can also use the Card class to collect card details in a form
      // This is recommended for production apps as it handles validation and tokenization
      // See: https://pub.dev/packages/flutter_stripe/example for examples
      
      return paymentMethod;
    } catch (e) {
      debugPrint('Error creating payment method: $e');
      throw Exception('Failed to create payment method');
    }
  }
  
  // Process a payment for a booking (50/50 split)
  Future<Map<String, dynamic>> processBookingPayment(BookingModel booking, {String? paymentMethodId}) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      if (user.id != booking.creatorId && user.id != booking.inviteeId) {
        throw Exception('You can only pay for your own bookings');
      }

      final amountToCharge = booking.inviteeId == null
          ? booking.totalAmount
          : booking.amountPerPlayer;

      await _client.from('booking_payments').upsert(
        {
          'booking_id': booking.id,
          'payer_user_id': user.id,
          'amount': amountToCharge,
          'currency': 'AUD',
          'status': 'complete',
        },
        onConflict: 'booking_id,payer_user_id',
      );

      if (paymentMethodId != null && paymentMethodId.trim().isNotEmpty) {
        await savePaymentMethod(user.id, paymentMethodId);
      }

      final paymentRows = await _client
          .from('booking_payments')
          .select('payer_user_id,status')
          .eq('booking_id', booking.id);

      final completedPayments = (paymentRows as List)
          .where((row) => row['status'] == 'complete')
          .length;
      final expectedPayments = booking.inviteeId == null ? 1 : 2;
      final bookingPaymentStatus =
          completedPayments >= expectedPayments ? 'complete' : 'partial';

      await _client
          .from('bookings')
          .update({'payment_status': bookingPaymentStatus})
          .eq('id', booking.id);

      return {
        'success': true,
        'bookingId': booking.id,
        'amount': amountToCharge,
        'paymentStatus': bookingPaymentStatus,
      };
    } catch (e) {
      debugPrint('Error processing payment: $e');
      throw Exception('Failed to process payment: ${e.toString()}');
    }
  }
  
  // Save a payment method for a user
  Future<void> savePaymentMethod(String userId, String paymentMethodId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null || user.id != userId) {
        throw Exception('User not authenticated or ID mismatch');
      }

      await _client.from('user_saved_payment_methods').upsert(
        {
          'user_id': userId,
          'provider': 'stripe',
          'provider_payment_method_id': paymentMethodId,
          'is_default': true,
        },
        onConflict: 'user_id,provider,provider_payment_method_id',
      );
    } catch (e) {
      debugPrint('Error saving payment method: $e');
      throw Exception('Failed to save payment method');
    }
  }
  
  // Get saved payment methods for a user
  Future<List<Map<String, dynamic>>> getSavedPaymentMethods(String userId) async {
    try {
      final rows = await _client
          .from('user_saved_payment_methods')
          .select()
          .eq('user_id', userId)
          .order('is_default', ascending: false)
          .order('created_at', ascending: false);

      return (rows as List)
          .map(
            (row) => <String, dynamic>{
              'id': row['id'],
              'paymentMethodId': row['provider_payment_method_id'],
              'provider': row['provider'],
              'brand': row['brand'],
              'last4': row['last4'],
              'expMonth': row['exp_month'],
              'expYear': row['exp_year'],
              'isDefault': row['is_default'] ?? false,
            },
          )
          .toList(growable: false);
    } catch (e) {
      debugPrint('Error getting payment methods: $e');
      throw Exception('Failed to get payment methods');
    }
  }
}
