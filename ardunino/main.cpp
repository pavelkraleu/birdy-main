
#include <SPI.h>
#include <MFRC522.h>
#include <rn2xx3.h>
#include <dht.h>

int RST_PIN = 9;
int SS_PIN = 10;
int PIR_SENSOR_PIN = 7;
int BUZZER_PIN = 6;
int DHT_PIN = 4;

unsigned long MIN_BIRD_DELAY_SECONDS = (1000 * 10);
unsigned long SEND_DATA_LORA_DELAY_SECONDS = (1000 * 60 * 60);

int birds_detected = 0;
int air_temperature = 0;
int air_humidity = 0;

const char *appEui = "XXXXX";
const char *appKey = "XXXXX";

unsigned long last_bird_detected = 0;
unsigned long last_lora_send = SEND_DATA_LORA_DELAY_SECONDS;

MFRC522 mfrc522(SS_PIN, RST_PIN);

dht DHT;

rn2xx3 myLora(Serial2);

void printHex(byte *buffer, byte bufferSize) {
  for (byte i = 0; i < bufferSize; i++) {
    SerialUSB.print(buffer[i] < 0x10 ? " 0" : " ");
    SerialUSB.print(buffer[i], HEX);
  }
}

void printDec(byte *buffer, byte bufferSize) {
  for (byte i = 0; i < bufferSize; i++) {
    SerialUSB.print(buffer[i] < 0x10 ? " 0" : " ");
    SerialUSB.print(buffer[i], DEC);
  }
}

void setup() {

  pinMode(LORA_RESET, OUTPUT);
  pinMode(PIR_SENSOR_PIN, INPUT);
  pinMode(BUZZER_PIN, OUTPUT);

  Serial2.begin(9600);
  SerialUSB.begin(9600);

  while ((!SerialUSB) && (millis() < 30000)) {
    // Wait for SerialUSB or start after 30 seconds
  }

  SerialUSB.println("Startup");

  SPI.begin();
  mfrc522.PCD_Init();

  setup_lora();

  SerialUSB.println("Ready to go !");

}

void setup_lora(){

  SerialUSB.println("Rebooting LoRa chip");

  digitalWrite(LORA_RESET, LOW);
  delay(500);
  digitalWrite(LORA_RESET, HIGH);

  delay(100);
  Serial2.flush();

  myLora.autobaud();

  String hweui = myLora.hweui();
  while(hweui.length() != 16)
  {
    SerialUSB.println("Communication with RN2xx3 unsuccessful. Power cycle the board.");

    digitalWrite(LORA_RESET, LOW);
    delay(500);
    digitalWrite(LORA_RESET, HIGH);

    SerialUSB.println(hweui);
    delay(10000);
    hweui = myLora.hweui();
  }

  SerialUSB.println("Trying to join TTN");
  bool join_result = false;

  myLora.tx("TTN Mapper on TTN Enschede node");

  join_result = myLora.initOTAA(appEui, appKey);

  while(!join_result)
  {
    SerialUSB.println("Unable to join. Are your keys correct, and do you have TTN coverage?");
    delay(60000);
    join_result = myLora.init();
  }

  SerialUSB.println("LoRa is ready");

}

void beep(int freq, int numbeep){

    for(int i=0; i < numbeep; i++){
      tone(BUZZER_PIN, freq);
      delay(100);

      noTone(BUZZER_PIN);
      delay(100);
    }

    noTone(BUZZER_PIN);

}


bool detect_bird(){

  if (digitalRead(PIR_SENSOR_PIN) == HIGH && millis() >= last_bird_detected + MIN_BIRD_DELAY_SECONDS) {

      SerialUSB.println("Bird detected !");

      beep(5000, 3);

      last_bird_detected = millis();

      SerialUSB.print("Bird detected at : ");
      SerialUSB.print(last_bird_detected);
      SerialUSB.println();

      birds_detected++;

      return true;
  }

  return false;

}

void detect_temperature(){
  int chk = DHT.read11(DHT_PIN);
  SerialUSB.print("Temperature = ");
  SerialUSB.println(DHT.temperature);
  SerialUSB.print("Humidity = ");
  SerialUSB.println(DHT.humidity);
}

void detect_card(){

  if (!mfrc522.PICC_IsNewCardPresent())
    return;

  if (!mfrc522.PICC_ReadCardSerial())
    return;

  // SerialUSB.print("PICC type: ");
  // MFRC522::PICC_Type piccType = mfrc522.PICC_GetType(mfrc522.uid.sak);
  // SerialUSB.println(mfrc522.PICC_GetTypeName(piccType));

  SerialUSB.println("The NUID tag is:");
  SerialUSB.print("In hex: ");
  printHex(mfrc522.uid.uidByte, mfrc522.uid.size);
  SerialUSB.println();
  SerialUSB.print("In dec: ");
  printDec(mfrc522.uid.uidByte, mfrc522.uid.size);
  SerialUSB.println();

  beep(1000, 3);
}

void send_lora(){
  if (millis() >= last_lora_send + SEND_DATA_LORA_DELAY_SECONDS){
    SerialUSB.println("Sending message to LoRa");

    SerialUSB.print("Number of birds detected : ");
    SerialUSB.print(birds_detected);
    SerialUSB.println();

    SerialUSB.print("Air temperature : ");
    SerialUSB.print(air_temperature);
    SerialUSB.println();

    SerialUSB.print("Air humidity : ");
    SerialUSB.print(air_humidity);
    SerialUSB.println();

    char buf[256];
    snprintf(buf, sizeof buf, "{\"t\":%d,\"h\":%d,\"b\":%d}", air_temperature, air_humidity, birds_detected);

    last_lora_send = millis();
    birds_detected = 0;

    SerialUSB.println("Sending message");
    SerialUSB.println(buf);

    myLora.tx(buf);

    beep(1000, 7);
  }
}

void loop() {

  detect_bird();

  detect_card();

  detect_temperature();

  send_lora();

}