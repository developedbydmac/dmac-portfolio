document.addEventListener('DOMContentLoaded', () => {
    // Mobile Navigation
    const burger = document.querySelector('.burger');
    const nav = document.querySelector('.nav-links');
    const navLinks = document.querySelectorAll('.nav-links li');

    burger.addEventListener('click', () => {
        // Toggle Navigation
        nav.classList.toggle('nav-active');

        // Animate Links
        navLinks.forEach((link, index) => {
            if (link.style.animation) {
                link.style.animation = '';
            } else {
                link.style.animation = `navLinkFade 0.5s ease forwards ${index / 7 + 0.3}s`;
            }
        });

        // Burger Animation
        burger.classList.toggle('toggle');
    });

    // Smooth Scrolling
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            document.querySelector(this.getAttribute('href')).scrollIntoView({
                behavior: 'smooth'
            });
        });
    });
});

document.addEventListener('DOMContentLoaded', () => {
    const navbar = document.querySelector('.navbar');
    let lastScrollTop = 0;

    window.addEventListener('scroll', () => {
        let currentScroll = window.pageYOffset || document.documentElement.scrollTop;

        if (currentScroll > lastScrollTop) {
            // Scrolling down
            navbar.classList.add('hide');
        } else {
            // Scrolling up
            navbar.classList.remove('hide');
        }

        lastScrollTop = currentScroll <= 0 ? 0 : currentScroll;
    });
document.addEventListener('DOMContentLoaded', function() {
    // Existing mobile navigation code...

    // View Projects CTA Button
    const viewProjectsBtn = document.getElementById('view-projects-btn');
    if (viewProjectsBtn) {
        viewProjectsBtn.addEventListener('click', function(event) {
            // Optional: Add analytics or tracking
            console.log('CTA: Navigating to Projects');

            // Optional: Add visual feedback
            this.classList.add('btn-clicked');

            // Navigate to projects page
            window.location.href = 'projects.html';
        });
    }
});
});