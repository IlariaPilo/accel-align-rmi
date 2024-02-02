#include "header.h"

using namespace std;

int main(int argc, char *argv[]) {
    try {
        // Check if a filename is provided in the command line arguments
        if (argc != 2) {
            cerr << "Usage: " << argv[0] << " <reference.fna>\n";
            return EXIT_FAILURE;
        }

        // make reference
        Reference ref(argv[1], 32, false, true, ' ');

        size_t b, e;

        while (true) {
            // Read integer from the command line
            uint64_t userInput;
            cout << "Enter an integer seed (Ctrl+C to exit): ";
            cin >> userInput;

            // Check if the input was a valid integer
            if (cin.fail()) {
                cerr << "Invalid input. Please enter a valid integer.\n";
                cin.clear();  // Clear the error flag
                cin.ignore(numeric_limits<streamsize>::max(), '\n');  // Discard invalid input
                continue;
            }

            ref.index_lookup(userInput, &b, &e);
            cout << "###### Lookup results ######\n";
            cout << "position interval = [" << b << ", " << e << ")\n";
            // TODO add actual check
        }
    } catch (...) {
        // Handle any unexpected exceptions
        std::cerr << "An unexpected error occurred.\n";
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}
