from flask import Flask, jsonify
import os

app = Flask(__name__)

# Home page
@app.route("/")
def home():
    return "Python Web App is running successfully on Azure App Service!"

# Test API endpoint
@app.route("/api")
def api():
    data = {
        "message": "API is working",
        "status": "Success"
    }
    return jsonify(data)

# Health check endpoint
@app.route("/health")
def health():
    return jsonify({"status": "Healthy"})

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8000))
    app.run(host="0.0.0.0", port=port)
