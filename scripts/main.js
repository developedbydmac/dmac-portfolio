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

// Enhanced Portfolio App with Azure integration
class PortfolioApp {
    constructor() {
        this.apiBase = '/api';
        this.visitCount = 0;
    }

    async init() {
        await this.loadComponents();
        this.setupEventListeners();
        await this.updateVisitCount();
        this.setupContactForm();
        this.setupSmoothScrolling();
        this.setupThemeToggle();
        this.initMagicalEffects();
    }

    async loadComponents() {
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
            
            console.log('Components loaded successfully');
        } catch (error) {
            console.error('Error loading components:', error);
        }
    }

    setupEventListeners() {
        // Mobile menu toggle
        const mobileMenuBtn = document.querySelector('.mobile-menu-btn');
        const navMenu = document.querySelector('.nav-menu');
        
        if (mobileMenuBtn && navMenu) {
            mobileMenuBtn.addEventListener('click', () => {
                navMenu.classList.toggle('active');
            });
        }

        // Close mobile menu when clicking outside
        document.addEventListener('click', (e) => {
            if (!e.target.closest('.nav-container')) {
                navMenu?.classList.remove('active');
            }
        });

        // Intersection Observer for animations
        this.setupScrollAnimations();
    }

    async updateVisitCount() {
        try {
            const response = await fetch(`${this.apiBase}/visits`, {
                method: 'GET',
                headers: {
                    'Accept': 'application/json',
                }
            });

            if (response.ok) {
                const data = await response.json();
                this.visitCount = data.visitCount || 0;
                this.displayVisitCount(data);
            }
        } catch (error) {
            console.warn('Visit count unavailable:', error.message);
            // Fallback to localStorage for offline tracking
            this.handleOfflineVisitCount();
        }
    }

    displayVisitCount(data) {
        const visitCountElement = document.getElementById('visit-count');
        if (visitCountElement && data.visitCount) {
            visitCountElement.innerHTML = `
                <div class="visit-counter">
                    <span class="counter-icon">👥</span>
                    <span class="counter-text">Visitor #${data.visitCount.toLocaleString()}</span>
                    <span class="counter-message">${data.message || 'Thanks for visiting!'}</span>
                </div>
            `;
            visitCountElement.classList.add('animate-fade-in');
        }
    }

    handleOfflineVisitCount() {
        const localCount = localStorage.getItem('portfolio-visits') || '0';
        const newCount = parseInt(localCount) + 1;
        localStorage.setItem('portfolio-visits', newCount.toString());
        
        const visitCountElement = document.getElementById('visit-count');
        if (visitCountElement) {
            visitCountElement.innerHTML = `
                <div class="visit-counter offline">
                    <span class="counter-icon">📱</span>
                    <span class="counter-text">Visit #${newCount} (Offline)</span>
                </div>
            `;
        }
    }

    setupContactForm() {
        const contactForm = document.getElementById('contact-form');
        if (!contactForm) return;

        contactForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            await this.handleContactSubmission(contactForm);
        });
    }

    async handleContactSubmission(form) {
        const submitBtn = form.querySelector('button[type="submit"]');
        const originalText = submitBtn.textContent;
        const formData = new FormData(form);
        
        // Create loading state
        submitBtn.disabled = true;
        submitBtn.textContent = 'Sending...';
        submitBtn.classList.add('loading');

        try {
            const response = await fetch(`${this.apiBase}/contact`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    name: formData.get('name'),
                    email: formData.get('email'),
                    subject: formData.get('subject'),
                    message: formData.get('message')
                })
            });

            const result = await response.json();

            if (response.ok) {
                this.showNotification('Message sent successfully! I\'ll get back to you soon.', 'success');
                form.reset();
                
                // Track successful form submission
                if (typeof gtag !== 'undefined') {
                    gtag('event', 'form_submit', {
                        event_category: 'Contact',
                        event_label: 'Success'
                    });
                }
            } else {
                throw new Error(result.message || 'Failed to send message');
            }
        } catch (error) {
            console.error('Contact form error:', error);
            this.showNotification(
                error.message || 'Failed to send message. Please try again or email me directly.', 
                'error'
            );
            
            // Track form submission error
            if (typeof gtag !== 'undefined') {
                gtag('event', 'form_error', {
                    event_category: 'Contact',
                    event_label: error.message
                });
            }
        } finally {
            submitBtn.disabled = false;
            submitBtn.textContent = originalText;
            submitBtn.classList.remove('loading');
        }
    }

    showNotification(message, type = 'info') {
        // Remove existing notifications
        const existingNotifications = document.querySelectorAll('.notification');
        existingNotifications.forEach(n => n.remove());

        // Create new notification
        const notification = document.createElement('div');
        notification.className = `notification notification-${type}`;
        notification.innerHTML = `
            <div class="notification-content">
                <span class="notification-icon">${type === 'success' ? '✅' : type === 'error' ? '❌' : 'ℹ️'}</span>
                <span class="notification-message">${message}</span>
                <button class="notification-close" onclick="this.parentElement.parentElement.remove()">×</button>
            </div>
        `;

        // Add to page
        document.body.appendChild(notification);

        // Auto-remove after 5 seconds
        setTimeout(() => {
            if (document.body.contains(notification)) {
                notification.classList.add('fade-out');
                setTimeout(() => notification.remove(), 300);
            }
        }, 5000);
    }

    setupSmoothScrolling() {
        // Smooth scrolling for anchor links
        document.querySelectorAll('a[href^="#"]').forEach(anchor => {
            anchor.addEventListener('click', function (e) {
                e.preventDefault();
                const target = document.querySelector(this.getAttribute('href'));
                if (target) {
                    target.scrollIntoView({
                        behavior: 'smooth',
                        block: 'start'
                    });
                }
            });
        });
    }

    setupScrollAnimations() {
        const observerOptions = {
            threshold: 0.1,
            rootMargin: '0px 0px -50px 0px'
        };

        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.classList.add('animate-in');
                }
            });
        }, observerOptions);

        // Observe elements for animation
        document.querySelectorAll('.animate-on-scroll').forEach(el => {
            observer.observe(el);
        });
    }

    setupThemeToggle() {
        const themeToggle = document.getElementById('theme-toggle');
        if (!themeToggle) return;

        // Check for saved theme preference
        const savedTheme = localStorage.getItem('theme') || 'light';
        document.documentElement.setAttribute('data-theme', savedTheme);
        
        themeToggle.addEventListener('click', () => {
            const currentTheme = document.documentElement.getAttribute('data-theme');
            const newTheme = currentTheme === 'dark' ? 'light' : 'dark';
            
            document.documentElement.setAttribute('data-theme', newTheme);
            localStorage.setItem('theme', newTheme);
            
            // Track theme change
            if (typeof gtag !== 'undefined') {
                gtag('event', 'theme_change', {
                    event_category: 'UI',
                    event_label: newTheme
                });
            }
        });
    }

    initMagicalEffects() {
        this.initTypingEffect();
        this.createFloatingOrbs();
        this.initScrollAnimations();
    }

    initTypingEffect() {
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

    createFloatingOrbs() {
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

    initScrollAnimations() {
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

    // Utility method for tracking page views
    trackPageView(pageName) {
        if (typeof gtag !== 'undefined') {
            gtag('config', 'GA_MEASUREMENT_ID', {
                page_title: pageName,
                page_location: window.location.href
            });
        }
    }

    // Method to track custom events
    trackEvent(action, category, label = '') {
        if (typeof gtag !== 'undefined') {
            gtag('event', action, {
                event_category: category,
                event_label: label
            });
        }
    }
}

// Initialize the portfolio app when DOM is loaded
document.addEventListener('DOMContentLoaded', async () => {
    console.log('Initializing Portfolio App...');
    
    const app = new PortfolioApp();
    await app.init();
    
    // Make app globally available for debugging
    window.portfolioApp = app;
    
    // Track initial page load
    app.trackPageView(document.title);
    
    console.log('Portfolio App initialized successfully');
});

// Handle page visibility changes for analytics
document.addEventListener('visibilitychange', () => {
    if (typeof gtag !== 'undefined') {
        gtag('event', document.hidden ? 'page_hide' : 'page_show', {
            event_category: 'Engagement'
        });
    }
});

// Export for module systems
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { PortfolioApp, ComponentLoader };
}
    const sparkle = document.createElement('div');
    sparkle.className = 'sparkle';
    sparkle.style.left = Math.random() * element.offsetWidth + 'px';
    sparkle.style.top = Math.random() * element.offsetHeight + 'px';
    element.appendChild(sparkle);

    setTimeout(() => {
      sparkle.remove();
    }, 1000);
