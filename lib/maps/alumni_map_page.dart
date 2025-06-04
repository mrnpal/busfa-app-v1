import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AlumniMapPage extends StatefulWidget {
  const AlumniMapPage({Key? key}) : super(key: key);

  @override
  _AlumniMapPageState createState() => _AlumniMapPageState();
}

class _AlumniMapPageState extends State<AlumniMapPage> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  List<Map<String, dynamic>> _alumniList = [];
  LatLng _initialPosition = const LatLng(-7.7501649, 113.7007051);

  // Satu field pencarian
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAlumniLocations();
  }

  Future<void> _loadAlumniLocations() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('alumniVerified').get();

    Set<Marker> loadedMarkers = {};
    List<Map<String, dynamic>> alumniList = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();

      double? lat;
      double? lng;

      if (data['latitude'] != null && data['longitude'] != null) {
        lat = data['latitude'];
        lng = data['longitude'];
      } else if (data['location'] != null && data['location'] is GeoPoint) {
        GeoPoint geo = data['location'];
        lat = geo.latitude;
        lng = geo.longitude;
      }

      if (lat != null && lng != null) {
        alumniList.add({...data, 'lat': lat, 'lng': lng, 'docId': doc.id});
        final photoUrl = data['photoUrl'] ?? data['profilePictureUrl'];

        Future<BitmapDescriptor> markerIcon =
            (photoUrl != null && photoUrl != "")
                ? _getMarkerFromUrl(photoUrl)
                : _getDefaultMarkerAsset();

        markerIcon.then((icon) {
          final marker = Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(lat!, lng!),
            icon: icon,
            onTap: () => _showAlumniDetail(data),
          );
          setState(() {
            _markers.add(marker);
          });
        });
      }
    }

    if (loadedMarkers.isNotEmpty) {
      setState(() {
        _alumniList = alumniList;
        _markers.clear();
        _markers.addAll(loadedMarkers);
        _initialPosition = loadedMarkers.first.position;
      });
    }
  }

  Future<BitmapDescriptor> _getMarkerFromUrl(String url) async {
    try {
      final http.Response response = await http.get(Uri.parse(url));
      final Uint8List bytes = response.bodyBytes;
      final ui.Codec codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 100,
        targetHeight: 100,
      );
      final ui.FrameInfo fi = await codec.getNextFrame();
      final ui.Image image = fi.image;

      // Buat gambar bulat
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      final double size = 100;
      final Paint paint = Paint();
      final Rect rect = Rect.fromLTWH(0, 0, size, size);

      // Clip lingkaran
      canvas.drawCircle(
        Offset(size / 2, size / 2),
        size / 2,
        Paint()..color = Colors.transparent,
      );
      canvas.clipPath(Path()..addOval(rect));
      canvas.drawImage(image, Offset.zero, paint);

      final ui.Image circularImage = await recorder.endRecording().toImage(
        100,
        100,
      );
      final ByteData? byteData = await circularImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
    } catch (e) {
      // Jika gagal, fallback ke marker default
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    }
  }

  Future<BitmapDescriptor> _getDefaultMarkerAsset() async {
    final ByteData byteData = await rootBundle.load(
      'assets/images/profile-icon.png',
    );
    final Uint8List bytes = byteData.buffer.asUint8List();
    final ui.Codec codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: 85,
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ByteData? resized = await fi.image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return BitmapDescriptor.fromBytes(resized!.buffer.asUint8List());
  }

  void _filterMarkers() {
    String query = _searchController.text.trim().toLowerCase();

    final filtered =
        _alumniList.where((alumni) {
          final alumniName = (alumni['name'] ?? '').toString().toLowerCase();
          final alumniYear = (alumni['graduationYear'] ?? '').toString();
          return query.isEmpty ||
              alumniName.contains(query) ||
              alumniYear == query;
        }).toList();

    Set<Marker> filteredMarkers = {};
    for (var alumni in filtered) {
      filteredMarkers.add(
        Marker(
          markerId: MarkerId(alumni['docId']),
          position: LatLng(alumni['lat'], alumni['lng']),
          onTap: () => _showAlumniDetail(alumni),
        ),
      );
    }

    setState(() {
      _markers
        ..clear()
        ..addAll(filteredMarkers);
      if (filteredMarkers.isNotEmpty) {
        _initialPosition = filteredMarkers.first.position;
      }
    });

    // Jika hanya satu hasil, pindahkan kamera ke marker tersebut
    if (filtered.length == 1) {
      final alumni = filtered.first;
      _mapController.animateCamera(
        CameraUpdate.newLatLng(LatLng(alumni['lat'], alumni['lng'])),
      );
    }

    // Jika tidak ada hasil, tampilkan info
    if (filtered.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Alumni tidak ditemukan')));
    }
  }

  void _showAlumniDetail(Map<String, dynamic> data) {
    final photo = data['photoUrl'] ?? data['profilePictureUrl'];
    final name = data['name'] ?? 'Tanpa Nama';
    final job = data['job'] ?? '-';
    final year = data['graduationYear']?.toString() ?? '-';
    final phone = data['phone'] ?? '-';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (_) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 200),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (photo != null)
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: NetworkImage(photo),
                      )
                    else
                      const CircleAvatar(radius: 40, child: Icon(Icons.person)),
                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            job,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.school,
                                size: 16,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Graduated $year',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.phone,
                                size: 16,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                phone,
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _initialPosition,
                zoom: 14,
              ),
              markers: _markers,
              onMapCreated: (controller) => _mapController = controller,
            ),
          ),
          //Pencarian
          Positioned(
            top: 70,
            left: 16,
            right: 16,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => _filterMarkers(),
                onSubmitted: (val) => _filterMarkers(),
                decoration: InputDecoration(
                  hintText: 'Cari nama atau tahun lulus',
                  prefixIcon: const Icon(Icons.search, color: Colors.blueGrey),
                  suffixIcon:
                      _searchController.text.isNotEmpty
                          ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: Colors.blueGrey,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _filterMarkers();
                            },
                          )
                          : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 0,
                  ),
                ),
                textInputAction: TextInputAction.search,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
