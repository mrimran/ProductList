import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/location_data.dart';

class AddressTag extends StatelessWidget {
  final String address;
  final LocationData location;

  AddressTag(this.address, {this.location});

  void openMapDialog(context) {
    if(location != null) {
      Navigator.of(context).push(new MaterialPageRoute<Null>(
          builder: (BuildContext context) {
            return MapDialog(location);
          },
          fullscreenDialog: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 5.0),
      child: GestureDetector(
        onTap: () {
          openMapDialog(context);
        },
        child: Text(
          address,
          style: TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey, width: 1.0),
          borderRadius: BorderRadius.circular(6.0)),
    );
  }
}

class MapDialog extends StatelessWidget {
  GoogleMapController mapController;
  LocationData location;

  MapDialog(this.location);

  @override
  Widget build(BuildContext context) {
    final gMap = GoogleMap(
      initialCameraPosition: CameraPosition(
          target: LatLng(location.lat, location.lng),
          zoom: 16.0),
      onMapCreated: (GoogleMapController controller) {
        mapController = controller;
        mapController.addMarker(MarkerOptions(
          position: LatLng(location.lat, location.lng),
        ));
      },
    );

    double screenWidth = MediaQuery.of(context).size.width;

    double screenHeight = MediaQuery.of(context).size.height;

    return new Scaffold(
        appBar: new AppBar(
          title: const Text('Map'),
        ),
        body: Container(
          width: screenWidth,
          height: screenHeight,
          child: gMap,
        ));
  }
}
