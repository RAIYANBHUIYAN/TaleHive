import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_sslcommerz/model/SSLCSdkType.dart';
import 'package:flutter_sslcommerz/model/SSLCommerzInitialization.dart';
import 'package:flutter_sslcommerz/model/SSLCurrencyType.dart';
import 'package:flutter_sslcommerz/sslcommerz.dart';
import '../models/club_payment_model.dart';

class PaymentService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Your SSLCommerz credentials
  static const String _storeId = 'wrist6830197f2308c';
  static const String _storePassword = 'wrist6830197f2308c@ssl';
  
  Future<ClubPayment?> createPayment({
    required String membershipId, // We'll keep this parameter for compatibility but won't use it in DB
    required String userId,
    required String clubId,
    required double amount,
    required PaymentMethod paymentMethod,
    String? transactionId,
  }) async {
    try {
      // Calculate author share (80%) and platform share (20%)
      final authorShare = amount * 0.8;
      final platformShare = amount * 0.2;
      
      final paymentData = {
        'user_id': userId,
        'club_id': clubId,
        'transaction_id': transactionId ?? 'PENDING_${DateTime.now().millisecondsSinceEpoch}',
        'amount': amount,
        'author_share': authorShare,
        'platform_share': platformShare,
        'payment_method': _paymentMethodToString(paymentMethod),
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('club_payments')
          .insert(paymentData)
          .select('''
            *,
            clubs!club_payments_club_id_fkey(name)
          ''')
          .single();

      // Get user info separately from auth.users via the Supabase client
      final user = _supabase.auth.currentUser;
      
      return ClubPayment.fromJson({
        ...response,
        'membership_id': membershipId, // Add this for model compatibility
        'user_first_name': user?.userMetadata?['first_name'] ?? 'User',
        'user_last_name': user?.userMetadata?['last_name'] ?? '',
        'user_email': user?.email ?? '',
        'club_name': response['clubs']?['name'],
      });
    } catch (e) {
      print('Error creating payment: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> initiateSSLCommerzPayment({
    required String paymentId,
    required double amount,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required PaymentMethod paymentMethod,
  }) async {
    try {
      // Generate transaction ID
      final tranId = "CLUB_${paymentId}_${DateTime.now().millisecondsSinceEpoch}";

      // Determine multi_card_name based on payment method
      String multiCardName = "visa,master,bkash,nagad,rocket";
      switch (paymentMethod) {
        case PaymentMethod.bkash:
          multiCardName = "bkash";
          break;
        case PaymentMethod.nagad:
          multiCardName = "nagad";
          break;
        case PaymentMethod.rocket:
          multiCardName = "rocket";
          break;
        case PaymentMethod.card:
          multiCardName = "visa,master";
          break;
        default:
          multiCardName = "visa,master,bkash,nagad,rocket";
      }

      Sslcommerz sslcommerz = Sslcommerz(
        initializer: SSLCommerzInitialization(
          multi_card_name: multiCardName,
          currency: SSLCurrencyType.BDT,
          product_category: "Club Membership",
          sdkType: SSLCSdkType.TESTBOX, // Use TESTBOX for development
          store_id: _storeId,
          store_passwd: _storePassword,
          total_amount: amount,
          tran_id: tranId,
        ),
      );

      final response = await sslcommerz.payNow();

      if (response.status == 'VALID') {
        // Determine actual payment method used based on card_type from response
        String actualPaymentMethod = _getActualPaymentMethod(response.cardType ?? '', paymentMethod);
        
        // Update payment with transaction details and actual payment method
        await _supabase
            .from('club_payments')
            .update({
              'transaction_id': response.tranId,
              'payment_method': actualPaymentMethod,
              'payment_data': {
                'bank_tran_id': response.bankTranId,
                'card_type': response.cardType,
                'card_no': response.cardNo,
                'amount': response.amount,
                'status': response.status,
              },
            })
            .eq('id', paymentId);

        return {
          'status': 'SUCCESS',
          'tran_id': response.tranId,
          'bank_tran_id': response.bankTranId,
          'amount': response.amount,
          'card_type': response.cardType,
        };
      } else {
        print('SSLCommerz payment failed: ${response.status}');
        return {
          'status': 'FAILED',
          'reason': 'Payment was not completed successfully',
        };
      }
    } catch (e) {
      print('Error initiating SSLCommerz payment: $e');
      return {
        'status': 'ERROR',
        'reason': e.toString(),
      };
    }
  }

  Future<bool> completePayment({
    required String paymentId,
    required String transactionId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Update payment status and transaction ID
      await _supabase
          .from('club_payments')
          .update({
            'status': 'completed',
            'transaction_id': transactionId,
          })
          .eq('id', paymentId);

      // Get the payment details to activate membership
      final paymentResponse = await _supabase
          .from('club_payments')
          .select('user_id, club_id')
          .eq('id', paymentId)
          .single();

      // Set membership to pending status after payment completion
      final userId = paymentResponse['user_id'];
      final clubId = paymentResponse['club_id'];
      
      await _supabase
          .from('club_memberships')
          .update({
            'membership_type': 'premium',
            'status': 'pending', // Set to pending for author approval
            'expires_at': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('club_id', clubId);

      return true;
    } catch (e) {
      print('Error completing payment: $e');
      return false;
    }
  }

  Future<bool> failPayment({
    required String paymentId,
    String? reason,
  }) async {
    try {
      await _supabase
          .from('club_payments')
          .update({
            'status': 'failed',
            'payment_data': reason != null ? {'failure_reason': reason} : null,
          })
          .eq('id', paymentId);

      return true;
    } catch (e) {
      print('Error failing payment: $e');
      return false;
    }
  }

  Future<List<ClubPayment>> getPaymentsByUser(String userId) async {
    try {
      final response = await _supabase
          .from('club_payments')
          .select('''
            *,
            clubs!club_payments_club_id_fkey(name)
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return response.map<ClubPayment>((json) {
        return ClubPayment.fromJson({
          ...json,
          'club_name': json['clubs']?['name'],
        });
      }).toList();
    } catch (e) {
      print('Error fetching user payments: $e');
      return [];
    }
  }

  Future<List<ClubPayment>> getPaymentsByClub(String clubId) async {
    try {
      final response = await _supabase
          .from('club_payments')
          .select('''
            *,
            clubs!club_payments_club_id_fkey(name)
          ''')
          .eq('club_id', clubId)
          .order('created_at', ascending: false);

      return response.map<ClubPayment>((json) {
        return ClubPayment.fromJson({
          ...json,
          'user_first_name': 'User', // Default values since we can't join with auth.users
          'user_last_name': '',
          'user_email': '',
          'club_name': json['clubs']?['name'],
        });
      }).toList();
    } catch (e) {
      print('Error fetching club payments: $e');
      return [];
    }
  }

  // Helper method to convert PaymentMethod enum to string
  String _paymentMethodToString(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.bkash:
        return 'bkash';
      case PaymentMethod.nagad:
        return 'nagad';
      case PaymentMethod.rocket:
        return 'rocket';
      case PaymentMethod.card:
        return 'card';
      case PaymentMethod.bank_transfer:
        return 'bank_transfer';
    }
  }

  // Helper method to determine actual payment method from SSL Commerz response
  String _getActualPaymentMethod(String cardType, PaymentMethod originalMethod) {
    // Check the card_type from SSL Commerz response to determine actual payment method
    if (cardType.toLowerCase().contains('bkash')) {
      return 'bkash';
    } else if (cardType.toLowerCase().contains('nagad')) {
      return 'nagad';
    } else if (cardType.toLowerCase().contains('rocket')) {
      return 'rocket';
    } else if (cardType.toLowerCase().contains('visa') || cardType.toLowerCase().contains('master')) {
      return 'card';
    } else {
      // If we can't determine from cardType, use the original method
      return _paymentMethodToString(originalMethod);
    }
  }
}
