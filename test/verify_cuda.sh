#!/bin/bash

# 简洁的 CUDA 安装检查脚本

echo "========================================"
echo "           CUDA 安装检查"
echo "========================================"
echo

# 检查计数器
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

# 1. 检查 NVIDIA GPU
echo "1. 检查 NVIDIA GPU"
if lspci | grep -i nvidia >/dev/null 2>&1; then
    check 0 "检测到 NVIDIA GPU"
    lspci | grep -i nvidia | head -1
else
    check 1 "未检测到 NVIDIA GPU"
fi
echo

# 2. 检查 NVIDIA 驱动
echo "2. 检查 NVIDIA 驱动"
if command -v nvidia-smi >/dev/null 2>&1; then
    if nvidia-smi >/dev/null 2>&1; then
        check 0 "NVIDIA 驱动正常"
        echo "驱动版本: $(nvidia-smi --query-gpu=driver_version --format=csv,noheader,nounits 2>/dev/null | head -1 || echo '无法获取')"
    else
        check 1 "NVIDIA 驱动异常"
    fi
else
    check 1 "未安装 NVIDIA 驱动"
fi
echo

# 3. 检查 CUDA Toolkit
echo "3. 检查 CUDA Toolkit"
if command -v nvcc >/dev/null 2>&1; then
    check 0 "CUDA 编译器可用"
    nvcc_version=$(nvcc --version 2>/dev/null | grep "release" | awk '{print $6}' | cut -c2- || echo "无法获取")
    echo "NVCC 版本: $nvcc_version"
else
    check 1 "CUDA 编译器不可用"
fi

# 检查 CUDA 安装路径
if [ -d "/usr/local/cuda" ] || ls -d /usr/local/cuda-* >/dev/null 2>&1; then
    check 0 "找到 CUDA 安装路径"
else
    check 1 "未找到 CUDA 安装路径"
fi
echo

# 4. 简单的 CUDA 功能测试
echo "4. CUDA 功能测试"
if command -v nvcc >/dev/null 2>&1; then
    cat >/tmp/cuda_test.cu <<'EOF'
#include <stdio.h>
#include <cuda_runtime.h>

int main() {
    int deviceCount;
    cudaError_t error = cudaGetDeviceCount(&deviceCount);
    
    if (error != cudaSuccess) {
        printf("CUDA 错误: %s\n", cudaGetErrorString(error));
        return 1;
    }
    
    printf("检测到 %d 个 CUDA 设备\n", deviceCount);
    return 0;
}
EOF

    if nvcc -o /tmp/cuda_test /tmp/cuda_test.cu >/dev/null 2>&1; then
        if /tmp/cuda_test 2>/dev/null; then
            check 0 "CUDA 功能测试通过"
            /tmp/cuda_test
        else
            check 1 "CUDA 功能测试失败"
        fi
        rm -f /tmp/cuda_test
    else
        check 1 "CUDA 测试程序编译失败"
    fi
    rm -f /tmp/cuda_test.cu
else
    echo "跳过 CUDA 功能测试（nvcc 不可用）"
fi
echo

# 总结
echo "========================================"
echo "检查结果: $passed/$total"
if [ $passed -eq $total ]; then
    echo "✓ CUDA 安装正常"
    exit 0
elif [ $passed -gt $((total / 2)) ]; then
    echo "⚠ CUDA 安装部分正常，存在问题"
    exit 1
else
    echo "✗ CUDA 安装异常"
    exit 2
fi
