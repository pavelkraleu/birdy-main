import datetime
from weather import Weather
import gspread
from oauth2client.service_account import ServiceAccountCredentials


class DataProcessor(object):

    google_sheet_id = "Birdy"
    google_sheet_file = "./client_secret.json"

    scope = ['https://spreadsheets.google.com/feeds']

    weather = Weather()

    def __init__(self):

        credentials = ServiceAccountCredentials.from_json_keyfile_name(self.google_sheet_file, self.scope)

        gc = gspread.authorize(credentials)

        self.birds_sheet = gc.open(self.google_sheet_id).worksheet("Sheet1")
        self.cards_sheet = gc.open(self.google_sheet_id).worksheet("Sheet2")

    def submit_data(self, number_of_birds):

        location = self.weather.lookup_by_location('Prague')
        condition = location.condition()

        condition_text = condition.text()
        # temperature = (int(condition.temp()) - 32) / 1.8
        temperature = int(condition.temp())

        self.birds_sheet.append_row([datetime.datetime.now(), number_of_birds, condition_text, temperature])

    def submit_card(self, card_id):

        self.cards_sheet.append_row([datetime.datetime.now(), card_id])