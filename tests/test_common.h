// test_common.h - tiny test helpers for the lab exercises
#pragma once
#include <cstdio>
#include <cstdlib>

// stop the test with a clear message if a CUDA call fails
static void check(cudaError_t err, const char* what) {
    if (err != cudaSuccess) {
        printf("  [FAIL] %s: %s\n", what, cudaGetErrorString(err));
        exit(1);
    }
}

static int g_pass = 0, g_fail = 0;

#define EXPECT(cond, ...)                                   \
    do {                                                    \
        if (cond) { ++g_pass; printf("  [PASS] "); }        \
        else      { ++g_fail; printf("  [FAIL] "); }        \
        printf(__VA_ARGS__); printf("\n");                  \
    } while (0)

static int finish(const char* name) {
    printf("  => %s: %d passed, %d failed\n", name, g_pass, g_fail);
    return g_fail == 0 ? 0 : 1;
}
