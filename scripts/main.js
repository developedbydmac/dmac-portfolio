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

// Magical effects and animations
class MagicalEffects {
  static initTypingEffect() {
    const heroTitle = document.querySelector('.hero h1');
    if (!heroTitle) return;

    const originalText = heroTitle.textContent;
    heroTitle.textContent = '';
    
    let index = 0;
    const typeSpeed = 100;
    
    function typeWriter() {
      if (index < originalText.length) {
        heroTitle.textContent += originalText.charAt(index);
        index++;
        setTimeout(typeWriter, typeSpeed);
      } else {
        // Add blinking cursor
        heroTitle.innerHTML += '<span class="cursor">|</span>';
      }
    }
    
    // Start typing after a short delay
    setTimeout(typeWriter, 1000);
  }

  static createFloatingOrbs() {
    const orbContainer = document.createElement('div');
    orbContainer.className = 'floating-orbs';
    document.body.appendChild(orbContainer);

    for (let i = 0; i < 8; i++) {
      const orb = document.createElement('div');
      orb.className = 'floating-orb';
      orb.style.left = Math.random() * 100 + '%';
      orb.style.animationDelay = Math.random() * 10 + 's';
      orb.style.animationDuration = (Math.random() * 10 + 10) + 's';
      orbContainer.appendChild(orb);
    }
  }

  static initScrollAnimations() {
    const observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add('animate-in');
        }
      });
    }, { threshold: 0.1 });

    document.querySelectorAll('.card, .timeline-item, .about-me, .testimonial').forEach(el => {
      observer.observe(el);
    });
  }

  static createSparkleEffect(element) {
    const sparkle = document.createElement('div');
    sparkle.className = 'sparkle';
    sparkle.style.left = Math.random() * element.offsetWidth + 'px';
    sparkle.style.top = Math.random() * element.offsetHeight + 'px';
    element.appendChild(sparkle);

    setTimeout(() => {
      sparkle.remove();
    }, 1000);
  }

  static initCardSparkles() {
    document.querySelectorAll('.card').forEach(card => {
      card.addEventListener('mouseenter', () => {
        for (let i = 0; i < 5; i++) {
          setTimeout(() => {
            this.createSparkleEffect(card);
          }, i * 100);
        }
      });
    });
  }

  static createMouseTrail() {
    const trail = [];
    const trailLength = 8;

    document.addEventListener('mousemove', (e) => {
      trail.push({ x: e.clientX, y: e.clientY });
      if (trail.length > trailLength) {
        trail.shift();
      }

      const existingTrails = document.querySelectorAll('.mouse-trail');
      existingTrails.forEach(t => t.remove());

      trail.forEach((point, index) => {
        const trailDot = document.createElement('div');
        trailDot.className = 'mouse-trail';
        trailDot.style.left = point.x + 'px';
        trailDot.style.top = point.y + 'px';
        trailDot.style.opacity = (index + 1) / trailLength;
        trailDot.style.transform = `scale(${(index + 1) / trailLength})`;
        document.body.appendChild(trailDot);

        setTimeout(() => trailDot.remove(), 500);
      });
    });
  }
}

// Initialize all magical effects when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
  setTimeout(() => {
    MagicalEffects.initTypingEffect();
    MagicalEffects.createFloatingOrbs();
    MagicalEffects.initScrollAnimations();
    MagicalEffects.initCardSparkles();
    MagicalEffects.createMouseTrail();
  }, 500);
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