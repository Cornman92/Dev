using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Better11.Core.Interfaces;
using Better11.Core.Models;
using Better11.Core.Services;
using Microsoft.Extensions.Logging;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Moq;

namespace Better11.Tests.Services
{
    [TestClass]
    public class PowerShellServiceTests
    {
        private Mock<ILogger<PowerShellService>> _mockLogger;
        private PowerShellService _service;

        [TestInitialize]
        public void Initialize()
        {
            _mockLogger = new Mock<ILogger<PowerShellService>>();
            _service = new PowerShellService(_mockLogger.Object);
        }

        [TestCleanup]
        public void Cleanup()
        {
            _service?.Dispose();
        }

        #region Initialization Tests

        [TestMethod]
        public async Task InitializeAsync_ShouldSucceed_WhenCalledFirstTime()
        {
            // Act
            var result = await _service.InitializeAsync();

            // Assert
            Assert.IsTrue(result.IsSuccess, "Initialization should succeed");
            Assert.IsFalse(string.IsNullOrEmpty(result.Message));
        }

        [TestMethod]
        public async Task InitializeAsync_ShouldReturnSuccess_WhenCalledMultipleTimes()
        {
            // Act
            var result1 = await _service.InitializeAsync();
            var result2 = await _service.InitializeAsync();

            // Assert
            Assert.IsTrue(result1.IsSuccess, "First initialization should succeed");
            Assert.IsTrue(result2.IsSuccess, "Second initialization should succeed");
        }

        [TestMethod]
        public async Task InitializeAsync_ShouldBeThreadSafe()
        {
            // Arrange
            var tasks = new List<Task<r>>();

            // Act
            for (int i = 0; i < 10; i++)
            {
                tasks.Add(_service.InitializeAsync());
            }

            var results = await Task.WhenAll(tasks);

            // Assert
            Assert.IsTrue(results.All(r => r.IsSuccess), "All initialization attempts should succeed");
        }

        #endregion

        #region Script Execution Tests

        [TestMethod]
        public async Task ExecuteScriptAsync_ShouldSucceed_WithSimpleScript()
        {
            // Arrange
            await _service.InitializeAsync();
            var script = "Write-Output 'Hello, World!'";

            // Act
            var result = await _service.ExecuteScriptAsync(script);

            // Assert
            Assert.IsTrue(result.IsSuccess, "Script execution should succeed");
            Assert.IsNotNull(result.Value, "Result value should not be null");
            Assert.IsTrue(result.Value.Success, "PowerShell result should be successful");
            Assert.IsTrue(result.Value.HasOutput, "Should have output");
            Assert.AreEqual("Hello, World!", result.Value.FirstOutput?.ToString());
        }

        [TestMethod]
        public async Task ExecuteScriptAsync_ShouldFail_WithNullScript()
        {
            // Arrange
            await _service.InitializeAsync();

            // Act
            var result = await _service.ExecuteScriptAsync(null);

            // Assert
            Assert.IsFalse(result.IsSuccess, "Should fail with null script");
            Assert.IsNull(result.Value, "Value should be null on failure");
        }

        [TestMethod]
        public async Task ExecuteScriptAsync_ShouldFail_WithEmptyScript()
        {
            // Arrange
            await _service.InitializeAsync();

            // Act
            var result = await _service.ExecuteScriptAsync(string.Empty);

            // Assert
            Assert.IsFalse(result.IsSuccess, "Should fail with empty script");
        }

        [TestMethod]
        public async Task ExecuteScriptAsync_ShouldHandleParameters_Correctly()
        {
            // Arrange
            await _service.InitializeAsync();
            var script = "param($Name, $Age) Write-Output \"$Name is $Age years old\"";
            var parameters = new Dictionary<string, object>
            {
                { "Name", "John" },
                { "Age", 30 }
            };

            // Act
            var result = await _service.ExecuteScriptAsync(script, parameters);

            // Assert
            Assert.IsTrue(result.IsSuccess, "Script execution should succeed");
            Assert.IsTrue(result.Value.Success, "PowerShell result should be successful");
            Assert.IsTrue(result.Value.HasOutput, "Should have output");
            Assert.AreEqual("John is 30 years old", result.Value.FirstOutput?.ToString());
        }

        [TestMethod]
        public async Task ExecuteScriptAsync_ShouldCaptureErrors_WhenScriptFails()
        {
            // Arrange
            await _service.InitializeAsync();
            var script = "Get-Item 'C:\\NonExistentFile12345.txt' -ErrorAction Stop";

            // Act
            var result = await _service.ExecuteScriptAsync(script);

            // Assert
            Assert.IsTrue(result.IsSuccess, "Execution should complete (even with PS errors)");
            Assert.IsFalse(result.Value.Success, "PowerShell result should indicate failure");
            Assert.IsTrue(result.Value.HasErrors, "Should have errors");
            Assert.IsTrue(result.Value.Errors.Count > 0, "Error count should be greater than 0");
        }

        [TestMethod]
        public async Task ExecuteScriptAsync_ShouldCaptureWarnings()
        {
            // Arrange
            await _service.InitializeAsync();
            var script = "Write-Warning 'This is a test warning'";

            // Act
            var result = await _service.ExecuteScriptAsync(script);

            // Assert
            Assert.IsTrue(result.IsSuccess, "Script execution should succeed");
            Assert.IsTrue(result.Value.HasWarnings, "Should have warnings");
            Assert.IsTrue(result.Value.Warnings.Any(w => w.Contains("test warning")));
        }

        [TestMethod]
        public async Task ExecuteScriptAsync_ShouldSupportCancellation()
        {
            // Arrange
            await _service.InitializeAsync();
            var script = "Start-Sleep -Seconds 10; Write-Output 'Done'";
            var cts = new CancellationTokenSource();

            // Act
            var task = _service.ExecuteScriptAsync(script, null, cts.Token);
            await Task.Delay(100); // Let it start
            cts.Cancel();
            var result = await task;

            // Assert
            Assert.IsFalse(result.IsSuccess, "Should fail when cancelled");
            Assert.IsTrue(result.Message.Contains("cancel", StringComparison.OrdinalIgnoreCase));
        }

        [TestMethod]
        public async Task ExecuteScriptAsync_ShouldTrackExecutionTime()
        {
            // Arrange
            await _service.InitializeAsync();
            var script = "Start-Sleep -Milliseconds 100; Write-Output 'Done'";

            // Act
            var result = await _service.ExecuteScriptAsync(script);

            // Assert
            Assert.IsTrue(result.IsSuccess, "Script execution should succeed");
            Assert.IsTrue(result.Value.ExecutionTime.TotalMilliseconds >= 100, 
                "Execution time should be at least 100ms");
        }

        [TestMethod]
        public async Task ExecuteScriptAsync_ShouldHandleMultipleOutputObjects()
        {
            // Arrange
            await _service.InitializeAsync();
            var script = "1..10 | ForEach-Object { Write-Output $_ }";

            // Act
            var result = await _service.ExecuteScriptAsync(script);

            // Assert
            Assert.IsTrue(result.IsSuccess, "Script execution should succeed");
            Assert.IsTrue(result.Value.Success, "PowerShell result should be successful");
            Assert.AreEqual(10, result.Value.Output.Count, "Should have 10 output items");
        }

        #endregion

        #region Command Execution Tests

        [TestMethod]
        public async Task ExecuteCommandAsync_ShouldSucceed_WithSimpleCommand()
        {
            // Arrange
            await _service.InitializeAsync();
            var command = "Get-Date";

            // Act
            var result = await _service.ExecuteCommandAsync(command);

            // Assert
            Assert.IsTrue(result.IsSuccess, "Command execution should succeed");
            Assert.IsTrue(result.Value.Success, "PowerShell result should be successful");
            Assert.IsTrue(result.Value.HasOutput, "Should have output");
            Assert.IsInstanceOfType(result.Value.FirstOutput, typeof(DateTime));
        }

        [TestMethod]
        public async Task ExecuteCommandAsync_ShouldFail_WithNullCommand()
        {
            // Arrange
            await _service.InitializeAsync();

            // Act
            var result = await _service.ExecuteCommandAsync(null);

            // Assert
            Assert.IsFalse(result.IsSuccess, "Should fail with null command");
        }

        [TestMethod]
        public async Task ExecuteCommandAsync_ShouldHandleParameters()
        {
            // Arrange
            await _service.InitializeAsync();
            var command = "Get-ChildItem";
            var parameters = new Dictionary<string, object>
            {
                { "Path", "C:\\Windows" },
                { "Filter", "*.exe" }
            };

            // Act
            var result = await _service.ExecuteCommandAsync(command, parameters);

            // Assert
            Assert.IsTrue(result.IsSuccess, "Command execution should succeed");
            Assert.IsTrue(result.Value.Success, "PowerShell result should be successful");
        }

        [TestMethod]
        public async Task ExecuteCommandAsync_ShouldFail_WithInvalidCommand()
        {
            // Arrange
            await _service.InitializeAsync();
            var command = "NonExistentCommand12345";

            // Act
            var result = await _service.ExecuteCommandAsync(command);

            // Assert
            Assert.IsTrue(result.IsSuccess, "Execution should complete");
            Assert.IsFalse(result.Value.Success, "PowerShell result should indicate failure");
            Assert.IsTrue(result.Value.HasErrors, "Should have errors");
        }

        #endregion

        #region File Execution Tests

        [TestMethod]
        public async Task ExecuteFileAsync_ShouldFail_WithNonExistentFile()
        {
            // Arrange
            await _service.InitializeAsync();
            var filePath = "C:\\NonExistent\\Script12345.ps1";

            // Act
            var result = await _service.ExecuteFileAsync(filePath);

            // Assert
            Assert.IsFalse(result.IsSuccess, "Should fail with non-existent file");
            Assert.IsTrue(result.Message.Contains("not found", StringComparison.OrdinalIgnoreCase));
        }

        [TestMethod]
        public async Task ExecuteFileAsync_ShouldFail_WithNullPath()
        {
            // Arrange
            await _service.InitializeAsync();

            // Act
            var result = await _service.ExecuteFileAsync(null);

            // Assert
            Assert.IsFalse(result.IsSuccess, "Should fail with null path");
        }

        #endregion

        #region Module Management Tests

        [TestMethod]
        public async Task ImportModuleAsync_ShouldSucceed_WithValidModule()
        {
            // Arrange
            await _service.InitializeAsync();
            var moduleName = "Microsoft.PowerShell.Management";

            // Act
            var result = await _service.ImportModuleAsync(moduleName);

            // Assert
            Assert.IsTrue(result.IsSuccess, "Module import should succeed");
            Assert.IsNotNull(result.Value, "Module info should not be null");
            Assert.AreEqual(moduleName, result.Value.Name);
            Assert.IsTrue(result.Value.HasCommands, "Module should have commands");
        }

        [TestMethod]
        public async Task ImportModuleAsync_ShouldFail_WithNullModule()
        {
            // Arrange
            await _service.InitializeAsync();

            // Act
            var result = await _service.ImportModuleAsync(null);

            // Assert
            Assert.IsFalse(result.IsSuccess, "Should fail with null module");
        }

        [TestMethod]
        public async Task ImportModuleAsync_ShouldReturnExisting_WhenModuleAlreadyLoaded()
        {
            // Arrange
            await _service.InitializeAsync();
            var moduleName = "Microsoft.PowerShell.Utility";

            // Act
            var result1 = await _service.ImportModuleAsync(moduleName);
            var result2 = await _service.ImportModuleAsync(moduleName);

            // Assert
            Assert.IsTrue(result1.IsSuccess, "First import should succeed");
            Assert.IsTrue(result2.IsSuccess, "Second import should succeed");
            Assert.AreEqual(result1.Value.Name, result2.Value.Name);
        }

        [TestMethod]
        public async Task RemoveModuleAsync_ShouldSucceed_WithLoadedModule()
        {
            // Arrange
            await _service.InitializeAsync();
            var moduleName = "Microsoft.PowerShell.Management";
            await _service.ImportModuleAsync(moduleName);

            // Act
            var result = await _service.RemoveModuleAsync(moduleName);

            // Assert
            Assert.IsTrue(result.IsSuccess, "Module removal should succeed");
        }

        [TestMethod]
        public async Task RemoveModuleAsync_ShouldFail_WithNullModule()
        {
            // Arrange
            await _service.InitializeAsync();

            // Act
            var result = await _service.RemoveModuleAsync(null);

            // Assert
            Assert.IsFalse(result.IsSuccess, "Should fail with null module");
        }

        [TestMethod]
        public async Task GetLoadedModulesAsync_ShouldReturnList()
        {
            // Arrange
            await _service.InitializeAsync();
            await _service.ImportModuleAsync("Microsoft.PowerShell.Management");
            await _service.ImportModuleAsync("Microsoft.PowerShell.Utility");

            // Act
            var result = await _service.GetLoadedModulesAsync();

            // Assert
            Assert.IsTrue(result.IsSuccess, "Should succeed");
            Assert.IsNotNull(result.Value, "List should not be null");
            Assert.IsTrue(result.Value.Count >= 2, "Should have at least 2 modules");
        }

        #endregion

        #region Utility Tests

        [TestMethod]
        public async Task TestCommandExistsAsync_ShouldReturnTrue_ForExistingCommand()
        {
            // Arrange
            await _service.InitializeAsync();

            // Act
            var result = await _service.TestCommandExistsAsync("Get-Process");

            // Assert
            Assert.IsTrue(result.IsSuccess, "Test should succeed");
            Assert.IsTrue(result.Value, "Command should exist");
        }

        [TestMethod]
        public async Task TestCommandExistsAsync_ShouldReturnFalse_ForNonExistentCommand()
        {
            // Arrange
            await _service.InitializeAsync();

            // Act
            var result = await _service.TestCommandExistsAsync("NonExistentCommand12345");

            // Assert
            Assert.IsTrue(result.IsSuccess, "Test should succeed");
            Assert.IsFalse(result.Value, "Command should not exist");
        }

        [TestMethod]
        public async Task TestCommandExistsAsync_ShouldFail_WithNullCommand()
        {
            // Arrange
            await _service.InitializeAsync();

            // Act
            var result = await _service.TestCommandExistsAsync(null);

            // Assert
            Assert.IsFalse(result.IsSuccess, "Should fail with null command");
        }

        [TestMethod]
        public async Task GetActiveExecutionsAsync_ShouldReturnEmpty_WhenNoExecutions()
        {
            // Arrange
            await _service.InitializeAsync();

            // Act
            var result = await _service.GetActiveExecutionsAsync();

            // Assert
            Assert.IsTrue(result.IsSuccess, "Should succeed");
            Assert.IsNotNull(result.Value, "Dictionary should not be null");
            Assert.AreEqual(0, result.Value.Count, "Should have no active executions");
        }

        [TestMethod]
        public async Task CancelExecutionAsync_ShouldFail_WithNonExistentId()
        {
            // Arrange
            await _service.InitializeAsync();
            var nonExistentId = Guid.NewGuid();

            // Act
            var result = await _service.CancelExecutionAsync(nonExistentId);

            // Assert
            Assert.IsFalse(result.IsSuccess, "Should fail with non-existent ID");
            Assert.IsTrue(result.Message.Contains("not found", StringComparison.OrdinalIgnoreCase));
        }

        #endregion

        #region Stress and Performance Tests

        [TestMethod]
        public async Task ExecuteScriptAsync_ShouldHandleMultipleConcurrentExecutions()
        {
            // Arrange
            await _service.InitializeAsync();
            var tasks = new List<Task<Result<PowerShellResult>>>();
            var script = "Write-Output 'Concurrent Test'";

            // Act
            for (int i = 0; i < 10; i++)
            {
                tasks.Add(_service.ExecuteScriptAsync(script));
            }

            var results = await Task.WhenAll(tasks);

            // Assert
            Assert.IsTrue(results.All(r => r.IsSuccess), "All executions should succeed");
            Assert.IsTrue(results.All(r => r.Value.Success), "All PowerShell results should be successful");
        }

        [TestMethod]
        public async Task ExecuteScriptAsync_ShouldHandleLargeOutput()
        {
            // Arrange
            await _service.InitializeAsync();
            var script = "1..1000 | ForEach-Object { Write-Output $_ }";

            // Act
            var result = await _service.ExecuteScriptAsync(script);

            // Assert
            Assert.IsTrue(result.IsSuccess, "Script execution should succeed");
            Assert.AreEqual(1000, result.Value.Output.Count, "Should have 1000 output items");
        }

        #endregion

        #region Disposal Tests

        [TestMethod]
        public void Dispose_ShouldCleanupResources()
        {
            // Arrange
            var service = new PowerShellService(_mockLogger.Object);
            var initTask = service.InitializeAsync();
            initTask.Wait();

            // Act
            service.Dispose();

            // Assert - No exception should be thrown
            Assert.IsTrue(true, "Disposal should complete without exceptions");
        }

        [TestMethod]
        public void Dispose_ShouldBeIdempotent()
        {
            // Arrange
            var service = new PowerShellService(_mockLogger.Object);

            // Act
            service.Dispose();
            service.Dispose(); // Second disposal

            // Assert - No exception should be thrown
            Assert.IsTrue(true, "Multiple disposals should not throw exceptions");
        }

        #endregion
    }
}
