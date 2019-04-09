import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../widgets/products/price_tag.dart';
import 'package:easy_list/widgets/ui_elements/title_default.dart';

import '../models/product.dart';
import '../widgets/products/address_tag.dart';
import '../models/location_data.dart';
import '../widgets/products/product_fab.dart';

class ProductPage extends StatelessWidget {
  final Product product;

  ProductPage(this.product);

  _showWarningDialog(BuildContext context) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Are you sure?'),
            content: Text('This action cannot be undone.'),
            actions: <Widget>[
              FlatButton(
                child: Text('DISCARD'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              FlatButton(
                child: Text('CONTINUE'),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, true);
                },
              )
            ],
          );
        });
    //Navigator.pop(context, true)
  }

  Widget _buildTitlePriceRow(String title, double price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        TitleDefault(title),
        SizedBox(
          width: 8.0,
        ),
        PriceTag(price.toString()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return WillPopScope(
        onWillPop: () {
          Navigator.pop(context, false);
          return Future.value(false); //ignore original pop request
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text('Product Detail'),
          ),
          body: ListView(
            padding: EdgeInsets.all(10.0),
            children: <Widget>[
              Hero(
                tag: product.id,
                child: FadeInImage(
                  image: NetworkImage(product.image),
                  height: 300.0,
                  fit: BoxFit.cover,
                  placeholder: AssetImage('assets/food.jpg'),
                ),
              ),
              SizedBox(
                height: 10.0,
              ),
              AddressTag(
                product.location.address,
                location: LocationData(
                    lat: product.location.lat, lng: product.location.lng),
              ),
              SizedBox(
                height: 10.0,
              ),
              _buildTitlePriceRow(product.title, product.price),
              SizedBox(
                height: 10.0,
              ),
              Center(
                child: Text(product.description),
              ),
            ],
          ),
          floatingActionButton: ProductFab(product),
        ));
  }
}
