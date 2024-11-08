// // contact.js
// document.addEventListener('DOMContentLoaded', () => {
//     const contactForm = document.getElementById('contact-form');
//     const formGroups = document.querySelectorAll('.form-group');

//     // Add floating label effect
//     formGroups.forEach(group => {
//         const input = group.querySelector('input, textarea');
//         const label = group.querySelector('label');

//         input.addEventListener('focus', () => {
//             label.classList.add('active');
//         });

//         input.addEventListener('blur', () => {
//             if (!input.value) {
//                 label.classList.remove('active');
//             }
//         });

//         // Check if input has value on page load
//         if (input.value) {
//             label.classList.add('active');
//         }
//     });

//     // Form submission
//     contactForm.addEventListener('submit', async (e) => {
//         e.preventDefault();

//         // Get form data
//         const formData = {
//             name: document.getElementById('name').value,
//             email: document.getElementById('email').value,
//             message: document.getElementByI