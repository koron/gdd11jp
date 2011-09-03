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

static int rank_limit = 36;

class puzzle_t
{
public:
    int w;
    int h;
    string data;

    explicit puzzle_t(const string& str) {
        char ch;
        istringstream is(str);
        is >> w >> ch >> h >> ch >> data;
    }

    int rank() { return w * h; }

    string solve(int version, int timeout_seconds) {
        return solve_puzzle(w, h, data, version, timeout_seconds);
    }

};

    void
solve_all(int version, const string& file, int timeout_seconds)
{
    log_open("output.log");

    clock_t start = clock();

    // Drop first 2 lines.
    std::ifstream ifs(file.c_str());
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
        char buf[1024];
        ifs.getline(buf, sizeof(buf));
        string line(buf);
        ++lnum;

        string answer;
        if (!line.empty())
        {
            puzzle_t puzzle(line);

            ++total;
            log_append("#%d (%d, %d): %s\n", lnum, puzzle.w, puzzle.h,
                    puzzle.data.c_str());

            if (puzzle.rank() <= rank_limit)
            {
                answer = puzzle.solve(version, timeout_seconds);
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
        }
        else if (ifs.eof())
            break;

        fprintf(fp, "%s\n", answer.c_str());
        fflush(fp);
    }
    fclose(fp);

    clock_t end = clock();
    float rate = (total > 0) ? (float)solved * 100.0f / total : 0;
    log_append("Solved %d/%d (%.2f%%) in %f sec\n", solved, total,
            rate, (float)(end - start) / CLOCKS_PER_SEC);

    log_close();
}

    int
main(int argc, char** argv)
{
    int version = 0;
    int timeout_seconds = 0;
    for (int i = 1; i < argc; ++i)
    {
        string a = argv[i];
        bool no_next = i + 1 >= argc;
        if (a == string("-f"))
        {
            if (no_next)
            {
                printf("option '-f' requires an argument.\n");
                return 1;
            }
            i += 1;
            solve_all(version, argv[i], timeout_seconds);
        }
        else if (a == string("-t") || a == string("--timeout"))
        {
            if (no_next)
            {
                printf("option '%s' requires an argument.\n", a.c_str());
                return 1;
            }
            i += 1;
            timeout_seconds = ::atoi(argv[i]);
        }
        else if (a == string("-r") || a == string("--rank"))
        {
            if (no_next)
            {
                printf("option '%s' requires an argument.\n", a.c_str());
                return 1;
            }
            i += 1;
            rank_limit = ::atoi(argv[i]);
        }
        else if (a == string("-1"))
            version = 1;
        else if (a == string("-2"))
            version = 2;
        else if (a == string("-3"))
            version = 3;
        else
        {
            puzzle_t p(a);
            log_append("(%d, %d): %s\n", p.w, p.h, p.data.c_str());

            string answer = p.solve(version, timeout_seconds);
            if (answer.empty())
                log_append("  => RETIRED\n");
            else
                log_append("  => ANSWER: %s\n", answer.c_str());
        }
    }
    return 0;
}
