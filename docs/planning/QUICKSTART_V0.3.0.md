# Better11 v0.3.0 Development - Quick Start Guide

**For Developers**: This guide helps you get started with Better11 v0.3.0 development.

---

## 🚀 Quick Start (5 minutes)

### 1. Install Dependencies

```bash
# Clone repository (if not already)
git clone <repository-url>
cd better11

# Install Python dependencies
pip install -r requirements.txt
```

### 2. Run Existing Tests

```bash
# Run all tests
python3 -m pytest tests/ -v

# Expected: 31 tests passing from v0.2.0
```

### 3. Test New Infrastructure

```bash
# Test configuration system
python3 -m pytest tests/test_config.py -v

# Test interfaces
python3 -m pytest tests/test_interfaces.py -v

# Test base classes
python3 -m pytest tests/test_base_classes.py -v
```

### 4. Try Configuration System

```python
# Create and save a configuration
from better11.config import Config

config = Config()
config.better11.auto_update = False
config.applications.verify_signatures = True
config.save()  # Saves to ~/.better11/config.toml

# Load configuration
config = Config.load()
print(config.to_dict())
```

---

## 📚 What to Read First

### For Implementation Work

1. **[IMPLEMENTATION_PLAN_V0.3.0.md](IMPLEMENTATION_PLAN_V0.3.0.md)** (15 min)
   - Read Phases 1-2 for immediate work
   - Understand the 12-week timeline
   - Review API designs

2. **[better11/interfaces.py](better11/interfaces.py)** (5 min)
   - Understand Version, Updatable, Configurable interfaces
   - See how to implement these interfaces

3. **[system_tools/base.py](system_tools/base.py)** (10 min)
   - Understand SystemTool base class
   - See the execution flow
   - Learn safety check patterns

### For Planning & Architecture

1. **[ROADMAP_V0.3-V1.0.md](ROADMAP_V0.3-V1.0.md)** (30 min)
   - See all 20 proposed modules
   - Understand long-term vision
   - Review complexity estimates

2. **[SETUP_COMPLETE.md](SETUP_COMPLETE.md)** (10 min)
   - What's been created so far
   - Current progress status
   - Next steps

---

## 🎯 Pick Your First Task

### Easy (1-2 days)
- **Complete configuration tests**: Add YAML, env variable tests
- **Implement logging enhancements**: Set up structured logging
- **Add version commands**: CLI commands for version checking

### Medium (3-5 days)
- **Startup Manager implementation**: Enumerate startup programs
- **Windows Features basic operations**: List features using DISM
- **Privacy settings reading**: Read current telemetry level

### Hard (1-2 weeks)
- **Code signing verification**: PowerShell integration for signatures
- **Windows Update checking**: Use Windows Update API
- **Complete privacy manager**: All telemetry and app permissions

---

## 🏗️ Implementation Patterns

### Creating a New System Tool

```python
# 1. Inherit from SystemTool
from system_tools.base import SystemTool, ToolMetadata

class MyTool(SystemTool):
    
    # 2. Define metadata
    def get_metadata(self) -> ToolMetadata:
        return ToolMetadata(
            name="My Tool",
            description="Does something useful",
            version="0.3.0",
            requires_admin=True,
            category="optimization"
        )
    
    # 3. Validate environment
    def validate_environment(self) -> None:
        # Check prerequisites
        pass
    
    # 4. Implement functionality
    def execute(self) -> bool:
        # Do the work
        return True

# 5. Use it
tool = MyTool(config={'confirm_destructive_actions': True})
result = tool.run()
```

### Writing Tests

```python
# tests/test_my_tool.py
import pytest
from system_tools.my_tool import MyTool

class TestMyTool:
    def test_tool_creation(self):
        tool = MyTool()
        assert tool.dry_run is False
    
    def test_tool_metadata(self):
        tool = MyTool()
        metadata = tool.get_metadata()
        assert metadata.name == "My Tool"
    
    def test_tool_execution(self):
        tool = MyTool(dry_run=True)
        result = tool.run(skip_confirmation=True)
        assert result is True
```

---

## 📋 Development Workflow

### Daily Workflow

```bash
# 1. Update from main
git pull origin main

# 2. Create feature branch
git checkout -b feature/my-feature

# 3. Make changes
# ... code ...

# 4. Run tests
python3 -m pytest tests/ -v

# 5. Check code quality
black better11/ system_tools/ tests/
flake8 better11/ system_tools/

# 6. Commit
git add .
git commit -m "feat: Add my feature"

# 7. Push
git push origin feature/my-feature
```

### Before Creating PR

```bash
# Run full test suite
python3 -m pytest tests/ -v --cov=better11 --cov=system_tools

# Check all code quality
black --check better11/ system_tools/ tests/
flake8 better11/ system_tools/ tests/
mypy better11/ system_tools/
isort --check better11/ system_tools/ tests/

# Update CHANGELOG.md
# Update documentation
```

---

## 🧪 Testing Guidelines

### Test Structure

```
tests/
├── test_config.py              # Configuration tests
├── test_interfaces.py          # Interface tests
├── test_base_classes.py        # Base class tests
├── test_code_signing.py        # Code signing tests
├── test_new_system_tools.py    # System tool tests
└── ... (existing tests)
```

### Testing Best Practices

1. **Mock Windows APIs**: Use `pytest-mock` for Windows-specific calls
2. **Test dry-run mode**: Ensure tools work without making changes
3. **Test error handling**: Cover error cases
4. **Test configurations**: Verify config options work
5. **Integration tests**: Test tool workflows end-to-end

### Example Mock

```python
def test_windows_operation(mocker):
    # Mock Windows API
    mock_subprocess = mocker.patch('subprocess.run')
    mock_subprocess.return_value.returncode = 0
    
    # Test your code
    tool = MyTool()
    result = tool.execute()
    
    # Verify
    assert result is True
    mock_subprocess.assert_called_once()
```

---

## 🐛 Debugging Tips

### Enable Debug Logging

```python
import logging
logging.basicConfig(level=logging.DEBUG)

# Now all Better11 logging is verbose
```

### Test Single Module

```bash
# Test just one file
python3 -m pytest tests/test_config.py -v -s

# Test single function
python3 -m pytest tests/test_config.py::TestConfig::test_default_config_creation -v -s
```

### Use Dry-Run Mode

```python
# Test without making real changes
tool = MyTool(dry_run=True)
tool.run()  # Won't modify system
```

---

## 📖 Key Files Reference

### Configuration
- `better11/config.py` - Configuration system
- `better11/interfaces.py` - Common interfaces
- `system_tools/base.py` - Base classes

### Module Stubs (v0.3.0)
- `better11/apps/code_signing.py` - Code signing verification
- `system_tools/updates.py` - Windows Update management
- `system_tools/privacy.py` - Privacy controls
- `system_tools/startup.py` - Startup manager
- `system_tools/features.py` - Windows Features manager

### Tests
- `tests/test_config.py` - Config tests (11 tests)
- `tests/test_interfaces.py` - Interface tests (15+ tests)
- `tests/test_base_classes.py` - Base class tests (8 tests)
- `tests/test_code_signing.py` - Signing tests (10 tests)
- `tests/test_new_system_tools.py` - Tool tests (15+ tests)

---

## 🚦 Current Status

### ✅ Complete
- Planning documents
- Base classes and interfaces
- Configuration system
- Module stubs
- Test stubs
- Requirements

### 🏗️ In Progress
- None (ready to start!)

### 📋 Todo
- Implement code signing
- Implement Windows Update management
- Implement privacy controls
- Implement startup manager
- Implement Windows Features manager
- GUI enhancements
- CLI enhancements
- Documentation updates

---

## 🎓 Learning Resources

### Python Windows Programming
- [pywin32 Documentation](https://github.com/mhammond/pywin32)
- [Windows Registry in Python](https://docs.python.org/3/library/winreg.html)
- [subprocess Module](https://docs.python.org/3/library/subprocess.html)

### Windows APIs
- [Windows Update API](https://docs.microsoft.com/en-us/windows/win32/wua_sdk/)
- [Authenticode](https://docs.microsoft.com/en-us/windows/win32/seccrypto/)
- [DISM](https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/dism-reference)

### Testing
- [pytest Documentation](https://docs.pytest.org/)
- [pytest-mock](https://pytest-mock.readthedocs.io/)
- [pytest-cov](https://pytest-cov.readthedocs.io/)

---

## 💡 Tips for Success

1. **Start Small**: Pick one module, implement one function at a time
2. **Test First**: Write tests before implementation (TDD)
3. **Use Dry-Run**: Test without making real changes
4. **Follow Patterns**: Look at existing code for examples
5. **Ask Questions**: Review docs when unclear
6. **Commit Often**: Small, focused commits
7. **Document As You Go**: Update docstrings and docs

---

## 🆘 Common Issues

### Import Errors
```bash
# Solution: Install in development mode
pip install -e .
```

### Test Failures
```bash
# Solution: Check if running on Windows
# Many tests require Windows or proper mocking
```

### Configuration Not Found
```bash
# Solution: Create default config
python3 -c "from better11.config import Config; Config().save()"
```

---

## 📞 Getting Help

1. **Read the docs**: Most answers are in planning docs
2. **Check test examples**: Tests show how to use APIs
3. **Review existing code**: Similar patterns are already implemented
4. **ARCHITECTURE.md**: Explains design decisions

---

## 🎉 Ready to Start!

You now have everything you need to start developing Better11 v0.3.0. Pick a task from the implementation plan and start coding!

**Recommended First Task**: Complete the configuration system tests and implement the logging enhancements. This gives you familiarity with the codebase while adding value.

Good luck! 🚀

---

**Last Updated**: December 9, 2025  
**Next Review**: After Phase 1 completion
