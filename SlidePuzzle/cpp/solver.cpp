#include <algorithm>
#include <cassert>
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
typedef int cell_t;

static const cell_t FREE_CELL = (cell_t)0x80;
static const cell_t WALL_CELL = (cell_t)0xFF;

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
    return (int)s.find_first_of('0');
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
string TIMEOUT("");

class pos_t
{
public:
    int col;
    int row;

    pos_t() : col(0), row(0) {}
    pos_t(const pos_t& s) : col(s.col), row(s.row) {}
    pos_t(int c, int r) : col(c), row(r) {}
    pos_t(int w, const string& s, char ch) {
        int n = (int)s.find_first_of(ch);
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

class step2_t
{
public:
    enum direction {
        UP = -8,
        LEFT = -1,
        NONE = 0,
        RIGHT = 1,
        DOWN = 8
    };

    direction moved;
    direction movable[6];
    int move_index;
    int pos;
    int distance;

    step2_t() : moved(NONE), move_index(0), pos(0), distance(-1) {
        movable[0] = NONE;
        movable[1] = NONE;
        movable[2] = NONE;
        movable[3] = NONE;
        movable[4] = NONE;
        movable[5] = NONE;
    }

    void reset(void) {
        moved = NONE;
        movable[0] = NONE;
        movable[1] = NONE;
        movable[2] = NONE;
        movable[3] = NONE;
        movable[4] = NONE;
        movable[5] = NONE;
        move_index = 0;
        pos = 0;
        distance = -1;
    }

    bool is_empty(void) {
        return  movable[move_index] == NONE;
    }

    bool has_movable(void) {
        return move_index > 0;
    }

    bool is_moved(void) {
        return moved != NONE;
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
get_distance(int w, const string& s, const string& final)
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
get_md_sum(int w, const string& s)
{
    int md_sum = 0;
    for (int i = 0, N = (int)s.length(); i < N; ++i)
    {
        char ch = s[i];
        if (ch == '=' || ch == '0')
            continue;
        md_sum += get_md_val(w, ch, i);
    }
    return md_sum;
}

    string
depth_first1(clock_t start, int depth, int w, int h,
        const string& first, const string& final)
{
    if (first == final)
    {
        log_append("  -> No moves\n");
        return string();
    }

    vector<step_t> steps(depth);
    step_t first_step(first);
    first_step.distance = get_md_sum(w, first);

    int count = 0;
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
                printf("  --- Not found: %d\n", count);
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
            if (curr.distance == 0)
                break;
        }
        else
        {
            // Check lower boundary for curr.board.
            ++count;
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

    bool
get_movable2(step2_t& curr, const step2_t& prev, const cell_t* board)
{
    const step2_t::direction moved = prev.moved;
    const int pos = prev.pos;
    int index = 0;
#if 1
    if (moved != step2_t::DOWN && board[pos + step2_t::UP] != WALL_CELL)
        curr.movable[++index] = step2_t::UP;
    if (moved != step2_t::RIGHT && board[pos + step2_t::LEFT] != WALL_CELL)
        curr.movable[++index] = step2_t::LEFT;
    if (moved != step2_t::LEFT && board[pos + step2_t::RIGHT] != WALL_CELL)
        curr.movable[++index] = step2_t::RIGHT;
    if (moved != step2_t::UP && board[pos + step2_t::DOWN] != WALL_CELL)
        curr.movable[++index] = step2_t::DOWN;
#else
    if (moved != step2_t::UP && board[pos + step2_t::DOWN] != WALL_CELL)
        curr.movable[++index] = step2_t::DOWN;
    if (moved != step2_t::LEFT && board[pos + step2_t::RIGHT] != WALL_CELL)
        curr.movable[++index] = step2_t::RIGHT;
    if (moved != step2_t::RIGHT && board[pos + step2_t::LEFT] != WALL_CELL)
        curr.movable[++index] = step2_t::LEFT;
    if (moved != step2_t::DOWN && board[pos + step2_t::UP] != WALL_CELL)
        curr.movable[++index] = step2_t::UP;
#endif
    curr.move_index = 1;
    return index == 0;
}

    int
get_md_val3(int s, int e)
{
    return ::abs((e & 0x7) - (s & 0x7)) + ::abs((e >> 3) - (s >> 3));
}

    string
compose_answer(const vector<step2_t>& steps)
{
    string answer;
    int cU = 0, cD = 0, cR = 0, cL = 0;
    for (vector<step2_t>::const_iterator i = steps.begin();
            i != steps.end(); ++i)
    {
        switch (i->moved)
        {
            case step2_t::UP:
                answer += 'U';
                ++cU;
                break;
            case step2_t::DOWN:
                answer += 'D';
                ++cD;
                break;
            case step2_t::RIGHT:
                answer += 'R';
                ++cR;
                break;
            case step2_t::LEFT:
                answer += 'L';
                ++cL;
                break;
        }
    }
    printf("  -- L:%d R:%d U:%d D:%d\n", cL, cR, cU, cD);
    return answer;
}

    void
dump_board(const cell_t* board)
{
    printf("  -- FINAL BOARD:");
    for (int i = 0; i < 64; ++i) {
        if ((i % 8) == 0)
            printf("\n  --- ");
        char ch = '=';
        cell_t cell = board[i];
        if (cell >= 0 && cell < 9)
            ch = (char)('1' + cell);
        else if (cell >= 9 && cell < 36)
            ch = (char)('A' + cell - 9);
        else if (cell == FREE_CELL)
            ch = '0';
        printf("%c", ch);
    }
    printf("\n");
}

    string
depth_first2(clock_t start, int depth_limit, int w, int h,
        const string& first, const string& final)
{
    if (first == final)
    {
        log_append("  -> No moves\n");
        return string();
    }

    // Setup expected positions.
    int cell2pos[36];
    for (int i = 0; i < 36; ++i)
        cell2pos[i] = (i / w) * 8 + (i % w) + 9;

    // Setup working board.
    int first_pos = 0;
    cell_t board[64];
    for (int i = 0; i < 64; ++i)
        board[i] = WALL_CELL;
    for (int i = 0; i < h; ++i)
    {
        for (int j = 0; j < w; ++j)
        {
            // Determine positions.
            int newpos = i * 8 + j + 9;
            int oldpos = i * w + j;
            // Determine a cell value.
            char ch = first[oldpos];
            cell_t cell = WALL_CELL;
            if (ch == '0')
            {
                cell = FREE_CELL;
                first_pos = newpos;
            }
            else if (ch >= '1' && ch <= '9')
                cell = ch - '1';
            else if (ch >= 'A' && ch <= 'Z')
                cell = ch - 'A' + 9;
            // Setup a cell of the board.
            board[newpos] = cell;
        }
    }

    // Init steps.
    vector<step2_t> steps(depth_limit + 1);
    steps[0].pos = first_pos;
    steps[0].distance = get_md_sum(w, first);

    int count = 0;
    int depth = 1;
    while (true)
    {
        const step2_t& prev = steps[depth - 1];
        step2_t& curr = steps[depth];

        // Determine current action.
        if (curr.is_empty())
        {
            bool backtrack = true;

            // Check backtrack required.
            if (!curr.has_movable())
            {
                // Setup movable values.
                backtrack = get_movable2(curr, prev, board);
            }

            // Make backtrack.
            if (backtrack)
            {
                if (curr.is_moved())
                {
                    // Revert board one step.
                    board[curr.pos] = board[prev.pos];
                    board[prev.pos] = FREE_CELL;
                }

                curr.reset();
                if (--depth <= 0)
                    break;
                else
                    continue;
            }
        }

        // Revert board for previous.
        if (curr.is_moved())
        {
            board[curr.pos] = board[prev.pos];
            board[prev.pos] = FREE_CELL;
        }
        curr.moved = curr.movable[curr.move_index++];
        curr.pos = prev.pos + curr.moved;
        cell_t cell = board[prev.pos] = board[curr.pos];
        board[curr.pos] = FREE_CELL;

        // Update distance.
        int expected_pos = cell2pos[cell];
        curr.distance = prev.distance
            - get_md_val3(expected_pos, curr.pos)
            + get_md_val3(expected_pos, prev.pos);

        if (depth < depth_limit)
        {
            // Check lower boundary for curr.board.
            if (depth + curr.distance <= depth_limit)
                ++depth;
        }
        else if (curr.distance == 0)
        {
            // Found the answer!
            log_append("  -> Found in depth %d at count %d\n", depth_limit,
                    count);
            dump_board(board);
            return compose_answer(steps);
        }
        ++count;

#if 0
        if ((count & 0x3FFFFFF) == 0)
        {
            int sec = (clock() - start) / CLOCKS_PER_SEC;
            if (sec > 120)
            {
                log_append("  -> Time over\n");
                return TIMEOUT;
            }
        }
#endif
    }

    printf("  --- Not found: %d\n", count);
    return NOTFOUND;
}


    string
solve_puzzle2(const clock_t& start, int w, int h, const string& s)
{
    string final = get_final_state(s);
    int init_depth = get_distance(w, s, final);
    int init_md = get_md_sum(w, s);
    if ((init_md % 2) != (init_depth % 2))
        init_depth = init_md + 1;
    else
        init_depth = init_md;
    for (int depth = init_depth; ; depth += 2)
    {
        printf("  -- Depth #%d\n", depth);
        string answer = depth_first2(start, depth, w, h, s, final);
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
