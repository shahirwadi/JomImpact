// lib/views/shared/feed_screen.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/feed_model.dart';
import '../../models/user_model.dart';
import '../../services/cloudinary_image_service.dart';
import '../../utils/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/feed_viewmodel.dart';
import 'widgets.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _postCtrl = TextEditingController();
  final _picker = ImagePicker();
  final _imageService = CloudinaryImageService();
  String? _imageUrl;
  bool _isUploadingImage = false;

  @override
  void dispose() {
    _postCtrl.dispose();
    super.dispose();
  }

  Future<void> _publishPost(UserModel user) async {
    final vm = context.read<FeedViewModel>();
    final ok = await vm.createPost(
      author: user,
      content: _postCtrl.text,
      imageUrl: _imageUrl,
    );
    if (!mounted) return;
    if (ok) {
      _postCtrl.clear();
      setState(() => _imageUrl = null);
      FocusScope.of(context).unfocus();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(vm.error ?? 'Unable to publish post'),
        backgroundColor: AppTheme.error,
      ));
    }
  }

  Future<void> _pickAndUploadImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
    );
    if (file == null) return;

    setState(() => _isUploadingImage = true);
    try {
      final imageUrl = await _imageService.uploadImage(
        file: file,
        folder: 'jomimpact/feed',
      );
      if (mounted) setState(() => _imageUrl = imageUrl);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppTheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    final feedVm = context.watch<FeedViewModel>();

    if (user == null) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.lock_outline,
          title: 'Sign in required',
          message: 'Please sign in to view the community feed.',
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Feed')),
      body: StreamBuilder<List<FeedPostModel>>(
        stream: feedVm.service.postsStream(),
        builder: (context, snapshot) {
          final posts = snapshot.data ?? [];

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _PostComposer(
                  user: user,
                  controller: _postCtrl,
                  isPosting: feedVm.isPosting,
                  imageUrl: _imageUrl,
                  isUploadingImage: _isUploadingImage,
                  onPickImage: _pickAndUploadImage,
                  onRemoveImage: () => setState(() => _imageUrl = null),
                  onPost: () => _publishPost(user),
                ),
                const SizedBox(height: 16),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (posts.isEmpty)
                  const SizedBox(
                    height: 360,
                    child: EmptyState(
                      icon: Icons.forum_outlined,
                      title: 'No posts yet',
                      message: 'Share an update, milestone, or volunteer story.',
                    ),
                  )
                else
                  ...posts.map((post) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _FeedPostCard(post: post, currentUser: user),
                      )),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PostComposer extends StatelessWidget {
  final UserModel user;
  final TextEditingController controller;
  final bool isPosting;
  final String? imageUrl;
  final bool isUploadingImage;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;
  final VoidCallback onPost;

  const _PostComposer({
    required this.user,
    required this.controller,
    required this.isPosting,
    required this.imageUrl,
    required this.isUploadingImage,
    required this.onPickImage,
    required this.onRemoveImage,
    required this.onPost,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NetworkAvatar(
                imageUrl: user.photoUrl,
                size: 42,
                fallbackIcon: user.role == UserRole.organizer
                    ? Icons.business
                    : Icons.person,
                backgroundColor: AppTheme.primary.withOpacity(0.1),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 2,
                  maxLines: 5,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    hintText: 'Share an update with the community',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
          if (imageUrl != null && imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppTheme.surface,
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
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton.filled(
                    onPressed: onRemoveImage,
                    icon: const Icon(Icons.close, size: 18),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.58),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              _RolePill(role: user.role),
              const SizedBox(width: 8),
              IconButton.outlined(
                onPressed: isUploadingImage ? null : onPickImage,
                tooltip: 'Add photo',
                icon: isUploadingImage
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.image_outlined, size: 18),
                style: IconButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.divider),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 112,
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: isPosting ? null : onPost,
                  icon: isPosting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send, size: 16),
                  label: const Text('Post'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(112, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeedPostCard extends StatelessWidget {
  final FeedPostModel post;
  final UserModel currentUser;

  const _FeedPostCard({
    required this.post,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    final liked = post.isLikedBy(currentUser.id);
    final service = context.read<FeedViewModel>().service;

    return StreamBuilder<UserModel?>(
      stream: service.userStream(post.authorId),
      builder: (context, snapshot) {
        final author = snapshot.data;
        final authorName = author?.name ?? post.authorName;
        final authorPhotoUrl = author?.photoUrl ?? post.authorPhotoUrl;
        final authorRole = author?.role ?? post.authorRole;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  NetworkAvatar(
                    imageUrl: authorPhotoUrl,
                    size: 42,
                    fallbackIcon: authorRole == UserRole.organizer
                        ? Icons.business
                        : Icons.person,
                    backgroundColor: AppTheme.primary.withOpacity(0.1),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authorName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textDark,
                          ),
                        ),
                        Row(
                          children: [
                            _RolePill(role: authorRole, compact: true),
                            const SizedBox(width: 6),
                            Text(
                              DateFormat('d MMM, h:mm a')
                                  .format(post.createdAt),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (post.content.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  post.content,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
              if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      post.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppTheme.surface,
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
              const SizedBox(height: 12),
              Row(
                children: [
                  _PostAction(
                    icon: liked ? Icons.favorite : Icons.favorite_border,
                    label: '${post.likeCount}',
                    color: liked ? AppTheme.error : AppTheme.textMedium,
                    onTap: () => context.read<FeedViewModel>().toggleLike(
                          postId: post.id,
                          userId: currentUser.id,
                          shouldLike: !liked,
                        ),
                  ),
                  const SizedBox(width: 8),
                  _PostAction(
                    icon: Icons.chat_bubble_outline,
                    label: '${post.commentCount}',
                    onTap: () => _showComments(context, post, currentUser),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showComments(
    BuildContext context,
    FeedPostModel post,
    UserModel currentUser,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CommentsSheet(post: post, currentUser: currentUser),
    );
  }
}

class _CommentsSheet extends StatefulWidget {
  final FeedPostModel post;
  final UserModel currentUser;

  const _CommentsSheet({
    required this.post,
    required this.currentUser,
  });

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _commentCtrl = TextEditingController();

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final vm = context.read<FeedViewModel>();
    final ok = await vm.addComment(
      postId: widget.post.id,
      author: widget.currentUser,
      content: _commentCtrl.text,
    );
    if (ok) _commentCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final service = context.read<FeedViewModel>().service;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.78,
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
                      'Comments',
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
              child: StreamBuilder<List<FeedCommentModel>>(
                stream: service.commentsStream(widget.post.id),
                builder: (context, snapshot) {
                  final comments = snapshot.data ?? [];
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (comments.isEmpty) {
                    return const EmptyState(
                      icon: Icons.chat_bubble_outline,
                      title: 'No comments yet',
                      message: 'Start the conversation on this post.',
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: comments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, index) {
                      final comment = comments[index];
                      return _CommentTile(comment: comment);
                    },
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppTheme.divider)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentCtrl,
                      minLines: 1,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Write a comment',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: IconButton.filled(
                      onPressed: _send,
                      icon: const Icon(Icons.send, size: 18),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final FeedCommentModel comment;

  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    final service = context.read<FeedViewModel>().service;

    return StreamBuilder<UserModel?>(
      stream: service.userStream(comment.authorId),
      builder: (context, snapshot) {
        final author = snapshot.data;
        final authorName = author?.name ?? comment.authorName;
        final authorPhotoUrl = author?.photoUrl ?? comment.authorPhotoUrl;
        final authorRole = author?.role ?? comment.authorRole;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NetworkAvatar(
              imageUrl: authorPhotoUrl,
              size: 34,
              fallbackIcon: authorRole == UserRole.organizer
                  ? Icons.business
                  : Icons.person,
              backgroundColor: AppTheme.primary.withOpacity(0.1),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authorName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      comment.content,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PostAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PostAction({
    required this.icon,
    required this.label,
    this.color = AppTheme.textMedium,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  final UserRole role;
  final bool compact;

  const _RolePill({
    required this.role,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isOrganizer = role == UserRole.organizer;
    final color = isOrganizer ? AppTheme.secondary : AppTheme.primary;
    final label = isOrganizer ? 'Organizer' : 'Volunteer';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
