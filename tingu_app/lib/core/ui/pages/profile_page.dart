import 'package:flutter/material.dart';
import '../../constants/announcement_types.dart';


class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0D14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0D14),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('个人中心', style: TextStyle(
          color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold,
        )),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 24),
          _buildStatCards(),
          const SizedBox(height: 24),
          _buildMenuSection(),
          const SizedBox(height: 24),
          _buildAboutSection(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00E5A0).withOpacity(0.12),
            const Color(0xFF00E5A0).withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00E5A0).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF00E5A0).withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Center(
              child: Text('👤', style: TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('听股通用户', style: TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold,
                )),
                SizedBox(height: 4),
                Text('v1.0.0', style: TextStyle(
                  color: Color(0xFF5A6072), fontSize: 12,
                )),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00E5A0).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('盲人炒股神器', style: TextStyle(
              color: Color(0xFF00E5A0), fontSize: 11,
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('3', '自选股', Colors.red)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('6', '今日播报', const Color(0xFFFFB800))),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('99%', '在线率', Color(0xFF00E5A0))),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF12151E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E2235)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(
            color: color, fontSize: 22, fontWeight: FontWeight.bold,
          )),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(
            color: Color(0xFF5A6072), fontSize: 11,
          )),
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('功能', style: TextStyle(
          color: Color(0xFF5A6072), fontSize: 11, fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        )),
        const SizedBox(height: 10),
        _buildMenuItem(Icons.history, '播报历史', '查看所有播报记录', () {}),
        _buildMenuItem(Icons.notifications, '通知管理', '系统通知设置', () {}),
        _buildMenuItem(Icons.data_usage, '数据使用', '流量与存储管理', () {}),
        _buildMenuItem(Icons.help_outline, '帮助与反馈', '使用帮助与问题反馈', () {}),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF12151E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1E2235)),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF00E5A0).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF00E5A0), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(
                    color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600,
                  )),
                  Text(subtitle, style: const TextStyle(
                    color: Color(0xFF5A6072), fontSize: 11,
                  )),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF5A6072), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: const Column(
        children: [
          Text('听股通 v1.0.0', style: TextStyle(
            color: Colors.white70, fontSize: 12,
          )),
          SizedBox(height: 4),
          Text('专为视力障碍人士设计的股票行情播报应用', style: TextStyle(
            color: Color(0xFF5A6072), fontSize: 11,
          )),
          SizedBox(height: 8),
          Text('© 2026 听股通团队', style: TextStyle(
            color: Color(0xFF5A6072), fontSize: 10,
          )),
        ],
      ),
    );
  }
}
