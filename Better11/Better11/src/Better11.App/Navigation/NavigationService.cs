// ============================================================================
// File: src/Better11.App/Navigation/NavigationService.cs
// Better11 System Enhancement Suite
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using Better11.Core.Interfaces;
using Microsoft.UI.Xaml.Controls;

namespace Better11.App.Navigation
{
    /// <summary>
    /// Implements frame-based navigation for the WinUI 3 shell.
    /// </summary>
    public sealed class NavigationService : INavigationService
    {
        private readonly Dictionary<string, Type> _pageMap = new();
        private Frame? _frame;

        /// <inheritdoc/>
        public Type? CurrentPage => _frame?.CurrentSourcePageType;

        /// <inheritdoc/>
        public bool CanGoBack => _frame?.CanGoBack ?? false;

        /// <inheritdoc/>
        public event EventHandler<Type>? Navigated;

        /// <summary>Sets the navigation frame.</summary>
        /// <param name="frame">The frame to navigate in.</param>
        public void SetFrame(Frame frame)
        {
            _frame = frame ?? throw new ArgumentNullException(nameof(frame));
            _frame.Navigated += (s, e) => Navigated?.Invoke(this, e.SourcePageType);
        }

        /// <summary>Registers a page type with a key.</summary>
        /// <param name="key">The page key.</param>
        /// <param name="pageType">The page type.</param>
        public void RegisterPage(string key, Type pageType)
        {
            _pageMap[key] = pageType;
        }

        /// <inheritdoc/>
        public bool NavigateTo(Type pageType, object? parameter = null)
        {
            if (_frame is null || _frame.CurrentSourcePageType == pageType)
            {
                return false;
            }

            return _frame.Navigate(pageType, parameter);
        }

        /// <inheritdoc/>
        public bool NavigateTo(string pageKey, object? parameter = null)
        {
            if (_pageMap.TryGetValue(pageKey, out var pageType))
            {
                return NavigateTo(pageType, parameter);
            }

            return false;
        }

        /// <inheritdoc/>
        public void GoBack()
        {
            if (_frame?.CanGoBack == true)
            {
                _frame.GoBack();
            }
        }
    }
}
