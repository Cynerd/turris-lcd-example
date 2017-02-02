#include <iostream>
#include <cstring>
#include <cstdio>
#include <cstdlib>
#include <string>
#include <LiquidCrystal_I2C.h>
#include <unistd.h>
#include <vector>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <cerrno>
#include <queue>
#include <sstream>


using namespace std;

const char omnia_str[] = "Turris Omnia feed:";

const int deftimeout = 2;
const char *pipe_path = "/tmp/turris-lcd";

void matrix_set(string str, int offset, int line, char (&matrix)[4][20]) {
	for (int i = 0; i < 20; i++) {
		if (str.length() > offset) {
			matrix[line][i] = str[offset];
			offset++;
		} else
			matrix[line][i] = ' ';
	}
}

void read_pipe(vector<string> &messages, queue<int> &newone, int pipe) {
	string msg = "";
	char c;
	int ec;
	while ((ec = read(pipe, &c, 1)) > 0) {
		if (c == '\n') {
			newone.push(messages.size());
			messages.push_back(msg);
			cout << "Input: " << msg << "\n";
		} else
			msg += c;
	}
	if (ec < 0 && errno != EAGAIN) {
		cout << "Input broken! " << strerror(errno) << "\n";
		exit(1);
	}
}

int main(int argc, char *argv[]) {
	/*
	if (argc < 1) {
		cout << "Please pass i2c device as first argument\n";
		exit(1);
	}*/
	// Initialize LCD
	LiquidCrystal_I2C lcd("/dev/i2c-7", 0x27, 2, 1, 0, 4, 5, 6, 7, 3, POSITIVE);
	lcd.begin(20, 4);

	char matrix[4][20];

	lcd.on();
	lcd.clear();
	// Autoscroll doesn't work as expected for some reason, probably cheap display

	mkfifo(pipe_path, NULL);
	errno = 0; // ignore if file exists
	int pipe = open(pipe_path, O_RDONLY | O_NONBLOCK);

	vector<string> messages;
	queue<int> newone;
	messages.push_back("");
	messages.push_back("");
	messages.push_back("");

	int msgs[3] = {0, 1, 2};
	int offsets[3] = {0, 0, 0};
	int timeout[3] = {deftimeout, deftimeout, deftimeout};
	int number_timeout = 0;

	while (true) {
		// Read new lones from pipe
		read_pipe(messages, newone, pipe);

		if (number_timeout > 3) {
			ostringstream ss;
			ss << "In total #";
			ss << (messages.size() - 3);
			matrix_set(ss.str(), 0, 0, matrix);
		} else
			matrix_set(omnia_str, 0, 0, matrix);
		number_timeout++;
		if (number_timeout > 6)
			number_timeout = 0;

		// Update matrix
		for (int i = 0; i < 3; i++) {
			matrix_set(messages[msgs[i]], offsets[i], i + 1, matrix);
			// Update offsets
			if (messages[msgs[i]].length() - offsets[i] > 20)
				offsets[i]++;
			else if (timeout[i] > 0)
				timeout[i]--;
			else {
				offsets[i] = 0;
				timeout[i] = deftimeout;
				if (newone.empty()) {
					int nw;
					bool fine = false;
					while (!fine) {
						nw = rand() % messages.size();
						fine = true;
						for (int s = 0; s < 3; s++) {
							if (s != i && msgs[s] == nw)
								fine = false;
						}
					}
					msgs[i] = nw;
				} else {
					msgs[i] = newone.front();
					newone.pop();
				}
			}
		}

		// Render matrix
		for (int i = 0; i < 4; i++) {
			lcd.setCursor(0, i);
			for (int y = 0; y < 20; y++) {
				lcd.write(matrix[i][y]);
			}
		}

		usleep(600000);
	}
}
