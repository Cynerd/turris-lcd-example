#include <iostream>
#include <LiquidCrystal_I2C.h>

using namespace std;

int main(int argc, char *argv[]) {
	// Initialize LCD
	LiquidCrystal_I2C lcd("/dev/i2c-2", 0x27, 2, 1, 0, 4, 5, 6, 7, 3, POSITIVE);
	lcd.begin(20, 4);

	lcd.on();
	lcd.clear();

	lcd.print("Turris Omnia");

	return 0;
}
