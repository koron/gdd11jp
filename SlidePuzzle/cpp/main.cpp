#include <string>
#include <sstream>

#include "solver.hpp"

using std::string;
using std::istringstream;

    int
main(int argc, char** argv)
{
    for (++argv; *argv; ++argv)
    {
        int w, h;
        char ch;
        string puzzle;

        istringstream is(*argv);
        is >> w >> ch >> h >> ch >> puzzle;

        printf("(%d, %d): %s\n", w, h, puzzle.c_str());
        string answer = solve_puzzle(w, h, puzzle);
        printf("-> %s\n", answer.c_str());
    }

    return 0;
}
