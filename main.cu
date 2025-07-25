#include <iostream>
#include <random>
#include <chrono>
#include <iomanip>
#include <string>
#include <vector>

#include "matrix.h"
#include "vector.h"
#include "utils.h"

#include "cuda.cuh"


int main(int argc, char **argv) {

    size_t N, M;

    std::cout << "N: ";
    std::cin >> N;

    std::cout << "M: ";
    std::cin >> M;

    try {
        std::cout << "Creating array (size: " << N*M << ").." << std::endl;

        const size_t group_size = 1024;

        float *data_x = Utils::create_array<float>(N*M, group_size, 0.1f);
        float *data_y = Utils::create_array<float>(N*M, group_size, 0.1f);
        float *data_z = Utils::create_array<float>(N*N, group_size, 0.0f);

        Utils::randomize_array(data_x, N*M);
        Utils::randomize_array(data_y, N*M);

        Vector<float> vx(data_x, N*M), vy(data_y, N*M);
        Matrix<float> mx(data_x, N, M), my(data_y, M, N), mz(data_z, N, N);

        VectorCuda cuda_vx(vx), cuda_vy(vy);
        VectorReduceCuda cuda_rvx(vx), cuda_rvy(vy);
        MatrixCuda cuda_mx(mx), cuda_my(my), cuda_mz(mz);

        std::cout << "Vector size: " << mx.size_mb() + my.size_mb() + mz.size_mb() << "MB" << std::endl;

        std::cout << std::left 
                  << std::setw(20)
                  << "C++ vector dot: "
                  << std::fixed
                  << Utils::measure([&vx, &vy]() {
                      std::cout << "(" << vx.dot(vy) << ")" << " ";
                  })
                  << "s" << std::endl;

        std::cout << std::left
                  << std::setw(20)
                  << "cuBLAS vector dot: "
                  << std::fixed
                  << Utils::measure([&cuda_vx, &cuda_vy]() {
                      std::cout << "(" << cuda_vx.dot(cuda_vy) << ")" << " ";
                  })
                  << "s" << std::endl;

        std::cout << std::left
                  << std::setw(20)
                  << "CUDA reduce vector dot: "
                  << std::fixed
                  << Utils::measure([&cuda_rvx, &cuda_rvy]() {
                      std::cout << "(" << cuda_rvx.dot(cuda_rvy) << ")" << " ";
                  })
                  << "s" << std::endl;
        // std::cout << std::left 
        //           << std::setw(20)
        //           << "C++ matrix mul: "
        //           << std::fixed
        //           << Utils::measure([&mx, &my, &mz]() {
        //                 mx.dot(my, mz);
        //                 std::cout << "(" << mz.sum() << ")" << " ";
        //           })
        //           << "s" << std::endl;

        std::cout << std::left
                  << std::setw(20)
                  << "cuBLAS matrix mul: "
                  << std::fixed
                  << Utils::measure([&cuda_mx, &cuda_my, &cuda_mz]() {
                        cuda_mx.dot(cuda_my, cuda_mz);
                        std::cout << "(" << cuda_mz.sum() << ")" << " ";
                  })
                  << "s" << std::endl;

        delete[] data_x;
        delete[] data_y;
        delete[] data_z;

    } catch (const std::exception &e) {
        std::cerr << e.what() << std::endl;
        return EXIT_FAILURE;
    }
    std::cout << "Exited" << std::endl;

    return EXIT_SUCCESS;
}