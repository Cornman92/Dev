"""Unit tests for unified-mcp-server."""

import pytest
from server.main import main


def test_main_exists() -> None:
    """Main entry point exists and is callable."""
    main()


def test_main_returns_none() -> None:
    """Main returns None (no return value)."""
    assert main() is None


def test_main_idempotent() -> None:
    """Main can be called multiple times without error."""
    main()
    main()


def test_server_module_importable() -> None:
    """Server package can be imported."""
    import server.main as m
    assert hasattr(m, 'main')
    assert callable(m.main)
