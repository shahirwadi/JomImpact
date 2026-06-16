import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/feed_model.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';
import '../../viewmodels/feed_viewmodel.dart';
import 'widgets.dart';

class ProfilePostHistory extends StatelessWidget {
  final UserModel user;

  const ProfilePostHistory({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final service = context.read<FeedViewModel>().service;

    return StreamBuilder<List<FeedPostModel>>(
      stream: service.userPostsStream(user.id),
      builder: (context, snapshot) {
        final posts = snapshot.data ?? [];
        final latestPost = posts.isEmpty ? null : posts.first;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Post',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                  if (posts.length > 1)
                    TextButton(
                      onPressed: () => _showAllPosts(context, posts),
                      child: const Text('See more'),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (latestPost == null)
                const _EmptyPostHistory()
              else
                _ProfilePostCard(post: latestPost, user: user),
            ],
          ),
        );
      },
    );
  }

  void _showAllPosts(BuildContext context, List<FeedPostModel> posts) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AllPostsSheet(posts: posts, user: user),
    );
  }
}

class _AllPostsSheet extends StatelessWidget {
  final List<FeedPostModel> posts;
  final UserModel user;

  const _AllPostsSheet({
    required this.posts,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.82,
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.divider,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Post history',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              itemCount: posts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, index) {
                return _ProfilePostCard(post: posts[index], user: user);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfilePostCard extends StatelessWidget {
  final FeedPostModel post;
  final UserModel user;

  const _ProfilePostCard({
    required this.post,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final canEdit = post.canEdit;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NetworkAvatar(
                imageUrl: user.photoUrl,
                size: 34,
                fallbackIcon:
                    user.role == UserRole.organizer ? Icons.business : Icons.person,
                backgroundColor: AppTheme.primary.withOpacity(0.1),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                      ),
                    ),
                    Text(
                      _postTimeLabel(post),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              if (canEdit)
                IconButton(
                  tooltip: 'Edit post',
                  onPressed: () => _showEditPostSheet(context, post),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                ),
              IconButton(
                tooltip: 'Delete post',
                onPressed: () => _confirmDelete(context, post),
                icon: const Icon(Icons.delete_outline, size: 18),
                color: AppTheme.error,
              ),
            ],
          ),
          if (post.content.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              post.content,
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
                color: AppTheme.textDark,
              ),
            ),
          ],
          if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  post.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.white,
                    child: const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.favorite_border,
                  size: 15, color: AppTheme.textLight),
              const SizedBox(width: 4),
              Text(
                '${post.likeCount}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
              ),
              const SizedBox(width: 14),
              const Icon(Icons.chat_bubble_outline,
                  size: 15, color: AppTheme.textLight),
              const SizedBox(width: 4),
              Text(
                '${post.commentCount}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
              ),
              const Spacer(),
              Text(
                canEdit ? 'Editable for 10 min' : 'Delete only',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: canEdit ? AppTheme.success : AppTheme.textLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _postTimeLabel(FeedPostModel post) {
    final base = DateFormat('d MMM, h:mm a').format(post.createdAt);
    return post.wasEdited ? '$base - edited' : base;
  }

  void _showEditPostSheet(BuildContext context, FeedPostModel post) {
    final contentCtrl = TextEditingController(text: post.content);
    final imageCtrl = TextEditingController(text: post.imageUrl ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            18,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Edit post',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: contentCtrl,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Post',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: imageCtrl,
                  decoration: const InputDecoration(labelText: 'Image URL'),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final vm = context.read<FeedViewModel>();
                      final ok = await vm.updatePost(
                        postId: post.id,
                        content: contentCtrl.text,
                        imageUrl: imageCtrl.text,
                      );
                      if (!ctx.mounted) return;
                      if (ok) {
                        Navigator.pop(ctx);
                      } else {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text(vm.error ?? 'Unable to edit post'),
                            backgroundColor: AppTheme.error,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.save_outlined, size: 18),
                    label: const Text('Save post'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, FeedPostModel post) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete post'),
        content: const Text('This post will be removed from your history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final vm = context.read<FeedViewModel>();
              final ok = await vm.deletePost(post.id);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (!ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(vm.error ?? 'Unable to delete post'),
                    backgroundColor: AppTheme.error,
                  ),
                );
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPostHistory extends StatelessWidget {
  const _EmptyPostHistory();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Icon(Icons.forum_outlined, color: AppTheme.textLight),
          SizedBox(height: 8),
          Text(
            'No posts yet',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
