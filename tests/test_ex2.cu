// Tests the student's vecAdd kernel directly: correct results for many sizes,
// and NO writes behind the end of the array (bounds check).
#define main student_main
#include STUDENT_FILE
#undef main
#include <vector>
#include <cstring>
#include "test_common.h"

static bool runCase(int n, int threads, int* wrong, int* overwritten) {
    const int pad = 1024;                                    // guard zone behind the array
    std::vector<float> a(n), b(n), c(n + pad);
    for (int i = 0; i < n; ++i) { a[i] = (float)(i % 1000); b[i] = 0.5f * (i % 777); }
    float *da, *db, *dc;
    check(cudaMalloc(&da, (n + pad) * sizeof(float)), "cudaMalloc");
    check(cudaMalloc(&db, (n + pad) * sizeof(float)), "cudaMalloc");
    check(cudaMalloc(&dc, (n + pad) * sizeof(float)), "cudaMalloc");
    check(cudaMemcpy(da, a.data(), n * sizeof(float), cudaMemcpyHostToDevice), "cudaMemcpy");
    check(cudaMemcpy(db, b.data(), n * sizeof(float), cudaMemcpyHostToDevice), "cudaMemcpy");
    check(cudaMemset(dc, 0x7F, (n + pad) * sizeof(float)), "cudaMemset");   // sentinel pattern
    int blocks = (n + threads - 1) / threads + 2;            // deliberately TOO MANY threads
    vecAdd<<<blocks, threads>>>(da, db, dc, n);
    cudaError_t err = cudaDeviceSynchronize();
    if (err != cudaSuccess) { printf("  kernel error: %s\n", cudaGetErrorString(err)); exit(1); }
    check(cudaMemcpy(c.data(), dc, (n + pad) * sizeof(float), cudaMemcpyDeviceToHost), "cudaMemcpy");
    float sentinel; memset(&sentinel, 0x7F, sizeof(float));
    *wrong = 0; *overwritten = 0;
    for (int i = 0; i < n; ++i) if (c[i] != a[i] + b[i]) ++*wrong;
    for (int i = n; i < n + pad; ++i) if (memcmp(&c[i], &sentinel, sizeof(float)) != 0) ++*overwritten;
    cudaFree(da); cudaFree(db); cudaFree(dc);
    return *wrong == 0 && *overwritten == 0;
}

int main() {
    printf("Ex 2 - vecAdd kernel\n");
    int sizes[] = {1, 100, 255, 256, 257, 1000003};
    for (int n : sizes) {
        int wrong, over;
        runCase(n, 256, &wrong, &over);
        EXPECT(wrong == 0, "n = %-8d correct results (%d wrong)", n, wrong);
        EXPECT(over == 0,  "n = %-8d no writes behind the array (bounds check) (%d overwritten)", n, over);
    }
    return finish("Ex 2 kernel");
}
