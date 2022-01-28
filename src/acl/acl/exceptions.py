"""ACL exceptions."""


class EdxException(Exception):
    """Raised when an Edx database request fails."""


class GrafanaException(Exception):
    """Raised when a Grafana API request fails."""
