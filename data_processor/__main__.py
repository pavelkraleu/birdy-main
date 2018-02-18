
from data_processor.data_processor import DataProcessor
from flask import Flask
app = Flask(__name__)

@app.route('/')
def process_data():

    processor = DataProcessor()
    processor.submit_data(10)
    processor.submit_card("ABCD")

    return "OK"

app.run()
