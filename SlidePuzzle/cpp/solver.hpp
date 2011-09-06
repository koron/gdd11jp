#ifndef SOLVER_HPP__
#define SOLVER_HPP__

void solver_set_depth_limit(
        int value);

std::string solve_puzzle(
        int w,
        int h,
        const std::string& s,
        int version,
        int timeout_seconds);

#endif//SOLVER_HPP__
