#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
PyTorch 安装测试脚本
测试 PyTorch 是否正确安装并能正常工作
"""

import sys
import os


def test_pytorch_import():
    """测试 PyTorch 导入"""
    print("=" * 50)
    print("1. 测试 PyTorch 导入...")
    try:
        import torch
        import torchvision
        import numpy as np

        print("✓ PyTorch 导入成功")
        return torch
    except ImportError as e:
        print(f"✗ PyTorch 导入失败: {e}")
        return None


def test_pytorch_version(torch):
    """测试 PyTorch 版本信息"""
    print("\n" + "=" * 50)
    print("2. PyTorch 版本信息:")
    print(f"   PyTorch 版本: {torch.__version__}")
    print(f"   Python 版本: {sys.version}")

    try:
        import torchvision

        print(f"   TorchVision 版本: {torchvision.__version__}")
    except:
        print("   TorchVision: 未安装")


def test_basic_operations(torch):
    """测试基本张量操作"""
    print("\n" + "=" * 50)
    print("3. 测试基本张量操作...")

    try:
        # 创建张量
        x = torch.randn(3, 4)
        y = torch.randn(4, 5)

        # 矩阵乘法
        z = torch.mm(x, y)
        print(f"✓ 张量创建和矩阵乘法成功")
        print(f"   x.shape = {x.shape}, y.shape = {y.shape}, z.shape = {z.shape}")

        # 梯度计算
        x.requires_grad_(True)
        loss = x.sum()
        loss.backward()
        print(f"✓ 梯度计算成功")
        print(f"   x.grad.shape = {x.grad.shape}")

        return True
    except Exception as e:
        print(f"✗ 基本操作失败: {e}")
        return False


def test_cuda_availability(torch):
    """测试 CUDA 可用性"""
    print("\n" + "=" * 50)
    print("4. 测试 CUDA 支持...")

    if torch.cuda.is_available():
        print("✓ CUDA 可用")
        print(f"   CUDA 版本: {torch.version.cuda}")
        print(f"   GPU 数量: {torch.cuda.device_count()}")

        for i in range(torch.cuda.device_count()):
            gpu_name = torch.cuda.get_device_name(i)
            print(f"   GPU {i}: {gpu_name}")

        # 测试 GPU 计算
        try:
            device = torch.device("cuda:0")
            x = torch.randn(1000, 1000).to(device)
            y = torch.randn(1000, 1000).to(device)
            z = torch.mm(x, y)
            print("✓ GPU 计算测试成功")
            return True
        except Exception as e:
            print(f"✗ GPU 计算测试失败: {e}")
            return False
    else:
        print("⚠ CUDA 不可用 (这是正常的，如果您没有 NVIDIA GPU)")
        return False


def test_simple_model(torch):
    """测试简单的神经网络模型"""
    print("\n" + "=" * 50)
    print("5. 测试简单神经网络...")

    try:
        import torch.nn as nn
        import torch.optim as optim

        # 创建简单的线性模型
        model = nn.Sequential(nn.Linear(10, 5), nn.ReLU(), nn.Linear(5, 1))

        # 创建虚拟数据
        x = torch.randn(100, 10)
        y = torch.randn(100, 1)

        # 定义损失函数和优化器
        criterion = nn.MSELoss()
        optimizer = optim.SGD(model.parameters(), lr=0.01)

        # 训练几步
        for epoch in range(5):
            optimizer.zero_grad()
            outputs = model(x)
            loss = criterion(outputs, y)
            loss.backward()
            optimizer.step()

        print("✓ 简单神经网络训练成功")
        print(f"   最终损失: {loss.item():.4f}")
        return True

    except Exception as e:
        print(f"✗ 神经网络测试失败: {e}")
        return False


def test_data_loading():
    """测试数据加载功能"""
    print("\n" + "=" * 50)
    print("6. 测试数据加载...")

    try:
        from torch.utils.data import DataLoader, TensorDataset
        import torch

        # 创建虚拟数据集
        x = torch.randn(100, 10)
        y = torch.randn(100, 1)
        dataset = TensorDataset(x, y)

        # 创建数据加载器
        dataloader = DataLoader(dataset, batch_size=32, shuffle=True)

        # 测试一个批次
        for batch_x, batch_y in dataloader:
            print(f"✓ 数据加载成功")
            print(f"   批次大小: {batch_x.shape[0]}")
            break

        return True

    except Exception as e:
        print(f"✗ 数据加载测试失败: {e}")
        return False


def main():
    """主测试函数"""
    print("PyTorch 安装测试开始")
    print("=" * 50)

    # 测试导入
    torch = test_pytorch_import()
    if torch is None:
        print("\n❌ PyTorch 未正确安装，请重新安装")
        return False

    # 测试版本
    test_pytorch_version(torch)

    # 测试基本操作
    if not test_basic_operations(torch):
        print("\n❌ 基本操作测试失败")
        return False

    # 测试 CUDA
    cuda_available = test_cuda_availability(torch)

    # 测试模型
    if not test_simple_model(torch):
        print("\n❌ 模型测试失败")
        return False

    # 测试数据加载
    if not test_data_loading():
        print("\n❌ 数据加载测试失败")
        return False

    # 总结
    print("\n" + "=" * 50)
    print("测试总结:")
    print("✓ PyTorch 基本功能正常")
    print("✓ 张量操作正常")
    print("✓ 神经网络功能正常")
    print("✓ 数据加载功能正常")
    if cuda_available:
        print("✓ CUDA GPU 加速可用")
    else:
        print("⚠ CUDA 不可用 (CPU 模式)")

    print("\n🎉 PyTorch 安装测试完成！所有核心功能正常工作。")
    return True


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
