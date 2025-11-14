import os
from collections.abc import Generator

import pytest
from fastapi.testclient import TestClient
from sqlmodel import Session, SQLModel, create_engine

from app.core.config import Settings, get_settings
from app.core.database import get_session
from app.main import app


@pytest.fixture(scope="session", autouse=True)
def override_settings() -> Generator[None, None, None]:
    os.environ["SECRET_KEY"] = "test-secret-key"
    os.environ["DATABASE_URL"] = "sqlite:///./test.db"
    get_settings.cache_clear()  # type: ignore[attr-defined]
    yield
    if os.path.exists("test.db"):
        os.remove("test.db")


@pytest.fixture(name="session")
def session_fixture() -> Generator[Session, None, None]:
    test_engine = create_engine(
        "sqlite:///./test.db", connect_args={"check_same_thread": False}
    )
    SQLModel.metadata.create_all(test_engine)
    with Session(test_engine) as session:
        yield session
    SQLModel.metadata.drop_all(test_engine)


@pytest.fixture(name="client")
def client_fixture(session: Session) -> Generator[TestClient, None, None]:
    def get_test_session() -> Generator[Session, None, None]:
        yield session

    app.dependency_overrides[get_session] = get_test_session
    with TestClient(app) as client:
        yield client
    app.dependency_overrides.clear()

