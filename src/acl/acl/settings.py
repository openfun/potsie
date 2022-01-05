"""ACL Settings."""

from pydantic import AnyHttpUrl, AnyUrl, BaseSettings, PostgresDsn, validator


class Settings(BaseSettings):
    """ACL web application settings."""

    EDX_DATABASE_HOST: str
    EDX_DATABASE_NAME: str
    EDX_DATABASE_PORT: int
    EDX_DATABASE_USER_NAME: str
    EDX_DATABASE_USER_PASSWORD: str
    EDX_DATABASE_URL: AnyUrl = None
    EDX_DATASOURCE_NAME: str
    GRAFANA_ROOT_URL: AnyHttpUrl

    @validator("EDX_DATABASE_URL", pre=True, always=True)
    @classmethod
    def default_edx_database_url(cls, value, *, values):
        """Set EDX_DATABASE_URL setting from separated settings if not already set."""

        return value or (
            "mysql://"
            f"{values['EDX_DATABASE_USER_NAME']}:"
            f"{values['EDX_DATABASE_USER_PASSWORD']}@"
            f"{values['EDX_DATABASE_HOST']}:"
            f"{values['EDX_DATABASE_PORT']}/"
            f"{values['EDX_DATABASE_NAME']}"
        )


class TestSettings(Settings):
    """ "ACL web application tests settings."""

    GRAFANA_DATABASE_HOST: str
    GRAFANA_DATABASE_NAME: str
    GRAFANA_DATABASE_PORT: int
    GRAFANA_DATABASE_USER_NAME: str
    GRAFANA_DATABASE_USER_PASSWORD: str
    GRAFANA_DATABASE_URL: PostgresDsn = None
    ACL_ROOT_URL: AnyHttpUrl = "http://acl:8000"

    @validator("GRAFANA_DATABASE_URL", pre=True, always=True)
    @classmethod
    def default_grafana_database_url(cls, value, *, values):
        """Set GRAFANA_DATABASE_URL setting from separated settings
        if not already set.
        """

        return value or (
            "postgresql://"
            f"{values['GRAFANA_DATABASE_USER_NAME']}:"
            f"{values['GRAFANA_DATABASE_USER_PASSWORD']}@"
            f"{values['GRAFANA_DATABASE_HOST']}:"
            f"{values['GRAFANA_DATABASE_PORT']}/"
            f"{values['GRAFANA_DATABASE_NAME']}"
        )
