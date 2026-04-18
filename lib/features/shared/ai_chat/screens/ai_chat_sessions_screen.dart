import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/ai_chat_providers.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class AiChatSessionsScreen extends ConsumerWidget {
  const AiChatSessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(authStateProvider);
    final user = userState.value;
    
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view chat sessions')),
      );
    }

    final sessionsAsync = ref.watch(userSessionsProvider(user.uid));

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: Text('Chat Assistant', style: AppTextStyles.headingSmall),
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: sessionsAsync.when(
        data: (sessions) {
          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.softGray.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text('No chat sessions yet', style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 8),
                  Text('Start a new session to get help', style: AppTextStyles.caption),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final session = sessions[index];
              final title = session['title'] as String? ?? 'New Session';
              final lastMsg = session['lastMessage'] as String? ?? '';
              final updatedAt = (session['lastUpdatedAt'] as Timestamp?)?.toDate();
              final timeStr = updatedAt != null 
                  ? DateFormat.yMMMd().add_jm().format(updatedAt)
                  : '';

              return ListTile(
                tileColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                title: Text(title, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (lastMsg.isNotEmpty)
                      Text(lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 4),
                    Text(timeStr, style: AppTextStyles.caption),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right, color: AppColors.softGray),
                onTap: () => context.push('/ai-chat/session?sessionId=${session['sessionId']}'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accentBlue)),
        error: (e, _) => Center(child: Text('Error loading sessions: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          try {
            final sessionId = await ref.read(activeChatControllerProvider(null)).startNewSession();
            if (context.mounted) {
              context.push('/ai-chat/session?sessionId=$sessionId');
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to start session: $e'), backgroundColor: AppColors.errorRed),
              );
            }
          }
        },
        backgroundColor: AppColors.accentBlue,
        icon: const Icon(Icons.add, color: AppColors.white),
        label: const Text('New Session', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
