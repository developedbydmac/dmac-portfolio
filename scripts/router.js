const contentArea = document.getElementById('content-area');
const routes = {
  '/': 'pages/home.html',
  '/resume': 'pages/resume.html',
  '/projects': 'pages/projects.html',
  '/blog': 'pages/blog.html'
};

function loadContent(path) {
  const route = routes[path] || routes['/'];
  fetch(route)
    .then(res => res.text())
    .then(html => {
      contentArea.innerHTML = html;
      history.pushState(null, '', path);
    });
}

document.querySelectorAll('nav a').forEach(link => {
  link.addEventListener('click', e => {
    e.preventDefault();
    loadContent(new URL(e.target.href).pathname);
  });
});

window.onpopstate = () => loadContent(location.pathname);
window.onload = () => loadContent(location.pathname);
