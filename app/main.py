from flask import Flask, jsonify
import os, socket, datetime

app = Flask(__name__)

@app.route("/")
def home():
    return jsonify({
        "status":    "ok",
        "message":   "DevOps Challenge API",
        "hostname":  socket.gethostname(),
        "timestamp": datetime.datetime.utcnow().isoformat() + "Z",
    })

@app.route("/health")
def health():
    return jsonify({"status": "healthy"}), 200

@app.route("/info")
def info():
    return jsonify({
        "app":         "devops-challenge",
        "version":     os.getenv("APP_VERSION", "1.0.0"),
        "environment": os.getenv("ENVIRONMENT", "production"),
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
