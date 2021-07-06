#include <string.h>
#include <stdlib.h>
#include <editline/readline.h>
#include <stdbool.h>
#include <stdio.h>

char *READ(char *s);
char *EVAL(char *s);
char *PRINT(char *s);
char *rep(char *s);


int main(void)
{
    char *line = NULL;
    char *res = NULL;

    while (1) {
        line = readline("user> ");


        if (NULL == line) {
            //printf("Exiting...\n");
            break;
        } else {
            add_history(line);
            res = rep(line);
            printf("%s\n", res);
        }

        free(line);
    }
    return 0;
}


char *READ(char *s)
{
    return s;
}

char *EVAL(char *s)
{
    return s;
}

char *PRINT(char *s)
{
    return s;
}

char *rep(char *s)
{
    char *ret = READ(s);
    ret = EVAL(ret);
    ret = PRINT(ret);
    return ret;
}
