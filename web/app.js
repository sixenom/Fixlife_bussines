const panel = document.querySelector('#panel');
const title = document.querySelector('#title');

function close() {
  panel.hidden = true;
  fetch(`https://${GetParentResourceName()}/close`, { method: 'POST', body: '{}' });
}

window.addEventListener('message', ({ data }) => {
  if (data.action === 'open') {
    title.textContent = data.label;
    panel.hidden = false;
  }
});

document.querySelector('#close').addEventListener('click', close);
document.addEventListener('keyup', ({ key }) => { if (key === 'Escape') close(); });
