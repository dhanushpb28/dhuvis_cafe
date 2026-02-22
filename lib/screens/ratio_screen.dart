import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RatioScreen extends StatefulWidget {
  const RatioScreen({super.key});

  @override
  State<RatioScreen> createState() => _RatioScreenState();
}

class _RatioScreenState extends State<RatioScreen> {

  Map<String, dynamic> dishes = {};
  String? selectedDish;

  List<String> ingredients = [];
  List<double> base = [];
  List<double> result = [];

  // ⭐ NEW: controllers for Enter fields
  List<TextEditingController> enterControllers = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString("dishes");

    if (data != null) {
      dishes = jsonDecode(data);
    }

    setState(() {});
  }

  Future saveData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("dishes", jsonEncode(dishes));
  }

  void saveCurrentDish() {
    if (selectedDish == null) return;

    dishes[selectedDish!] = {
      "ingredients": ingredients,
      "base": base,
      "baseOutput": baseOutput, // ⭐ save output
    };

    saveData();
  }

  // ================= DISH =================

  void loadDish(String name) {
    final dish = dishes[name];

    setState(() {
      selectedDish = name;
      ingredients = List<String>.from(dish["ingredients"]);
      base = List<double>.from(dish["base"]);
      baseOutput = (dish["baseOutput"] ?? 1).toDouble();
      targetOutput = baseOutput;
      result = List.from(base);

      // ⭐ CREATE ENTER CONTROLLERS
      enterControllers =
          List.generate(base.length, (_) => TextEditingController());
    });
  }

  void addDishDialog() {
    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("New Dish Name"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () {
              String name = controller.text.trim();
              if (name.isEmpty) return;

              dishes[name] = {
                "ingredients": ["Ingredient 1", "Ingredient 2", "Ingredient 3"],
                "base": [1.0, 2.0, 3.0],
                "baseOutput": 1,
              };

              saveData();
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text("ADD"),
          )
        ],
      ),
    );
  }

  // ⭐ DELETE DISH
  void deleteDish() {
    if (selectedDish == null) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Item"),
        content: Text("Delete '$selectedDish'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              dishes.remove(selectedDish);
              selectedDish = null;
              ingredients.clear();
              base.clear();
              result.clear();
              enterControllers.clear();

              saveData();
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text("Delete"),
          )
        ],
      ),
    );
  }

  // ================= INGREDIENT =================

  void editIngredient(int index) {
    TextEditingController controller =
        TextEditingController(text: ingredients[index]);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Ingredient"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => ingredients[index] = controller.text);
              saveCurrentDish();
              Navigator.pop(context);
            },
            child: const Text("SAVE"),
          )
        ],
      ),
    );
  }

  // ⭐ DELETE INGREDIENT
  void removeVariable(int i) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Ingredient"),
        content: Text("Delete '${ingredients[i]}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                base.removeAt(i);
                result.removeAt(i);
                ingredients.removeAt(i);
                enterControllers.removeAt(i); // ⭐ remove controller
              });
              saveCurrentDish();
              Navigator.pop(context);
            },
            child: const Text("Delete"),
          )
        ],
      ),
    );
  }

  // ================= RATIO =================

  List<double> scaleRatio(List<double> base, int index, double newValue) {
    double factor = newValue / base[index];
    return base.map((e) => e * factor).toList();
  }

  void updateValue(int index, String val) {
    if (val.isEmpty) return;
    double newVal = double.tryParse(val) ?? 0;

    // ⭐ CLEAR OTHER ENTER FIELDS
    for (int i = 0; i < enterControllers.length; i++) {
      if (i != index) {
        enterControllers[i].clear();
      }
    }

    setState(() {
      result = scaleRatio(base, index, newVal);
    });
  }

  // ⭐ SCALE BY OUTPUT
  void updateOutput(String val) {
    if (val.isEmpty) return;

    targetOutput = double.tryParse(val) ?? baseOutput;

    double factor = targetOutput / baseOutput;

    setState(() {
      result = base.map((e) => e * factor).toList();
    });
  }

  // ================= VARIABLE =================

  void addVariable() {
    if (base.length >= 7) return;

    setState(() {
      base.add(1);
      result.add(1);
      ingredients.add("Ingredient ${ingredients.length + 1}");
      enterControllers.add(TextEditingController()); // ⭐ add controller
    });

    saveCurrentDish();
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: const EdgeInsets.all(12),

      child: Column(
        children: [

          Row(
            children: [
              Expanded(
                child: DropdownButton<String>(
                  value: selectedDish,
                  hint: const Text("Select Item"),
                  isExpanded: true,
                  items: dishes.keys.map((name) {
                    return DropdownMenuItem(
                      value: name,
                      child: Text(name),
                    );
                  }).toList(),
                  onChanged: (v) => loadDish(v!),
                ),
              ),
              IconButton(icon: const Icon(Icons.add), onPressed: addDishDialog),
              IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: deleteDish),
            ],
          ),

          const SizedBox(height: 15),

          if (selectedDish == null)
            const Text("Select or add a dish")
          else
            Expanded(
              child: GridView.builder(
                itemCount: base.length,
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.65,
                ),
                itemBuilder: (context, i) {
                  return Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () => editIngredient(i),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              color: Colors.grey.shade200,
                              child: Text(
                                ingredients[i],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  TextField(
                                    controller: TextEditingController(text: base[i].toString()),
                                    decoration: const InputDecoration(labelText: "Base", isDense: true),
                                    onChanged: (v) {
                                      base[i] = double.tryParse(v) ?? 1;
                                      saveCurrentDish();
                                    },
                                  ),
                                  const SizedBox(height: 4),

                                  // ⭐ ENTER FIELD WITH CONTROLLER
                                  TextField(
                                    controller: enterControllers[i],
                                    decoration: const InputDecoration(
                                      labelText: "Enter",
                                      isDense: true,
                                    ),
                                    onChanged: (v) => updateValue(i, v),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(result[i].toStringAsFixed(2),
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                  IconButton(icon: const Icon(Icons.delete), onPressed: () => removeVariable(i)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          // ⭐ PRODUCTION OUTPUT PANEL
          if (selectedDish != null)
            Card(
              margin: const EdgeInsets.only(top: 10),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    const Text("Production Output",
                        style: TextStyle(fontWeight: FontWeight.bold)),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: TextEditingController(text: baseOutput.toString()),
                            decoration: const InputDecoration(
                                labelText: "Base Output",
                                helperText: "Items from base recipe"),
                            onChanged: (v) {
                              baseOutput = double.tryParse(v) ?? 1;
                              saveCurrentDish();
                            },
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                                labelText: "Target Output",
                                helperText: "Items needed"),
                            onChanged: updateOutput,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          if (selectedDish != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: ElevatedButton.icon(
                onPressed: addVariable,
                icon: const Icon(Icons.add),
                label: const Text("Add Ingredient"),
              ),
            ),
        ],
      ),
    );
  }
}
