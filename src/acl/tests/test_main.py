"""Tests for ACL main (server) module."""

from pydantic import BaseModel

from acl import edx, grafana


def test_proxy_without_grafana_session(settings, test_client):
    """Test proxy view without grafana session."""

    response = test_client.get(f"{settings.ACL_ROOT_URL}/test/proxy")

    assert response.status_code == 401
    assert "X-Accel-Redirect" not in response.headers
    assert response.json() == {
        "detail": "Cannot get grafana user. See logs for details"
    }


def test_proxy_with_bad_user_email(
    settings, test_client, grafana_session_teacher, monkeypatch
):
    """Test proxy view with an open teacher grafana session but an invalid user
    email.
    """

    class BadEmailUser(BaseModel):
        """User model with a bad email address."""

        email: str

    # pylint: disable=unused-argument
    async def __current_user(session, grafana_base_url, grafana_session):
        """Mock grafana.current_user response with a non-standard email."""
        return BadEmailUser(email="teacher@localhost")

    monkeypatch.setattr(grafana, "current_user", __current_user)

    response = test_client.get(
        f"{settings.ACL_ROOT_URL}/test/proxy",
        cookies={"grafana_session": grafana_session_teacher},
    )

    assert response.status_code == 400
    assert "X-Accel-Redirect" not in response.headers
    assert response.json() == {
        "detail": "Cannot get courses from edx. See logs for details"
    }


def test_proxy_with_teacher_grafana_session(
    settings, test_client, grafana_session_teacher
):
    """Test proxy view with an open teacher grafana session"""

    response = test_client.get(
        f"{settings.ACL_ROOT_URL}/test/proxy",
        cookies={"grafana_session": grafana_session_teacher},
    )

    assert response.status_code == 200
    assert response.headers["X-Accel-Redirect"] == "/test/proxy"

    response = test_client.get(
        f"{settings.ACL_ROOT_URL}/any/path/should/respond",
        cookies={"grafana_session": grafana_session_teacher},
    )

    assert response.status_code == 200
    assert response.headers["X-Accel-Redirect"] == "/any/path/should/respond"


def test_proxy_with_no_courses_account(
    settings, test_client, grafana_session_teacher, monkeypatch
):

    """Test proxy view with an open teacher grafana session for a teacher not
    associated with courses in edx.
    """

    # pylint: disable=unused-argument
    async def __user_courses(database, email):
        """User is not a registered teacher in edx."""
        return []

    monkeypatch.setattr(edx, "user_courses", __user_courses)

    # If no course key has been given as a request query, allow proxying
    # request.
    response = test_client.get(
        f"{settings.ACL_ROOT_URL}/test/proxy",
        cookies={"grafana_session": grafana_session_teacher},
    )
    assert response.status_code == 200
    assert response.headers["X-Accel-Redirect"] == "/test/proxy"

    # Even with partial course key parameters
    response = test_client.get(
        f"{settings.ACL_ROOT_URL}/test/proxy",
        cookies={"grafana_session": grafana_session_teacher},
        params={"var-SCHOOL": "foo"},
    )
    assert response.status_code == 200
    assert response.headers["X-Accel-Redirect"] == "/test/proxy"

    response = test_client.get(
        f"{settings.ACL_ROOT_URL}/test/proxy",
        cookies={"grafana_session": grafana_session_teacher},
        params={"var-COURSE": "bar"},
    )
    assert response.status_code == 200
    assert response.headers["X-Accel-Redirect"] == "/test/proxy"

    response = test_client.get(
        f"{settings.ACL_ROOT_URL}/test/proxy",
        cookies={"grafana_session": grafana_session_teacher},
        params={"var-SESSION": "baz"},
    )
    assert response.status_code == 200
    assert response.headers["X-Accel-Redirect"] == "/test/proxy"

    response = test_client.get(
        f"{settings.ACL_ROOT_URL}/test/proxy",
        cookies={"grafana_session": grafana_session_teacher},
        params={
            "var-SCHOOL": "foo",
            "var-COURSE": "bar",
        },
    )
    assert response.status_code == 200
    assert response.headers["X-Accel-Redirect"] == "/test/proxy"

    # With a course key in the request, we check that the user is allowed to
    # view course-related data.
    response = test_client.get(
        f"{settings.ACL_ROOT_URL}/test/proxy",
        cookies={"grafana_session": grafana_session_teacher},
        params={"var-COURSE_KEY": "foo"},
    )
    assert response.status_code == 403
    assert "X-Accel-Redirect" not in response.headers
    assert response.text == "You are not allowed to view this."

    # With a schoo/course/session keys in the request, we check that the user
    # is allowed to view course-related data.
    response = test_client.get(
        f"{settings.ACL_ROOT_URL}/test/proxy",
        cookies={"grafana_session": grafana_session_teacher},
        params={
            "var-SCHOOL": "foo",
            "var-COURSE": "bar",
            "var-SESSION": "baz",
        },
    )
    assert response.status_code == 403
    assert "X-Accel-Redirect" not in response.headers
    assert response.text == "You are not allowed to view this."
