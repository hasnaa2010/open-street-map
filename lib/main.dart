import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:http/http.dart'as http;
import 'dart:convert';

void main(){
  runApp(MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MapScreen(),
    );
  }
}
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
   final MapController mapController = MapController();
   LocationData? currentLocation;
   List<LatLng> routePoints =[];
   List<Marker> markers =[];
   final String orsApiKey='5b3ce3597851110001cf6248385c6f497e94488c8d83330b9649cdb3';
   
   
   @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }
Future<void> _getCurrentLocation() async{
     var location = Location();

     try{
       var userLocation = await location.getLocation();
       setState(() {
         currentLocation = userLocation;
         markers.add(
           Marker(
             width: 80,
             height: 80,
             point: LatLng(userLocation.latitude!, userLocation.longitude!),
             child: Icon(Icons.my_location,color: Colors.blue,size: 40,)
           )
         );
       });
     } on Exception {
       currentLocation = null;
     }
     location.onLocationChanged.listen((LocationData newLocation){
       setState(() {
         currentLocation = newLocation ;
       });
     });
}
Future<void> _getRoute(LatLng destination) async {
     if (currentLocation == null) return ;
     final start =LatLng(currentLocation!.latitude!, currentLocation!.longitude!);
     final response = await http.get(
       Uri.parse(
           'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$orsApiKey&start=${start.longitude},${start.latitude}&end=${destination.longitude},${destination.latitude}'),
     );
     if (response.statusCode == 200){
       final date = json.decode(response.body);
       final List<dynamic> coords =
           date['features'][0]['geometry']['coordinates'];
       setState(() {
         routePoints =
             coords.map((coord)=> LatLng(coord[1],coord[0])).toList();
         markers.add(
           Marker(
             width: 80,
               height: 80,
               point: destination,
               child:Icon(Icons.location_on,color: Colors.red,size: 40,)
         ));
       });
     }else {
       print('failled to fetch route');
     }
}
 void _addDestinationMarker(LatLng point){
     setState(() {
       markers.add(
         Marker(
           width: 80,
             height: 80,
             point: point,
             child: Icon(Icons.location_on,color: Colors.red,size: 40,)
       ));

     });
    _getRoute(point);
 }
 @override
  Widget build (BuildContext context){
     return Scaffold(
       appBar:  AppBar(
         title: Text('Street Map'),
         backgroundColor: Colors.grey,
       ),
       body: currentLocation == null
         ? Center(child: CircularProgressIndicator())
           : FlutterMap(
           mapController: mapController,
           options: MapOptions(
             initialCenter: LatLng(
               currentLocation!.latitude!,currentLocation!.longitude!),
                 initialZoom: 15 ,
             onTap: (tapPosition, point)=> _addDestinationMarker(point),
             ),
         children: [
           TileLayer(
             urlTemplate:
             "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
             subdomains: const ['a', 'b', 'c'],
           ),
           MarkerLayer(
             markers: markers,
           ),
           PolylineLayer(
             polylines: [
               Polyline(
                 points: routePoints,
                 strokeWidth: 4.0,
                 color: Colors.blue,
               ),
             ],
           ),
         ],
           ),
       floatingActionButton: FloatingActionButton(
         onPressed: () {
           if (currentLocation != null) {
             mapController.move(
               LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
               15.0,
             );
           }
         },
         child: const Icon(Icons.my_location),
       ),


       );

 }
}
