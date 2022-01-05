"""ACL tests configuration."""
# pylint: disable=redefined-outer-name

import aiohttp
import pytest
import pytest_asyncio
from databases import Database
from fastapi.testclient import TestClient

from acl.settings import TestSettings


@pytest.fixture
def settings():
    """ACL application settings."""

    return TestSettings()


@pytest.fixture
def test_client():
    """HTTP test client."""
    # pylint: disable=import-outside-toplevel
    from acl.main import app

    with TestClient(app) as client:
        yield client


@pytest_asyncio.fixture
async def http_requests_session():
    """HTTP requests session fixture."""

    session = aiohttp.ClientSession()
    yield session
    await session.close()


@pytest_asyncio.fixture
async def grafana_http_requests_session_admin(settings, http_requests_session):
    """Grafana-authenticated HTTP requests session fixture for the admin user."""

    async with http_requests_session.post(
        f"{settings.GRAFANA_ROOT_URL}/login",
        json={"user": "admin", "password": "pass"},
    ):
        yield http_requests_session


@pytest_asyncio.fixture
async def grafana_http_requests_session_teacher(settings, http_requests_session):
    """Grafana-authenticated HTTP requests session fixture for the teacher user."""

    async with http_requests_session.post(
        f"{settings.GRAFANA_ROOT_URL}/login",
        json={"user": "teacher", "password": "funfunfun"},
    ):
        yield http_requests_session


@pytest_asyncio.fixture
async def grafana_session_teacher(settings, grafana_http_requests_session_teacher):
    """Shortcut to get grafana_session cookie value."""

    return (
        grafana_http_requests_session_teacher.cookie_jar.filter_cookies(
            settings.GRAFANA_ROOT_URL
        )
        .get("grafana_session")
        .value
    )


@pytest_asyncio.fixture
async def mysql_database(settings):
    """Mysql database fixture."""

    database = Database(settings.EDX_DATABASE_URL, force_rollback=True)
    await database.connect()
    yield database
    await database.disconnect()


@pytest_asyncio.fixture
async def grafana_database(settings):
    """Grafana database fixture."""

    database = Database(settings.GRAFANA_DATABASE_URL, force_rollback=True)
    await database.connect()
    yield database
    await database.disconnect()
