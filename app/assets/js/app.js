document.addEventListener('DOMContentLoaded',()=>{
  const t=document.getElementById('toast'); if(t) setTimeout(()=>t.classList.add('hide'),4200);
  document.querySelectorAll('[data-confirm]').forEach(el=>el.addEventListener('click',e=>{if(!confirm(el.dataset.confirm||'¿Confirmar?'))e.preventDefault();}));
  document.querySelectorAll('[data-filter]').forEach(input=>input.addEventListener('input',()=>{const q=input.value.toLowerCase();document.querySelectorAll(input.dataset.filter+' tbody tr').forEach(r=>r.style.display=r.innerText.toLowerCase().includes(q)?'':'none');}));
});
