"""Tests for ACL grafana module."""

import pytest

from acl import exceptions, grafana


def _get_grafana_session(grafana_http_requests_session, grafana_root_url):
    """Shortcut to get grafana_session cookie value."""

    return (
        grafana_http_requests_session.cookie_jar.filter_cookies(grafana_root_url)
        .get("grafana_session")
        .value
    )


@pytest.mark.asyncio
async def test_perform_request_without_session(settings, http_requests_session):
    """Test grafana HTTP API requests without grafana session."""

    with pytest.raises(
        exceptions.GrafanaException,
        match="A grafana session is required to impersonate user requests.",
    ):
        await grafana.perform_request(
            http_requests_session, settings.GRAFANA_ROOT_URL, "/api/user", None
        )

    # We use a non existing fake session here.
    with pytest.raises(
        exceptions.GrafanaException,
        match="Grafana request failed. Check logs for details.",
    ):
        await grafana.perform_request(
            http_requests_session, settings.GRAFANA_ROOT_URL, "/api/user", "fakesession"
        )

    # Trying to access the root url performs a redirection to /login with a 200
    # response but with a wrong content-type (HTML vs JSON).
    with pytest.raises(
        exceptions.GrafanaException,
        match="Unexpected response content type.",
    ):
        await grafana.perform_request(
            http_requests_session, settings.GRAFANA_ROOT_URL, "/", "fakesession"
        )


# pylint: disable=unused-argument
@pytest.mark.asyncio
async def test_perform_request_with_session(
    settings, grafana_http_requests_session_admin, grafana_database
):
    """Test grafana HTTP API requests with an opened grafana session."""

    # Perform a GET request with request parameters
    response = await grafana.perform_request(
        grafana_http_requests_session_admin,
        settings.GRAFANA_ROOT_URL,
        "/api/users/lookup",
        _get_grafana_session(
            grafana_http_requests_session_admin, settings.GRAFANA_ROOT_URL
        ),
        payload={"loginOrEmail": "teacher"},
    )
    user = grafana.User(**response)
    assert user.email == "teacher@example.org"

    # Now create a new folder
    response = await grafana.perform_request(
        grafana_http_requests_session_admin,
        settings.GRAFANA_ROOT_URL,
        "/api/folders",
        _get_grafana_session(
            grafana_http_requests_session_admin, settings.GRAFANA_ROOT_URL
        ),
        method="POST",
        payload={"uid": "1234", "title": "Foo folder"},
    )
    assert response.get("url") == "/dashboards/f/1234/foo-folder"

    # Delete this folder
    response = await grafana.perform_request(
        grafana_http_requests_session_admin,
        settings.GRAFANA_ROOT_URL,
        "/api/folders/1234",
        _get_grafana_session(
            grafana_http_requests_session_admin, settings.GRAFANA_ROOT_URL
        ),
        method="DELETE",
    )
    assert response.get("message") == "Folder Foo folder deleted"


@pytest.mark.asyncio
async def test_current_user(settings, grafana_http_requests_session_teacher):
    """Test grafana current_user."""

    user = await grafana.current_user(
        grafana_http_requests_session_teacher,
        settings.GRAFANA_ROOT_URL,
        _get_grafana_session(
            grafana_http_requests_session_teacher, settings.GRAFANA_ROOT_URL
        ),
    )
    assert user.email == "teacher@example.org"


@pytest.mark.asyncio
async def test_current_user_with_model_validation_error(
    settings, grafana_http_requests_session_teacher, monkeypatch
):
    """Test grafana current_user with invalid user response."""

    class FakeUserModel(grafana.User):
        """A fake user model to test model validation error."""

        fakeField: str

    monkeypatch.setattr(grafana, "User", FakeUserModel)

    with pytest.raises(exceptions.GrafanaException, match="Invalid request user."):
        await grafana.current_user(
            grafana_http_requests_session_teacher,
            settings.GRAFANA_ROOT_URL,
            _get_grafana_session(
                grafana_http_requests_session_teacher, settings.GRAFANA_ROOT_URL
            ),
        )
