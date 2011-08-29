#include <cstdio>
#include <cstdarg>

static FILE* logfp = NULL;
static char logbuf[1024];

    void
log_open(const char* path)
{
    if (logfp == NULL)
    {
        logfp = ::fopen(path, "wt");
    }
}

    void
log_close(void)
{
    if (logfp != NULL)
    {
        fclose(logfp);
        logfp = NULL;
    }
}

    void
log_append(const char* fmt, ...)
{
    va_list args;
    va_start(args, fmt);
    ::vsnprintf(logbuf, sizeof(logbuf), fmt, args);
    va_end(args);

    printf("%s", logbuf);
    if (logfp != NULL)
    {
        fprintf(logfp, "%s", logbuf);
        fflush(logfp);
    }
}
