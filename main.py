from flask import Flask, jsonify

app = Flask(__name__)

# Mock inventory data
inventory = [
    {"id": 1, "name": "Resistor", "quantity": 1200, "location": "A1"},
    {"id": 2, "name": "Capacitor", "quantity": 800, "location": "B3"},
    {"id": 3, "name": "IC Chip", "quantity": 500, "location": "C2"},
    {"id": 4, "name": "LED", "quantity": 1000, "location": "A2"},
]

@app.route('/')
def home():
    return jsonify({"message": "Welcome to Inventory Tracker API!!Good Evening"})

@app.route('/inventory', methods=['GET'])
def get_inventory():
    return jsonify({"inventory": inventory})

@app.route('/inventory/<int:item_id>', methods=['GET'])
def get_item(item_id):
    for item in inventory:
        if item["id"] == item_id:
            return jsonify(item)
    return jsonify({"error": "Item not found"}), 404

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
