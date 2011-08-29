#include <cstdio>
#include <fstream>
#include <iostream>
#include <string>

#include "solver.hpp"
#include "log.hpp"

using std::string;
using std::istringstream;
using std::ifstream;

    int
main(int argc, char** argv)
{
    log_open("output.log");
    std::ifstream ifs("problems.txt");

    // Drop first 2 lines.
    {
        string black_hole;
        std::getline(ifs, black_hole);
        std::getline(ifs, black_hole);
    }

    int lnum = 0;
    FILE *fp = ::fopen("answers.txt", "wt");
    while (!ifs.eof())
    {
        ++lnum;

        int w, h;
        char ch;
        string puzzle;
        ifs >> w >> ch >> h >> ch >> puzzle;

        log_append("#%d (%d, %d): %s\n", lnum, w, h, puzzle.c_str());
        int rank = w * h;
        string answer;
        if (rank <= 12)
        {
            answer = solve_puzzle(w, h, puzzle);
            if (answer.empty())
                log_append("  => RETIRED\n");
            else
                log_append("  => ANSWER: %s\n", answer.c_str());
        }
        else
            log_append("  => SKIPED\n");
        fprintf(fp, "%s\n", answer.c_str());
        fflush(fp);
    }
    fclose(fp);

    log_close();

    return 0;
}
