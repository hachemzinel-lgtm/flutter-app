import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import '../../../../features/auth/providers/auth_providers.dart';
import 'package:flutter_application_1/core/models/user_model.dart';
import '../../../../core/constants/app_colors.dart';

class MarketplaceProfileScreen extends ConsumerStatefulWidget {
  final String id;
  const MarketplaceProfileScreen({super.key, required this.id});

  @override
  ConsumerState<MarketplaceProfileScreen> createState() => _MarketplaceProfileScreenState();
}

class _MarketplaceProfileScreenState extends ConsumerState<MarketplaceProfileScreen> {
  String _cityName = 'Loading location...';
  
  double _haversineDistance(GeoPoint a, GeoPoint b) {
    const R = 6371.0;
    final lat1 = a.latitude * pi / 180;
    final lat2 = b.latitude * pi / 180;
    final dLat = (b.latitude - a.latitude) * pi / 180;
    final dLon = (b.longitude - a.longitude) * pi / 180;
    final x = sin(dLat/2)*sin(dLat/2) + cos(lat1)*cos(lat2)*sin(dLon/2)*sin(dLon/2);
    final c = 2*atan2(sqrt(x), sqrt(1-x));
    return R * c;
  }

  Future<void> _fetchCityName(GeoPoint location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(location.latitude, location.longitude);
      if (placemarks.isNotEmpty) {
        if (mounted) setState(() => _cityName = placemarks.first.locality ?? 'Unknown city');
      }
    } catch (e) {
      if (mounted) setState(() => _cityName = 'Location available');
    }
  }

  Future<void> _onMessageTap(String targetId) async {
    final currentUserId = ref.read(currentUserDocProvider).value?.uid;
    if (currentUserId == null) return;
    
    final query = await FirebaseFirestore.instance.collection('conversations')
        .where('participants', arrayContains: currentUserId)
        .get();
        
    String? conversationId;
    for (var doc in query.docs) {
      final parts = List<String>.from(doc['participants']);
      if (parts.contains(targetId)) {
        conversationId = doc.id;
        break;
      }
    }
    
    if (conversationId == null) {
      final docRef = await FirebaseFirestore.instance.collection('conversations').add({
        'participants': [currentUserId, targetId],
        'createdAt': Timestamp.now(),
        'lastMessage': '',
        'lastMessageTime': Timestamp.now(),
      });
      conversationId = docRef.id;
    }
    
    if (mounted) context.push('/messages/$conversationId');
  }

  @override
  Widget build(BuildContext context) {
    final currentUserDoc = ref.watch(currentUserDocProvider).value;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(widget.id).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final user = UserModel.fromJson(data);
          
          if (user.location != null && _cityName == 'Loading location...') {
            _fetchCityName(user.location!);
          }

          double? distance;
          if (currentUserDoc?.location != null && user.location != null) {
            distance = _haversineDistance(currentUserDoc!.location!, user.location!);
          }
          
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty ? NetworkImage(user.photoUrl!) : null,
                        child: user.photoUrl == null || user.photoUrl!.isEmpty ? const Icon(Icons.store, size: 50) : null,
                      ),
                      const SizedBox(height: 16),
                      Text(user.businessName ?? user.displayName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Chip(label: Text(user.category ?? 'General')),
                      if (distance != null) Text('${distance.toStringAsFixed(1)} km away', style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: user.openStatus == true ? Colors.green : Colors.red)),
                          const SizedBox(width: 8),
                          Text(user.openStatus == true ? 'Open' : 'Closed'),
                        ],
                      ),
                      
                      const Divider(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(children: [
                            Row(children: [const Icon(Icons.star, color: Colors.amber), Text(user.averageRating.toStringAsFixed(1), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
                            const Text('Rating')
                          ]),
                          Column(children: [
                            Text('${user.reviewCount}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const Text('Reviews')
                          ]),
                        ],
                      ),
                      
                      const Divider(height: 32),
                      const Align(alignment: AlignmentDirectional.centerStart, child: Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                      const SizedBox(height: 8),
                      Align(alignment: AlignmentDirectional.centerStart, child: Text(user.description ?? 'No description provided.')),
                      const SizedBox(height: 16),
                      Align(alignment: AlignmentDirectional.centerStart, child: Text('Delivery radius: ${user.deliveryRadius ?? 0} km')),
                      Align(alignment: AlignmentDirectional.centerStart, child: Text('Location: $_cityName')),
                      const SizedBox(height: 32),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          if (currentUserDoc?.accountType == 'client')
                            TextButton(
                              onPressed: () => context.push('/rate-service/${widget.id}'),
                              child: const Text('Leave a Review'),
                            )
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(widget.id).collection('reviews').orderBy('timestamp', descending: true).limit(5).get(),
                builder: (context, reviewSnapshot) {
                  if (!reviewSnapshot.hasData) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
                  final reviews = reviewSnapshot.data!.docs;
                  if (reviews.isEmpty) return const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(16), child: Text('No reviews yet.')));
                  
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final rev = reviews[index].data() as Map<String, dynamic>;
                        final date = rev['timestamp'] != null ? DateFormat.yMMMd().format((rev['timestamp'] as Timestamp).toDate()) : '';
                        
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: rev['fromPhotoUrl'] != null && rev['fromPhotoUrl'].toString().isNotEmpty ? NetworkImage(rev['fromPhotoUrl']) : null, 
                            child: rev['fromPhotoUrl'] == null || rev['fromPhotoUrl'].toString().isEmpty ? const Icon(Icons.person) : null
                          ),
                          title: Row(
                            children: [
                              Expanded(child: Text(rev['fromName'] ?? 'Anonymous')),
                              Row(children: List.generate(5, (i) => Icon(Icons.star, size: 14, color: i < (rev['rating'] ?? 0) ? Colors.amber : Colors.grey))),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(date, style: const TextStyle(fontSize: 12)),
                              if (rev['comment'] != null && rev['comment'].toString().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(rev['comment']),
                              ]
                            ],
                          ),
                        );
                      },
                      childCount: reviews.length,
                    ),
                  );
                },
              ),
              if (user.reviewCount > 5)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(child: TextButton(onPressed: () {}, child: Text('See all ${user.reviewCount} reviews'))),
                  ),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: widget.id == currentUserDoc?.uid
          ? null
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: FilledButton(
                onPressed: () => _onMessageTap(widget.id),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Message', style: TextStyle(fontSize: 18)),
                ),
              ),
            ),
    );
  }
}
