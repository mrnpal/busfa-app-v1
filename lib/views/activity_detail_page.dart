import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ActivityDetailPage extends StatelessWidget {
  const ActivityDetailPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ambil data activity dari Get.arguments
    final activity = Get.arguments;
    final dateFormat = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');
    final timeFormat = DateFormat('HH:mm');

    // Parsing tanggal dan waktu
    DateTime? eventDate;
    try {
      if (activity.date is DateTime) {
        eventDate = activity.date;
      } else if (activity.date is String) {
        eventDate = DateTime.tryParse("${activity.date} ${activity.time}");
      }
    } catch (_) {}

    final formattedDate =
        eventDate != null ? dateFormat.format(eventDate) : '-';
    final formattedTime =
        eventDate != null ? timeFormat.format(eventDate) : '-';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  activity.imageUrl != null && activity.imageUrl != ""
                      ? Image.network(
                        activity.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (c, e, s) => Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.image,
                                size: 80,
                                color: Colors.grey,
                              ),
                            ),
                      )
                      : Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.image,
                          size: 80,
                          color: Colors.grey,
                        ),
                      ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.45),
                          Colors.transparent,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 24,
                    bottom: 24,
                    right: 24,
                    child: Text(
                      activity.title ?? "-",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 12,
                            color: Colors.black54,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date & Time
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Colors.blue[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.access_time, color: Colors.blueGrey, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        formattedTime,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Location
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.red[400], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          activity.location ?? "-",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Description
                  const Text(
                    "Deskripsi",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    activity.description ?? "-",
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[800],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Agenda (jika ada)
                  if (activity.agenda != null &&
                      activity.agenda is List &&
                      activity.agenda.isNotEmpty) ...[
                    const Text(
                      "Agenda Kegiatan",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(activity.agenda.length, (i) {
                      final item = activity.agenda[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  "${i + 1}",
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['time'] ?? "-",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(item['activity'] ?? "-"),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                  ],
                  // Button
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Implementasi pendaftaran
                          },
                          icon: const Icon(Icons.event_available),
                          label: const Text("Daftar Kegiatan"),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: Colors.blue[700],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () {
                          // TODO: Implementasi share
                        },
                        icon: const Icon(Icons.share, color: Colors.blueGrey),
                        tooltip: "Bagikan",
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
