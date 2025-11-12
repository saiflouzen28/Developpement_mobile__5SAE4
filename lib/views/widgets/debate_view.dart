import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../models/debate_model.dart';

class DebateView extends StatefulWidget {
  final DebateAnalysis debate;
  final VoidCallback onRefresh;

  const DebateView({
    super.key,
    required this.debate,
    required this.onRefresh,
  });

  @override
  State<DebateView> createState() => _DebateViewState();
}

class _DebateViewState extends State<DebateView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // AI Judge Header
        _buildAIJudgeHeader(),
        
        // Tab Bar
        _buildTabBar(),
        
        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildDebateTab(),
              _buildSummaryTab(),
              _buildInsightsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAIJudgeHeader() {
    return FadeInDown(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF6C63FF),
              const Color(0xFF5A52E0),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // AI Avatar
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.psychology_rounded,
                color: Color(0xFF6C63FF),
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI Debate Moderator',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Analyzed ${widget.debate.forArguments.length + widget.debate.againstArguments.length + widget.debate.neutralArguments.length} comments',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: widget.onRefresh,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF6C63FF),
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(0xFF6C63FF),
        indicatorWeight: 3,
        tabs: const [
          Tab(icon: Icon(Icons.forum_rounded), text: 'Debate'),
          Tab(icon: Icon(Icons.summarize_rounded), text: 'Summary'),
          Tab(icon: Icon(Icons.emoji_events_rounded), text: 'Insights'),
        ],
      ),
    );
  }

  Widget _buildDebateTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (widget.debate.forArguments.isNotEmpty) ...[
          _buildStanceSection(
            '✅ Supporting Arguments',
            widget.debate.forArguments,
            Colors.green,
          ),
          const SizedBox(height: 20),
        ],
        if (widget.debate.againstArguments.isNotEmpty) ...[
          _buildStanceSection(
            '❌ Opposition Arguments',
            widget.debate.againstArguments,
            Colors.red,
          ),
          const SizedBox(height: 20),
        ],
        if (widget.debate.neutralArguments.isNotEmpty) ...[
          _buildStanceSection(
            '⚖️ Neutral Perspectives',
            widget.debate.neutralArguments,
            Colors.orange,
          ),
        ],
      ],
    );
  }

  Widget _buildStanceSection(String title, List<DebateArgument> arguments, Color color) {
    return FadeInUp(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${arguments.length}',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...arguments.map((arg) => _buildArgumentCard(arg, color)),
        ],
      ),
    );
  }

  Widget _buildArgumentCard(DebateArgument argument, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: color.withOpacity(0.1),
                child: Text(
                  argument.userName[0].toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  argument.userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getQualityColor(argument.qualityScore).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: _getQualityColor(argument.qualityScore),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      argument.qualityScore.toStringAsFixed(1),
                      style: TextStyle(
                        color: _getQualityColor(argument.qualityScore),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            argument.content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline_rounded, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    argument.reasoning,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    return FadeIn(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Verdict Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6C63FF).withOpacity(0.1),
                  const Color(0xFF5A52E0).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.gavel_rounded,
                  size: 48,
                  color: Color(0xFF6C63FF),
                ),
                const SizedBox(height: 12),
                const Text(
                  'AI Verdict',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.debate.verdict,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6C63FF),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Summary Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.summarize_rounded, color: Color(0xFF6C63FF)),
                    SizedBox(width: 8),
                    Text(
                      'Discussion Summary',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.debate.summary,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Statistics
          _buildStatistics(),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    final total = widget.debate.forArguments.length +
        widget.debate.againstArguments.length +
        widget.debate.neutralArguments.length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Supporting',
            widget.debate.forArguments.length,
            total,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Opposition',
            widget.debate.againstArguments.length,
            total,
            Colors.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Neutral',
            widget.debate.neutralArguments.length,
            total,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total * 100).round() : 0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Top Contributor
        if (widget.debate.topContributor != null) ...[
          FadeInUp(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Top Contributor',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.debate.topContributor!.userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          widget.debate.topContributor!.contributionScore.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.debate.topContributor!.contributionReason,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        
        // Quality Distribution
        _buildQualityDistribution(),
      ],
    );
  }

  Widget _buildQualityDistribution() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_rounded, color: Color(0xFF6C63FF)),
              SizedBox(width: 8),
              Text(
                'Argument Quality Distribution',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildQualityBar('High Quality (8-10)', _countByQuality(8, 10), Colors.green),
          _buildQualityBar('Good Quality (6-8)', _countByQuality(6, 8), Colors.blue),
          _buildQualityBar('Average (4-6)', _countByQuality(4, 6), Colors.orange),
          _buildQualityBar('Low Quality (0-4)', _countByQuality(0, 4), Colors.red),
        ],
      ),
    );
  }

  Widget _buildQualityBar(String label, int count, Color color) {
    final total = widget.debate.forArguments.length +
        widget.debate.againstArguments.length +
        widget.debate.neutralArguments.length;
    final percentage = total > 0 ? count / total : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 13)),
              Text('$count', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  int _countByQuality(double min, double max) {
    final allArgs = [
      ...widget.debate.forArguments,
      ...widget.debate.againstArguments,
      ...widget.debate.neutralArguments,
    ];
    return allArgs.where((arg) => arg.qualityScore >= min && arg.qualityScore < max).length;
  }

  Color _getQualityColor(double score) {
    if (score >= 8) return Colors.green;
    if (score >= 6) return Colors.blue;
    if (score >= 4) return Colors.orange;
    return Colors.red;
  }
}
