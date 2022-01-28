"""ACL server application."""
import logging
from typing import Optional

import aiohttp
import databases
from fastapi import Cookie, FastAPI, HTTPException, Query, Response, status

from . import edx, grafana
from .exceptions import EdxException, GrafanaException
from .settings import Settings

logger = logging.getLogger(__name__)

# pylint: disable=invalid-name
settings = Settings()
logger.debug("Database url: %s", settings.EDX_DATABASE_URL)
edx_database = databases.Database(settings.EDX_DATABASE_URL)
http_requests_session = None
app = FastAPI()


# pylint: disable=invalid-name,global-statement
@app.on_event("startup")
async def startup():
    """Application startup event handling."""
    # Prevent aiohttp warning:
    #
    # the aiohttp.ClientSession object should be created within an async
    # function
    global http_requests_session

    http_requests_session = aiohttp.ClientSession()
    await edx_database.connect()


@app.on_event("shutdown")
async def shutdown():
    """Application shutdown event handling."""

    await http_requests_session.close()
    await edx_database.disconnect()


@app.get("/{request_path:path}")
async def proxy(
    request_path: str,
    course_key: Optional[str] = Query(None, alias="var-COURSE_KEY"),
    school: Optional[str] = Query(None, alias="var-SCHOOL"),
    course: Optional[str] = Query(None, alias="var-COURSE"),
    session: Optional[str] = Query(None, alias="var-SESSION"),
    grafana_session: str = Cookie(None),
):
    """Look for authorizations of the current user."""

    x_accel_redirect = f"/{request_path}"
    allowed = Response(
        headers={"X-Accel-Redirect": f"{x_accel_redirect}"},
    )
    forbidden = Response(
        content="You are not allowed to view this.",
        status_code=status.HTTP_403_FORBIDDEN,
        media_type="text/html",
    )

    try:
        user = await grafana.current_user(
            http_requests_session, settings.GRAFANA_ROOT_URL, grafana_session
        )
    except GrafanaException as error:
        raise HTTPException(
            status_code=401,
            detail="Cannot get grafana user. See logs for details",
        ) from error

    try:
        user_course_keys = [
            key
            for row in await edx.user_courses(edx_database, user.email)
            for key in row
        ]
    except EdxException as error:
        raise HTTPException(
            status_code=400,
            detail="Cannot get courses from edx. See logs for details",
        ) from error
    logger.debug("User course key: %s", user_course_keys)

    if course_key is not None and course_key not in user_course_keys:
        return forbidden

    if (
        all((school, course, session))
        and f"course-v1:{school}+{course}+{session}" not in user_course_keys
    ):
        return forbidden

    return allowed
