import os
import unittest
from dataclasses import FrozenInstanceError
from unittest.mock import patch

from modules.DashboardEnvironment import DashboardEnvironment


class DashboardEnvironmentTestCase(unittest.TestCase):
    @patch.dict(os.environ, {}, clear=True)
    def test_defaults_preserve_the_existing_runtime_layout(self):
        environment = DashboardEnvironment.FromEnvironment()

        self.assertEqual(environment.ConfigurationPath, os.getcwd())
        self.assertEqual(environment.AssetPath, os.getcwd())
        self.assertTrue(environment.AutostartInterfaces)

    def test_paths_are_resolved_independently(self):
        with patch.dict(
            os.environ,
            {
                "CONFIGURATION_PATH": "relative-state",
                "WGDASHBOARD_ASSET_PATH": "/opt/wgdashboard",
            },
            clear=True,
        ):
            environment = DashboardEnvironment.FromEnvironment()

        self.assertEqual(
            environment.ConfigurationPath,
            os.path.join(os.getcwd(), "relative-state"),
        )
        self.assertEqual(environment.AssetPath, "/opt/wgdashboard")

    def test_autostart_accepts_common_true_values(self):
        for value in ("1", "true", "TRUE", "yes", "on"):
            with self.subTest(value=value):
                with patch.dict(
                    os.environ,
                    {"WGDASHBOARD_AUTOSTART_INTERFACES": value},
                    clear=True,
                ):
                    environment = DashboardEnvironment.FromEnvironment()

                self.assertTrue(environment.AutostartInterfaces)

    def test_autostart_rejects_other_values(self):
        for value in ("0", "false", "no", "off", "invalid"):
            with self.subTest(value=value):
                with patch.dict(
                    os.environ,
                    {"WGDASHBOARD_AUTOSTART_INTERFACES": value},
                    clear=True,
                ):
                    environment = DashboardEnvironment.FromEnvironment()

                self.assertFalse(environment.AutostartInterfaces)

    def test_environment_is_immutable(self):
        environment = DashboardEnvironment.FromEnvironment()

        with self.assertRaises(FrozenInstanceError):
            environment.AssetPath = "/tmp/other-assets"


if __name__ == "__main__":
    unittest.main()
