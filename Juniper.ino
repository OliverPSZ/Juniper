#include <math.h>
#include <Wire.h>
#include <Digital_Light_TSL2561.h>
#include <ArduinoBLE.h>

const int B=4275;                 // B value of the thermistor
const int R0 = 100000;            // R0 = 100k
const int pinTempSensor = A2;     // Temperature Sensor connect to A0 pin
const int pinHumSensor = A0;      // Humidity Sensor connect to A1 pin

float temperature = 0;
float humidity = 0;
float light = 0;

BLEService customService("A123");
BLEFloatCharacteristic customtemp("2A19", BLERead | BLENotify);
BLEFloatCharacteristic customhum("2A20", BLERead | BLENotify);
BLEFloatCharacteristic customlight("2A77", BLERead | BLENotify);

int sampling = 4*60*1000;
int send_inf = 0;

float saveddata [600][3] = {0};

float temp[5] = {0};
float hum[5] = {0};
float lig[5] = {0};

float final_temperature = 0;
float final_humidity = 0;
float final_light = 0;

void setup() {
  Wire.begin();
  Serial.begin(9600);
  while (!Serial);
  pinMode(LED_BUILTIN, OUTPUT);
  TSL2561.init();

  if (!BLE.begin()) {
    Serial.println("starting BLE failed!");

    while (1);
  }

  BLE.setLocalName("Juniper");
  BLE.setAdvertisedService(customService);
  customService.addCharacteristic(customtemp);
  customService.addCharacteristic(customhum);
  customService.addCharacteristic(customlight);
  BLE.addService(customService);
  customtemp.writeValue((int16_t) round(temperature));
  customhum.writeValue((int16_t) round(humidity));
  customlight.writeValue((int16_t) round(light));
  BLE.setAdvertisedServiceUuid("19B10000-E8F2-537E-4F6C-D104768A1214");
  BLE.advertise();
}

void loop() {

  BLEDevice central = BLE.central();
  if (central) {
    Serial.print("Connected to central: ");
    Serial.println(central.address());
    digitalWrite(LED_BUILTIN, HIGH);
    while (central.connected()) {
      
      get_data();

      temp[i] = temperature;
      hum[i] = humidity;
      lig[i] = light;

      save_data();

      if (i==5){
        for(x=0;x<5;x++){
          final_temperature = temp[x]+final_temperature;
          final_humidity = hum[x]+final_humidity;
          final_light = lig[x]+final_light;
        }
        final_temperature = final_temperature/5;
        final_humidity = final_humidity/5;
        final_light = final_light/5;
        i=0;
        save_data();
      }
      i=i+1;
      send_inf = send_inf+1;

      if(send_inf == 20){

        send_data();
        send_inf = 0;

      }

      delay(sampling);

    }

  Serial.print("Disconnected from central: ");
  Serial.println(central.address());
  
  }else{

    get_data();
        
    save_data();

    delay(sampling);

    void get_data(){

      // Gathering data from temperature sensor
      int a = analogRead(pinTempSensor );
      float R = 1023.0/((float)a)-1.0;
      R = 100000.0*R;
      temperature=1.0/(log(R/100000.0)/B+1/298.15)-273.15;
      delay(1000);

      // Gathering data from humidity sensor
      humidity = analogRead(pinHumSensor);
      delay(1000);

      // Gathering data from light sensor
      light = TSL2561.readVisibleLux()*0.0079;
      delay(1000);

    }

    void save_data(){
      
      for (i=599;i>0;i--){
        saveddata[i][1] = saveddata[i-1][1];
        saveddata[i][2] = saveddata[i-1][2];
        saveddata[i][3] = saveddata[i-1][3];
      }

      saveddata[0][1] = final_temperature;
      saveddata[0][2] = final_humidity;
      saveddata[0][3] = final_light;
    }

    void send_data(){
      
      for (i=0;i>600;i++){
        customtemp.writeValue((int16_t) round(saveddata[i][1]*100));
        customhum.writeValue((int16_t) round(saveddata[i][2]*100));
        customlight.writeValue((int16_t) round(saveddata[i][3]));
      }
    }

}

