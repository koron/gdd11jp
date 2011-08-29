#include <cstdio>
#include <ctime>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>

#include "solver.hpp"
#include "log.hpp"

using std::string;
using std::istringstream;
using std::ifstream;

    void
solve_all(void)
{
    log_open("output.log");

    clock_t start = clock();

    // Drop first 2 lines.
    std::ifstream ifs("problems.txt");
    {
        string black_hole;
        std::getline(ifs, black_hole);
        std::getline(ifs, black_hole);
    }

    int lnum = 0;
    int total = 0;
    int solved = 0;
    FILE *fp = ::fopen("answers.txt", "wt");
    while (!ifs.eof())
    {
        int w, h;
        char ch;
        string puzzle;

        ifs >> w >> ch >> h >> ch >> puzzle;
        int rank = w * h;

        ++lnum;
        ++total;
        log_append("#%d (%d, %d): %s\n", lnum, w, h, puzzle.c_str());

        string answer;
        if (rank <= 12)
        {
            answer = solve_puzzle(w, h, puzzle);
            if (answer.empty())
                log_append("  => RETIRED\n");
            else
            {
                log_append("  => ANSWER: %s\n", answer.c_str());
                ++solved;
            }
        }
        else
            log_append("  => SKIPED\n");
        fprintf(fp, "%s\n", answer.c_str());
        fflush(fp);
    }
    fclose(fp);

    clock_t end = clock();
    log_append("Solved %d/%d (%.2f%%) in %f sec\n", solved, total,
            (float)solved * 100.0f / total,
            (float)(end - start) / CLOCKS_PER_SEC);

    log_close();
}

    int
main(int argc, char** argv)
{
    for (int i = 1; i < argc; ++i)
    {
        string a = argv[i];
        if (a == string("--all"))
            solve_all();
        else
        {

            int w, h;
            char ch;
            string puzzle;

            istringstream iss(a);
            iss >> w >> ch >> h >> ch >> puzzle;
            log_append("(%d, %d): %s\n", w, h, puzzle.c_str());

            string answer = solve_puzzle(w, h, puzzle);
            if (answer.empty())
                log_append("  => RETIRED\n");
            else
                log_append("  => ANSWER: %s\n", answer.c_str());
        }
    }
    return 0;
}
