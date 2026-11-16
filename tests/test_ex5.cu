// Tests the student's matmulTiled kernel against a CPU reference, also for sizes
// that are not a multiple of the tile size.
#define main student_main
#include STUDENT_FILE
#undef main
#include <vector>
#include <cmath>
#include "test_common.h"

int main() {
    printf("Ex 5 - matmulTiled kernel (bonus)\n");
    for (int N : {1, 16, 17, 64, 100}) {
        std::vector<float> A(N * N), B(N * N), C(N * N), R(N * N, 0.0f);
        for (int i = 0; i < N * N; ++i) { A[i] = (float)((i * 7) % 11) - 5; B[i] = (float)((i * 3) % 13) - 6; }
        for (int r = 0; r < N; ++r)
            for (int k = 0; k < N; ++k)
                for (int c = 0; c < N; ++c) R[r * N + c] += A[r * N + k] * B[k * N + c];
        float *dA, *dB, *dC; size_t bytes = (size_t)N * N * sizeof(float);
        check(cudaMalloc(&dA, bytes), "cudaMalloc"); check(cudaMalloc(&dB, bytes), "cudaMalloc"); check(cudaMalloc(&dC, bytes), "cudaMalloc");
        check(cudaMemcpy(dA, A.data(), bytes, cudaMemcpyHostToDevice), "cudaMemcpy");
        check(cudaMemcpy(dB, B.data(), bytes, cudaMemcpyHostToDevice), "cudaMemcpy");
        dim3 block(TILE, TILE), grid((N + TILE - 1) / TILE, (N + TILE - 1) / TILE);
        matmulTiled<<<grid, block>>>(dA, dB, dC, N);
        check(cudaGetLastError(), "kernel launch"); check(cudaDeviceSynchronize(), "kernel");
        check(cudaMemcpy(C.data(), dC, bytes, cudaMemcpyDeviceToHost), "cudaMemcpy");
        int wrong = 0;
        for (int i = 0; i < N * N; ++i) if (std::fabs(C[i] - R[i]) > 1e-3f) ++wrong;
        EXPECT(wrong == 0, "N = %-4d matches CPU result (%d wrong)", N, wrong);
        cudaFree(dA); cudaFree(dB); cudaFree(dC);
    }
    return finish("Ex 5 kernel");
}
