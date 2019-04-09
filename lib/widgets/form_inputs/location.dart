import 'package:flutter/material.dart';

//import 'package:map_view/map_view.dart';
import 'dart:convert'; //JSON to dart maps

import 'package:http/http.dart' as http;
import 'package:location/location.dart' as geoloc;
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/location_data.dart';
import '../../models/product.dart';

class LocationInput extends StatefulWidget {
  final Function setLocation;
  final Product product;

  LocationInput(this.setLocation, this.product);

  @override
  State<StatefulWidget> createState() {
    return LocationInputState();
  }
}

class LocationInputState extends State<LocationInput> {
  GoogleMapController mapController;
  final FocusNode _addressInput = FocusNode();
  Uri _staticMapUri;
  final TextEditingController _addressInputController = TextEditingController();
  LocationData _locationData;

  @override
  void initState() {
    _addressInput.addListener(_updateLocation);

    if (widget.product != null && widget.product.location != null) {
      getStaticMap(widget.product.location.address, geocode: false);
    }

    super.initState();
  }

  void setControllerTextInitialValue(Product product, String text,
      String productText, TextEditingController controller) {
    if (product == null && text == '') {
      controller.text = '';
    } else if (product != null && text == '') {
      controller.text = productText;
    } else if (text != '') {
      controller.text = text;
    } else {
      controller.text = '';
    }
  }

  @override
  void dispose() {
    //stop always listening, this will make sure to only listen for address change if the location widget is loaded
    this._addressInput.removeListener(_updateLocation);
    super.dispose();
  }

  void getStaticMap(String address,
      {bool geocode = true, double lat, double lng}) async {
    if (address.isEmpty) {
      setState(() {
        _staticMapUri = null;
      });
      widget.setLocation(null);
      return;
    }

    if (geocode) {
      final Uri uri = Uri.https(
          'maps.googleapis.com', '/maps/api/geocode/json', {
        'address': address,
        'key': 'AIzaSyDp2Ed2RgWYzpfut750mb8DITmyo0afw9g'
      });
      final http.Response res = await http.get(uri);
      final decodedRes = json.decode(res.body);

      final formattedAddr = decodedRes['results'][0]['formatted_address'];
      final coords = decodedRes['results'][0]['geometry']['location'];
      _locationData = LocationData(
          address: formattedAddr, lat: coords['lat'], lng: coords['lng']);
    } else if (lat == null && lng == null) {
      _locationData = widget.product.location;
    } else {
      _locationData = LocationData(address: address, lat: lat, lng: lng);
    }

    /*final StaticMapProvider staticMapProvider =
        StaticMapProvider('AIzaSyDp2Ed2RgWYzpfut750mb8DITmyo0afw9g');
    final Uri staticMapUri = staticMapProvider.getStaticUriWithMarkers(
        [Marker('position', 'Position', _locationData.lat, _locationData.lng)],
        center: Location(_locationData.lat, _locationData.lng),
        width: 500,
        height: 300,
        maptype: StaticMapViewType.roadmap);*/

    _goToUserLocationOnGoogleMap(_locationData);

    widget.setLocation(_locationData);
    setState(() {
      _addressInputController.text = _locationData.address;
      //this._staticMapUri = staticMapUri;
      this._staticMapUri = null;
    });
  }

  void _updateLocation() {
    if (!_addressInput.hasFocus) {
      getStaticMap(_addressInputController.text);
    }
  }

  void _getUserLocation() async {
    try {
      final location = geoloc.Location();
      final currLocation = await location.getLocation();
      final address = await _getAddressFromGeocode(
          currLocation.latitude, currLocation.longitude);

      getStaticMap(address,
          geocode: false,
          lat: currLocation.latitude,
          lng: currLocation.longitude);
    } catch (error) {
      showDialog(context: context, builder: (BuildContext context) {
        return AlertDialog(title: Text('Could not fetch location'),
          content: Text('Please add an address manually.'), actions: <Widget>[
            FlatButton(child: Text('Okay'), onPressed: () {
              Navigator.pop(context);
            },)
          ],);
      });
    }
  }

  Future _getAddressFromGeocode(double lat, double lng) async {
    final Uri uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
      'latlng': '$lat,$lng',
      'key': 'AIzaSyDp2Ed2RgWYzpfut750mb8DITmyo0afw9g'
    });

    final http.Response res = await http.get(uri);
    final decodedRes = json.decode(res.body);

    return decodedRes['results'][0]['formatted_address'];
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      mapController = controller;
    });

    if (_locationData !=
        null) { //moving map on the location in product edit mode too.
      _goToUserLocationOnGoogleMap(_locationData);
    }
  }

  void _goToUserLocationOnGoogleMap(LocationData location) {
    print('inside mapController');
    print(location.lat);

    if (mapController == null) {
      return;
    }

    mapController.addMarker(MarkerOptions(
      position: LatLng(location.lat, location.lng),
    ));
    mapController.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        target: LatLng(location.lat, location.lng),
        zoom: 16.0,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    return Column(
      children: <Widget>[
        TextFormField(
          focusNode: _addressInput,
          controller: _addressInputController,
          validator: (String value) {
            if (_locationData == null || value.isEmpty) {
              return 'No valid location found.';
            }
          },
          decoration: InputDecoration(labelText: "Address"),
        ),
        SizedBox(
          height: 10.0,
        ),
        FlatButton(
          child: Text('Locate User'),
          onPressed: _getUserLocation,
        ),
        SizedBox(
          height: 10.0,
        ),
        /*_staticMapUri == null
            ? Container()
            : Image.network(this._staticMapUri.toString()),*/
        Center(
          child: SizedBox(
            width: screenWidth * 0.95,
            height: 200.0,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                  target: _locationData != null
                      ? LatLng(_locationData.lat, _locationData.lng)
                      : LatLng(0.00, 0.00),
                  zoom: 14.0),
              onMapCreated: _onMapCreated,
            ),
          ),
        ),
      ],
    );
  }
}
