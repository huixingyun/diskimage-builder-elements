#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
PyTorch Installation Test Script
Tests whether PyTorch is correctly installed and functioning properly
"""

import sys
import os


def test_pytorch_import():
    """Test PyTorch import"""
    print("=" * 50)
    print("1. Testing PyTorch import...")
    try:
        import torch
        import torchvision
        import numpy as np

        print("✓ PyTorch import successful")
        return torch
    except ImportError as e:
        print(f"✗ PyTorch import failed: {e}")
        return None


def test_pytorch_version(torch):
    """Test PyTorch version information"""
    print("\n" + "=" * 50)
    print("2. PyTorch version information:")
    print(f"   PyTorch version: {torch.__version__}")
    print(f"   Python version: {sys.version}")

    try:
        import torchvision

        print(f"   TorchVision version: {torchvision.__version__}")
    except:
        print("   TorchVision: Not installed")


def test_basic_operations(torch):
    """Test basic tensor operations"""
    print("\n" + "=" * 50)
    print("3. Testing basic tensor operations...")

    try:
        # Create tensors
        x = torch.randn(3, 4)
        y = torch.randn(4, 5)

        # Matrix multiplication
        z = torch.mm(x, y)
        print(f"✓ Tensor creation and matrix multiplication successful")
        print(f"   x.shape = {x.shape}, y.shape = {y.shape}, z.shape = {z.shape}")

        # Gradient computation
        x.requires_grad_(True)
        loss = x.sum()
        loss.backward()
        print(f"✓ Gradient computation successful")
        print(f"   x.grad.shape = {x.grad.shape}")

        return True
    except Exception as e:
        print(f"✗ Basic operations failed: {e}")
        return False


def test_cuda_availability(torch):
    """Test CUDA availability"""
    print("\n" + "=" * 50)
    print("4. Testing CUDA support...")

    if torch.cuda.is_available():
        print("✓ CUDA available")
        print(f"   CUDA version: {torch.version.cuda}")
        print(f"   GPU count: {torch.cuda.device_count()}")

        for i in range(torch.cuda.device_count()):
            gpu_name = torch.cuda.get_device_name(i)
            print(f"   GPU {i}: {gpu_name}")

        # Test GPU computation
        try:
            device = torch.device("cuda:0")
            x = torch.randn(1000, 1000).to(device)
            y = torch.randn(1000, 1000).to(device)
            z = torch.mm(x, y)
            print("✓ GPU computation test successful")
            return True
        except Exception as e:
            print(f"✗ GPU computation test failed: {e}")
            return False
    else:
        print("⚠ CUDA not available (this is normal if you don't have an NVIDIA GPU)")
        return False


def test_simple_model(torch):
    """Test simple neural network model"""
    print("\n" + "=" * 50)
    print("5. Testing simple neural network...")

    try:
        import torch.nn as nn
        import torch.optim as optim

        # Create simple linear model
        model = nn.Sequential(nn.Linear(10, 5), nn.ReLU(), nn.Linear(5, 1))

        # Create dummy data
        x = torch.randn(100, 10)
        y = torch.randn(100, 1)

        # Define loss function and optimizer
        criterion = nn.MSELoss()
        optimizer = optim.SGD(model.parameters(), lr=0.01)

        # Train for a few steps
        for epoch in range(5):
            optimizer.zero_grad()
            outputs = model(x)
            loss = criterion(outputs, y)
            loss.backward()
            optimizer.step()

        print("✓ Simple neural network training successful")
        print(f"   Final loss: {loss.item():.4f}")
        return True

    except Exception as e:
        print(f"✗ Neural network test failed: {e}")
        return False


def test_data_loading():
    """Test data loading functionality"""
    print("\n" + "=" * 50)
    print("6. Testing data loading...")

    try:
        from torch.utils.data import DataLoader, TensorDataset
        import torch

        # Create dummy dataset
        x = torch.randn(100, 10)
        y = torch.randn(100, 1)
        dataset = TensorDataset(x, y)

        # Create data loader
        dataloader = DataLoader(dataset, batch_size=32, shuffle=True)

        # Test one batch
        for batch_x, batch_y in dataloader:
            print(f"✓ Data loading successful")
            print(f"   Batch size: {batch_x.shape[0]}")
            break

        return True

    except Exception as e:
        print(f"✗ Data loading test failed: {e}")
        return False


def main():
    """Main test function"""
    print("PyTorch Installation Test Started")
    print("=" * 50)

    # Test import
    torch = test_pytorch_import()
    if torch is None:
        print("\n❌ PyTorch is not correctly installed, please reinstall")
        return False

    # Test version
    test_pytorch_version(torch)

    # Test basic operations
    if not test_basic_operations(torch):
        print("\n❌ Basic operations test failed")
        return False

    # Test CUDA
    cuda_available = test_cuda_availability(torch)

    # Test model
    if not test_simple_model(torch):
        print("\n❌ Model test failed")
        return False

    # Test data loading
    if not test_data_loading():
        print("\n❌ Data loading test failed")
        return False

    # Summary
    print("\n" + "=" * 50)
    print("Test Summary:")
    print("✓ PyTorch basic functionality working")
    print("✓ Tensor operations working")
    print("✓ Neural network functionality working")
    print("✓ Data loading functionality working")
    if cuda_available:
        print("✓ CUDA GPU acceleration available")
    else:
        print("⚠ CUDA not available (CPU mode)")

    print(
        "\n🎉 PyTorch installation test completed! All core functions are working properly."
    )
    return True


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
