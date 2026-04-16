from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_ready_endpoint() -> None:
    response = client.get('/ready')
    assert response.status_code in (200, 503)
