#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(dirname -- "${SCRIPT_DIR}")"
CODE_DIR="${WORKSPACE_DIR}/code"
TESTS_DIR="${WORKSPACE_DIR}/tests"
DEMO_SOURCE="${CODE_DIR}/recursion_demo.c"
SOURCE="${CODE_DIR}/energia.c"
PROGRAM="${CODE_DIR}/energia"
TEMP_DIR="$(mktemp -d)" || exit 2
VALIDATION_PROGRAM="${TEMP_DIR}/energia"
PASSES=0
FAILURES=0

cleanup() {
    rm -rf -- "${TEMP_DIR}"
}

trap cleanup EXIT

check() {
    local message="$1"
    shift

    if "$@" >/dev/null 2>&1; then
        printf 'PASS: %s\n' "${message}"
        PASSES=$((PASSES + 1))
    else
        printf 'FAIL: %s\n' "${message}"
        FAILURES=$((FAILURES + 1))
    fi
}

demo_compiles_cleanly() {
    gcc -Wall -Wextra -Werror -std=c11 \
        "${DEMO_SOURCE}" -o "${TEMP_DIR}/recursion_demo" \
        >/dev/null 2>&1
}

program_compiles_cleanly() {
    gcc -Wall -Wextra -Werror -std=c11 \
        "${SOURCE}" -o "${VALIDATION_PROGRAM}" \
        >/dev/null 2>&1
}

program_is_binary() {
    [[ -x "${PROGRAM}" ]] || return 1
    file -b "${PROGRAM}" | grep -Eq 'ELF.*(executable|pie executable)'
}

all_test_cases_exist() {
    local number=""
    local test_name=""

    for number in $(seq -w 1 10); do
        test_name="test0${number}"
        [[ -f "${TESTS_DIR}/${test_name}.in" ]] || return 1
        [[ -f "${TESTS_DIR}/${test_name}.expected" ]] || return 1
    done
}

program_matches() {
    local input="$1"
    local expected="$2"
    local input_file="${TEMP_DIR}/case.in"
    local expected_file="${TEMP_DIR}/case.expected"
    local output_file="${TEMP_DIR}/case.out"

    [[ -x "${VALIDATION_PROGRAM}" ]] || return 1
    printf '%s' "${input}" > "${input_file}"
    printf '%s' "${expected}" > "${expected_file}"

    timeout 3 "${VALIDATION_PROGRAM}" < "${input_file}" \
        > "${output_file}" 2>/dev/null || return 1
    cmp -s "${expected_file}" "${output_file}"
}

control_cases_are_correct() {
    program_matches \
        $'4\n7\n7 3 4 2\n' \
        $'Resultado: encontrado\nCantidad de modulos: 1\nModulos: 7\nEnergia total: 7\n' &&
        program_matches \
            $'4\n20\n3 4 5 6\n' \
            $'Resultado: no encontrado\n'
}

debug_helper_works() {
    local object_file="${TEMP_DIR}/energia.o"
    local harness_source="${TEMP_DIR}/trace-helper.c"
    local harness_program="${TEMP_DIR}/trace-helper"
    local output_file="${TEMP_DIR}/trace-helper.out"
    local error_file="${TEMP_DIR}/trace-helper.err"
    local expected_file="${TEMP_DIR}/trace-helper.expected"

    printf '%s\n' \
        '#include <stdio.h>' \
        'extern int debug_enabled;' \
        'void trace_event(const char *, int, int, int, int, int);' \
        'int main(void)' \
        '{' \
        '    debug_enabled = 0;' \
        '    trace_event("OCULTO", 0, 1, 2, 3, 1);' \
        '    debug_enabled = 1;' \
        '    trace_event("ENTRAR", 1, 2, 3, 4, 1);' \
        '    trace_event("OCULTO", 2, 3, 4, 5, 0);' \
        '    return 0;' \
        '}' > "${harness_source}"

    printf '%s\n' \
        'DEBUG:   ENTRAR profundidad=1 indice=2 suma=3 seleccionadas=4' \
        > "${expected_file}"

    gcc -Wall -Wextra -Werror -std=c11 -Dmain=energia_main \
        -c "${SOURCE}" -o "${object_file}" >/dev/null 2>&1 || return 1
    gcc -Wall -Wextra -Werror -std=c11 \
        "${harness_source}" "${object_file}" -o "${harness_program}" \
        >/dev/null 2>&1 || return 1
    "${harness_program}" > "${output_file}" 2> "${error_file}" || return 1

    [[ ! -s "${output_file}" ]] || return 1
    cmp -s "${expected_file}" "${error_file}"
}

recursive_result_is_propagated() {
    program_matches \
        $'5\n9\n4 5 20 30 40\n' \
        $'Resultado: encontrado\nCantidad de modulos: 2\nModulos: 4 5\nEnergia total: 9\n' &&
        program_matches \
            $'6\n13\n3 4 6 20 30 40\n' \
            $'Resultado: encontrado\nCantidad de modulos: 3\nModulos: 3 4 6\nEnergia total: 13\n'
}

state_is_restored() {
    program_matches \
        $'5\n9\n20 4 5 30 40\n' \
        $'Resultado: encontrado\nCantidad de modulos: 2\nModulos: 4 5\nEnergia total: 9\n' &&
        program_matches \
            $'6\n11\n50 3 20 8 40 60\n' \
            $'Resultado: encontrado\nCantidad de modulos: 2\nModulos: 3 8\nEnergia total: 11\n'
}

all_modules_are_considered() {
    program_matches \
        $'5\n10\n30 4 20 40 6\n' \
        $'Resultado: encontrado\nCantidad de modulos: 2\nModulos: 4 6\nEnergia total: 10\n' &&
        program_matches \
            $'6\n15\n50 7 20 30 40 8\n' \
            $'Resultado: encontrado\nCantidad de modulos: 2\nModulos: 7 8\nEnergia total: 15\n'
}

has_clean_stderr() {
    local input_file=""
    local output_file="${TEMP_DIR}/clean.out"
    local error_file="${TEMP_DIR}/clean.err"

    [[ -x "${VALIDATION_PROGRAM}" ]] || return 1

    for input_file in "${TESTS_DIR}"/test*.in; do
        timeout 3 "${VALIDATION_PROGRAM}" < "${input_file}" \
            > "${output_file}" 2> "${error_file}" || return 1
        [[ ! -s "${error_file}" ]] || return 1
    done
}

suite_passes() {
    all_test_cases_exist || return 1
    [[ -x "${SCRIPT_DIR}/tests-run.sh" ]] || return 1
    [[ -x "${VALIDATION_PROGRAM}" ]] || return 1
    "${SCRIPT_DIR}/tests-run.sh" "${VALIDATION_PROGRAM}" \
        "${TESTS_DIR}" >/dev/null 2>&1
}

printf '%s\n' '========================================='
printf '%s\n' '==   Verificación de laboratorio REC   =='
printf '%s\n' '========================================='
printf '\n== Actividades ==========================\n\n'

check "[1.2] recursion_demo.c compila sin warnings" demo_compiles_cleanly
check "[1.4] energia.c compila sin warnings" program_compiles_cleanly
check "[1.4] energia corresponde a un binario" program_is_binary
check "[1.5] tests-run.sh tiene permiso de ejecución" test -x "${SCRIPT_DIR}/tests-run.sh"
check "[1.5] Existen los diez pares de archivos de prueba" all_test_cases_exist
check "[1.5] Los casos de control mantienen su comportamiento" control_cases_are_correct
check "[2.2] trace_event combina los controles global y local" debug_helper_works
check "[3.3] El resultado se propaga entre las llamadas recursivas" recursive_result_is_propagated
check "[4.3] El estado se restaura antes de explorar otra alternativa" state_is_restored
check "[5.2] La búsqueda considera todos los módulos disponibles" all_modules_are_considered
check "[6.1] El programa no emite trazas con la depuración desactivada" has_clean_stderr
check "[6.2] La suite completa finaliza correctamente" suite_passes
check "[7.1] check.sh tiene permiso de ejecución" test -x "${SCRIPT_DIR}/check.sh"

printf '\n== Resumen ===============================\n\n'
TOTAL=$((PASSES + FAILURES))
COUNT_WIDTH=${#TOTAL}
printf '%-26s %*d\n' 'Comprobaciones exitosas:' "${COUNT_WIDTH}" "${PASSES}"
printf '%-26s %*d\n\n' 'Comprobaciones pendientes:' "${COUNT_WIDTH}" "${FAILURES}"

if (( FAILURES == 0 )); then
    exit 0
fi

exit 1
