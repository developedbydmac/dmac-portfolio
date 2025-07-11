// Component loader for reusable HTML components
class ComponentLoader {
  static async loadComponent(componentName, targetSelector, basePath = '') {
    try {
      const componentPath = basePath ? `${basePath}/components/${componentName}.html` : `components/${componentName}.html`;
      const response = await fetch(componentPath);
      const html = await response.text();
      const target = document.querySelector(targetSelector);
      if (target) {
        target.innerHTML = html;
      }
    } catch (error) {
      console.error(`Failed to load component ${componentName}:`, error);
    }
  }

  static async loadMultipleComponents(components, basePath = '') {
    const promises = components.map(({ name, selector }) => 
      this.loadComponent(name, selector, basePath)
    );
    await Promise.all(promises);
  }
}

// Auto-load common components when DOM is ready
document.addEventListener('DOMContentLoaded', async () => {
  // Determine if we're in a subdirectory
  const isSubdirectory = window.location.pathname.includes('/experience/');
  const basePath = isSubdirectory ? '..' : '';
  
  await ComponentLoader.loadMultipleComponents([
    { name: 'header', selector: '#header-placeholder' },
    { name: 'footer', selector: '#footer-placeholder' },
    { name: 'contact', selector: '#contact-placeholder' },
    { name: 'music', selector: '#music-placeholder' }
  ], basePath);
});

// Utility functions
const Utils = {
  // Smooth scroll to section
  scrollToSection(sectionId) {
    const element = document.getElementById(sectionId);
    if (element) {
      element.scrollIntoView({ behavior: 'smooth' });
    }
  },

  // Toggle mobile menu (if needed)
  toggleMobileMenu() {
    const nav = document.querySelector('nav');
    nav.classList.toggle('mobile-open');
  },

  // Load external content dynamically
  async loadExternalContent(url, targetSelector) {
    try {
      const response = await fetch(url);
      const html = await response.text();
      document.querySelector(targetSelector).innerHTML = html;
    } catch (error) {
      console.error('Failed to load external content:', error);
    }
  }
};