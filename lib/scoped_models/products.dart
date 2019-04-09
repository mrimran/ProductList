import 'package:scoped_model/scoped_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

import '../models/product.dart';
import '../scoped_models/user.dart';
import '../models/location_data.dart';

mixin ProductsModel on Model {
  List<Product> _products = [];
  String _selectedProductId;
  bool _showFav = false;
  bool isLoading = false;

  final productsEndpoint = 'https://flutter-easylist-35b62.firebaseio.com/';

  List<Product> get products {
    //Making clone of original List so we make changes in clone not the original one.
    return List.from(_products);
  }

  List<Product> get displayedProducts {
    if (_showFav) {
      return _products.where((Product product) => product.isFavorite).toList();
    }

    return List.from(_products);
  }

  void addProduct(Product product) {
    _products.add(product);
  }

  Future uploadImageOnServer(File image, {String imagePath}) async {
    final mimeTypeData =
        lookupMimeType(image.path).split('/'); //info will be like image/jpg
    final imageUploadRequest = http.MultipartRequest(
        'POST',
        Uri.parse(
            'https://us-central1-flutter-easylist-35b62.cloudfunctions.net/storeImage'));

    final file = await http.MultipartFile.fromPath('image', image.path, contentType: MediaType(mimeTypeData[0], mimeTypeData[1]));
    
    imageUploadRequest.files.add(file);

    if(imagePath != null) {//updating an existing product image
      imageUploadRequest.fields['imagePath'] = Uri.encodeComponent(imagePath);//name doesn't matter here as in server code we kept our code generic
    }

    imageUploadRequest.headers['Authorization'] = 'Bearer ${UserModel.loggedInUser.token}';

    try {
      final stremedRes = await imageUploadRequest.send();
      final res = await http.Response.fromStream(stremedRes);

      if(res.statusCode != 200 && res.statusCode != 201) {
        print('Something went wrong.');
        print(json.decode(res.body));

        return null;
      }
      return json.decode(res.body);
    } catch (error) {
      print(error);

      return null;
    }
  }

  Future saveProductOnServer(Map productData, {String productId = ''}) async {
    if (productId.isEmpty) {
      return await http.post(
          productsEndpoint +
              'products.json?auth=${UserModel.loggedInUser.token}',
          body: json.encode(productData));
    } else {
      return await http.put(
          productsEndpoint +
              'products/$productId.json?auth=${UserModel.loggedInUser.token}',
          body: json.encode(productData));
    }
  }

  int get selectedProductIndex {
    return _products.indexWhere((Product product) {
      return product.id == this.selectedProductId;
    });
  }

  void updateProduct(Product product) {
    _products[this.selectedProductIndex] = product;
  }

  void deleteProduct() async {
    final deletedProductId = selectedProduct.id;
    _products.removeAt(selectedProductIndex);
    this._selectedProductId = null;
    try {
      await http.delete(productsEndpoint +
          'products/$deletedProductId.json?auth=${UserModel.loggedInUser.token}');
      this.isLoading = false;
    } catch (e) {
      print(e.toString());
      this.isLoading = false;
    }
  }

  void selectProduct(String productId) {
    _selectedProductId = productId;
  }

  String get selectedProductId {
    return _selectedProductId;
  }

  Product get selectedProduct {
    if (_selectedProductId == null || _products.length <= 0) {
      return null;
    }

    return _products.firstWhere((product) {
      return product.id == this.selectedProductId;
    });
  }

  void toggleProductFavorite() async {
    final newFavStatus = !_products[this.selectedProductIndex].isFavorite;
    _products[this.selectedProductIndex].isFavorite = newFavStatus;
    try {
      http.Response res;
      if (newFavStatus) {
        res = await http.put(
            productsEndpoint +
                'products/${this.selectedProduct.id}/wishlistUsers/${UserModel.loggedInUser.id}.json?auth=${UserModel.loggedInUser.token}',
            body: json.encode(true));
      } else {
        res = await http.delete(productsEndpoint +
            'products/${this.selectedProduct.id}/wishlistUsers/${UserModel.loggedInUser.id}.json?auth=${UserModel.loggedInUser.token}');
      }

      if (res.statusCode != 200 && res.statusCode != 201) {
        _products[this.selectedProductIndex].isFavorite = !newFavStatus;
      }
    } catch (e) {
      print("toggleProductFavorite: " + e.toString());
      //the request failed to toggle back the local update
      _products[this.selectedProductIndex].isFavorite = !newFavStatus;
    }
    this._selectedProductId = null;
    notifyListeners(); //notify view to reload and update the change of the favt icon
  }

  void toggleFavDisplayMode() {
    _showFav = !_showFav;

    notifyListeners();
  }

  Future fetchProducts({onlyForUser = false}) async {
    this.isLoading = true;
    http.Response res;
    try {
      res = await http.get(productsEndpoint +
          'products.json?auth=${UserModel.loggedInUser.token}');
      final Map<String, dynamic> productListData = json.decode(res.body);
      final List<Product> fetchedProductList = [];

      //print(resBody);
      //add the product list on local codebase

      if (productListData != null) {
        productListData.forEach((String productId, dynamic productData) {
          final LocationData location = LocationData(
              lat: productData['lat'],
              lng: productData['lng'],
              address: productData['address']);

          final Product product = Product(
              id: productId,
              title: productData['title'],
              description: productData['description'],
              price: productData['price'],
              image: productData['image'],
              imagePath: productData['imagePath'],
              location: location,
              userId:
                  productData['userId'] == null ? '' : productData['userId'],
              userEmail:
              productData['userEmail'] == null ? '' : productData['userEmail'],
              isFavorite: productData['wishlistUsers'] != null
                  ? (productData['wishlistUsers'] as Map<String, dynamic>)
                      .containsKey(UserModel.loggedInUser.id)
                  : false);

          if (onlyForUser) {
            if (UserModel.loggedInUser.id == product.userId) {
              fetchedProductList.add(product);
            }
          } else {
            fetchedProductList.add(product);
          }
        });
      }

      _products = fetchedProductList;
    } catch (e) {
      print(e.toString());
    }

    this.isLoading = false;

    notifyListeners();

    return res;
  }

  bool get displayFavOnly {
    return _showFav;
  }

  void toggleIsLoading() {
    this.isLoading = !this.isLoading;
    notifyListeners();
  }
}
