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

            // Real results
            uint64_t* guess_key, *prec_key = reinterpret_cast<uint64_t*>(ref.keyv);
            // TODO RM
            guess_key = reinterpret_cast<uint64_t*>(ref.keyv+(1654588965*3));
            cout << *guess_key << "\n";
            // END RM
            for (uint64_t i=0; i<ref.nkeyv_true; i++) {
                guess_key = reinterpret_cast<uint64_t*>(ref.keyv+(i*3));
                if (*guess_key == userInput) {
                    cout << "###### Real results ######\n";
                    cout << "Key " << *guess_key << " found at i = " << i << "\n";
                    b = ref.get_keyv_val(i);
                    e = ref.get_keyv_val(i+1);
                    cout << "position interval = [" << b << ", " << e << ")\n";
                }
                if (*guess_key < *prec_key)
                    cerr << "*panic* at position " << i << "\n";
                prec_key = guess_key;
            }
            // Index results
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
