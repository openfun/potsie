"""ACL Grafana client."""
import logging
from datetime import datetime
from pathlib import Path
from typing import List, Optional, Union
from urllib.parse import urljoin

import aiohttp
from pydantic import BaseModel, EmailStr, FileUrl, ValidationError

from .exceptions import GrafanaException

logger = logging.getLogger(__name__)


class User(BaseModel):
    """Grafana User"""

    id: int
    email: EmailStr
    name: str
    login: str
    theme: str
    orgId: int
    isGrafanaAdmin: bool
    isDisabled: bool
    isExternal: bool
    authLabels: List[str] = None
    updatedAt: datetime
    createdAt: datetime
    avatarUrl: Optional[Union[FileUrl, Path]]


async def perform_request(
    session, grafana_base_url, endpoint, grafana_session, method="GET", payload=None
):
    """Perform asynchronous request against Grafana API."""

    url = urljoin(grafana_base_url, endpoint)

    if grafana_session is None:
        raise GrafanaException(
            "A grafana session is required to impersonate user requests."
        )

    request_kwargs = {}
    if payload is not None:
        if method.upper() == "GET":
            request_kwargs.update({"params": payload})
        else:
            request_kwargs.update({"json": payload})

    logger.debug("%s %s %s", method.upper(), url, request_kwargs)

    async with getattr(session, method.lower())(
        url,
        headers={
            "Cookie": f"grafana_session={grafana_session}",
            "content-type": "application/json",
        },
        **request_kwargs,
    ) as response:

        try:
            response.raise_for_status()
        except aiohttp.client_exceptions.ClientResponseError as error:
            logger.debug("exception: %s", error)
            raise GrafanaException(
                "Grafana request failed. Check logs for details."
            ) from error

        try:
            return await response.json()
        except aiohttp.ContentTypeError as error:
            logger.debug("response.text: %s", await response.text())
            logger.debug("exception: %s", error)
            raise GrafanaException("Unexpected response content type.") from error


async def current_user(session, grafana_base_url, grafana_session):
    """Get logged user informations."""

    response = await perform_request(
        session, grafana_base_url, "/api/user", grafana_session
    )
    logger.debug("Grafana user response: %s", response)
    try:
        user = User(**response)
    except ValidationError as error:
        logger.debug("Raw user response: %s", response)
        raise GrafanaException("Invalid request user.") from error

    logger.debug("User: %s", user)

    return user
