#include <stdio.h>

#ifndef ENV_NAME
#  define ENV_NAME "host"
#endif

int main(int argc, char** argv)
{
    printf("Hello World from Rebuild environment " ENV_NAME "\n");
    return 0;
}
