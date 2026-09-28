"""
WGDashboard runtime environment.
"""
import os
from dataclasses import dataclass


def _GetBoolean(name: str, default: bool) -> bool:
    value = os.getenv(name)
    if value is None:
        return default
    return value.strip().lower() in ("1", "true", "yes", "on")


@dataclass(frozen=True)
class DashboardEnvironment:
    """Runtime paths and startup behavior captured from the process environment."""

    ConfigurationPath: str
    AssetPath: str
    AutostartInterfaces: bool

    @classmethod
    def FromEnvironment(cls) -> "DashboardEnvironment":
        return cls(
            ConfigurationPath=os.path.abspath(
                os.getenv("CONFIGURATION_PATH", ".")
            ),
            AssetPath=os.path.abspath(
                os.getenv("WGDASHBOARD_ASSET_PATH", ".")
            ),
            AutostartInterfaces=_GetBoolean(
                "WGDASHBOARD_AUTOSTART_INTERFACES", True
            ),
        )


RuntimeEnvironment = DashboardEnvironment.FromEnvironment()
