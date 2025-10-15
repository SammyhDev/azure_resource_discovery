# Web App Configuration for Azure App Service
import os
from app import app

if __name__ == "__main__":
    # This is used when running locally
    app.run(debug=True)