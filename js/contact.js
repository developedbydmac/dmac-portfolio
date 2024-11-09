document.addEventListener('DOMContentLoaded', function() {
    const contactForm = document.getElementById('contact-form');
    
    contactForm.addEventListener('submit', function(e) {
        e.preventDefault();
        
        // You can add form submission logic here
        // For now, just show an alert
        alert('Thank you for your message! I will get back to you soon.');
        
        // Reset the form
        contactForm.reset();
    });
});