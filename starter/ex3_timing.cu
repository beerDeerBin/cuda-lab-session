// =====================================================================
// Exercise 3 - Where does the time go?
// ---------------------------------------------------------------------
// 1) THE PROBLEM
//    Is the GPU really faster than the CPU? We measure every step:
//    copying to the GPU, the kernel, and copying back.
//
// 2) YOUR TASK
//    - Run vecAdd (from Exercise 2, already here) on the GPU.
//    - Measure the three steps with CUDA events (they use the GPU's clock):
//      copy CPU -> GPU, kernel, copy GPU -> CPU.
//      Tip: the very first kernel launch is slower (setup) - do one warm-up launch.
//    - Store the three times in h2d_ms, kernel_ms and d2h_ms
//      (the printf lines are already there).
//
// 3) RUN & TEST
//    Build -> Run -> Test (all lines must show [PASS])
//    Then in the terminal:  ./ex3_timing 1000000   and   ./ex3_timing 200000000
//    Which step takes longest? Compare the CPU loop with the GPU kernel
//    alone - and with the GPU total. When is the GPU really worth it?
// =====================================================================
#include <cstdio>
#include <cstdlib>
#include <chrono>
#include <vector>

__global__ void vecAdd(const float* a, const float* b, float* c, int n) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) c[i] = a[i] + b[i];
}

int main(int argc, char** argv) {
    const int n = (argc > 1) ? atoi(argv[1]) : (1 << 24);
    const size_t bytes = (size_t)n * sizeof(float);
    std::vector<float> a(n, 1.0f), b(n, 2.0f), c(n), c_cpu(n);   // expected: c[i] = 3

    // CPU version, measured with a normal CPU clock
    auto t0 = std::chrono::high_resolution_clock::now();
    for (int i = 0; i < n; ++i) c_cpu[i] = a[i] + b[i];
    auto t1 = std::chrono::high_resolution_clock::now();
    printf("n = %d elements\n", n);
    printf("CPU loop        : %8.3f ms\n", std::chrono::duration<double, std::milli>(t1 - t0).count());

    // ---------------- GPU part ----------------
    float *d_a = nullptr, *d_b = nullptr, *d_c = nullptr;
    int threads = 256, blocks = (n + threads - 1) / threads;

    // allocate GPU memory (like in Exercise 2)

    // warm-up: start vecAdd once and wait (the first launch includes setup time)

    // four events = four points in time on the GPU's clock
    cudaEvent_t e0, e1, e2, e3;
    // create the events (cudaEventCreate)

    // record e0 -> copy a and b to the GPU -> record e1
    // start vecAdd                         -> record e2
    // copy the result back into c          -> record e3

    // wait until e3 has happened (cudaEventSynchronize), then check for errors

    // time between two events (cudaEventElapsedTime)
    float h2d_ms = 0, kernel_ms = 0, d2h_ms = 0;

    printf("copy CPU -> GPU : %8.3f ms\n", h2d_ms);
    printf("GPU kernel      : %8.3f ms\n", kernel_ms);
    printf("copy GPU -> CPU : %8.3f ms\n", d2h_ms);
    printf("GPU total       : %8.3f ms   (copies + kernel)\n", h2d_ms + kernel_ms + d2h_ms);

    // free the GPU memory and destroy the events
    // -------------------------------------------

    printf("c[n-1] = %.1f (expected 3.0)\n", c[n - 1]);
    return 0;
}
