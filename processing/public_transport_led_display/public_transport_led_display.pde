/*
 * Display next train delay on Arduino (require Firmata / StandardFirmata installed on Arduino)
 * Each 30s
 *   - Fetch next trains schedule data (current line)
 *   - Display next train schedule via LEDs
 *   - Fetch next bike station data (current station)
 *   - Display number of bike available via LEDs
 */

import processing.serial.*;
import cc.arduino.*;

// Arduino object wrapper
Arduino arduino;

// Number of ms to display current transport information
int DISPLAY_TIME = 3000;

// LED pins
int LED0 = 2;
int LED1 = 3;
int LED2 = 4;
int LED3 = 5;
int LED4 = 6;
int LED5 = 7;
int LED10 = 8;

int LED_TRAIN0 = 9;
int LED_TRAIN1 = 10;
int[] LEDS_TRAIN = {LED_TRAIN0, LED_TRAIN1};

int LED_BIKE0 = 11;
int[] LEDS_BIKE = {LED_BIKE0};

int[] LEDS_TYPE = {LED_TRAIN0, LED_TRAIN1, LED_BIKE0};

// ALL LEDS
int[] LEDS = {LED0, LED1, LED2, LED3, LED4, LED5, LED10, LED_TRAIN0, LED_TRAIN1, LED_BIKE0};


// train lines to fetch
String[] TRAIN_LINES = {"chevaleret/nation/6", "chevaleret/charles+de+gaulle+etoile/6"};
//String[] LINES = {"chevaleret/nation/6", "chevaleret/charles+de+gaulle+etoile/6", "bibliotheque+francois+mitterrand/saint+lazare/14", "bibliotheque+francois+mitterrand/olympiades/14"};
// number of trains to display per line
int NUMBER_OF_TRAINS = 2;
// variable to store currently displayed line
int current_train_line = 0;

// bikes
// https://developer.jcdecaux.com/#/account
// Velib API Key: 9201fa29978f510302724e1a5a526f91fef1a544
// https://api.jcdecaux.com/vls/v1/stations/13018?contract=Paris&apiKey=9201fa29978f510302724e1a5a526f91fef1a544
String BIKE_CONTRACT = "Paris";
String BIKE_API_KEY = "9201fa29978f510302724e1a5a526f91fef1a544";
int[] BIKE_STATION_IDS = {13018};
// variable to store currently displayed bike station
int current_bike_station = 0;





void setup() {
  arduino = new Arduino(this, Arduino.list()[2], 57600);
  for(int i = 0; i < LEDS.length; i++) {
    output(LEDS[i]);
  }
  allOff();
  //allOn();
}

void draw() {
  // trains
  if(current_train_line >= TRAIN_LINES.length) { current_train_line = 0; }
  // update type of public transport LED
  displayType(LEDS_TRAIN[current_train_line]);
  // fetch train data
  String train_line = TRAIN_LINES[current_train_line++];
  String[] train_line_infos = split(train_line, "/");
  String from = train_line_infos[0];
  String to = train_line_infos[1];
  String number = train_line_infos[2];
  int[] times = getTrainTimeSchedule(number, from, to);
  // display train data
  displaySchedules(times);
  
  // velib
  if(current_bike_station >= BIKE_STATION_IDS.length) { current_bike_station = 0; }
  // update type of public transport LED
  displayType(LEDS_BIKE[current_bike_station]);
  // fetch bike data
  int station_id = BIKE_STATION_IDS[current_bike_station];
  int bikes = getAvailableBikes(station_id, BIKE_CONTRACT);
  // display bike data
  displaySchedule(bikes);
}

void displayType(int pin) {
  for(int i = 0; i < LEDS_TYPE.length; i++) {
    off(LEDS_TYPE[i]);
  }
  on(pin);
}

void displaySchedules(int[] times) {
  int iteration = min(times.length, NUMBER_OF_TRAINS);
  for(int i = 0; i < iteration; i++) {
    int nextTime = times[i];
    displaySchedule(nextTime);
  }
}

int getAvailableBikes(int stationId, String contract) {
  println("fetching bike at station " + stationId + ", contract " + contract);
  String url = "https://api.jcdecaux.com/vls/v1/stations/" + stationId + "?contract=" + contract + "&apiKey=" + BIKE_API_KEY + "";
  JSONObject json = loadJSONObject(url);
  //println(json);
  int available_bikes = json.getInt("available_bikes");
  return available_bikes;
}

int[] getTrainTimeSchedule(String line, String from, String to) {
  println("fetching schedule of line " + line + " from " + from + " to " + to);
  String url = "https://api-ratp.pierre-grimaud.fr/v2/metros/" + line + "/stations/" + from + "?destination=" + to + "";
  JSONObject json = loadJSONObject(url);
  int[] times =  processTrainTimeSchedule(json);
  //println(times);
  return times;
}

int[] processTrainTimeSchedule(JSONObject json) {
  JSONObject response = json.getJSONObject("response");
  JSONArray schedules = response.getJSONArray("schedules");
  int size = schedules.size();
  int[] minutes = new int[size];
  for(int i = 0; i < size; i++) {
    JSONObject schedule = schedules.getJSONObject(i);
    String message = schedule.getString("message");
    //println(message);
    String[] messages = split(message, " ");
    int minute = int(messages[0]);
    //println(minute);
    minutes[i] = minute;
  }
  //println(minutes);
  return minutes;
}

void displaySchedule(int minutes) {
  println("next train in: " + minutes);
  int minutesLeft = minutes;
  if (minutesLeft == 0) {
    on(LED0);
  } else {
    off(LED0);
  }
  if (minutesLeft >= 10) {
    on(LED10);
    minutesLeft -= 10;
  } else {
    off(LED10);
  }
  if (minutesLeft >= 5) {
    on(LED5);
    minutesLeft -= 5;
  } else {
    off(LED5);
  }
  if (minutesLeft >= 4) {
    on(LED4);
  } else {
    off(LED4);
  }
  if (minutesLeft >= 3) {
    on(LED3);
  } else {
    off(LED3);
  }
  if (minutesLeft >= 2) {
    on(LED2);
  } else {
    off(LED2);
  }
  if (minutesLeft >= 1) {
    on(LED1);
  } else {
    off(LED1);
  }
  delay(DISPLAY_TIME);
}

void blink(int pin) {
  arduino.digitalWrite(pin, Arduino.HIGH);
  delay(1000);
  arduino.digitalWrite(pin, Arduino.LOW);
  delay(1000);
}

void on(int pin) {
  arduino.digitalWrite(pin, Arduino.HIGH);
}

void value(int pin, int value) {
  arduino.analogWrite(pin, value);
}

void off(int pin) {
  arduino.digitalWrite(pin, Arduino.LOW);
}

void output(int pin) {
  arduino.pinMode(pin, Arduino.OUTPUT);
}

void input(int pin) {
  arduino.pinMode(pin, Arduino.INPUT);
}

void allOff() {
  for(int i = 0; i < LEDS.length; i++) {
    off(LEDS[i]);
  }
}

void allOn() {
  for(int i = 0; i < LEDS.length; i++) {
    on(LEDS[i]);
  }
}