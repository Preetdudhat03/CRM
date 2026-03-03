import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../services/activity_service.dart';

class AllActivitiesScreen extends StatefulWidget {
  const AllActivitiesScreen({super.key});

  @override
  State<AllActivitiesScreen> createState() => _AllActivitiesScreenState();
}

class _AllActivitiesScreenState extends State<AllActivitiesScreen> {
  final ActivityService _service = ActivityService();
  final List<Map<String, dynamic>> _activities = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 0;
  final int _pageSize = 20;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadActivities();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadActivities() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getAllActivities(page: 0, pageSize: _pageSize);
      setState(() {
        _activities.clear();
        _activities.addAll(data);
        _hasMore = data.length >= _pageSize;
        _page = 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    _page++;
    try {
      final data = await _service.getAllActivities(page: _page, pageSize: _pageSize);
      setState(() {
        _activities.addAll(data);
        _hasMore = data.length >= _pageSize;
        _isLoadingMore = false;
      });
    } catch (e) {
      _page--;
      _isLoadingMore = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Activities'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _activities.isEmpty
              ? const Center(child: Text('No activities yet'))
              : RefreshIndicator(
                  onRefresh: _loadActivities,
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _activities.length + (_hasMore ? 1 : 0),
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      if (index >= _activities.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return _buildActivityTile(context, _activities[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildActivityTile(BuildContext context, Map<String, dynamic> item) {
    final typeStr = item['type'] ?? 'other';
    final title = item['title'] ?? 'Activity';
    final createdBy = item['created_by'] ?? '';
    final description = item['description'] ?? '';
    final dateStr = item['date'] ?? item['created_at'];
    final date = dateStr != null
        ? DateTime.tryParse(dateStr.toString()) ?? DateTime.now()
        : DateTime.now();

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      leading: CircleAvatar(
        backgroundColor: _getColorForType(typeStr).withOpacity(0.1),
        child: Icon(_getIconForType(typeStr), color: _getColorForType(typeStr), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (createdBy.isNotEmpty)
            Text(
              'by $createdBy',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          if (description.isNotEmpty)
            Text(description, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      trailing: Text(
        timeago.format(date),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'deal':
        return Colors.green;
      case 'task':
        return Colors.blue;
      case 'lead':
        return Colors.orange;
      case 'contact':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'deal':
        return Icons.attach_money;
      case 'task':
        return Icons.check_circle_outline;
      case 'lead':
        return Icons.person_add_alt_1_outlined;
      case 'contact':
        return Icons.contacts_outlined;
      default:
        return Icons.info_outline;
    }
  }
}
