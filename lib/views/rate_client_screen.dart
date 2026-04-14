import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/providers/auth_providers.dart';
import 'package:flutter_application_1/models/user_model.dart';
import 'package:flutter_application_1/views/app_colors.dart';

class RateClientScreen extends ConsumerStatefulWidget {
  final String clientId;
  const RateClientScreen({super.key, required this.clientId});

  @override
  ConsumerState<RateClientScreen> createState() => _RateClientScreenState();
}

class _RateClientScreenState extends ConsumerState<RateClientScreen> {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userDoc = ref.read(currentUserDocProvider).value;
      if (userDoc != null && userDoc.accountType == 'client') {
        context.go('/home');
      }
    });
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a rating')));
      return;
    }

    setState(() => _isSubmitting = true);
    final currentUser = ref.read(currentUserDocProvider).value;
    if (currentUser == null) {
      setState(() => _isSubmitting = false);
      return;
    }
    
    try {
      final targetRef = FirebaseFirestore.instance.collection('users').doc(widget.clientId);
      final newReviewRef = targetRef.collection('reviews').doc();
      
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final targetDoc = await transaction.get(targetRef);
        if (!targetDoc.exists) throw Exception("Target client not found");
        
        final data = targetDoc.data()!;
        final currentCount = data['reviewCount'] ?? 0;
        final currentAvg = (data['averageRating'] ?? 0.0).toDouble();
        
        final newCount = currentCount + 1;
        final newAvg = ((currentAvg * currentCount) + _rating) / newCount;
        
        transaction.set(newReviewRef, {
          'fromId': currentUser.uid,
          'fromName': currentUser.businessName ?? currentUser.displayName,
          'fromPhotoUrl': currentUser.photoUrl,
          'rating': _rating,
          'comment': _commentController.text,
          'timestamp': Timestamp.now(),
        });
        
        transaction.update(targetRef, {
          'reviewCount': newCount,
          'averageRating': newAvg,
        });
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review submitted!')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rate Client')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(widget.clientId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final targetUser = UserModel.fromJson(data);
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: targetUser.photoUrl != null && targetUser.photoUrl!.isNotEmpty ? NetworkImage(targetUser.photoUrl!) : null,
                  child: targetUser.photoUrl == null || targetUser.photoUrl!.isEmpty ? const Icon(Icons.person, size: 40) : null,
                ),
                const SizedBox(height: 16),
                Text(targetUser.displayName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const Text('Client', style: TextStyle(color: Colors.grey, fontSize: 16)),
                const SizedBox(height: 32),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < _rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 40,
                      ),
                      onPressed: () => setState(() => _rating = index + 1),
                    );
                  }),
                ),
                const SizedBox(height: 32),
                
                TextField(
                  controller: _commentController,
                  maxLength: 300,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Comment (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 32),
                
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _submitReview,
                    child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Submit Review'),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
