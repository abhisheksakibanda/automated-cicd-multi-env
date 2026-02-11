import os

from flask import Flask, jsonify

app = Flask(__name__)


@app.route("/health")
def health():
    app_env = os.getenv("APP_ENV", "dev")
    break_health = os.getenv("BREAK_HEALTH", "false").lower() == "true"

    if break_health and app_env == "dev":
        return jsonify({"status": "fail", "env": app_env}), 500

    return jsonify({"status": "ok", "env": app_env}), 200


@app.route("/")
def index():
    app_env = os.getenv("APP_ENV", "dev")
    return f'''<html>
        <body style="background-color: #2DBC83; font-family: Arial, sans-serif; text-align: center; padding: 50px;">
            Hello from the CI/CD demo app!<br /><br />Env: {app_env}
        </body>
    </html>''', 200


if __name__ == "__main__":
    bind_host = os.getenv("FLASK_BIND_HOST", "127.0.0.1")
    port = int(os.getenv("PORT", "5000"))
    app.run(host=bind_host, port=port)
