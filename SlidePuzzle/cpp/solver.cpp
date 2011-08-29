#include <algorithm>
#include <cstdio>
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
get_movable(vector<char>& movable, int w, int h, const string& s, int pos)
{
    int x = pos % w;
    if (x > 0 && s[pos - 1] != '=')
        movable.push_back('L');
    if (x < (w - 1) && s[pos + 1] != '=')
        movable.push_back('R');

    int y = pos / w;
    if (y > 0 && s[pos - w] != '=')
        movable.push_back('U');
    if (y < (h - 1) && s[pos + w] != '=')
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

    string
solve_puzzle2(int w, int h, const string& s)
{
    deque<qitem> queue;
    queue.push_back(qitem(s, string("")));
    set<string> hash;
    hash.insert(s);
    string final = get_final_state(s);

    int count = 0;
    while (!queue.empty())
    {
        ++count;

        const qitem& curr = queue.front();
        int pos = get_pos(curr.first);

        vector<char> movable;
        get_movable(movable, w, h, curr.first, pos);
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
            if (hash.count(next) == 0)
            {
                hash.insert(next);
                queue.push_back(qitem(next, new_hist));
            }
        }

        queue.pop_front();

        if ((count % 500000) == 0) {
            printf("  ITERATION %d\n", count);
        }
        if (count >= 1500000) {
            log_append("  OVER ITERATION\n");
            break;
        }
    }

    return string();
}

    string
solve_puzzle(int w, int h, const string& s)
{
    return solve_puzzle2(w, h, s);
}
