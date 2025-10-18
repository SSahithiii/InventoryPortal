import pytest
from main import app

@pytest.fixture
def client():
    with app.test_client() as client:
        yield client

# Home route test
def test_home(client):
    response = client.get('/')
    assert response.status_code == 200
    assert response.json == {"message": "Welcome to Inventory Tracker API!!GoodMorning This is for testing purpose.Added Respective changes!!"}

# Get all inventory
def test_get_inventory(client):
    response = client.get('/inventory')
    assert response.status_code == 200
    assert "inventory" in response.json
    assert len(response.json["inventory"]) == 4  # Expect 4 items

# Get single item by ID (valid case)
def test_get_item_valid(client):
    response = client.get('/inventory/1')  # ID 1 ("Resistor")
    assert response.status_code == 200
    assert response.json["id"] == 1
    assert response.json["name"] == "Resistor"

# Get single item by ID (invalid case)
def test_get_item_invalid(client):
    response = client.get('/inventory/9999')  # Non-existent item ID
    assert response.status_code == 404
    assert response.json == {"error": "Item not found"}
    
 

# Test if JSON response format is correct
def test_json_response_format(client):
    response = client.get('/inventory')
    assert response.status_code == 200
    assert response.content_type == 'application/json'

# Test invalid ID format (non-integer ID)
def test_non_integer_id(client):
    response = client.get('/inventory/abc')  # Invalid ID type
    assert response.status_code == 404  # Should return a 404 due to URL converter

# Test for non-existent route
def test_nonexistent_route(client):
    response = client.get('/nonexistentroute')
    assert response.status_code == 404

