// Component loader for reusable HTML components
class ComponentLoader {
  static async loadComponent(componentName, targetSelector, basePath = '') {
    try {
      const componentPath = basePath ? `${basePath}/components/${componentName}.html` : `components/${componentName}.html`;
      const response = await fetch(componentPath);
      let html = await response.text();
      
      // Fix navigation links based on current location
      if (basePath && componentName === 'header') {
        html = html.replace(/href="index\.html"/g, 'href="../index.html"');
        html = html.replace(/href="resume\.html"/g, 'href="../resume.html"');
        html = html.replace(/href="projects\.html"/g, 'href="../projects.html"');
        html = html.replace(/href="blog\.html"/g, 'href="../blog.html"');
        html = html.replace(/src="assets\/images/g, 'src="../assets/images');
      }
      
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
  console.log('Loading components...');
  
  // Determine if we're in a subdirectory
  const isSubdirectory = window.location.pathname.includes('/experience/');
  const basePath = isSubdirectory ? '..' : '';
  
  try {
    await ComponentLoader.loadMultipleComponents([
      { name: 'header', selector: '#header-placeholder' },
      { name: 'footer', selector: '#footer-placeholder' },
      { name: 'contact', selector: '#contact-placeholder' },
      { name: 'music', selector: '#music-placeholder' }
    ], basePath);
    
    console.log('All components loaded successfully');
  } catch (error) {
    console.error('Error loading components:', error);
  }
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