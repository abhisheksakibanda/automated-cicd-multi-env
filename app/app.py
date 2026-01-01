import os

from flask import Flask, jsonify

app = Flask(__name__)

APP_ENV = os.getenv("APP_ENV", "dev")


@app.route("/health")
def health():
    return jsonify({"status": "ok", "env": APP_ENV}), 200


@app.route("/")
def index():
    return f'''
    <html>
        <body style="background-color: #2DBC83; color: #2D3D37; font-family: Arial, sans-serif; text-align: center; padding: 50px;">
            Hello from the CI/CD demo app!<br /><br />Env: {APP_ENV}
        </body>
    </html>''', 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
