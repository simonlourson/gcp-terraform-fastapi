from google.cloud import secretmanager
from google.cloud.sql.connector import Connector, IPTypes
import sqlalchemy
from sqlalchemy import text

# Get the database password from Google Secret Manager
def get_secret(secret_id):
    client = secretmanager.SecretManagerServiceClient()
    name = f"projects/doctolib-case-dataops/secrets/{secret_id}/versions/latest"
    response = client.access_secret_version(name=name)
    return response.payload.data.decode("UTF-8")

# Configuration
db_user = "doctolib-admin"
db_password = get_secret("cloudsql-db-password")
db_name = "movie_db"
instance_connection_name = "doctolib-case-dataops:europe-west1:doctolib-sql-instance"

# Function to connect using the Google Cloud SQL Connector
def connect_with_connector() -> sqlalchemy.engine.base.Engine:
    connector = Connector(IPTypes.PRIVATE)

    def getconn():
        return connector.connect(
            instance_connection_name,
            "pymysql",
            user=db_user,
            password=db_password,
            db=db_name,
        )

    pool = sqlalchemy.create_engine(
        "mysql+pymysql://",
        creator=getconn,
    )
    return pool

# Load the SQL script into the database
def load_sql_script(script_path: str):
    engine = connect_with_connector()
    
    try:
        with open(script_path, 'r') as file:
            sql_script = file.read()
        
        # Split the script into individual statements
        statements = sql_script.split(';')
        
        with engine.connect() as connection:
            for statement in statements:
                statement = statement.strip()
                if statement:  # Only execute non-empty statements
                    connection.execute(text(statement))
        
        print("Database loaded successfully from", script_path)
    except Exception as e:
        print("An error occurred:", str(e))

if __name__ == "__main__":
    load_sql_script('movie.sql')
