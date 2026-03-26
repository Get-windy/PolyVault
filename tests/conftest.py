"""
PolyVault Test Configuration
Shared fixtures and configuration for pytest
"""

import pytest
import asyncio
import os
import sys
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root / "src"))


@pytest.fixture(scope="session")
def event_loop():
    """Create an instance of the default event loop for each test case."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()


@pytest.fixture(scope="session")
def test_config():
    """Test configuration fixture."""
    return {
        "database_url": "sqlite:///:memory:",
        "redis_url": "redis://localhost:6379/15",
        "encryption_key": "test_encryption_key_32_bytes_long!!",
        "log_level": "DEBUG",
    }


@pytest.fixture(scope="session")
def test_data_dir():
    """Test data directory fixture."""
    data_dir = project_root / "tests" / "fixtures"
    data_dir.mkdir(exist_ok=True)
    return data_dir


@pytest.fixture
def mock_redis():
    """Mock Redis client for testing."""
    class MockRedis:
        def __init__(self):
            self.data = {}
        
        async def get(self, key):
            return self.data.get(key)
        
        async def set(self, key, value, ex=None):
            self.data[key] = value
            return True
        
        async def delete(self, key):
            if key in self.data:
                del self.data[key]
                return 1
            return 0
        
        async def ping(self):
            return True
    
    return MockRedis()


@pytest.fixture
def mock_database():
    """Mock database for testing."""
    return {
        "credentials": [],
        "devices": [],
        "sessions": [],
        "audit_logs": [],
    }


# Test markers
def pytest_configure(config):
    """Register custom markers."""
    config.addinivalue_line("markers", "slow: mark test as slow running")
    config.addinivalue_line("markers", "integration: mark test as integration test")
    config.addinivalue_line("markers", "security: mark test as security test")
    config.addinivalue_line("markers", "performance: mark test as performance test")


# Skip slow tests by default
def pytest_collection_modifyitems(config, items):
    """Skip slow tests unless explicitly requested."""
    if config.getoption("-m") != "slow":
        skip_slow = pytest.mark.skip(reason="need -m slow option to run")
        for item in items:
            if "slow" in item.keywords:
                item.add_marker(skip_slow)