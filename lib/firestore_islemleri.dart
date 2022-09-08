import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreIslemleri extends StatelessWidget {
  FirestoreIslemleri({Key? key}) : super(key: key);

  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _userSubscribe = null;

  @override
  Widget build(BuildContext context) {
    //IDs
    debugPrint(_firestore.collection("users").id);
    debugPrint(_firestore.collection("users").doc().id);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Firestore Islemleri"),
      ),
      body: Center(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () => VeriEklemeAdd(),
              child: const Text("Veri Ekleme Add"),
            ),
            ElevatedButton(
              onPressed: () => veriEklemeSet(),
              style: ElevatedButton.styleFrom(primary: Colors.green),
              child: const Text("Veri Ekleme Set"),
            ),
            ElevatedButton(
              onPressed: () => veriGuncelleme(),
              style: ElevatedButton.styleFrom(primary: Colors.yellow),
              child: const Text("Veri Güncelleme"),
            ),
            ElevatedButton(
              onPressed: () => veriSil(),
              style: ElevatedButton.styleFrom(primary: Colors.red),
              child: const Text("Veri Sil"),
            ),
            ElevatedButton(
              onPressed: () => veriOkuOneTime(),
              style: ElevatedButton.styleFrom(primary: Colors.red),
              child: const Text("veri Oku One Time"),
            ),
            ElevatedButton(
              onPressed: () => veriOkuRealTime(),
              style: ElevatedButton.styleFrom(primary: Colors.purpleAccent),
              child: const Text("Veri Oku Real Time"),
            ),
            ElevatedButton(
              onPressed: () => streamDurdur(),
              style: ElevatedButton.styleFrom(primary: Colors.greenAccent),
              child: const Text("Stream Durdur"),
            ),
            ElevatedButton(
              onPressed: () => batchKavrami(),
              style: ElevatedButton.styleFrom(primary: Colors.blueGrey),
              child: const Text("Batch Kavramı"),
            ),
            ElevatedButton(
              onPressed: () => transactionKavrami(),
              style: ElevatedButton.styleFrom(primary: Colors.brown),
              child: const Text("Transaction Kavramı"),
            ),
          ],
        ),
      ),
    );
  }

  VeriEklemeAdd() async {
    Map<String, dynamic> _eklenecekUser = <String, dynamic>{};
    _eklenecekUser["name"] = "numan";
    _eklenecekUser["age"] = 24;
    _eklenecekUser["isStudent"] = false;
    _eklenecekUser["address"] = {"city": "istanbul", "province": "üsküdar"};
    _eklenecekUser["renkler"] = FieldValue.arrayUnion(["mavi", "yesil"]);
    _eklenecekUser["createdAt"] = FieldValue.serverTimestamp();
    await _firestore.collection("users").add(_eklenecekUser);
  }

  veriEklemeSet() async {
    var _yeniDocID = _firestore.collection("users").doc().id;

    await _firestore
        .doc("users/$_yeniDocID")
        .set({"isim": "numan", "userID": _yeniDocID});
    await _firestore.doc("users/m9hbsuNl8ULPE40xn883").set({
      "University": "Boğaziçi",
      "age": FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  veriGuncelleme() async {
    await _firestore.doc("users/m9hbsuNl8ULPE40xn883").update({
      "name": "güncel numan",
      "isStudent": true,
    });
  }

  veriSil() async {
    await _firestore.doc("users/m9hbsuNl8ULPE40xn883").delete();

    await _firestore
        .doc("users/m9hbsuNl8ULPE40xn883")
        .update({"okul": FieldValue.delete()});
  }

  veriOkuOneTime() async {
    var _usersDocuments = await _firestore.collection("users").get();
    debugPrint(_usersDocuments.size.toString());
    debugPrint(_usersDocuments.docs.length.toString());
    for (var eleman in _usersDocuments.docs) {
      debugPrint("Döküman id ${eleman.id}");
      Map userMap = eleman.data();
      debugPrint(userMap["name"]);
    }

    var _numanDoc = await _firestore.doc("users/76L4QqKndEKGFqcGZfb1").get();
    debugPrint(_numanDoc.data()!["address"]["city"].toString());
  }

  veriOkuRealTime() async {
    //var _userStream = await _firestore.collection("users").snapshots();
    var _userDocStream =
        await _firestore.doc("users/76L4QqKndEKGFqcGZfb1").snapshots();
    _userSubscribe = _userDocStream.listen((event) {
      /* event.docChanges.forEach((element) {
        debugPrint(element.doc.data().toString());
      }); */

      debugPrint(event.data().toString());
      /*event.docs.forEach((element) {
        debugPrint(element.data().toString());
      });*/
    });
  }

  streamDurdur() async {
    await _userSubscribe?.cancel();
  }

  batchKavrami() async {
    WriteBatch _batch = _firestore.batch();
    CollectionReference _counterColRef = _firestore.collection("counter");

    // TOPLU EKLEME
    /*for (int i = 0; i < 100; i++) {
      var _yeniDoc = _counterColRef.doc();
      _batch.set(_yeniDoc, {'sayac': ++i, 'id': _yeniDoc.id});
    }*/

    //TOPLU GÜNCELLEME
    /*var _counterDocs = await _counterColRef.get();
    _counterDocs.docs.forEach((element) {
      _batch.update(
          element.reference, {"createdAt": FieldValue.serverTimestamp()});
    });*/

    //TOPLU SİLME
    var _counterDocs = await _counterColRef.get();
    _counterDocs.docs.forEach((element) {
      _batch.delete(element.reference);
    });

    await _batch.commit();
  }

  transactionKavrami() async {
    _firestore.runTransaction((transaction) async {
      //mervenin bakiyesini öğren
      //merveden 100 lira düş
      //numana 100 lira ekle
      DocumentReference<Map<String, dynamic>> merveRef =
          _firestore.doc('users/7tPYe4V6vEosxPtR83H9');
      DocumentReference<Map<String, dynamic>> numanRef =
          _firestore.doc('users/76L4QqKndEKGFqcGZfb1');

      var _merveSnapshot = await transaction.get(merveRef);
      var _merveBakiye = _merveSnapshot.data()!['para'];
      if (_merveBakiye > 100) {
        var _yeniBakiye = _merveBakiye - 100;
        transaction.update(merveRef, {"para": _yeniBakiye});
        transaction.update(numanRef, {"para": FieldValue.increment(100)});
      }
    });
  }
}
