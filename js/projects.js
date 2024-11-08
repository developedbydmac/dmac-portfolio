// projects.js
document.addEventListener('DOMContentLoaded', () => {
    // Initialize Variables
    const filterButtons = document.querySelectorAll('.filter-btn');
    const timelineItems = document.querySelectorAll('.timeline-item');
    const miniCards = document.querySelectorAll('.mini-card');
    
    // Scroll Animation for Timeline Items
    const observerOptions = {
        threshold: 0.2,
        rootMargin: '0px 0px -50px 0px'
    };

    const fadeInOnScroll = new IntersectionObserver((entries, observer) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.style.opacity = '1';
                entry.target.style.transform = 'translateY(0)';
                observer.unobserve(entry.target);
            }
        });
    }, observerOptions);

    // Apply observer to timeline items
    timelineItems.forEach(item => {
        item.style.opacity = '0';
        item.style.transform = 'translateY(20px)';
        fadeInOnScroll.observe(item);
    });

    // Project Preview Hover Effects
    document.querySelectorAll('.project-preview').forEach(preview => {
        preview.addEventListener('mouseenter', (e) => {
            const overlay = preview.querySelector('.preview-overlay');
            overlay.style.opacity = '1';
        });

        preview.addEventListener('mouseleave', (e) => {
            const overlay = preview.querySelector('.preview-overlay');
            overlay.style.opacity = '0';
        });
    });

    // Featured Project Scroll Effects
    const featuredProject = document.querySelector('.featured-project');
    if (featuredProject) {
        window.addEventListener('scroll', () => {
            const scrollPosition = window.scrollY;
            const opacity = Math.max(1 - scrollPosition / 500, 0.5);
            featuredProject.style.opacity = opacity;
        });
    }

    // Filter Functionality
    if (filterButtons) {
        filterButtons.forEach(button => {
            button.addEventListener('click', () => {
                // Remove active class from all buttons
                filterButtons.forEach(btn => btn.classList.remove('active'));
                // Add active class to clicked button
                button.classList.add('active');

                const filter = button.getAttribute('data-filter');
                filterProjects(filter);
            });
        });
    }

    function filterProjects(filter) {
        // Filter Timeline Items
        timelineItems.forEach(item => {
            if (filter === 'all' || item.getAttribute('data-category') === filter) {
                showElement(item);
            } else {
                hideElement(item);
            }
        });

        // Filter Mini Cards
        miniCards.forEach(card => {
            if (filter === 'all' || card.getAttribute('data-category') === filter) {
                showElement(card);
            } else {
                hideElement(card);
            }
        });
    }

    function showElement(element) {
        element.style.display = 'block';
        setTimeout(() => {
            element.style.opacity = '1';
            element.style.transform = 'translateY(0)';
        }, 50);
    }

    function hideElement(element) {
        element.style.opacity = '0';
        element.style.transform = 'translateY(20px)';
        setTimeout(() => {
            element.style.display = 'none';
        }, 300);
    }

    // Project Links Hover Animation
    document.querySelectorAll('.card-link, .project-link').forEach(link => {
        link.addEventListener('mouseenter', (e) => {
            link.style.transform = 'translateX(5px)';
        });

        link.addEventListener('mouseleave', (e) => {
            link.style.transform = 'translateX(0)';
        });
    });

    // Load More Projects Functionality (if needed)
    const loadMoreBtn = document.querySelector('.load-more');
    if (loadMoreBtn) {
        loadMoreBtn.addEventListener('click', () => {
            const hiddenProjects = document.querySelectorAll('.timeline-item.hidden');
            hiddenProjects.forEach((project, index) => {
                if (index < 3) { // Show 3 more projects at a time
                    setTimeout(() => {
                        project.classList.remove('hidden');
                        fadeInOnScroll.observe(project);
                    }, index * 200);
                }
            });

            // Hide button if no more projects
            if (hiddenProjects.length <= 3) {
                loadMoreBtn.style.display = 'none';
            }
        });
    }

    // Smooth Scroll for Navigation Links
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function(e) {
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
});