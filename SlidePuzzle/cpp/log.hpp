#ifndef LOG_HPP__
#define LOG_HPP__

void log_open(const char* path);
void log_close(void);
void log_append(const char* fmt, ...);

#endif//LOG_HPP__
