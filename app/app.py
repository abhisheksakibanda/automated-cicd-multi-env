import os

from flask import Flask, jsonify

app = Flask(__name__)

APP_ENV = os.getenv("APP_ENV", "dev")
BREAK_HEALTH = os.getenv("BREAK_HEALTH", "false").lower() == "true"


@app.route("/health")
def health():
    if APP_ENV == "dev" and BREAK_HEALTH:
        return jsonify({"status": "fail", "env": APP_ENV}), 500
    return jsonify({"status": "ok", "env": APP_ENV}), 200


@app.route("/")
def index():
    return f'''<html>
        <body style="background-color: #2DBC83; font-family: Arial, sans-serif; text-align: center; padding: 50px;">
            Hello from the CI/CD demo app!<br /><br />Env: {APP_ENV}
        </body>
    </html>''', 200


if __name__ == "__main__":
    # Secure default: local-only. Override in EC2 with FLASK_BIND_HOST=0.0.0.0
    bind_host = os.getenv("FLASK_BIND_HOST", "127.0.0.1")
    port = int(os.getenv("PORT", "5000"))
    app.run(host=bind_host, port=port)
