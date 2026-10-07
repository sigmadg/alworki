import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/social_service.dart';
import '../../theme/app_colors.dart';
import '../widgets/app_screen_insets.dart';
import '../widgets/alworki_image.dart';
import '../widgets/shell_tab_header.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SocialService>().loadMessages();
    });
  }

  @override
  Widget build(BuildContext context) {
    final social = context.watch<SocialService>();
    final chats = social.chats;

    return ColoredBox(
      color: AppColors.scaffold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShellTabHeader(
            title: 'Mensajes',
            subtitle: 'Chats y cotizaciones con proveedores',
            onMenuTap: () => Scaffold.of(context).openDrawer(),
            trailing: IconButton(
              icon: const Icon(Icons.people_outline),
              tooltip: 'Ver contactos',
              onPressed: () => context.push('/contacts'),
            ),
          ),
          if (social.isLoading && chats.isEmpty)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(16, 0, 16, AppScreenInsets.shellBottom(context)),
                itemCount: chats.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return ListTile(
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          gradient: AppColors.fabGradient,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.smart_toy, color: Colors.white),
                          onPressed: () => context.push('/chat'),
                        ),
                      ),
                      title: const Text('Asistente Alworki', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Pregúntame sobre favores e intercambios'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/chat'),
                      tileColor: AppColors.card,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    );
                  }
                  final chat = chats[i - 1];
                  final subtitle = chat.profession.isNotEmpty
                      ? '${chat.name} - ${chat.profession}'
                      : chat.lastMessage;
                  return ListTile(
                    leading: AlworkiAvatar(avatarKey: chat.avatarKey, radius: 24),
                    title: Text(
                      chat.profession.isNotEmpty ? '${chat.name} - ${chat.profession}' : chat.name,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      chat.profession.isNotEmpty ? chat.lastMessage : subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(chat.time, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        if (chat.unread > 0) ...[
                          const SizedBox(height: 4),
                          CircleAvatar(
                            radius: 10,
                            backgroundColor: AppColors.fabStart,
                            child: Text('${chat.unread}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                          ),
                        ],
                      ],
                    ),
                    onTap: () => context.push('/messages/${chat.id}'),
                    tileColor: AppColors.card,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
