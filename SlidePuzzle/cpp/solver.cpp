#include <algorithm>
#include <cstdio>
#include <ctime>
#include <deque>
#include <set>
#include <string>
#include <vector>

#include "log.hpp"

using std::deque;
using std::pair;
using std::set;
using std::string;
using std::vector;

typedef pair<string, string> qitem;

static bool enable_shrink = true;
static int iteration_limit = 1500000;

    string
get_final_state(const string& s)
{
    string s2;
    for (string::const_iterator i = s.begin(); i != s.end(); ++i)
        if (*i != '=' && *i != '0')
            s2 += *i;
    std::sort(s2.begin(), s2.end());
    s2 += '0';

    string s3;
    string::const_iterator r = s2.begin();
    for (string::const_iterator i = s.begin(); i != s.end(); ++i)
    {
        if (*i != '=')
            s3 += *r++;
        else
            s3 += '=';
    }

    return s3;
}

    int
get_pos(const string& s)
{
    return s.find_first_of('0');
}

    void
get_movable(
        vector<char>& movable,
        int w,
        int h,
        const string& s,
        int pos,
        char last_move)
{
    int x = pos % w;
    if (x > 0 && last_move != 'R' && s[pos - 1] != '=')
        movable.push_back('L');
    if (x < (w - 1) && last_move != 'L' && s[pos + 1] != '=')
        movable.push_back('R');

    int y = pos / w;
    if (y > 0 && last_move != 'D' && s[pos - w] != '=')
        movable.push_back('U');
    if (y < (h - 1) && last_move != 'U' && s[pos + w] != '=')
        movable.push_back('D');
}

    string
apply_move(const string& s, int pos, int w, char dir)
{
    int diff = 0;
    switch (dir)
    {
        case 'L': diff = -1; break;
        case 'R': diff = 1; break;
        case 'U': diff = -w; break;
        case 'D': diff = w; break;
    }

    string new_s = s;
    if (diff != 0)
    {
        int new_pos = pos + diff;
        new_s[pos] = s[new_pos];
        new_s[new_pos] = '0';
    }

    return new_s;
}

    bool
match_head_row(const string& a, const string& b, int w)
{
    for (int i = 0; i < w; ++i)
        if (a[i] != b[i])
            return false;
    return true;
}

    bool
match_head_col(const string& a, const string& b, int w, int h)
{
    for (int i = 0, N = w * h; i < N; i += w)
        if (a[i] != b[i])
            return false;
    return true;
}

    string
solve_puzzle2(const clock_t& start, int w, int h, const string& s)
{
    deque<qitem> queue;
    queue.push_back(qitem(s, string("")));
    set<string> hash;
    hash.insert(s);
    string final = get_final_state(s);

    // Setup option switches.
    bool shrinkable_height = false;
    if (enable_shrink && h > 2
            && s[w + 1] != '=' && s[w * 2 - 2] != '=')
    {
        shrinkable_height = true;
    }
    bool shrinkable_width = false;
    if (enable_shrink && w > 2
            && s[w + 1] != '=' && s[w * (h - 2) + 1] != '=')
    {
        shrinkable_width = true;
    }

    int count = 0;
    while (!queue.empty())
    {
        ++count;

        const qitem& curr = queue.front();
        int pos = get_pos(curr.first);

        vector<char> movable;
        char last_move = (curr.second.length() > 0)
            ? *curr.second.rbegin() : ' ';
        get_movable(movable, w, h, curr.first, pos, last_move);
        for (vector<char>::const_iterator i = movable.begin();
                i != movable.end(); ++i)
        {
            string next = apply_move(curr.first, pos, w, *i);
            string new_hist = curr.second;
            new_hist += *i;

            if (next == final) {
                log_append("  -> Found at %d\n", count);
                return new_hist;
            }

            // Check height shrinkable.
            if (shrinkable_height && match_head_row(next, final, w))
            {
                string puzzle2 = string(next, w);
                string answer2 = solve_puzzle2(start, w, h - 1, puzzle2);
                if (!answer2.empty())
                {
                    new_hist += answer2;
                    log_append("  -> Found at %d (height shrinked)\n", count);
                    return new_hist;
                }
            }

            // Check width shrinkable.
            if (shrinkable_width && match_head_col(next, final, w, h))
            {
                int new_w = w - 1;
                string puzzle3;
                for (int i = 1, N = w * h; i < N; i += w)
                    puzzle3 += string(next, i, new_w);
                string answer3 = solve_puzzle2(start, new_w, h, puzzle3);
                if (!answer3.empty())
                {
                    new_hist += answer3;
                    log_append("  -> Found at %d (width shrinked)\n", count);
                    return new_hist;
                }
            }

            if (hash.count(next) == 0)
            {
                hash.insert(next);
                queue.push_back(qitem(next, new_hist));
            }
        }

        queue.pop_front();

        if ((count % 500000) == 0)
            printf("  ITERATION %d\n", count);

        if (count >= iteration_limit)
        {
            log_append("  OVER ITERATION\n");
            break;
        }

        clock_t now = clock();
        int sec = (now - start) / CLOCKS_PER_SEC;
        if (sec >= 60)
        {
            log_append("  OVER TIME\n");
            break;
        }
    }

    return string();
}

    string
solve_puzzle(int w, int h, const string& s)
{
    clock_t start = ::clock();
    string answer = solve_puzzle2(start, w, h, s);
    clock_t end = ::clock();
    float sec = (float)(end - start) / CLOCKS_PER_SEC;
    log_append("  -> in %f sec\n", sec);
    return answer;
}
