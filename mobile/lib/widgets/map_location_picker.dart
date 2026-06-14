import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../paginas/home.dart';

class MapLocation {
  const MapLocation({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

class MapLocationPicker extends StatelessWidget {
  const MapLocationPicker({
    super.key,
    required this.height,
    required this.selectedLocation,
    required this.onLocationChanged,
  });

  static const LatLng _initialCenter = LatLng(-27.75, -50.5);

  final double height;
  final MapLocation? selectedLocation;
  final ValueChanged<MapLocation> onLocationChanged;

  @override
  Widget build(BuildContext context) {
    final MapLocation? location = selectedLocation;
    final LatLng selectedPoint = location == null
        ? _initialCenter
        : LatLng(location.latitude, location.longitude);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFFEAEAEA),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFFD8D8D8)),
          ),
          clipBehavior: Clip.antiAlias,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: selectedPoint,
              initialZoom: location == null ? 6.7 : 15,
              minZoom: 5,
              maxZoom: 18,
              onTap: (_, LatLng point) {
                onLocationChanged(
                  MapLocation(
                    latitude: point.latitude,
                    longitude: point.longitude,
                  ),
                );
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.mobile',
              ),
              if (location != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: selectedPoint,
                      width: 46,
                      height: 46,
                      alignment: Alignment.topCenter,
                      child: const Icon(
                        Icons.location_pin,
                        color: Color(0xFFFF6A00),
                        size: 46,
                        shadows: [
                          Shadow(
                            color: Colors.black38,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          location == null
              ? 'Toque no mapa para marcar a localização.'
              : 'Localização marcada: ${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: BaileSulColors.headerText,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
