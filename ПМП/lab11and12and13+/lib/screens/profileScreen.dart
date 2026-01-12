import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/appBLoC.dart';
import '../bloc/appEvent.dart';
import '../bloc/appState.dart';
import '../services/databaseService.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userStatus;
  StreamSubscription<Map<String, dynamic>?>? _statusSubscription;

  @override
  void initState() {
    super.initState();
    _loadUserStatus();
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }

  void _loadUserStatus() {
    final bloc = context.read<AppBloc>();
    final state = bloc.state;
    if (state is AppLoaded && state.currentUser != null) {
      final databaseService = bloc.databaseService;
      _statusSubscription = databaseService
          .getUserStatusStream(state.currentUser!.id)
          .listen((status) {
        if (mounted) {
          setState(() => _userStatus = status);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Профиль',
          style: TextStyle(
            fontFamily: 'Pretendard',
            color: Color(0xFF5d666f),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF5d666f)),
      ),
      body: BlocBuilder<AppBloc, AppState>(
        builder: (context, state) {
          if (state is AppLoaded && state.currentUser != null) {
            final user = state.currentUser!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade200,
                      foregroundImage: user.avatarPath.startsWith('http')
                          ? NetworkImage(user.avatarPath)
                          : AssetImage(user.avatarPath) as ImageProvider,
                      child: const Icon(Icons.person, size: 60),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Pretendard',
                        color: Color(0xFF5d666f),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: user.isAdmin ? Colors.red.shade50 : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        user.roleName,
                        style: TextStyle(
                          color: user.isAdmin ? Colors.red : Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildInfoCard(
                    'Дата регистрации',
                    _formatDate(user.createdAt),
                    Icons.calendar_today,
                  ),
                  const SizedBox(height: 16),
                  _buildStatusCard(),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                    key: const Key('profile_logout_button'),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Выход'),
                            content: const Text('Вы уверены, что хотите выйти?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Отмена'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  context.read<AppBloc>().add(const SignOutRequested());
                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                    '/auth',
                                    (route) => false,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Выйти'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        'Выйти',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF5d666f)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontFamily: 'Pretendard',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Pretendard',
                    color: Color(0xFF5d666f),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final status = _userStatus?['status'] ?? 'offline';
    final lastSeen = _userStatus?['lastSeen'];
    
    String statusText;
    Color statusColor;
    IconData statusIcon;
    
    if (status == 'online') {
      statusText = 'Онлайн';
      statusColor = Colors.green;
      statusIcon = Icons.circle;
    } else {
      statusText = 'Офлайн';
      statusColor = Colors.grey;
      statusIcon = Icons.circle_outlined;
    }
    
    String lastSeenText = 'Неизвестно';
    if (lastSeen != null) {
      try {
        if (lastSeen is String) {
          final date = DateTime.parse(lastSeen);
          lastSeenText = _formatDate(date);
        }
        else if (lastSeen is int) {
          final date = DateTime.fromMillisecondsSinceEpoch(lastSeen);
          lastSeenText = _formatDate(date);
        }
      } catch (e) {
        print('Ошибка парсинга даты: $e');
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 16),
              const SizedBox(width: 8),
              Text(
                'Статус: $statusText',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                  fontFamily: 'Pretendard',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Последняя активность: $lastSeenText',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontFamily: 'Pretendard',
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

