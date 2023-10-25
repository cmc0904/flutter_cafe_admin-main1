import 'package:flutter/material.dart';
import 'package:flutter_cafe_admin/my_cafe.dart';

MyCafe myCafe = MyCafe();
String categoryCollectionName = 'cafe-category';
String itemCollectionName = 'cafe-item';

class CafeItem extends StatefulWidget {
  const CafeItem({super.key});

  @override
  State<CafeItem> createState() => _CafeItemState();
}

class _CafeItemState extends State<CafeItem> {
  dynamic body = const Text('Loading...');

  Future<void> getCategory() async {
    setState(() {
      body = FutureBuilder(
        builder: (context, snapshot) {
          if (snapshot.hasData == true) {
            var datas = snapshot.data?.docs;
            if (datas == null) {
              return const Center(
                child: Text("empty"),
              );
            }
            //진짜 데이터가 있는 곳
            //데이터가 리스트 형태이기 때문에 리스트뷰를 이용해서 하나씩 뿌려줌
            return ListView.separated(
              itemBuilder: (context, index) {
                var data = datas[index];
                return ListTile(
                  onTap: () async {
                    var result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CafeItemList(id: data.id),
                        ));
                  },
                  title: Text(data["categoryName"]),
                  trailing: PopupMenuButton(
                    onSelected: (value) async {
                      switch (value) {
                        case 'modify':
                          var result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CafeCategoryAddForm(id: datas[index].id),
                              ));
                          if (result == true) {
                            getCategory();
                          }
                          break;
                        case 'delete':
                          var result = await myCafe.delete(
                              collectionName: categoryCollectionName,
                              id: data.id);
                          if (result == true) {
                            getCategory();
                          }
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'modify',
                        child: Text('수정'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('삭제'),
                      ),
                    ],
                  ),
                );
              },
              separatorBuilder: (context, index) => const Divider(),
              itemCount: datas.length,
            );
          } else {
            //아직 기다리는 중
            return const Center(
              child: Text("불러오는중"),
            );
          }
        },
        future: myCafe.get(
          collectionName: categoryCollectionName,
          id: null,
          fieldName: null,
          fieldValue: null,
        ),
      );
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCategory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: body,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          var result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CafeCategoryAddForm(id: null),
            ),
          );
          if (result) {
            getCategory();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class CafeCategoryAddForm extends StatefulWidget {
  String? id;
  CafeCategoryAddForm({super.key, required this.id});

  @override
  State<CafeCategoryAddForm> createState() => _CafeCategoryAddFormState();
}

class _CafeCategoryAddFormState extends State<CafeCategoryAddForm> {
  TextEditingController controller = TextEditingController();

  String? id;
  var isUsed = true;

  Future<dynamic> getData({required String id}) async {
    var data = await myCafe.get(
      collectionName: categoryCollectionName,
      id: id,
      fieldName: null,
      fieldValue: null,
    );
    setState(() {
      controller.text = data['categoryName'];
      isUsed = data['isUsed'];
    });
    return data;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    id = widget.id;
    if (id != null) {
      getData(id: id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Category Add"),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                var data = {
                  'categoryName': controller.text,
                  'isUsed': isUsed,
                };
                var result = id != null
                    ? await myCafe.update(
                        collectionName: categoryCollectionName,
                        id: id!,
                        data: data,
                      )
                    : await myCafe.insert(
                        collectionName: categoryCollectionName,
                        data: {
                          'categoryName': controller.text,
                          'isUsed': isUsed,
                        },
                      );
                if (result) {
                  Navigator.pop(context, true);
                }
              }
            },
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.white),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          TextFormField(
            decoration: const InputDecoration(
              label: Text('Category Name'),
              border: OutlineInputBorder(),
            ),
            controller: controller,
          ),
          SwitchListTile(
            title: const Text("Used?"),
            value: isUsed,
            onChanged: (value) {
              setState(
                () {
                  isUsed = value;
                },
              );
            },
          )
        ],
      ),
    );
  }
}

// 아이템 목록 보기
class CafeItemList extends StatefulWidget {
  String id;
  CafeItemList({super.key, required this.id});

  @override
  State<CafeItemList> createState() => _CafeItemListState();
}

class _CafeItemListState extends State<CafeItemList> {
  late String id;
  dynamic dropdownMenu = const Text("Loading . . .");
  dynamic itemList = const Text("Item List");
  @override
  void initState() {
    // TODO: implement initState
    id = widget.id;
    getCategory(id);
  }

  Future<void> getCategory(String id) async {
    var datas = myCafe.get(collectionName: categoryCollectionName);
    List<DropdownMenuEntry> entries = [];

    setState(() {
      dropdownMenu = FutureBuilder(
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            var datas = snapshot.data.docs;
            for (var data in datas) {
              entries.add(DropdownMenuEntry(
                  value: data.id, label: data['categoryName']));
            }
            return DropdownMenu(
              dropdownMenuEntries: entries,
              initialSelection: id,
              onSelected: (value) {
                print('$value Item List');
              },
            );
          }
          return const Text("Loading . . ");
        },
        future: datas,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Item List"),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CafeItemAddForm(categoryId: id, itemId: null),
                  ));
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          dropdownMenu,
        ],
      ),
    );
  }
}

//아이템 추가 / 수정 폼

class CafeItemAddForm extends StatefulWidget {
  String categoryId;
  String? itemId;
  CafeItemAddForm({super.key, required this.categoryId, required this.itemId});

  @override
  State<CafeItemAddForm> createState() => _CafeItemAddFormState();
}

class _CafeItemAddFormState extends State<CafeItemAddForm> {
  late String categoryId;
  String? itemId;
  TextEditingController controllerTitle = TextEditingController();
  TextEditingController controllerPrice = TextEditingController();
  TextEditingController controllerDesc = TextEditingController();
  bool isSoldOut = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    categoryId = widget.categoryId;
    itemId = widget.itemId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Item Add Form"),
        actions: [
          TextButton(
            onPressed: () async {
              var data = {
                'itemName': controllerTitle.text,
                'itemPrice': int.parse(controllerPrice.text),
                'itemDesc': controllerDesc.text,
                'itemIsSoldOut': isSoldOut
              };

              var result = await myCafe.insert(
                  collectionName: itemCollectionName, data: data);

              if (result) {
                Navigator.pop(context, true);
              }
            },
            child: const Text(
              "Save",
              style: TextStyle(color: Colors.white),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          TextFormField(
            controller: controllerTitle,
            decoration: const InputDecoration(
              label: Text("상품명"),
            ),
          ),
          TextFormField(
            controller: controllerPrice,
            decoration: const InputDecoration(
              label: Text("가격"),
            ),
          ),
          TextFormField(
            maxLines: 1,
            controller: controllerDesc,
            decoration: const InputDecoration(
              label: Text("상품 설명"),
            ),
          ),
          SwitchListTile(
            value: isSoldOut,
            onChanged: (value) {
              setState(() {
                isSoldOut = value;
              });
            },
            title: const Text("매진 여부"),
          )
        ],
      ),
    );
  }
}
