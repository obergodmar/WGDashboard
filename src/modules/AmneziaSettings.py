"""AmneziaWG configuration fields and validation helpers."""

import base64
import binascii
import re


AMNEZIA_LEGACY_INTERFACE_FIELDS = (
    "Jc",
    "Jmin",
    "Jmax",
    "S1",
    "S2",
    "S3",
    "S4",
    "H1",
    "H2",
    "H3",
    "H4",
    "I1",
    "I2",
    "I3",
    "I4",
    "I5",
    "J1",
    "J2",
    "J3",
    "Itime",
)

AMNEZIA_V3_INTERFACE_FIELDS = (
    "HeaderProtectionKey",
    "ContentPaddingAddition",
    "RekeyAfterTime",
    "RekeyTimeout",
    "RejectAfterTime",
    "KeepaliveTimeout",
    "MaxHandshakeAttempts",
    "RandomTrailers",
    "DisableCookies",
)

AMNEZIA_INTERFACE_FIELDS = (
    AMNEZIA_LEGACY_INTERFACE_FIELDS + AMNEZIA_V3_INTERFACE_FIELDS
)

_U16_FIELDS = ("Jc", "Jmin", "Jmax", "S1", "S2", "S3", "S4")
_U32_RANGE_FIELDS = ("H1", "H2", "H3", "H4")
_U16_RANGE_FIELDS = (
    "ContentPaddingAddition",
    "RekeyAfterTime",
    "RekeyTimeout",
    "RejectAfterTime",
    "KeepaliveTimeout",
    "MaxHandshakeAttempts",
)
_BOOLEAN_FIELDS = ("RandomTrailers", "DisableCookies")
_RANGE_PATTERN = re.compile(r"^(\d+)(?:-(\d+))?$")


def _ValidateRange(value, maximum):
    text = str(value).strip()
    match = _RANGE_PATTERN.fullmatch(text)
    if match is None:
        return False

    lower = int(match.group(1))
    upper = int(match.group(2) or match.group(1))
    return lower <= upper <= maximum


def _ValidateHeaderProtectionKey(value):
    try:
        decoded = base64.b64decode(str(value), validate=True)
    except (binascii.Error, ValueError):
        return False
    return len(decoded) == 32


def ValidateAmneziaInterfaceSettings(data):
    """Validate fields understood by upstream AmneziaWG 3.x tools."""

    for field in _U16_FIELDS:
        value = str(data.get(field, "")).strip()
        if value and (not value.isdecimal() or int(value) > 65535):
            return False, f"{field} must be an integer between 0 and 65535", field

    for field in _U32_RANGE_FIELDS:
        value = str(data.get(field, "")).strip()
        if value and not _ValidateRange(value, 4294967295):
            return False, f"{field} must be an integer or an ascending uint32 range", field

    for field in _U16_RANGE_FIELDS:
        value = str(data.get(field, "")).strip()
        if value and not _ValidateRange(value, 65535):
            return False, f"{field} must be an integer or an ascending uint16 range", field

    for field in _BOOLEAN_FIELDS:
        value = str(data.get(field, "")).strip().lower()
        if value and value not in ("on", "off", "0", "1"):
            return False, f"{field} must be on, off, 0, or 1", field

    header_protection_key = str(data.get("HeaderProtectionKey", "")).strip()
    if header_protection_key:
        if not _ValidateHeaderProtectionKey(header_protection_key):
            return False, "HeaderProtectionKey must be a base64-encoded 32-byte key", "HeaderProtectionKey"
        for field in ("S1", "S2", "S3", "S4"):
            value = str(data.get(field, "")).strip()
            if not value.isdecimal() or int(value) < 12:
                return False, f"{field} must be at least 12 when header protection is enabled", field

    jmin = str(data.get("Jmin", "")).strip()
    jmax = str(data.get("Jmax", "")).strip()
    if jmin and jmax and jmin.isdecimal() and jmax.isdecimal() and int(jmin) > int(jmax):
        return False, "Jmin must not be greater than Jmax", "Jmin"

    return True, None, None


def PersistentKeepaliveStorage(value, protocol):
    """Return validation status plus legacy integer and lossless range storage."""

    text = "" if value is None else str(value).strip()
    if not text:
        text = "0"

    allow_range = protocol == "awg"
    if not _ValidateRange(text, 65535) or (not allow_range and "-" in text):
        expected = "an integer or ascending uint16 range" if allow_range else "an integer"
        return False, f"Persistent Keepalive must be {expected} between 0 and 65535", None, None

    legacy_value = int(text.split("-", maxsplit=1)[0])
    range_value = text if allow_range else None
    return True, None, legacy_value, range_value
