#!/bin/bash

# Simple CUDA installation check script

echo "========================================"
echo "         CUDA Installation Check"
echo "========================================"
echo

# Check counters
passed=0
total=0

check() {
    ((total++))
    if [ $1 -eq 0 ]; then
        ((passed++))
        echo "✓ $2"
    else
        echo "✗ $2"
    fi
}

# 1. Check NVIDIA GPU
echo "1. Check NVIDIA GPU"
if lspci | grep -i nvidia >/dev/null 2>&1; then
    check 0 "NVIDIA GPU detected"
    lspci | grep -i nvidia | head -1
else
    check 1 "No NVIDIA GPU detected"
fi
echo

# 2. Check NVIDIA driver
echo "2. Check NVIDIA Driver"
if command -v nvidia-smi >/dev/null 2>&1; then
    if nvidia-smi >/dev/null 2>&1; then
        check 0 "NVIDIA driver is working"
        echo "Driver version: $(nvidia-smi --query-gpu=driver_version --format=csv,noheader,nounits 2>/dev/null | head -1 || echo 'Unable to get')"
    else
        check 1 "NVIDIA driver is abnormal"
    fi
else
    check 1 "NVIDIA driver not installed"
fi
echo

# 3. Check CUDA Toolkit
echo "3. Check CUDA Toolkit"
if command -v nvcc >/dev/null 2>&1; then
    check 0 "CUDA compiler available"
    nvcc_version=$(nvcc --version 2>/dev/null | grep "release" | awk '{print $6}' | cut -c2- || echo "Unable to get")
    echo "NVCC version: $nvcc_version"
else
    check 1 "CUDA compiler not available"
fi

# Check CUDA installation path
if [ -d "/usr/local/cuda" ] || ls -d /usr/local/cuda-* >/dev/null 2>&1; then
    check 0 "CUDA installation path found"
else
    check 1 "CUDA installation path not found"
fi
echo

# 4. Simple CUDA functionality test
echo "4. CUDA Functionality Test"
if command -v nvcc >/dev/null 2>&1; then
    cat >/tmp/cuda_test.cu <<'EOF'
#include <stdio.h>
#include <cuda_runtime.h>

int main() {
    int deviceCount;
    cudaError_t error = cudaGetDeviceCount(&deviceCount);
    
    if (error != cudaSuccess) {
        printf("CUDA error: %s\n", cudaGetErrorString(error));
        return 1;
    }
    
    printf("Detected %d CUDA device(s)\n", deviceCount);
    return 0;
}
EOF

    if nvcc -o /tmp/cuda_test /tmp/cuda_test.cu >/dev/null 2>&1; then
        if /tmp/cuda_test 2>/dev/null; then
            check 0 "CUDA functionality test passed"
            /tmp/cuda_test
        else
            check 1 "CUDA functionality test failed"
        fi
        rm -f /tmp/cuda_test
    else
        check 1 "CUDA test program compilation failed"
    fi
    rm -f /tmp/cuda_test.cu
else
    echo "Skipping CUDA functionality test (nvcc not available)"
fi
echo

# Summary
echo "========================================"
echo "Check results: $passed/$total"
if [ $passed -eq $total ]; then
    echo "✓ CUDA installation is normal"
    exit 0
elif [ $passed -gt $((total / 2)) ]; then
    echo "⚠ CUDA installation is partially working, issues exist"
    exit 1
else
    echo "✗ CUDA installation is abnormal"
    exit 2
fi
