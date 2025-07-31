import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationsHistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF2A9D8F),
        elevation: 0,
        title: Text(
          'История уведомлений',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Здесь будут отображаться уведомления, которые вы получили',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  // Пример элемента уведомления
                  _buildNotificationItem(
                    context,
                    title: 'Срок годности',
                    body: 'Молоко испортится через 3 дня!',
                    time: 'Сегодня, 10:30',
                    icon: Icons.notifications_active,
                    color: Color(0xFF2A9D8F),
                  ),
                  _buildNotificationItem(
                    context,
                    title: 'Срок годности',
                    body: 'Йогурт испортится через 3 дня!',
                    time: 'Вчера, 15:45',
                    icon: Icons.notifications_active,
                    color: Color(0xFF2A9D8F),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
      BuildContext context, {
        required String title,
        required String body,
        required String time,
        required IconData icon,
        required Color color,
      }) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    body,
                    style: GoogleFonts.poppins(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    time,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
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