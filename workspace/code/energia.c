#include <stdio.h>

#define MAXIMUM_MODULES 20

typedef struct
{
    int module_count;
    int required_energy;
    int capacity[MAXIMUM_MODULES];
} EnergyProblem;

typedef struct
{
    const EnergyProblem *problem;
    int selected[MAXIMUM_MODULES];
} SearchState;

int debug_enabled = 0;

void trace_event(const char *event, int depth, int index,
                 int sum, int selected_count, int condition)
{
    /* TODO: Completar este placeholder durante la actividad 2.2. */
    (void)event;
    (void)depth;
    (void)index;
    (void)sum;
    (void)selected_count;
    (void)condition;
}

static int read_problem(EnergyProblem *problem)
{
    if (scanf("%d", &problem->module_count) != 1)
    {
        return 0;
    }

    if (scanf("%d", &problem->required_energy) != 1)
    {
        return 0;
    }

    if (problem->module_count < 1 ||
        problem->module_count > MAXIMUM_MODULES)
    {
        return 0;
    }

    for (int index = 0; index < problem->module_count; index++)
    {
        if (scanf("%d", &problem->capacity[index]) != 1)
        {
            return 0;
        }
    }

    return 1;
}

static int problem_is_valid(const EnergyProblem *problem)
{
    if (problem->required_energy <= 0)
    {
        return 0;
    }

    for (int index = 0; index < problem->module_count; index++)
    {
        if (problem->capacity[index] <= 0)
        {
            return 0;
        }
    }

    return 1;
}

static int count_selected(const SearchState *state)
{
    int count = 0;

    for (int index = 0; index < state->problem->module_count; index++)
    {
        if (state->selected[index])
        {
            count++;
        }
    }

    return count;
}

static int search_modules(SearchState *state, int index,
                          int current_sum, int depth)
{
    trace_event("ENTRAR", depth, index, current_sum,
                count_selected(state), 1);

    if (current_sum > state->problem->required_energy)
    {
        trace_event("EXCESO", depth, index, current_sum,
                    count_selected(state), 1);
        return 0;
    }

    if (index >= state->problem->module_count - 1)
    {
        trace_event("SIN_OPCIONES", depth, index, current_sum,
                    count_selected(state), 1);
        return 0;
    }

    state->selected[index] = 1;
    int next_sum = current_sum + state->problem->capacity[index];

    trace_event("ELEGIR", depth, index, next_sum,
                count_selected(state), 1);

    if (next_sum == state->problem->required_energy)
    {
        trace_event("SOLUCION", depth, index, next_sum,
                    count_selected(state), 1);
        return 1;
    }

    int found = search_modules(state, index + 1, next_sum, depth + 1);

    trace_event("RETORNAR", depth, index, next_sum,
                count_selected(state), found);

    if (found)
    {
        return 0;
    }

    trace_event("RETROCEDER", depth, index, current_sum,
                count_selected(state), 1);

    trace_event("OMITIR", depth, index, current_sum,
                count_selected(state), 1);

    found = search_modules(state, index + 1, current_sum, depth + 1);

    if (found)
    {
        return 1;
    }

    return 0;
}

static int selected_energy(const SearchState *state)
{
    int total = 0;

    for (int index = 0; index < state->problem->module_count; index++)
    {
        if (state->selected[index])
        {
            total += state->problem->capacity[index];
        }
    }

    return total;
}

static void print_solution(const SearchState *state, int found)
{
    if (!found)
    {
        printf("Resultado: no encontrado\n");
        return;
    }

    printf("Resultado: encontrado\n");
    printf("Cantidad de modulos: %d\n", count_selected(state));
    printf("Modulos:");

    for (int index = 0; index < state->problem->module_count; index++)
    {
        if (state->selected[index])
        {
            printf(" %d", state->problem->capacity[index]);
        }
    }

    printf("\n");
    printf("Energia total: %d\n", selected_energy(state));
}

int main(void)
{
    EnergyProblem problem = {0};

    if (!read_problem(&problem) || !problem_is_valid(&problem))
    {
        fprintf(stderr, "Error: entrada invalida\n");
        return 1;
    }

    SearchState state = {0};
    state.problem = &problem;

    int found = search_modules(&state, 0, 0, 0);
    print_solution(&state, found);

    return 0;
}
