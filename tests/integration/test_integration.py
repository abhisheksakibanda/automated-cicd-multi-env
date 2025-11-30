import requests

def test_health_endpoint_running():
    response = requests.get("http://localhost:5000/health")
    assert response.status_code == 200
