
from data_processor.data_processor import DataProcessor
from flask import Flask, request
import json
from flask_httpauth import HTTPBasicAuth
from secret_keys import SecretKeys

app = Flask(__name__)
auth = HTTPBasicAuth()

# users = {
#     "test": "ixielee8johghu9Nae3Teu4Quae2fa",
# }
#
# @auth.get_password
# def get_pw(username):
#     if username in users:
#         return users.get(username)
#     return None


@app.route('/', methods=['GET', 'POST'])
def process_data():
    # This callback gets called by LoRa provider

    lora_object = json.loads(request.data)
    lora_data = json.loads(lora_object["data"])["data"]

    # print(lora_object)
    # print(lora_data)

    # LoRa sends data HEX encoded
    birdy_object = json.loads(bytearray.fromhex(lora_data).decode())

    print(birdy_object)

    processor = DataProcessor()

    if "c" in birdy_object:
        # New card has been registered
        processor.submit_card(birdy_object["c"])

    if "b" in birdy_object:
        # Bird reading
        processor.submit_data(birdy_object["b"])

    return "OK"

app.run(host='0.0.0.0', port=SecretKeys.http_listen_port)
