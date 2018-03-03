import datetime
from weather import Weather
import gspread
from oauth2client.service_account import ServiceAccountCredentials


class DataProcessor(object):

    google_sheet_id = "Birdy"
    google_sheet_file = "./client_secret.json"

    scope = ['https://spreadsheets.google.com/feeds']
    credentials = ServiceAccountCredentials.from_json_keyfile_name(google_sheet_file, scope)

    gc = gspread.authorize(credentials)

    birds_sheet = gc.open(google_sheet_id).worksheet("Sheet1")
    cards_sheet = gc.open(google_sheet_id).worksheet("Sheet2")

    weather = Weather()

    def __init__(self):
        pass

    def submit_data(self, number_of_birds):

        location = self.weather.lookup_by_location('Prague')
        condition = location.condition()

        condition_text = condition.text()
        # temperature = (int(condition.temp()) - 32) / 1.8
        temperature = int(condition.temp())

        self.birds_sheet.append_row([datetime.datetime.now(), number_of_birds, condition_text, temperature])

    def submit_card(self, card_id):

        self.cards_sheet.append_row([datetime.datetime.now(), card_id])