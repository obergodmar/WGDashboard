import configparser
import os
from sqlalchemy_utils import database_exists, create_database
from .DashboardEnvironment import RuntimeEnvironment

def ConnectionString(database) -> str:    
    configurationPath = RuntimeEnvironment.ConfigurationPath
    parser = configparser.ConfigParser(strict=False)
    parser.read_file(open(os.path.join(configurationPath, 'wg-dashboard.ini'), "r+"))

    sqlitePath = os.path.join(configurationPath, "db")
    if not os.path.isdir(sqlitePath):
        os.mkdir(sqlitePath)

    if parser.get("Database", "type") == "postgresql":
        cn = f'postgresql+psycopg://{parser.get("Database", "username")}:{parser.get("Database", "password")}@{parser.get("Database", "host")}/{database}'
    elif parser.get("Database", "type") == "mysql":
        cn = f'mysql+pymysql://{parser.get("Database", "username")}:{parser.get("Database", "password")}@{parser.get("Database", "host")}/{database}'
    else:
        cn = f'sqlite:///{os.path.join(sqlitePath, f"{database}.db")}'
    try:
        if not database_exists(cn):
            create_database(cn)
    except Exception as e:
        exit(1)

    return cn
