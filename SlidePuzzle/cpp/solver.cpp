#include <algorithm>
#include <cmath>
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
solve_puzzle1(const clock_t& start, int w, int h, const string& s)
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
                string answer2 = solve_puzzle1(start, w, h - 1, puzzle2);
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
                string answer3 = solve_puzzle1(start, new_w, h, puzzle3);
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

////////////////////////////////////////////////////////////////////////////
//

string NOTFOUND("NOTFOUND");

class pos_t
{
public:
    int col;
    int row;

    pos_t() : col(0), row(0) {}
    pos_t(const pos_t& s) : col(s.col), row(s.row) {}
    pos_t(int c, int r) : col(c), row(r) {}
    pos_t(int w, const string& s, char ch) {
        int n = s.find_first_of(ch);
        col = n % w;
        row = n / w;
    }
};

class step_t
{
public:
    char last_move;
    vector<char> movable;
    string board;
    int pos;
    int distance;

    step_t() : last_move('\0'), pos(-1), distance(0) {}
    step_t(const string& b) : last_move('\0'), distance(0) {
        set_board(b);
    }
    void reset(void) {
        last_move = '\0';
        movable.clear();
        board.clear();
        pos = -1;
        distance = 0;
    }
    void set_board(const string& b) {
        board = b;
        pos = get_pos(board);
    }
};

    int
operator - (const pos_t& a, const pos_t& b)
{
    int dr = a.row - b.row;
    if (dr < 0)
        dr = -dr;
    int dc = a.col - b.col;
    if (dc < 0)
        dc = -dc;
    return dr + dc;
}

    int
get_distance(int w, int h, const string& s, const string& final)
{
    pos_t p0(w, s, '0');
    pos_t p1(w, final, '0');
    return p1 - p0;
}

    int
get_md_val(int w, char ch, int i)
{
    int j = (ch >= 'A') ? (ch - 'A' + 9) : (ch - '1');
    return ::abs((i % w) - (j % w)) + ::abs((i / w) - (j / w));
}

    int
get_md_sum(int w, const string& s, const string& final)
{
    int md_sum = 0;
    for (int i = 0, N = s.length(); i < N; ++i)
    {
        char ch = s[i];
        if (ch == '=' || ch == '0')
            continue;
        md_sum += get_md_val(w, ch, i);
    }
    return md_sum;
}

    string
depth_first(clock_t start, int depth, int w, int h,
        const string& first, const string& final)
{
    if (first == final)
    {
        log_append("  -> No moves\n");
        return string();
    }

    vector<step_t> steps(depth);
    step_t first_step(first);
    first_step.distance = get_md_sum(w, first, final);

    int count = 0;
    int count2 = 0;
    int i = 0;
    while (true)
    {
        // Get previous step infos.
        const step_t& prev = (i > 0) ? steps[i - 1] : first_step;

        // Determine current action.
        step_t& curr = steps[i];
        bool backtrack = false;
        if (curr.movable.empty())
        {
            if (curr.last_move == '\0')
            {
                get_movable(curr.movable, w, h, prev.board, prev.pos,
                        prev.last_move);
                backtrack = curr.movable.empty();
            }
            else
            {
                backtrack = true;
            }
        }

        // Make backtrack if needs.
        if (backtrack)
        {
            // back track.
            curr.reset();
            if (--i >= 0)
            {
                continue;
            }
            else
            {
                printf("    --> Try count: %d/%d\n", count, count2);
                //log_append("  -> Not found!\n");
                return NOTFOUND;
            }
        }

        curr.last_move = curr.movable.back();
        curr.movable.pop_back();
        curr.set_board(apply_move(prev.board, prev.pos, w, curr.last_move));

        // Update distance.
        char ch = curr.board[prev.pos];
        curr.distance = prev.distance - get_md_val(w, ch, curr.pos)
            + get_md_val(w, ch, prev.pos);

        if (i + 1 >= depth)
        {
            // Check does curr.board equal with final.
            ++count;
            if (curr.distance == 0)
                break;
        }
        else
        {
            // Check lower boundary for curr.board.
            ++count2;
            if (i + curr.distance <= depth)
                ++i;
        }
    }

    log_append("  -> Found in depth %d at count %d\n", depth, count);
    string answer;
    for (vector<step_t>::const_iterator i = steps.begin();
            i != steps.end(); ++i)
        answer += i->last_move;
    return answer;
}

    string
solve_puzzle2(const clock_t& start, int w, int h, const string& s)
{
    string final = get_final_state(s);
    int init_depth = get_distance(w, h, s, final);
    int init_md = get_md_sum(w, s, final);
    if ((init_md % 2) != (init_depth % 2))
        init_depth = init_md + 1;
    else
        init_depth = init_md;
    for (int depth = init_depth; ; depth += 2)
    {
        printf("  -> Depth #%d\n", depth);
        string answer = depth_first(start, depth, w, h, s, final);
        if (answer != NOTFOUND)
            return answer;
    }
}

////////////////////////////////////////////////////////////////////////////
//

    string
solve_puzzle(int w, int h, const string& s, int version)
{
    clock_t start = ::clock();
    string answer;
    switch (version)
    {
        case 1:
            answer = solve_puzzle1(start, w, h, s);
            break;
        case 2:
        default:
            answer = solve_puzzle2(start, w, h, s);
    }
    clock_t end = ::clock();
    float sec = (float)(end - start) / CLOCKS_PER_SEC;
    log_append("  -> in %f sec\n", sec);
    return answer;
}
