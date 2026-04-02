function toggleClass(target) {
    target.classList.toggle('smol');
    target.classList.toggle('beeg');
}
function toggleIcon(target) {
    if (target.textContent.trim() === 'keyboard_arrow_down') {
        target.textContent = 'keyboard_arrow_up';
    } else {
        target.textContent = 'keyboard_arrow_down';
    }
    toggleClass(target.parentNode);
}