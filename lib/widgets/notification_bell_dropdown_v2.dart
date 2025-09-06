import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

/// Drop-in notification bell for AppBar actions.
///
/// Fixes & changes from your version:
/// - Eliminates LateInitializationError by making the bell controller robust to hot reloads
///   and guarding usage when null.
/// - Replaces in-widget full-screen Stack/Positioned overlay (which caused huge RenderFlex
///   overflows when placed in AppBar actions) with a `showGeneralDialog` right-side drawer.
///   This ensures proper constraints and no layout overflows.
/// - Solid refresh/mark-as-read flows with setState + FutureBuilder.
/// - Defensive null/empty handling and minor style cleanups.
class NotificationBellDropdownV2 extends StatefulWidget {
  const NotificationBellDropdownV2({Key? key}) : super(key: key);

  @override
  State<NotificationBellDropdownV2> createState() => _NotificationBellDropdownV2State();
}

class _NotificationBellDropdownV2State extends State<NotificationBellDropdownV2>
    with TickerProviderStateMixin {
  int _unreadCount = 0;
  int _refreshKey = 0;
  bool _isRefreshing = false;

  // Bell shake animation (nullable + guarded to avoid LateInitializationError on hot reload).
  AnimationController? _bellAnimationController;
  Animation<double>? _bellShakeAnimation;

  Future<List<AppNotification>>? _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _initBellAnimation();
    _loadUnreadCount();
    _loadNotifications();
  }

  // Handle hot reload safely: re-create the bell controller if needed.
  @override
  void reassemble() {
    super.reassemble();
    // Rebuild animation controller to prevent LateInitializationError after hot reload.
    _bellAnimationController?.dispose();
    _initBellAnimation();
    if (_unreadCount > 0) {
      _bellAnimationController?.repeat(reverse: true);
    }
  }

  void _initBellAnimation() {
    _bellAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _bellShakeAnimation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(parent: _bellAnimationController!, curve: Curves.elasticInOut),
    );
  }

  void _loadNotifications() {
    setState(() {
      _notificationsFuture = NotificationService.fetchNotifications();
    });
  }

  @override
  void dispose() {
    _bellAnimationController?.dispose();
    super.dispose();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await NotificationService.getUnreadCount();
      if (!mounted) return;
      setState(() => _unreadCount = count);
      if (count > 0) {
        _bellAnimationController?.repeat(reverse: true);
      } else {
        _bellAnimationController?.stop();
      }
    } catch (e) {
      debugPrint('Error loading unread count: $e');
    }
  }

  Future<void> _refreshNotifications() async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
      _refreshKey++;
    });

    try {
      await Future.wait([
        _loadUnreadCount(),
        Future.delayed(const Duration(milliseconds: 600)), // minimum spinner time
      ]);
      _loadNotifications();
    } catch (e) {
      debugPrint('Error refreshing notifications: $e');
    } finally {
      if (!mounted) return;
      setState(() => _isRefreshing = false);
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await NotificationService.markAllAsRead();
      if (!mounted) return;
      setState(() {
        _unreadCount = 0;
      });
      _bellAnimationController?.stop();
      _loadNotifications();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All notifications marked as read', style: GoogleFonts.poppins(fontSize: 14)),
          backgroundColor: Colors.green.shade600,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      debugPrint('Error marking all as read: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to mark notifications as read', style: GoogleFonts.poppins(fontSize: 14)),
          backgroundColor: Colors.red.shade600,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _handleNotificationTap(AppNotification notification) async {
    if (notification.isRead) return;
    try {
      await NotificationService.markAsRead(notification.id);
      if (!mounted) return;
      setState(() {
        _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
      });
      if (_unreadCount == 0) {
        _bellAnimationController?.stop();
      }
      _loadNotifications();
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // === UI helpers ===
  void _openSidebarDialog() {
    showGeneralDialog(
      context: context,
      barrierLabel: 'Notifications',
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, _, __) {
        final screenWidth = MediaQuery.of(context).size.width;
        final sidebarWidth = screenWidth > 600
            ? 400.0
            : (screenWidth * 0.85).clamp(280.0, 400.0);
        return SafeArea(
          child: Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: Colors.transparent,
              child: SizedBox(
                width: sidebarWidth,
                height: double.infinity,
                child: _buildNotificationsSidebar(),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, _, child) {
        final offsetAnimation = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }

  Widget _buildNotificationsSidebar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), bottomLeft: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 24, offset: const Offset(-8, 0)),
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(-4, 0)),
        ],
      ),
      child: Column(
        children: [
          _buildSidebarHeader(),
          Expanded(child: _buildNotificationsList()),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0096C7), Color(0xFF00B4D8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _buildBackButton(),
                  const SizedBox(width: 16),
                  Expanded(child: _buildHeaderTitle()),
                  _buildRefreshButton(),
                ],
              ),
              if (_unreadCount > 0) ...[
                const SizedBox(height: 16),
                _buildMarkAllReadButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).maybePop(),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          ),
          child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildHeaderTitle() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Notifications',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (_unreadCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.shade600,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Text(
              _unreadCount > 99 ? '99+' : _unreadCount.toString(),
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }

  Widget _buildRefreshButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isRefreshing ? null : _refreshNotifications,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _isRefreshing ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          ),
          child: _isRefreshing
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    backgroundColor: Colors.white.withOpacity(0.3),
                  ),
                )
              : const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildMarkAllReadButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _markAllAsRead,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.done_all_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('Mark all as read',
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsList() {
    return FutureBuilder<List<AppNotification>>(
      key: ValueKey(_refreshKey),
      future: _notificationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }
        if (snapshot.hasError) {
          return _buildErrorState();
        }
        final notifications = snapshot.data ?? <AppNotification>[];
        if (notifications.isEmpty) {
          return _buildEmptyState();
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: notifications.length,
          itemBuilder: (context, index) => _buildNotificationItem(
            notifications[index],
            index == 0,
            index == notifications.length - 1,
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF0096C7).withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFF0096C7), strokeWidth: 3),
            ),
          ),
          const SizedBox(height: 24),
          Text('Loading notifications...',
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(20)),
              child: Icon(Icons.error_outline_rounded, color: Colors.red.shade400, size: 48),
            ),
            const SizedBox(height: 24),
            Text('Failed to load notifications',
                style: GoogleFonts.poppins(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Something went wrong while fetching your notifications',
                style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 14), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshNotifications,
              icon: const Icon(Icons.refresh_rounded),
              label: Text('Try Again', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0096C7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey.shade100, Colors.grey.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Icon(Icons.notifications_none_outlined, size: 64, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 32),
            Text('No notifications yet',
                style: GoogleFonts.poppins(color: Colors.black87, fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text(
              "When you have new notifications, they'll appear here for you to stay updated",
              style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 15, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(AppNotification notification, bool isFirst, bool isLast) {
    return Container(
      margin: EdgeInsets.fromLTRB(16, isFirst ? 4 : 2, 16, isLast ? 4 : 2),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white : const Color(0xFF0096C7).withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notification.isRead ? Colors.grey.shade200 : const Color(0xFF0096C7).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          if (!notification.isRead)
            BoxShadow(color: const Color(0xFF0096C7).withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleNotificationTap(notification),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNotificationIcon(notification),
                const SizedBox(width: 16),
                Expanded(child: _buildNotificationContent(notification)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(AppNotification notification) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getNotificationColor(notification.type).withOpacity(0.15),
            _getNotificationColor(notification.type).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getNotificationColor(notification.type).withOpacity(0.2), width: 1),
      ),
      child: Icon(_getNotificationIcon(notification.type), color: _getNotificationColor(notification.type), size: 24),
    );
  }

  Widget _buildNotificationContent(AppNotification notification) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                notification.title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w700,
                  color: Colors.black87,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!notification.isRead) ...[
              const SizedBox(width: 8),
              Container(width: 8, height: 8, decoration: BoxDecoration(color: const Color(0xFF0096C7), borderRadius: BorderRadius.circular(4))),
            ],
          ],
        ),
        if ((notification.body ?? '').isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            notification.body!,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade500),
            const SizedBox(width: 6),
            Text(
              _formatDateTime(notification.createdAt),
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
            ),
            if (_getNotificationTypeLabel(notification.type) != null) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getNotificationColor(notification.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _getNotificationColor(notification.type).withOpacity(0.3), width: 0.5),
                ),
                child: Text(
                  _getNotificationTypeLabel(notification.type)!,
                  style: GoogleFonts.poppins(fontSize: 10, color: _getNotificationColor(notification.type), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'borrow_approved':
        return Icons.check_circle_rounded;
      case 'borrow_rejected':
        return Icons.cancel_rounded;
      case 'due_reminder':
        return Icons.schedule_rounded;
      case 'overdue':
        return Icons.warning_rounded;
      case 'return_reminder':
        return Icons.assignment_return_rounded;
      case 'fine':
        return Icons.payment_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type.toLowerCase()) {
      case 'borrow_approved':
        return Colors.green.shade600;
      case 'borrow_rejected':
        return Colors.red.shade600;
      case 'due_reminder':
        return Colors.orange.shade600;
      case 'overdue':
        return Colors.red.shade700;
      case 'return_reminder':
        return Colors.blue.shade600;
      case 'fine':
        return Colors.purple.shade600;
      default:
        return const Color(0xFF0096C7);
    }
  }

  String? _getNotificationTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'borrow_approved':
        return 'APPROVED';
      case 'borrow_rejected':
        return 'REJECTED';
      case 'due_reminder':
        return 'DUE SOON';
      case 'overdue':
        return 'OVERDUE';
      case 'return_reminder':
        return 'RETURN';
      case 'fine':
        return 'FINE';
      default:
        return null;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    } else if (difference.inDays > 7) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // === Public build: a compact bell suitable for AppBar actions ===
  @override
  Widget build(BuildContext context) {
    final bell = Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: _unreadCount > 0
                ? [BoxShadow(color: const Color(0xFF0096C7).withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _openSidebarDialog,
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: SizedBox(width: 28, height: 28),
              ),
            ),
          ),
        ),
        // The icon itself (kept separate so we can rotate it)
        const Positioned.fill(
          child: IgnorePointer(
            child: Center(
              child: Icon(Icons.notifications_outlined, color: Color(0xAA0096C7), size: 28),
            ),
          ),
        ),
        if (_unreadCount > 0)
          const Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Icon(Icons.notifications_active_rounded, color: Color(0xFF0096C7), size: 28),
              ),
            ),
          ),
        if (_unreadCount > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.redAccent, Colors.red]),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [BoxShadow(color: Colors.red.shade300, blurRadius: 4, offset: const Offset(0, 2))],
              ),
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              child: Text(
                _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );

    // If we have a valid controller, wrap with rotation for shake effect.
    if (_bellAnimationController != null && _bellShakeAnimation != null) {
      return AnimatedBuilder(
        animation: _bellAnimationController!,
        builder: (context, child) => Transform.rotate(angle: _bellShakeAnimation!.value, child: child),
        child: SizedBox(width: 44, height: 44, child: bell),
      );
    }

    // Fallback (should rarely happen): no animation.
    return SizedBox(width: 44, height: 44, child: bell);
  }
}
