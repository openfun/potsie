"""EDX database client."""
import logging

from email_validator import EmailNotValidError, validate_email

from .exceptions import EdxException

logger = logging.getLogger(__name__)


async def user_courses(database, email):
    """Get logged user courses."""

    if email is None:
        raise EdxException("An email is required to get user courses")

    # Validate input email so that no SQL injection attack can be made
    try:
        valid = validate_email(email)
    except EmailNotValidError as error:
        raise EdxException(f"Invalid input email {email}") from error

    edx_course_keys_sql_request = (  # nosec
        "SELECT DISTINCT `student_courseaccessrole`.`course_id` "
        "FROM `student_courseaccessrole` WHERE ("
        "  `student_courseaccessrole`.`user_id` = ("
        "    SELECT id from auth_user "
        f'    WHERE email="{valid.email}" '
        '    AND `student_courseaccessrole`.`role` IN ("staff", "instructor")'
        "  )"
        ")"
    )
    logger.debug("Edx course keys SQL request: %s", edx_course_keys_sql_request)

    return await database.fetch_all(query=edx_course_keys_sql_request)
