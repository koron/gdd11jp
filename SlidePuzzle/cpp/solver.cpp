#include <algorithm>
#include <cassert>
#include <cmath>
#include <cstdio>
#include <ctime>
#include <deque>
#include <set>
#include <string>
#include <vector>

#if defined(_MSC_VER) && _MSC_VER < 1600
typedef __int64 int64_t;
#else
#include <stdint.h>
#endif

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
solve_puzzle1(
        const clock_t& start,
        int w,
        int h,
        const string& s,
        int timeout_seconds)
{
    deque<qitem> queue;
    queue.push_back(qitem(s, string(" ")));
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

        if (count > 5000000)
        {
            log_append("  -> Over iteration\n");
            break;
        }
        if ((count & 0x3FFFF) == 0)
        {
            printf(" -- count:%d queue:%d hash:%d\n",
                    count, queue.size(), hash.size());
        }
        if (timeout_seconds > 0)
        {
            clock_t now = clock();
            int sec = (now - start) / CLOCKS_PER_SEC;
            if (sec >= timeout_seconds)
            {
                log_append("  -> Time over\n");
                break;
            }
        }

        const qitem& curr = queue.front();
        int pos = get_pos(curr.first);

        vector<char> movable;
        char last_move = *curr.second.rbegin();
        get_movable(movable, w, h, curr.first, pos, last_move);
        for (vector<char>::const_iterator i = movable.begin();
                i != movable.end(); ++i)
        {
            string next = apply_move(curr.first, pos, w, *i);
            string new_hist = curr.second;
            new_hist += *i;

            if (next == final) {
                log_append("  -> Found at %d\n", count);
                return new_hist.substr(1);
            }

            // Check height shrinkable.
            if (shrinkable_height && match_head_row(next, final, w))
            {
                string puzzle2 = string(next, w);
                string answer2 = solve_puzzle1(start, w, h - 1, puzzle2,
                        timeout_seconds);
                if (!answer2.empty())
                {
                    new_hist += answer2;
                    log_append("  -> Found at %d (height shrinked)\n", count);
                    return new_hist.substr(1);
                }
            }

            // Check width shrinkable.
            if (shrinkable_width && match_head_col(next, final, w, h))
            {
                int new_w = w - 1;
                string puzzle3;
                for (int i = 1, N = w * h; i < N; i += w)
                    puzzle3 += string(next, i, new_w);
                string answer3 = solve_puzzle1(start, new_w, h, puzzle3,
                        timeout_seconds);
                if (!answer3.empty())
                {
                    new_hist += answer3;
                    log_append("  -> Found at %d (width shrinked)\n", count);
                    return new_hist.substr(1);
                }
            }

            if (hash.find(next) == hash.end())
            {
                hash.insert(next);
                queue.push_back(qitem(next, new_hist));
            }
        }

        queue.pop_front();
    }

    return string();
}

////////////////////////////////////////////////////////////////////////////
//

string NOTFOUND("NOTFOUND");
string TIMEOUT("TIMEOUT");

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
    //printf("  -- L:%d R:%d U:%d D:%d\n", cL, cR, cU, cD);
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

    int
depth_first2(
        string& answer,
        clock_t start,
        int depth_limit,
        int w,
        int h,
        const string& first,
        const string& final,
        int timeout_seconds)
{
    if (first == final)
    {
        log_append("  -> No moves\n");
        answer = string("");
        return 0;
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

    int min_dist = -1;
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
            answer = compose_answer(steps);
            return 0;
        }

        if (min_dist < 0 || curr.distance < min_dist)
            min_dist = curr.distance;
        ++count;

        if (timeout_seconds > 0 && (count & 0x3FFFFFF) == 0)
        {
            int sec = (clock() - start) / CLOCKS_PER_SEC;
            if (sec > timeout_seconds)
            {
                log_append("  -> Time over\n");
                answer = TIMEOUT;
                return min_dist;
            }
        }
    }

    printf("  --- Not found: %d (min=%d)\n", count, min_dist);
    answer = NOTFOUND;
    return min_dist;
}


    string
solve_puzzle2(
        const clock_t& start,
        int w,
        int h,
        const string& s,
        int timeout_seconds)
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
        string answer;
        int retval = depth_first2(answer, start, depth, w, h, s, final,
                timeout_seconds);
        if (retval == 0)
            return answer;
        else if (answer == TIMEOUT)
            return string();
    }
}

////////////////////////////////////////////////////////////////////////////
//

class postbl_t
{
public:
    int _new2old[64];
    int _old2new[36];

    postbl_t(int w, int h)
    {
        for (int i = 0; i < 64; ++i)
            _new2old[i] = -1;
        for (int i = 0; i < 36; ++i)
            _old2new[i] = -1;
        for (int i = 0; i < h; ++i)
        {
            for (int j = 0; j < w; ++j)
            {
                int newpos = i * 8 + j + 9;
                int oldpos = i * w + j;
                _new2old[newpos] = oldpos;
                _old2new[oldpos] = newpos;
            }
        }
    }

    int new2old(int i) { return _new2old[i]; }
    int old2new(int i) { return _old2new[i]; }

private:
    postbl_t();
    postbl_t(const postbl_t&);
};

class board_t
{
public:
    int width;
    int height;
    int pos; // Position of '0'.
    cell_t data[64];

    board_t(int w, int h, const string& s) : width(w), height(h), pos(0)
    {
        for (int i = 0; i < 64; ++i)
            data[i] = WALL_CELL;
        for (int i = 0; i < height; ++i)
        {
            for (int j = 0; j < width; ++j)
            {
                int newpos = i * 8 + j + 9;
                int oldpos = i * w + j;
                // Determine a cell value.
                char ch = s[oldpos];
                cell_t cell = WALL_CELL;
                if (ch == '0')
                {
                    cell = FREE_CELL;
                    pos = newpos;
                }
                else if (ch >= '1' && ch <= '9')
                    cell = ch - '1';
                else if (ch >= 'A' && ch <= 'Z')
                    cell = ch - 'A' + 9;
                // Setup a cell of the board.
                data[newpos] = cell;
            }
        }
    }

    cell_t get(int col, int row) const {
        return data[col + (row << 3) + 9];
    }

    cell_t get(int pos) const {
        return data[pos];
    }

    bool is_valid_cell(int pos) const {
        cell_t cell = get(pos);
        return cell != WALL_CELL;
    }

    void print(const string& title, const string& head) {
        printf("%s", title.c_str());
        for (int i = 0; i < 64; ++i) {
            if ((i % 8) == 0)
                printf("\n%s", head.c_str());
            char ch = '=';
            cell_t cell = data[i];
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

    cell_t move_freecell(int newpos) {
        cell_t c = data[pos] = data[newpos];
        data[newpos] = FREE_CELL;
        pos = newpos;
        return c;
    }

    void apply(const string& moves) {
        for (string::const_iterator i = moves.begin(); i != moves.end(); ++i)
        {
            int diff = 0;
            switch (*i) {
                case 'U': diff = -8; break;
                case 'L': diff = -1; break;
                case 'R': diff = 1; break;
                case 'D': diff = 8; break;
            }
            if (diff != 0)
                move_freecell(pos + diff);
        }
    }

    string raw_state() const
    {
        string raw;
        for (int i = 0; i < height; ++i)
        {
            for (int j = 0; j < width; ++j)
            {
                cell_t cell = data[i * 8 + j + 9];
                if (cell == WALL_CELL)
                    raw += '=';
                else if (cell == FREE_CELL)
                    raw += '0';
                if (cell >= 0 && cell < 9)
                    raw += (char)('1' + cell);
                else if (cell >= 9 && cell < 36)
                    raw += (char)('A' + cell - 9);
            }
        }
        return raw;
    }

private:
    board_t();
    //board_t(const board_t&);
};

class distbl_t
{
public:
    int width, height;
    postbl_t postbl;
    int units[36][36];

    distbl_t(const board_t& goal) :
        width(goal.width),
        height(goal.height),
        postbl(goal.width, goal.height)
    {
        ::memset(units, 0, sizeof(units));
        // Setup units table.
        for (int i = 0; i < 36; ++i)
        {
            int newpos = postbl.old2new(i);
            if (newpos < 0 || !goal.is_valid_cell(newpos))
                continue;
            cell_t c = goal.get(i % goal.width, i / goal.width);
            if (c == FREE_CELL)
                continue;

            set<int> seen;
            seen.insert(newpos);
            vector<int> seed;
            seed.push_back(newpos);
            int distance = 1;
            while (true)
            {
                vector<int> detected;
                if (detect_neighbor(detected, seed, seen, goal) <= 0)
                    break;
                for (vector<int>::const_iterator j = detected.begin();
                        j != detected.end(); ++j)
                {
                    seen.insert(*j);
                    units[c][postbl.new2old(*j)] = distance;
                }
                seed = detected;
                ++distance;
            }
        }
    }

    int detect_neighbor(
            vector<int>& detected,
            const vector<int>& seed,
            const set<int>& seen,
            const board_t& board)
    {
        for (vector<int>::const_iterator i = seed.begin();
                i != seed.end(); ++i)
        {
            int pos = *i;
            detect_neighbor_item(pos - 8, detected, seen, board);
            detect_neighbor_item(pos - 1, detected, seen, board);
            detect_neighbor_item(pos + 1, detected, seen, board);
            detect_neighbor_item(pos + 8, detected, seen, board);
        }

        return (int)detected.size();
    }

    void detect_neighbor_item(
            int pos, 
            vector<int>& detected,
            const set<int>& seen,
            const board_t& board)
    {
        if (pos >= 0 && pos < 64 && board.is_valid_cell(pos)
                && seen.find(pos) == seen.end())
            detected.push_back(pos);
    }

    int get_distance(const board_t& curr) {
        int sum = 0;
        int pos = 0;
        for (int i = 0; i < curr.height; ++i)
        {
            for (int j = 0; j < curr.width; ++j)
            {
                cell_t c = curr.get(j, i);
                if (c != WALL_CELL && c != FREE_CELL)
                    sum += units[c][pos];
                ++pos;
            }
        }
        return sum;
    }

    int get_unit(int a, int b) {
        return units[a][postbl.new2old(b)];
    }

    void print(const string& title, const string& head) {
        printf("%s\n", title.c_str());
        int all = width * height;
        for (int i = 0; i < all; i += width) {
            vector<string> buf(height);
            if (i != 0) {
                printf("\n");
            }
            for (int j = 0; j < height; ++j) {
                buf[j] += head;
            }

            for (int j = 0; j < width; ++j) {
                int* p = units[i + j];
                for (int k = 0; k < all; k += width) {
                    int row = k / width;
                    if (j != 0) {
                        buf[row] += ' ';
                    }
                    for (int l = 0; l < width; ++l) {
                        char ch = 'X';
                        int u = p[k + l];
                        if (u >= 0) {
                            if (u < 10) {
                                ch = (char)(u + '0');
                            } else if (u < 36) {
                                ch = (char)(u - 10 + 'A');
                            }
                        }
                        buf[row] += ch;
                    }
                }
            }
            for (int j = 0; j < height; ++j) {
                printf("%s\n", buf[j].c_str());
            }
        }
    }

private:
    distbl_t();
    distbl_t(const distbl_t&);
};

    int
depth_first3(
        string& answer,
        clock_t start,
        int depth_limit,
        board_t& board,
        distbl_t& distbl,
        int timeout_seconds,
        string* min_answer = NULL)
{
    // Init steps.
    vector<step2_t> steps(depth_limit + 1);
    steps[0].pos = board.pos;
    steps[0].distance = distbl.get_distance(board);
    if (steps[0].distance == 0)
    {
        log_append("  -> No moves\n");
        answer = string("");
        return 0;
    }

    clock_t start_depth = clock();
    int min_dist = INT_MAX;
    int min_depth = 0;
    int64_t count = 0;
    int depth = 1;
    while (true)
    {
        // Check timeout first.
        if (timeout_seconds > 0 && (count & 0x3FFFFFFLL) == 0)
        {
            int sec = (clock() - start) / CLOCKS_PER_SEC;
            if (sec > timeout_seconds)
            {
                log_append("  -> Time over\n");
                answer = TIMEOUT;
                return min_dist;
            }
        }

        // Determine step info.
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
                backtrack = get_movable2(curr, prev, board.data);
            }

            // Make backtrack.
            if (backtrack)
            {
                if (curr.is_moved())
                {
                    // Revert board one step.
                    board.move_freecell(prev.pos);
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
            board.move_freecell(prev.pos);
        curr.moved = curr.movable[curr.move_index++];
        curr.pos = prev.pos + curr.moved;
        cell_t cell = board.move_freecell(curr.pos);
        ++count;

        // Update distance.
        int distance = curr.distance = (prev.distance
                - distbl.get_unit(cell, curr.pos)
                + distbl.get_unit(cell, prev.pos));

        if (distance == 0)
        {
            // Found the answer!
            float sec = (float)(clock() - start_depth) / CLOCKS_PER_SEC;
            printf("  --- Found at count %lld in %f sec\n", count, sec);
            log_append("  -> Found in depth %d at count %lld\n", depth,
                    count);
            answer = compose_answer(steps);
#if 0
            board.print(string("  -- FINAL BOARD:"), string("  --- "));
            printf("  -- MOVE: %s\n", answer.c_str());
            printf("  -- DISTANCE: %d\n", distbl.get_distance(board));
#endif
            return 0;
        }

        if (distance <= min_dist)
        {
            if (distance < min_dist || depth < min_depth)
            {
                min_dist = distance;
                min_depth = depth;
                if (min_answer)
                    *min_answer = compose_answer(steps);
            }
        }

        // Prepare for next step.
        if (depth < depth_limit)
        {
            // Check lower boundary for curr.board.
            if (depth + distance <= depth_limit)
                ++depth;
        }
    }

    float sec = (float)(clock() - start_depth) / CLOCKS_PER_SEC;
    printf("  --- Not found: %lld (min=%d, sec=%f)\n", count, min_dist, sec);
    if (min_answer)
    {
        printf("  ---- %s\n", min_answer->c_str());
    }
    answer = NOTFOUND;
    return min_dist;
}

    string
solve_puzzle3(
        const clock_t& start,
        int w,
        int h,
        const string& s,
        int timeout_seconds)
{
    string final = get_final_state(s);
    board_t board(w, h, s);
    board_t goal(w, h, final);
    distbl_t distbl(goal);

    int init_depth = distbl.get_distance(board);

    // fix init_depth even/odd.
    int zero_dist = get_distance(w, s, final);
    if ((init_depth % 2) != (zero_dist % 2))
        init_depth += 1;

    for (int depth = init_depth; ; depth += 2)
    {
        printf("  -- Depth #%d\n", depth);
        string answer;
        board_t work(w, h, s);
        int retval = depth_first3(answer, start, depth, work, distbl,
                timeout_seconds);
        if (retval == 0)
            return answer;
        else if (answer == TIMEOUT)
            return string();
    }
}

////////////////////////////////////////////////////////////////////////////
//

    int
get_init_depth(
        distbl_t& distbl,
        const board_t& board,
        const string& final)
{
    int init_depth = distbl.get_distance(board);

    // fix init_depth even/odd.
    int zero_dist = get_distance(board.width, board.raw_state(), final);
    if ((init_depth % 2) != (zero_dist % 2))
        init_depth += 1;

    return init_depth;
}

    string
solve_puzzle4(
        const clock_t& start,
        int w,
        int h,
        const string& s,
        int timeout_seconds)
{
    string final = get_final_state(s);
    board_t board(w, h, s);
    board_t goal(w, h, final);
    distbl_t distbl(goal);
    //distbl.print(string("  -- DISTANCE TABLE:"), string("  --- "));

    int init_depth = get_init_depth(distbl, board, final);
    string prefix;
    int last_retval = 0;
    float depth_timeout = 0.5f;

    for (int depth = init_depth; ; depth += 2)
    {
        printf("  -- Depth #%d\n", depth);
        string answer;
        string min_answer;
        board_t work(board);
        clock_t start2 = ::clock();
        int retval = depth_first3(answer, start, depth, work, distbl,
                timeout_seconds, &min_answer);
        if (retval == 0)
            return prefix + answer;
        else if (answer == TIMEOUT)
            return string();

        float sec = (float)(clock() - start2) / CLOCKS_PER_SEC;
        if (sec >= depth_timeout)
        {
            if (last_retval == retval)
            {
                depth_timeout *= 4.0f;
                depth += retval - 2;
                printf("  -- Extend depth's timeout: %f\n",depth_timeout);
            }
            else
            {
                last_retval = retval;
                prefix += min_answer;
                board.apply(min_answer);
                board.print(string("  -- FORCE FORWARD:"), string("  --- "));
                depth = get_init_depth(distbl, board, final) - 2;
            }
        }
    }
}

////////////////////////////////////////////////////////////////////////////
//

    string
reverse_answer(const string& answer)
{
    string reversed;
    for (string::const_reverse_iterator i = answer.rbegin();
            i != answer.rend(); ++i)
    {
        switch (*i)
        {
            case 'L': reversed += 'R'; break;
            case 'R': reversed += 'L'; break;
            case 'U': reversed += 'D'; break;
            case 'D': reversed += 'U'; break;
        }
    }
    return reversed;
}

    string
solve_puzzle5(
        const clock_t& start,
        int w,
        int h,
        const string& s,
        int timeout_seconds)
{
    string final = get_final_state(s);
    board_t board(w, h, s);
    board_t goal(w, h, final);
    distbl_t distbl(board);

    int init_depth = distbl.get_distance(goal);

    // fix init_depth even/odd.
    int zero_dist = get_distance(w, s, final);
    if ((init_depth % 2) != (zero_dist % 2))
        init_depth += 1;

    for (int depth = init_depth; ; depth += 2)
    {
        printf("  -- Depth #%d\n", depth);
        string answer;
        board_t work(goal);
        int retval = depth_first3(answer, start, depth, work, distbl,
                timeout_seconds);
        if (retval == 0)
            return reverse_answer(answer);
        else if (answer == TIMEOUT)
            return string();
    }
}

////////////////////////////////////////////////////////////////////////////
//

static int opt_depth_limit = 0;

    void
solver_set_depth_limit(int value)
{
    opt_depth_limit = value;
}

    string
solve_puzzle6(
        const clock_t& start,
        int w,
        int h,
        const string& s,
        int timeout_seconds)
{
    string final = get_final_state(s);
    board_t board(w, h, s);
    board_t goal(w, h, final);
    distbl_t distbl(goal);

    int depth = opt_depth_limit;
    if (depth <= 0)
        depth = 100;

    printf("  -- Depth #%d\n", depth);
    string answer;
    int retval = depth_first3(answer, start, depth, board, distbl,
            timeout_seconds);
    if (retval == 0)
        return answer;

    return string();
}

////////////////////////////////////////////////////////////////////////////
//

    string
solve_puzzle(
        int w,
        int h,
        const string& s,
        int version,
        int timeout_seconds)
{
    clock_t start = ::clock();
    string answer;
    switch (version)
    {
        case 1:
            answer = solve_puzzle1(start, w, h, s, timeout_seconds);
            break;
        case 2:
            answer = solve_puzzle2(start, w, h, s, timeout_seconds);
            break;
        case 3:
        default:
            answer = solve_puzzle3(start, w, h, s, timeout_seconds);
            break;
        case 4:
            answer = solve_puzzle4(start, w, h, s, timeout_seconds);
            break;
        case 5:
            answer = solve_puzzle5(start, w, h, s, timeout_seconds);
            break;
        case 6:
            answer = solve_puzzle6(start, w, h, s, timeout_seconds);
            break;
    }
    clock_t end = ::clock();
    float sec = (float)(end - start) / CLOCKS_PER_SEC;
    log_append("  -> in %f sec\n", sec);
    return answer;
}
