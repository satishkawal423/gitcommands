from flask import Flask

app = Flask(__name__)

@app.route("/")
def home():
    return "Hello, Azure App Service! Python app is running successfully."

@app.route("/health")
def health():
    return {"status": "Healthy"}

if __name__ == "__main__":
    # Azure App Service runs on port 8000 or provided by environment
    app.run(host="0.0.0.0", port=8000)
