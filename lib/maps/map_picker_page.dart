import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapPickerPage extends StatefulWidget {
  @override
  _MapPickerPageState createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  LatLng? pickedLocation;
  GoogleMapController? _controller;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied)
      return;

    final position = await Geolocator.getCurrentPosition();
    _controller?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(position.latitude, position.longitude),
        15,
      ),
    );
  }

  void _onTap(LatLng latLng) {
    setState(() {
      pickedLocation = latLng;
    });
  }

  void _confirmLocation() {
    if (pickedLocation != null) {
      Navigator.pop(context, pickedLocation);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Pilih Lokasi")),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(-7.250445, 112.768845), // Surabaya default
          zoom: 14,
        ),
        onMapCreated: (controller) => _controller = controller,
        onTap: _onTap,
        markers:
            pickedLocation != null
                ? {
                  Marker(
                    markerId: MarkerId("picked"),
                    position: pickedLocation!,
                  ),
                }
                : {},
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _confirmLocation,
        icon: Icon(Icons.check),
        label: Text("Gunakan Lokasi"),
      ),
    );
  }
}
