import base64
import unittest

from modules.AmneziaSettings import (
    PersistentKeepaliveStorage,
    ValidateAmneziaInterfaceSettings,
)


class AmneziaSettingsTestCase(unittest.TestCase):
    def test_accepts_awg3_settings(self):
        settings = {
            "S1": "12",
            "S2": "24",
            "S3": "36",
            "S4": "48",
            "H1": "1-10",
            "HeaderProtectionKey": base64.b64encode(bytes(range(32))).decode(),
            "ContentPaddingAddition": "0-64",
            "RekeyAfterTime": "100-140",
            "RandomTrailers": "on",
            "DisableCookies": "off",
        }

        self.assertEqual(
            ValidateAmneziaInterfaceSettings(settings),
            (True, None, None),
        )

    def test_rejects_invalid_ranges(self):
        for value in ("20-10", "-1", "1-", "1-65536", "value"):
            with self.subTest(value=value):
                valid, _, field = ValidateAmneziaInterfaceSettings(
                    {"ContentPaddingAddition": value}
                )
                self.assertFalse(valid)
                self.assertEqual(field, "ContentPaddingAddition")

    def test_rejects_ranges_for_scalar_legacy_fields(self):
        for field in ("Jc", "Jmin", "Jmax", "S1", "S2", "S3", "S4"):
            with self.subTest(field=field):
                valid, _, invalid_field = ValidateAmneziaInterfaceSettings(
                    {field: "12-24"}
                )
                self.assertFalse(valid)
                self.assertEqual(invalid_field, field)

    def test_rejects_invalid_header_protection_key(self):
        valid, _, field = ValidateAmneziaInterfaceSettings(
            {
                "S1": "12",
                "S2": "12",
                "S3": "12",
                "S4": "12",
                "HeaderProtectionKey": base64.b64encode(b"too short").decode(),
            }
        )

        self.assertFalse(valid)
        self.assertEqual(field, "HeaderProtectionKey")

    def test_header_protection_requires_sufficient_padding(self):
        settings = {
            "S1": "11",
            "S2": "12",
            "S3": "12",
            "S4": "12",
            "HeaderProtectionKey": base64.b64encode(bytes(range(32))).decode(),
        }

        valid, _, field = ValidateAmneziaInterfaceSettings(settings)

        self.assertFalse(valid)
        self.assertEqual(field, "S1")

    def test_awg_keepalive_range_is_stored_losslessly(self):
        self.assertEqual(
            PersistentKeepaliveStorage("20-30", "awg"),
            (True, None, 20, "20-30"),
        )

    def test_wireguard_rejects_keepalive_range(self):
        valid, _, _, _ = PersistentKeepaliveStorage("20-30", "wg")
        self.assertFalse(valid)


if __name__ == "__main__":
    unittest.main()
