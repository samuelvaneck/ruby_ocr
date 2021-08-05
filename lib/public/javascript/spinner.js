window.addEventListener('DOMContentLoaded', () => {
  document.getElementById('convert-btn').addEventListener('click', (event) => {
    const sWrapper = document.getElementById('spinner-wrapper');
    sWrapper.classList.remove('d-none');
    sWrapper.classList.add('d-flex');
  });
});
