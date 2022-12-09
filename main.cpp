#include <iostream>

#include "DragonLispDriver.hh"

int main() {
	DragonLisp::DLDriver driver;
	return driver.parse(std::cin);
}
