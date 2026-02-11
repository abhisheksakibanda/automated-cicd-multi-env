from app.app import app


def test_root_endpoint_includes_env(monkeypatch):
    monkeypatch.setenv("APP_ENV", "staging")
    client = app.test_client()
    res = client.get("/")
    assert res.status_code == 200
    body = res.get_data(as_text=True)
    assert "Hello from the CI/CD demo app!" in body
    assert "Env: staging" in body


def test_health_ok_by_default(monkeypatch):
    monkeypatch.delenv("BREAK_HEALTH", raising=False)
    monkeypatch.delenv("APP_ENV", raising=False)

    client = app.test_client()
    res = client.get("/health")
    assert res.status_code == 200
    assert res.get_json()["status"] == "ok"
    assert res.get_json()["env"] == "dev"  # default


def test_health_fails_only_in_dev_when_break_health_true(monkeypatch):
    monkeypatch.setenv("APP_ENV", "dev")
    monkeypatch.setenv("BREAK_HEALTH", "true")

    client = app.test_client()
    res = client.get("/health")
    assert res.status_code == 500
    data = res.get_json()
    assert data["status"] == "fail"
    assert data["env"] == "dev"


def test_health_ok_in_prod_even_if_break_health_true(monkeypatch):
    monkeypatch.setenv("APP_ENV", "prod")
    monkeypatch.setenv("BREAK_HEALTH", "true")

    client = app.test_client()
    res = client.get("/health")
    assert res.status_code == 200
    data = res.get_json()
    assert data["status"] == "ok"
    assert data["env"] == "prod"
