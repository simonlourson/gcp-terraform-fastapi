from fastapi import FastAPI, HTTPException
from google.cloud import secretmanager
from google.cloud.sql.connector import Connector, IPTypes
import sqlalchemy
from sqlalchemy import text
import os

app = FastAPI()
project_id = os.getenv("PROJECT_ID")
region_parts = project_id.split("-")[-2:]
region = "-".join(region_parts)

# Get the database password from Google Secret Manager
def get_secret(secret_id):
    client = secretmanager.SecretManagerServiceClient()
    name = f"projects/{project_id}/secrets/{secret_id}/versions/latest"
    response = client.access_secret_version(name=name)
    return response.payload.data.decode("UTF-8")

# Configuration
db_user = f"{project_id}-sql"
db_password = get_secret("cloudsql-db-password")
db_name = "movie_db"
instance_connection_name = f"{project_id}:{region}:{project_id}-cloud-sql"


query_actors = """
    SELECT * FROM actor
"""

query_movies = """
    SELECT 
    Movie.mov_id AS id,
    Movie.mov_title AS movie_title,
    Movie.mov_year AS release_year,
    director.dir_lname AS director_last_name
    FROM 
        Movie
    JOIN 
        movie_direction ON Movie.mov_id = movie_direction.mov_id
    JOIN 
        director ON movie_direction.dir_id = director.dir_id;

"""

query_actors_movies = """
    SELECT 
        actor.act_id AS actor_id,
        actor.act_fname AS actor_first_name,
        actor.act_lname AS actor_last_name,
        Movie.mov_id AS movie_id,
        Movie.mov_title AS movie_title,
        Movie.mov_year AS release_year,
        movie_cast.role AS role
    FROM 
        actor
    JOIN 
        movie_cast ON actor.act_id = movie_cast.act_id
    JOIN 
        Movie ON movie_cast.mov_id = Movie.mov_id
    WHERE 
        actor.act_id = :actor_id;
"""

query_actors_in_movie = """
    SELECT 
        actor.act_id AS actor_id,
        actor.act_fname AS actor_first_name,
        actor.act_lname AS actor_last_name,
        movie.mov_id AS movie_id,
        movie.mov_title AS movie_title,
        movie.mov_year AS release_year,
        movie_cast.role AS role
    FROM 
        actor
    JOIN 
        movie_cast ON actor.act_id = movie_cast.act_id
    JOIN 
        Movie AS movie ON movie_cast.mov_id = movie.mov_id
    WHERE 
        movie.mov_id = :movie_id;
"""

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

# Create the SQLAlchemy engine with the private connection
engine = connect_with_connector()

@app.get("/")
async def root():
    return {"message": "Hello, World!"}

@app.get("/debug")
async def debug():
    return {"debug": "Debugging endpoint"}

@app.get("/actors_list")
async def get_actors():
    try:
        with engine.connect() as connection:
            result = connection.execute(text(query_actors)).mappings()
            actors = [{"id": row["act_id"], "first_name": row["act_fname"].strip(), "last_name": row["act_lname"].strip(), "gender": row["act_gender"].strip()} for row in result]
            return {"actors": actors}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/movies_list")
async def get_movies():
    try:
        with engine.connect() as connection:
            result = connection.execute(text(query_movies)).mappings()
            movies = [{"id": row["id"], "movie_title": row["movie_title"].strip(), "release_year": row["release_year"], "director_last_name": row["director_last_name"].strip()} for row in result]
            return {"movies": movies}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/actor/{actor_id}/movies")
async def get_actors_movies(actor_id: int):
    try:
        with engine.connect() as connection:
            result = connection.execute(text(query_actors_movies), {"actor_id": actor_id}).mappings()
            actor_movies = [
                {
                    "actor_id": row["actor_id"],
                    "actor_first_name": row["actor_first_name"].strip(),
                    "actor_last_name": row["actor_last_name"].strip(),
                    "movie_id": row["movie_id"],
                    "movie_title": row["movie_title"].strip(),
                    "release_year": row["release_year"],
                    "role": row["role"].strip(),
                }
                for row in result
            ]
            if not actor_movies:
                raise HTTPException(status_code=404, detail="Actor not found or no movies found for this actor.")
            
            return {"actor_movies": actor_movies}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/movie/{movie_id}/actors")
async def get_actors_in_movie(movie_id: int):
    try:
        with engine.connect() as connection:
            result = connection.execute(text(query_actors_in_movie), {"movie_id": movie_id}).mappings()
            actors = [
                {
                    "actor_id": row["actor_id"],
                    "actor_first_name": row["actor_first_name"].strip(),
                    "actor_last_name": row["actor_last_name"].strip(),
                    "movie_id": row["movie_id"],
                    "movie_title": row["movie_title"].strip(),
                    "release_year": row["release_year"],
                    "role": row["role"].strip(),
                }
                for row in result
            ]
            if not actors:
                raise HTTPException(status_code=404, detail="No actors found for this movie.")
            
            return {"movie_id": movie_id, "actors": actors}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))