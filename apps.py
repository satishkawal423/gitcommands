from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route("/")
def home():
    return "Flask App is running on Azure!"

@app.route("/health")
def health():
    return jsonify({"status": "Healthy"})

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8000))
    app.run(host="0.0.0.0", port=port)
