// =====================================================================
// Exercise 2 - Vector addition
// ---------------------------------------------------------------------
// 1) THE PROBLEM
//    Add two arrays with one million numbers: c[i] = a[i] + b[i].
//    On the GPU, every thread adds ONE pair. The data has to get to the
//    GPU first, and the result has to come back.
//
// 2) YOUR TASK
//    - Write the kernel vecAdd (keep the name and parameters - the tests use them).
//      Careful: n is NOT a multiple of the block size.
//    - In main(): allocate GPU memory, copy a and b to the GPU, start the
//      kernel with enough blocks for all n elements, wait for the GPU,
//      check for errors, copy the result back into c, free the GPU memory.
//
// 3) RUN & TEST
//    Build -> Run (prints c[0], c[n/2], c[n-1]) -> Test (all lines must show [PASS])
// =====================================================================
#include <cstdio>
#include <cmath>
#include <vector>
#include <initializer_list>

__global__ void vecAdd(const float* a, const float* b, float* c, int n) {
    // global index of this thread

    // only threads with a valid index may write: c = a + b
}

int main() {
    const int n = 1000003;
    const size_t bytes = n * sizeof(float);

    std::vector<float> a(n), b(n), c(n);
    for (int i = 0; i < n; ++i) { a[i] = std::sin(i); b[i] = std::cos(i); }

    // ---------------- GPU part ----------------
    float *d_a = nullptr, *d_b = nullptr, *d_c = nullptr;

    // allocate GPU memory for d_a, d_b and d_c (cudaMalloc)

    // copy a and b to the GPU (cudaMemcpy, use a.data() and b.data())

    // enough blocks of 256 threads for ALL n elements
    int threads = 256;
    int blocks  = 0;

    // start vecAdd

    // check for launch errors, wait for the GPU, check again

    // copy the result back into c

    // free the GPU memory (cudaFree)
    // -------------------------------------------

    // print a few results (Test compares them with the correct values)
    for (int i : {0, n / 2, n - 1})
        printf("c[%7d] = %9.6f\n", i, c[i]);
    return 0;
}
