"""Tests for ACL edx module."""

import pytest

from acl.edx import user_courses
from acl.exceptions import EdxException


@pytest.mark.asyncio
async def test_user_courses_email_verification(mysql_database):
    """Test user_courses function with SQL injection attacks."""

    with pytest.raises(EdxException, match="An email is required to get user courses"):
        await user_courses(mysql_database, None)

    with pytest.raises(EdxException, match="Invalid input email admin@localhost"):
        await user_courses(mysql_database, "admin@localhost")

    with pytest.raises(EdxException, match="Invalid input email foo"):
        await user_courses(mysql_database, "foo")

    with pytest.raises(EdxException, match="Invalid input email "):
        await user_courses(mysql_database, "")

    with pytest.raises(
        EdxException, match='Invalid input email foo@localhost" OR 1 == 1 --];'
    ):
        await user_courses(mysql_database, 'foo@localhost" OR 1 == 1 --];')


@pytest.mark.asyncio
async def test_user_courses(mysql_database):
    """Test user_courses fetching."""

    assert await user_courses(mysql_database, "teacher@example.org") == [
        ("course-v1:FUN-MOOC+00001+session01",),
        ("course-v1:FUN-MOOC+00002+session01",),
    ]
    assert await user_courses(mysql_database, "student@example.org") == []
