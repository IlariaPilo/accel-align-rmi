#include "header.h"

std::string get_last_directory_part(const std::string& directory_path) {
    size_t last_slash_pos = directory_path.find_last_of("/");
    if (last_slash_pos == std::string::npos)
        return directory_path; // No slash found, return the whole path
    else
        return directory_path.substr(last_slash_pos + 1);
}

int main(int argc, char** argv) {
    if (argc == 1) {
        std::cerr << "Usage: ./index_gen <reference string prefix>" << std::endl;
        std::cerr << "Example: ./index_gen ./data/hg37" << std::endl;
        return 1;
    }
    std::string ref_string_prefix = argv[1];
    std::string out_file = ref_string_prefix + "_index/index_uint32";
    std::string in_file = ref_string_prefix + "_index/keys_uint32";
    std::string library = ref_string_prefix + "_index/" + get_last_directory_part(ref_string_prefix) + "_index.so";

    std::cerr << std::endl << "Reading from " << in_file << std::endl;
    std::cerr << "Writing to " << out_file << std::endl;
    std::cerr << "Library " << library << std::endl << std::endl;

    // First, we load the library
    RMI rmi(library.c_str());
    // Now, we open the files
    std::ifstream fi(in_file.c_str(), std::ios::binary);
    std::ofstream fo(out_file.c_str(), std::ios::binary);
    // Get the number of entries
    uint64_t eof = 0;
    uint32_t key;
    uint32_t value;
    size_t err;
    fi.read((char *) &eof, 8);
    std::cerr << "Reading " << eof << " entries." << std::endl;
    fo.write((char *) &eof, 8);
    // Start!
    for (uint64_t i=0; i<eof; i++) {
        // Read a key
        fi.read((char *) &key, 4);
        // Get the value
        value = (uint32_t) rmi.lookup((uint64_t)key, &err);
        // Write the value
        fo.write((char *) &value, 8);
    }
    // Close the files
    fi.close();
    fo.close();
    std::cerr << "Indexing done!" << std::endl;
    return 0;
}

