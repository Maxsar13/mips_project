// converts assembly source into binary instruction memory
//
//   c++ -std=c++17 -Wall -Wextra -Werror tools/assembler.cpp -o assembler
//   ./assembler program.asm tb/cpu_program.mem
//
// supports li nop r3 operations and r4 operations
// commas are optional
// hash slash slash and semicolon start comments
//
// accepts the descriptive r4 aliases listed with the r4 opcode map

#include <algorithm>
#include <array>
#include <bitset>
#include <cctype>
#include <cstdint>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <sstream>
#include <stdexcept>
#include <string>
#include <unordered_map>
#include <vector>

namespace {

using OpcodeMap = std::unordered_map<std::string, std::uint8_t>;

// maps r3 mnemonics to their four bit opcode fields
const OpcodeMap kR3Opcodes = {
    {"absdb", 0x1}, {"au", 0x2},    {"cnt1w", 0x3}, {"ahs", 0x4},
    {"and", 0x5},   {"bcw", 0x6},   {"maxws", 0x7}, {"minws", 0x8},
    {"mlhu", 0x9},  {"mlhcu", 0xa}, {"or", 0xb},    {"cntlz", 0xc},
    {"rotw", 0xd},  {"sfwu", 0xe},  {"sfhs", 0xf},
};

// maps r4 mnemonics and aliases to their three bit mode fields
const OpcodeMap kR4Modes = {
    {"maddl", 0},     {"maddh", 1},     {"msubl", 2},     {"msubh", 3},
    {"lmaddl", 4},    {"lmaddh", 5},    {"lmsubl", 6},    {"lmsubh", 7},
    {"sima_low", 0},  {"sima_high", 1}, {"sims_low", 2},  {"sims_high", 3},
    {"slima_low", 4}, {"slima_high", 5},{"slims_low", 6}, {"slims_high", 7},
};

// accepts upper case or lower case assembly source
std::string lower(std::string text) {
    for (char& c : text)
        c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    return text;
}

// removes comments and separates a source line into lowercase tokens
std::vector<std::string> tokenize(std::string line) {
    const std::array<std::string, 3> comment_markers = {"//", "#", ";"};
    std::size_t comment = line.size();
    for (const std::string& marker : comment_markers) {
        const std::size_t position = line.find(marker);
        if (position != std::string::npos)
            comment = std::min(comment, position);
    }
    // keeps only the instruction before the first comment marker
    line.resize(comment);

    // treats commas like whitespace for simple assembly syntax
    for (char& c : line) {
        if (c == ',')
            c = ' ';
    }

    // returns the mnemonic first followed by its operands
    std::istringstream stream(line);
    std::vector<std::string> tokens;
    for (std::string token; stream >> token;)
        tokens.push_back(lower(token));
    return tokens;
}

// parses decimal hexadecimal or other c plus plus base prefixed values
std::uint32_t parse_number(const std::string& text, std::uint32_t maximum,
                           const std::string& description) {
    try {
        std::size_t consumed = 0;
        const unsigned long value = std::stoul(text, &consumed, 0);
        if (consumed != text.size() || value > maximum)
            throw std::out_of_range("out of range");
        return static_cast<std::uint32_t>(value);
    } catch (const std::exception&) {
        throw std::runtime_error(description + " must be between 0 and " +
                                 std::to_string(maximum) + ": " + text);
    }
}

// validates the r zero through r thirty one register form
std::uint32_t parse_register(const std::string& text) {
    if (text.size() < 2 || text.front() != 'r')
        throw std::runtime_error("register must use r0 through r31: " + text);
    return parse_number(text.substr(1), 31, "register number");
}

// rejects instructions with missing or extra operands
void require_operand_count(const std::vector<std::string>& tokens,
                           std::size_t expected, std::size_t line_number) {
    if (tokens.size() != expected + 1) {
        throw std::runtime_error("line " + std::to_string(line_number) +
                                 ": expected " + std::to_string(expected) +
                                 " operand(s) for " + tokens.front());
    }
}

// builds the r3 instruction fields from opcode sources and destination
std::uint32_t encode_r3(std::uint32_t opcode, std::uint32_t rs2_or_imm,
                        std::uint32_t rs1, std::uint32_t rd) {
    return (0x3u << 23) | (opcode << 15) | (rs2_or_imm << 10) |
           (rs1 << 5) | rd;
}

// converts one tokenized assembly line into one twenty five bit instruction
std::uint32_t assemble(const std::vector<std::string>& tokens,
                       std::size_t line_number) {
    // blank lines and comment only lines produce no instruction
    if (tokens.empty())
        return UINT32_MAX;

    const std::string& mnemonic = tokens.front();

    // nop is the r3 opcode zero encoding with no operands
    if (mnemonic == "nop") {
        require_operand_count(tokens, 0, line_number);
        return encode_r3(0, 0, 0, 0);
    }

    // li selects one sixteen bit lane and preserves the other lanes
    if (mnemonic == "li") {
        require_operand_count(tokens, 3, line_number);
        const std::uint32_t rd = parse_register(tokens[1]);
        const std::uint32_t lane = parse_number(tokens[2], 7, "LI lane");
        const std::uint32_t immediate = parse_number(tokens[3], 0xffff, "LI immediate");
        return (lane << 21) | (immediate << 5) | rd;
    }

    // r4 instructions use three sources in rs one rs two rs three order
    if (const auto r4 = kR4Modes.find(mnemonic); r4 != kR4Modes.end()) {
        require_operand_count(tokens, 4, line_number);
        const std::uint32_t rd = parse_register(tokens[1]);
        const std::uint32_t rs1 = parse_register(tokens[2]);
        const std::uint32_t rs2 = parse_register(tokens[3]);
        const std::uint32_t rs3 = parse_register(tokens[4]);
        return (0x2u << 23) | (static_cast<std::uint32_t>(r4->second) << 20) |
               (rs3 << 15) | (rs2 << 10) | (rs1 << 5) | rd;
    }

    // all remaining supported operations use the r3 format
    const auto r3 = kR3Opcodes.find(mnemonic);
    if (r3 == kR3Opcodes.end())
        throw std::runtime_error("line " + std::to_string(line_number) +
                                 ": unknown mnemonic: " + mnemonic);

    const std::uint32_t opcode = r3->second;

    // these r3 operations read only rs one
    if (mnemonic == "cnt1w" || mnemonic == "bcw" || mnemonic == "cntlz") {
        require_operand_count(tokens, 2, line_number);
        return encode_r3(opcode, 0, parse_register(tokens[2]),
                         parse_register(tokens[1]));
    }

    // mlhcu stores its five bit constant in the rs two field
    if (mnemonic == "mlhcu") {
        require_operand_count(tokens, 3, line_number);
        return encode_r3(opcode, parse_number(tokens[3], 31, "MLHCU immediate"),
                         parse_register(tokens[2]), parse_register(tokens[1]));
    }

    // ordinary r3 operations use two register sources
    require_operand_count(tokens, 3, line_number);
    return encode_r3(opcode, parse_register(tokens[3]), parse_register(tokens[2]),
                     parse_register(tokens[1]));
}

} // namespace

int main(int argc, char* argv[]) {
    // requires the input assembly path and output memory path
    if (argc != 3) {
        std::cerr << "Usage: " << argv[0] << " <program.asm> <program.mem>\n";
        return 1;
    }

    // opens the human readable assembly program
    std::ifstream input(argv[1]);
    if (!input) {
        std::cerr << "Could not open input file: " << argv[1] << '\n';
        return 1;
    }

    // creates the instruction memory file for the testbench
    std::ofstream output(argv[2]);
    if (!output) {
        std::cerr << "Could not open output file: " << argv[2] << '\n';
        return 1;
    }

    try {
        std::string line;
        std::size_t line_number = 0;
        std::size_t instruction_count = 0;
        while (std::getline(input, line)) {
            ++line_number;
            const std::uint32_t instruction = assemble(tokenize(line), line_number);
            if (instruction == UINT32_MAX)
                continue;

            // the instruction buffer stores at most sixty four instructions
            if (instruction_count == 64)
                throw std::runtime_error("program exceeds the 64-instruction buffer");

            // writes exactly twenty five binary digits for each instruction
            output << std::bitset<25>(instruction) << '\n';
            ++instruction_count;
        }
    } catch (const std::exception& error) {
        std::cerr << "Assembly error: " << error.what() << '\n';
        return 1;
    }

    return 0;
}
