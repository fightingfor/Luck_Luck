import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // 用户信息卡片
          Container(
            padding: const EdgeInsets.all(20),
            color: Theme.of(context).primaryColor,
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Colors.grey),
                ),
                SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '未登录',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      '点击登录账号',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 功能列表
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('历史记录'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 实现历史记录功能
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.favorite),
            title: const Text('我的收藏'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 实现收藏功能
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('消息通知'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 实现通知功能
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('设置'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 实现设置功能
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('关于'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 实现关于页面
            },
          ),
        ],
      ),
    );
  }
}
