// Tests the student's stridedCopy kernel: out[i] must be in[i * stride]
#define main student_main
#include STUDENT_FILE
#undef main
#include <vector>
#include "test_common.h"

int main() {
    printf("Ex 4 - stridedCopy kernel\n");
    const int n = 5000, maxStride = 32;
    std::vector<float> in((size_t)n * maxStride), out(n);
    for (size_t j = 0; j < in.size(); ++j) in[j] = (float)j;      // value = its own position
    float *din, *dout;
    check(cudaMalloc(&din, in.size() * sizeof(float)), "cudaMalloc");
    check(cudaMalloc(&dout, n * sizeof(float)), "cudaMalloc");
    check(cudaMemcpy(din, in.data(), in.size() * sizeof(float), cudaMemcpyHostToDevice), "cudaMemcpy");
    for (int stride : {1, 2, 7, 32}) {
        check(cudaMemset(dout, 0, n * sizeof(float)), "cudaMemset");
        stridedCopy<<<(n + 255) / 256, 256>>>(din, dout, n, stride);
        check(cudaGetLastError(), "kernel launch"); check(cudaDeviceSynchronize(), "kernel");
        check(cudaMemcpy(out.data(), dout, n * sizeof(float), cudaMemcpyDeviceToHost), "cudaMemcpy");
        int wrong = 0;
        for (int i = 0; i < n; ++i) if (out[i] != (float)((size_t)i * stride)) ++wrong;
        EXPECT(wrong == 0, "stride %-2d: out[i] == in[i * stride] (%d wrong)", stride, wrong);
    }
    cudaFree(din); cudaFree(dout);
    return finish("Ex 4 kernel");
}
