#include <iostream>

#include "DragonLispDriver.hh"

int main(int argc, char** argv) {
	DragonLisp::DLDriver driver;
	if (argc <= 1)
		return driver.parse(std::cin);
	return driver.parse(argv[1]);
}
