import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';

import './price_tag.dart';
import 'package:easy_list/widgets/ui_elements/title_default.dart';
import './address_tag.dart';
import '../../models/product.dart';
import '../../scoped_models/main.dart';
import '../../models/location_data.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  ProductCard(this.product);

  Widget _buildTitlePriceRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Flexible(//allows line breaks
          child: TitleDefault(product.title),
        ),
        Flexible(
          child: SizedBox(
            width: 8.0,
          ),
        ),
        Flexible(
          child: PriceTag(product.price.toString()),
        )
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return ScopedModelDescendant<MainModel>(
        builder: (BuildContext context, Widget child, MainModel model) {
      return ButtonBar(
        alignment: MainAxisAlignment.center,
        children: <Widget>[
          IconButton(
            icon: Icon(Icons.info),
            color: Theme.of(context).accentColor,
            onPressed: () {
              model.selectProduct(product.id);
              Navigator.pushNamed<bool>(context, '/product/' + product.id).then(
                  (_) => model.selectProduct(
                      null)); //reset product to null when going back
            },
          ),
          IconButton(
            icon: Icon(
                product.isFavorite ? Icons.favorite : Icons.favorite_border),
            color: Colors.red,
            onPressed: () {
              model.selectProduct(product.id);
              model.toggleProductFavorite();
            },
          )
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Card(
      child: Column(
        children: <Widget>[
          //Image.asset(product.image),
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
          _buildTitlePriceRow(),
          SizedBox(
            height: 10.0,
          ),
          AddressTag(
            product.location.address,
            location: LocationData(
                lat: product.location.lat, lng: product.location.lng),
          ),
          _buildActionButtons(context)
        ],
      ),
    );
  }
}
