import requests
import os
import time

# Get app URL from environment or use default
APP_URL = os.getenv("APP_URL", "http://localhost:5000")

def test_health_endpoint_running():
    """Test that the health endpoint is accessible and returns 200"""
    response = requests.get(f"{APP_URL}/health", timeout=5)
    assert response.status_code == 200
    assert response.json()["status"] == "ok"

def test_health_endpoint_response_time():
    """Test that health endpoint responds within acceptable time"""
    start_time = time.time()
    response = requests.get(f"{APP_URL}/health", timeout=5)
    response_time = time.time() - start_time
    
    assert response.status_code == 200
    assert response_time < 1.0, f"Response time {response_time}s exceeds 1 second"

def test_root_endpoint():
    """Test that the root endpoint is accessible"""
    response = requests.get(f"{APP_URL}/", timeout=5)
    assert response.status_code == 200
    assert "Hello" in response.text or "CI/CD" in response.text

def test_health_endpoint_json_format():
    """Test that health endpoint returns valid JSON"""
    response = requests.get(f"{APP_URL}/health", timeout=5)
    assert response.status_code == 200
    
    data = response.json()
    assert "status" in data
    assert data["status"] == "ok"
