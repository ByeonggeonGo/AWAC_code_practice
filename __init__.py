from flask import Flask
import serve
import os
import sys


app = Flask(__name__)

if __name__ == "__main__":
    app.register_blueprint(serve.bp)
    app.run(host='0.0.0.0', port = 51212)

