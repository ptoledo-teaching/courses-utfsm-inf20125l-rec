#include <stdio.h>

int debug_enabled = 1;

void trace_demo(const char *event, int depth, int value,
                int result, int condition)
{
    if (!debug_enabled || !condition)
    {
        return;
    }

    fprintf(stderr,
            "DEBUG: %*s%s profundidad=%d valor=%d resultado=%d\n",
            depth * 2, "", event, depth, value, result);
}

static int sum_to(int value, int depth)
{
    trace_demo("ENTRAR", depth, value, 0, 1);

    if (value == 0)
    {
        trace_demo("CASO_BASE", depth, value, 0, 1);
        return 0;
    }

    int partial_result = sum_to(value - 1, depth + 1);
    int result = value + partial_result;

    trace_demo("RETORNAR", depth, value, result, 1);
    return result;
}

int main(void)
{
    int value = 4;
    int result = sum_to(value, 0);

    printf("Suma de 1 a %d: %d\n", value, result);
    return 0;
}
