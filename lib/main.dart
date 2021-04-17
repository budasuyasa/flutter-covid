import 'package:flutter/material.dart';
import 'dart:convert';
import 'provinsi.dart';
import 'package:http/http.dart' as http;
import 'indonesia.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // Widget utama dari aplikasi
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Covid',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: PageIndonesia(title: 'Data Covid'),
    );
  }
}

/**
 * PageeIndonesia Screen utama dari aplikasi yang menampilkan total keseluruhan 
 * data Covid di Indonesia. Data diambil dengan menggunakan REST API dari
 * https://api.kawalcorona.com/indonesia/
 */
class PageIndonesia extends StatefulWidget {
  PageIndonesia({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _PageIndonesiaState createState() => _PageIndonesiaState();
}

/**
 * State dari PageIndonesia. Method getDataIndonesia() dipanggil ketika inisiasi
 * state. dataIndonesia merupakan variabel yang digunakan untuk menampung
 * response API Request ke dalam objek Indonesia (indonesia.dart)
 */
class _PageIndonesiaState extends State<PageIndonesia> {
  Future<Indonesia> dataIndonesia;

  @override
  void initState() {
    super.initState();
    dataIndonesia = getDataIndonesia();
  }

  @override
  Widget build(BuildContext context) {
    /**
     * Screen PageIndonesia berisikan list widget Text yang menampilkan data
     * pasien positif, meninggal dan sembuh. Widget ElevatedButton untuk
     * melakukan navigasi ke PageProvinsi
     */
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        // Child dari widget dibungkus dengan FutureBuilder karena akan
        // mengamil dari state dataIndonesia
        child: FutureBuilder<Indonesia>(
          future: dataIndonesia,
          builder: (context, snapshoot) {
            if (snapshoot.hasData) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text("Data covid di seluruh Indonesia",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 25)),
                  Text("Positif: ${snapshoot.data.positif}",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.pink[400],
                          fontSize: 25)),
                  Text("Sembuh: ${snapshoot.data.sembuh}",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontSize: 25)),
                  Text("Meninggal: ${snapshoot.data.meninggal}",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                          fontSize: 25)),
                  ElevatedButton(
                      onPressed: () => {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => PageProvinsi()),
                            )
                          },
                      child: Text("Lihat di Provinsi")),
                  ElevatedButton(
                      onPressed: () => {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => PageTentang()),
                            )
                          },
                      child: Text("Tentang Saya"))
                ],
              );
            } else {
              return Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }
}

/**
 * Method getDataIndonesia() merupakan method yang berfungsi untuk melakukan
 * request http ke endpoint REST API. Response dari request ke endpoint
 * indonesia adalah JSON of array. Contoh bentuk response:
 * [
 *   {
 *     "name": "Indonesia",
 *     "positif": "1,594,722",
 *     "sembuh": "1,444,229",
 *     "meninggal": "43,196",
 *     "dirawat": "107,297"
 *   }
 * ]
 */
Future<Indonesia> getDataIndonesia() async {
  final response =
      await http.get(Uri.https('api.kawalcorona.com', 'indonesia'));

  if (response.statusCode == 200) {
    // Jika status code dari response sukses (200) maka response JSON
    // diserialisasi menjadi object Indonesia (indonesia.dart)
    // Karena response berbentuk array, maka proses serialisasi dilakukan dari
    // array pertama (index ke 0 pada fungsi jsonDecode)
    return Indonesia.fromJson(jsonDecode(response.body)[0]);
  } else {
    // Jika request gagal
    throw Exception('Gagal Mendapatkan data');
  }
}

class PageProvinsi extends StatefulWidget {
  PageProvinsi({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _PageProvinsiState createState() => _PageProvinsiState();
}

class _PageProvinsiState extends State<PageProvinsi> {
  List<Provinsi> dataProvinsi;
  List<Provinsi> firstDataProvinsi;

  // Controller untuk text input filter (pencarian)
  final searchController = TextEditingController();

  /**
   * Method untuk mendapatkan list data provinsi dari REST API
   * return value dari method ini adalah List<Provinsi> karena response dari 
   * REST API berbentuk JSON Array of object. Setiap object JSON dari repsponse
   * diserialisasi menjadi object Provinsi (provinsi.dart)
   */
  Future<Null> getDataProvinsi() async {
    final response =
        await http.get(Uri.https('api.kawalcorona.com', 'indonesia/provinsi'));

    if (response.statusCode == 200) {
      // Jika status code dari response sukses (200) maka response JSON
      // diserialisasi menjadi list object provinsi (provinsi.dart)
      // Variabel _provinsi bertipe List<Provinsi> berfungsi untuk menampung
      // response dari endpoint REST API.
      List<Provinsi> _provinsi = (jsonDecode(response.body) as List)
          .map((i) => Provinsi.fromJson(i))
          .toList();

      setState(() {
        firstDataProvinsi = _provinsi;
        dataProvinsi = _provinsi;
      });
    } else {
      // Jika request gagal
      throw Exception('Gagal Mendapatkan data');
    }
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    searchController.dispose();
    super.dispose();
  }

  /**
   * Method untuk melakukan filter data yang ditampilkan dalam listview
   * dengan memanipulasi state dataProvinsi 
   */
  void filterProvinsi() {
    setState(() {
      if (searchController.text.isEmpty) {
        getDataProvinsi();
      } else {
        List<Provinsi> _temp = List<Provinsi>();
        for (var i = 0; i < firstDataProvinsi.length; i++) {
          if (firstDataProvinsi[i]
              .attributes
              .provinsi
              .toLowerCase()
              .contains(searchController.text.toLowerCase())) {
            _temp.add(firstDataProvinsi[i]);
          }
        }
        dataProvinsi.clear();
        dataProvinsi.addAll(_temp);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // Ambil data dari API ketika screen pertama kali dirender
    getDataProvinsi();
  }

  @override
  Widget build(BuildContext context) {
    /**
     * Screen PageProvinsi berisikan list widget Card yang menampilkan data
     * pasien positif, meninggal dan sembuh dari masing-masing provinsi dengan
     * menggunakan endpoint /indonesia/provinsi
     */
    return Scaffold(
      appBar: AppBar(
        title: Text("Data Covid di Pronvinsi Indonesia"),
      ),
      body: Column(children: <Widget>[
        Row(
          children: <Widget>[
            Flexible(
              child: new TextField(
                controller: searchController,
                decoration: InputDecoration(
                    border: OutlineInputBorder(), hintText: 'Cari Provinsi'),
              ),
            ),
            ElevatedButton(onPressed: filterProvinsi, child: Text("Cari"))
          ],
        ),
        // Child dari widget dibungkus dengan FutureBuilder karena akan
        // mengamil dari state dataProvinsi dengan tipe List<Provinsi>
        // Setiap data dalam ListProvinsi akan ditampilkan dalam widget ListView
        // yang mempunyai child Card
        Flexible(
            child: ListView.builder(
                scrollDirection: Axis.vertical,
                shrinkWrap: true,
                padding: EdgeInsets.all(8),
                itemCount: dataProvinsi == null ? 0 : dataProvinsi.length,
                // Setiap item list view merupakan widget card
                itemBuilder: (BuildContext context, int index) {
                  return Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Text(
                              "${dataProvinsi[index].attributes.provinsi}",
                              style: TextStyle(fontSize: 18),
                            )),
                        Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Text(
                              "Positif: ${dataProvinsi[index].attributes.kasusPosi}",
                              style: TextStyle(
                                  fontSize: 14, color: Colors.pink[200]),
                            )),
                        Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Text(
                              "Meninggal: ${dataProvinsi[index].attributes.kasusMeni}",
                              style: TextStyle(fontSize: 14, color: Colors.red),
                            )),
                        Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              "Sembuh: ${dataProvinsi[index].attributes.kasusSemb}",
                              style:
                                  TextStyle(fontSize: 14, color: Colors.green),
                            )),
                      ],
                    ),
                  );
                })),
      ]),
    );
  }
}

class PageTentang extends StatelessWidget{
  @override
  Widget build(BuildContext
   context) {
    /**
     * Screen tentang Saya, hanya Stateless Widget Menampilkan informasi nama
     * nim dan kelas
     */
    return Scaffold(
      appBar: AppBar(
        title: Text("Tentang Saya"),
      ),
      body: Center(
        child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text("Nama: ",
                      style:
                          TextStyle(fontSize: 25)),
                  Text("NIM: ",
                      style:
                          TextStyle(fontSize: 25)),
                  Text("Kelas: ",
                      style:
                          TextStyle(fontSize: 25)),
                ],
              )
      ),
    );

  }
  
}
