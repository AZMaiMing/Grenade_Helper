document.addEventListener('DOMContentLoaded', () => {
    // Theme Toggle
    const themeToggleBtn = document.getElementById('theme-toggle');
    if (themeToggleBtn) {
        const themeIcon = themeToggleBtn.querySelector('span');

        // Check local storage or system preference
        const savedTheme = localStorage.getItem('theme');
        const systemPrefersLight = window.matchMedia('(prefers-color-scheme: light)').matches;

        let currentTheme = savedTheme || (systemPrefersLight ? 'light' : 'dark');

        // Apply initial theme
        document.documentElement.setAttribute('data-theme', currentTheme);
        updateIcon(currentTheme);

        themeToggleBtn.addEventListener('click', () => {
            // Toggle theme
            currentTheme = currentTheme === 'dark' ? 'light' : 'dark';

            // Update DOM
            document.documentElement.setAttribute('data-theme', currentTheme);

            // Save to local storage
            localStorage.setItem('theme', currentTheme);

            // Update Icon
            updateIcon(currentTheme);
        });

        function updateIcon(theme) {
            // Simple text-based icon switch. Can be replaced with SVG or FontAwesome later.
            themeIcon.textContent = theme === 'dark' ? '🌙' : '☀️';
        }
    }

    // Documentation Tab Switching
    const tabLinks = document.querySelectorAll('.tab-link');
    const tabPanels = document.querySelectorAll('.tab-panel');

    if (tabLinks.length > 0 && tabPanels.length > 0) {
        // Check URL hash on load
        const hash = window.location.hash.substring(1);
        if (hash) {
            switchToTab(hash);
        }

        tabLinks.forEach(link => {
            link.addEventListener('click', (e) => {
                e.preventDefault();
                const tabId = link.getAttribute('data-tab');
                switchToTab(tabId);
                // Update URL hash without scrolling
                history.pushState(null, null, `#${tabId}`);
            });
        });

        function switchToTab(tabId) {
            // Remove active class from all links and panels
            tabLinks.forEach(l => l.classList.remove('active'));
            tabPanels.forEach(p => p.classList.remove('active'));

            // Add active class to clicked link and corresponding panel
            const activeLink = document.querySelector(`.tab-link[data-tab="${tabId}"]`);
            const activePanel = document.getElementById(tabId);

            if (activeLink) activeLink.classList.add('active');
            if (activePanel) activePanel.classList.add('active');
        }

        // Handle browser back/forward
        window.addEventListener('popstate', () => {
            const hash = window.location.hash.substring(1);
            if (hash) {
                switchToTab(hash);
            }
        });
    }
});
