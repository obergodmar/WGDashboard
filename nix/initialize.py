import argparse
import configparser
import os

import bcrypt


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--configuration-path", required=True)
    parser.add_argument("--settings-file", required=True)
    parser.add_argument("--password-file")
    parser.add_argument("--username", default="admin")
    parser.add_argument("--listen-address", required=True)
    parser.add_argument("--port", required=True, type=int)
    parser.add_argument("--wireguard-path", required=True)
    parser.add_argument("--amneziawg-path", required=True)
    args = parser.parse_args()

    os.makedirs(args.configuration_path, mode=0o700, exist_ok=True)
    os.makedirs(args.wireguard_path, mode=0o700, exist_ok=True)
    os.makedirs(args.amneziawg_path, mode=0o700, exist_ok=True)
    for directory in ("attachments", "db", "download", "log", "plugins"):
        os.makedirs(
            os.path.join(args.configuration_path, directory),
            mode=0o700,
            exist_ok=True,
        )

    configuration_file = os.path.join(args.configuration_path, "wg-dashboard.ini")
    configuration = configparser.RawConfigParser(strict=False)
    if os.path.exists(configuration_file):
        configuration.read(configuration_file)

    declarative_configuration = configparser.RawConfigParser(strict=False)
    declarative_configuration.read(args.settings_file)
    for section in declarative_configuration.sections():
        if not configuration.has_section(section):
            configuration.add_section(section)
        for key, value in declarative_configuration.items(section):
            configuration.set(section, key, value)

    if not configuration.has_section("Account"):
        configuration.add_section("Account")
    if not configuration.has_option("Account", "password"):
        if args.password_file is None:
            raise ValueError(
                "an initial administrator password file is required for a new installation"
            )
        with open(args.password_file, "rb") as password_file:
            password = password_file.read().rstrip(b"\n")
        if len(password) < 8:
            raise ValueError("the initial administrator password must contain at least 8 bytes")
        configuration.set("Account", "username", args.username)
        configuration.set(
            "Account",
            "password",
            bcrypt.hashpw(password, bcrypt.gensalt()).decode("utf-8"),
        )

    if not configuration.has_section("Server"):
        configuration.add_section("Server")
    configuration.set("Server", "app_ip", args.listen_address)
    configuration.set("Server", "app_port", str(args.port))
    configuration.set("Server", "wg_conf_path", args.wireguard_path)
    configuration.set("Server", "awg_conf_path", args.amneziawg_path)

    with open(configuration_file, "w", encoding="utf-8") as output:
        configuration.write(output)
    os.chmod(configuration_file, 0o600)


if __name__ == "__main__":
    main()
