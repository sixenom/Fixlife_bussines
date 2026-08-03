const panel = document.querySelector('#panel');
const loginScreen = document.querySelector('#login-screen');
const adminScreen = document.querySelector('#admin-screen');
const dashboard = document.querySelector('.dashboard');
const membersScreen = document.querySelector('#members-screen');
const vehiclesScreen = document.querySelector('#vehicles-screen');
const financeScreen = document.querySelector('#finance-screen');
const gymManagementButton = document.querySelector('#gym-management');
const gymMembershipsButton = document.querySelector('#gym-memberships');
const gymPlansButton = document.querySelector('#gym-plans');
const settingsButton = document.querySelector('aside nav button:last-child');
settingsButton.dataset.view = 'settings';
settingsButton.dataset.feature = 'settings';
gymManagementButton.hidden = true;
gymMembershipsButton.hidden = true;
gymPlansButton.hidden = true;
const settingsScreen = document.createElement('div');
settingsScreen.id = 'settings-screen';
settingsScreen.hidden = true;
settingsScreen.innerHTML = '<header><div><span class="status"></span><span>Configuración de la organización</span><h1>Puntos de gestión</h1></div></header><section class="card settings-card"><div class="card-title"><h3>Punto de acceso a la gestión</h3><span>SOLO JEFE</span></div><p class="empty">Selecciona el tipo de punto y colócalo en la ubicación desde la que se gestionará la organización.</p><button class="hire" id="save-management-point">Colocar punto de gestión</button><p id="settings-status" class="empty"></p></section>';
document.querySelector('#admin-screen').append(settingsScreen);
const gymScreen = document.createElement('div');
gymScreen.id = 'gym-screen';
gymScreen.hidden = true;
gymScreen.innerHTML = '<header><div><span class="status"></span><span>Gestión del gimnasio</span><h1 id="gym-title">Gimnasio</h1></div></header><div class="stats"><article><span class="icon green"><i class="fa-solid fa-dumbbell"></i></span><div><small>MÁQUINAS CONFIGURADAS</small><strong id="gym-machine-count">—</strong><em>Instaladas en el gimnasio</em></div></article><article><span class="icon blue"><i class="fa-solid fa-id-card"></i></span><div><small>MEMBRESÍAS ACTIVAS</small><strong id="gym-membership-count">—</strong><em>Clientes vigentes</em></div></article><article><span class="icon red"><i class="fa-solid fa-tags"></i></span><div><small>PLANES DISPONIBLES</small><strong id="gym-plan-count">—</strong><em>Configurados para venta</em></div></article></div><section class="card"><div class="card-title"><h3>Máquinas del gimnasio</h3><span id="gym-machine-status">Cargando...</span></div><div class="vehicle-list" id="gym-machine-list"></div></section>';
document.querySelector('#admin-screen').append(gymScreen);
const gymMembershipsScreen = document.createElement('div');
gymMembershipsScreen.id = 'gym-memberships-screen';
gymMembershipsScreen.hidden = true;
  gymMembershipsScreen.innerHTML = '<header><div><span class="status"></span><span>Gestión del gimnasio</span><h1>Membresías</h1></div></header><div class="stats"><article><span class="icon blue"><i class="fa-solid fa-id-card"></i></span><div><small>MEMBRESÍAS ACTIVAS</small><strong id="gym-membership-total">—</strong><em>Clientes con acceso vigente</em></div></article><article><span class="icon green"><i class="fa-solid fa-tags"></i></span><div><small>PLANES DISPONIBLES</small><strong id="gym-membership-plans">—</strong><em>Planes configurados</em></div></article></div><section class="card"><div class="card-title"><h3>Clientes con membresía</h3><span id="gym-membership-status">Cargando...</span></div><div class="vehicle-list" id="gym-membership-list"></div></section>';
document.querySelector('#admin-screen').append(gymMembershipsScreen);
gymMembershipsScreen.insertAdjacentHTML('beforeend', '<section class="card"><div class="card-title"><h3>Precios de membresías</h3><span>SOLO DUEÑO</span></div><div class="membership-plan-list" id="gym-membership-plan-list"></div></section>');
gymMembershipsScreen.querySelector('#gym-membership-plan-list')?.closest('.card')?.remove();
const gymPlansScreen = document.createElement('div');
gymPlansScreen.id = 'gym-plans-screen';
gymPlansScreen.hidden = true;
gymPlansScreen.innerHTML = '<header><div><span class="status"></span><span>GestiÃ³n del gimnasio</span><h1>Precios</h1></div></header><section class="card"><div class="card-title"><h3>Precios de membresÃ­as</h3><span>SOLO DUEÃ‘O</span></div><div class="membership-plan-list" id="gym-membership-plan-list"></div></section>';
document.querySelector('#admin-screen').append(gymPlansScreen);
const managementPointType = document.createElement('select');
managementPointType.innerHTML = '<option value="laptop">Laptop con silla y animación</option><option value="tablet">Tablet sin animación</option><option value="object">Objeto existente del mapa</option>';
managementPointType.className = 'management-type-select';
const managementPointButton = settingsScreen.querySelector('#save-management-point');
managementPointButton.className = 'hire management-save';
const settingsCard = settingsScreen.querySelector('.settings-card');
const settingsStatus = settingsScreen.querySelector('#settings-status');
const gymMachineList = gymScreen.querySelector('#gym-machine-list');
const gymMachineCount = gymScreen.querySelector('#gym-machine-count');
const gymMembershipCount = gymScreen.querySelector('#gym-membership-count');
const gymPlanCount = gymScreen.querySelector('#gym-plan-count');
const gymMachineStatus = gymScreen.querySelector('#gym-machine-status');
const gymAddMachine = document.createElement('button');
gymAddMachine.className = 'hire';
gymAddMachine.textContent = '+ Agregar máquina';
gymScreen.querySelector('header').append(gymAddMachine);
const gymTitle = gymScreen.querySelector('#gym-title');
const gymMembershipTotal = gymMembershipsScreen.querySelector('#gym-membership-total');
const gymMembershipPlans = gymMembershipsScreen.querySelector('#gym-membership-plans');
const gymMembershipList = gymMembershipsScreen.querySelector('#gym-membership-list');
const gymMembershipPlanList = gymPlansScreen.querySelector('#gym-membership-plan-list');
const gymMembershipStatus = gymMembershipsScreen.querySelector('#gym-membership-status');
settingsCard.querySelector('.empty').className = 'settings-description';
const settingsControls = document.createElement('div');
settingsControls.className = 'settings-controls';
settingsControls.append(managementPointType, managementPointButton);
settingsCard.insertBefore(settingsControls, settingsStatus);
const memberList = document.querySelector('#member-list');
const vehicleList = document.querySelector('#vehicle-list');
const memberCount = document.querySelector('#member-count');
const fleetCount = document.querySelector('#fleet-count');
const memberSearch = document.querySelector('#member-search');
const vehicleSearch = document.querySelector('#vehicle-search');
const financeBalance = document.querySelector('#finance-balance');
const financeProvider = document.querySelector('#finance-provider');
const financeStatus = document.querySelector('#finance-status');
const financeTransactions = document.querySelector('#finance-transactions');
const statMembers = document.querySelector('#stat-members');
const statBalance = document.querySelector('#stat-balance');
const statService = document.querySelector('.icon.green').parentElement.querySelector('strong');
const title = document.querySelector('#title');
const logo = document.querySelector('#logo');
const username = document.querySelector('#username');
const password = document.querySelector('#password');
const modal = document.querySelector('#modal');
const modalTitle = document.querySelector('#modal-title');
const modalLabel = document.querySelector('#modal-label');
const modalInput = document.querySelector('#modal-input');
const modalForm = document.querySelector('#modal-form');
let typing;
let memberData = { members: [], grades: [] };
let vehicles = [];
let modalAction;
let modalTarget;
let features = {};
let gymData = {};

const nui = (name, body = {}) => fetch(`https://${GetParentResourceName()}/${name}`, { method: 'POST', body: JSON.stringify(body) }).then(r => r.json());

function close() {
  clearInterval(typing);
  modal.hidden = true;
  panel.hidden = true;
  fetch(`https://${GetParentResourceName()}/close`, { method: 'POST', body: '{}' });
}

function openModal(action, target) {
  modalAction = action;
  modalTarget = target;
  modalTitle.textContent = action === 'hire' ? 'Contratar miembro' : action === 'grade' ? 'Cambiar rango' : action === 'bonus' ? 'Dar bono' : action === 'financeDeposit' ? 'Recargar cuenta de sociedad' : action === 'vehicleOwner' ? 'Cambiar propietario' : action === 'vehicleModel' ? 'Cambiar modelo' : action === 'vehicleState' ? 'Cambiar estado' : 'Despedir miembro';
  modalLabel.hidden = action === 'fire' || action === 'gymMembershipRevoke';
  if (action === 'gymMachine') modalTitle.textContent = 'Agregar máquina';
  if (action === 'gymMembershipExpiry') modalTitle.textContent = 'Cambiar vencimiento';
  if (action === 'gymMembershipRevoke') modalTitle.textContent = 'Revocar membresía';
  if (action === 'gymPlanPrice') modalTitle.textContent = 'Cambiar precio';
  modalInput.required = action !== 'fire' && action !== 'gymMembershipRevoke';
  modalInput.type = action === 'bonus' || action === 'hire' || action === 'financeDeposit' ? 'number' : 'text';
  if (action === 'gymPlanPrice') {
    modalLabel.innerHTML = 'Nuevo precio <input id="modal-input" type="number" min="0" step="1" required>';
  } else if (action === 'gymMembershipExpiry') {
    modalLabel.innerHTML = 'Nuevo vencimiento <input id="modal-input" type="datetime-local" required>';
  } else if (action === 'gymMembershipRevoke') {
    modalLabel.innerHTML = '¿Confirmas revocar esta membresía? <input id="modal-input" type="hidden" value="confirm">';
  } else if (action === 'gymMachine') {
    modalLabel.innerHTML = 'Tipo de máquina <select id="modal-input" required><option value="">Selecciona una máquina</option>' + (gymData.machineTypes || []).map(machine => `<option value="${machine.type}">${machine.label}</option>`).join('') + '</select>';
  } else if (action === 'grade') {
    const current = memberData.members.find(member => member.id === target)?.grade;
    modalLabel.innerHTML = 'Nuevo rango <select id="modal-input" required>' + memberData.grades.map(grade => `<option value="${grade.level}" ${grade.level === current ? 'selected' : ''}>${grade.level} · ${grade.name}</option>`).join('') + '</select>';
    modalInput.replaceWith(modalLabel.querySelector('#modal-input'));
  } else if (action === 'vehicleOwner') {
    modalLabel.innerHTML = 'Nuevo propietario <select id="modal-input" required>' + memberData.members.map(member => `<option value="${member.id}">${member.name} · ${member.gradeName}</option>`).join('') + '</select>';
  } else if (action === 'vehicleModel') {
    modalLabel.innerHTML = 'Nombre del modelo <input id="modal-input" required placeholder="Ej: police3">';
  } else if (action === 'vehicleState') {
    modalLabel.innerHTML = 'Estado <select id="modal-input" required><option value="1">En garaje</option><option value="0">Fuera de garaje</option></select>';
  } else {
    modalLabel.innerHTML = action === 'hire' ? 'ID del jugador <input id="modal-input" type="number" required>' : action === 'bonus' ? 'Valor del bono <input id="modal-input" type="number" min="1" required>' : action === 'financeDeposit' ? 'Monto desde tu banco <input id="modal-input" type="number" min="1" required>' : '¿Confirmas despedir a este miembro? <input id="modal-input" type="hidden" value="confirm">';
  }
  modal.hidden = false;
  if (action !== 'fire' && action !== 'gymMembershipRevoke') document.querySelector('#modal-input').focus();
}

function closeModal() { modal.hidden = true; }

function formatExpiry(value) {
  const number = Number(value);
  const date = Number.isFinite(number) ? new Date(number < 1e12 ? number * 1000 : number) : new Date(value);
  return Number.isNaN(date.getTime()) ? String(value || '—') : date.toLocaleString('es-CO', { dateStyle: 'medium', timeStyle: 'short' });
}

function renderGym() {
  const machines = gymData.machines || [];
  gymTitle.textContent = gymData.label || 'Gimnasio';
  gymMachineCount.textContent = machines.length;
  gymMembershipCount.textContent = gymData.memberships ?? '—';
  gymPlanCount.textContent = gymData.plans ?? '—';
  gymMembershipTotal.textContent = gymData.memberships ?? '—';
  gymMembershipPlans.textContent = gymData.plans ?? '—';
  const plans = gymData.membershipPlans || [];
  gymMembershipPlanList.innerHTML = plans.map(plan => {
    const duration = plan.days ? `${plan.days} día${plan.days === 1 ? '' : 's'}` : `${plan.hours} hora${plan.hours === 1 ? '' : 's'}`;
    const durationHours = (plan.days || 0) * 24 + (plan.hours || 0);
    return `<div class="membership-plan"><div><strong>${duration}</strong><small>Duración del acceso</small></div><b>$ ${Number(plan.price || 0).toLocaleString('es-CO')}</b><button data-plan-hours="${durationHours}" data-action="gymPlanPrice">Editar precio</button></div>`;
  }).join('') || '<p class="empty">No hay planes configurados.</p>';
  const memberships = gymData.membershipList || [];
  gymMembershipStatus.textContent = `${memberships.length} cliente${memberships.length === 1 ? '' : 's'}`;
  gymMembershipList.innerHTML = memberships.map(member => `<article class="vehicle-row"><span class="vehicle-icon"><i class="fa-solid fa-user"></i></span><div class="member-info"><strong>${member.firstname ? `${member.firstname} ${member.lastname || ''}` : member.identifier}</strong><small>${member.membership}</small></div><div class="vehicle-owner"><small>VENCE</small><strong>${formatExpiry(member.expires)}</strong><em class="vehicle-status">Activa</em><div class="membership-actions"><button data-membership-action="expiry" data-identifier="${member.identifier}">Cambiar</button><button class="danger" data-membership-action="revoke" data-identifier="${member.identifier}">Revocar</button></div></div></article>`).join('') || '<p class="empty members-empty">No hay clientes con membresía activa.</p>';
  gymMachineStatus.textContent = `${machines.length} configurada${machines.length === 1 ? '' : 's'}`;
  gymMachineList.innerHTML = machines.map(machine => `<article class="vehicle-row"><span class="vehicle-icon"><i class="fa-solid fa-dumbbell"></i></span><div class="member-info"><strong>${machine.name}</strong><small>${machine.model || 'Sin modelo'}</small></div><div class="vehicle-owner"><small>UBICACIÓN</small><strong>${machine.x?.toFixed?.(2) ?? '—'}, ${machine.y?.toFixed?.(2) ?? '—'}</strong><em class="vehicle-status">Activa</em></div></article>`).join('') || '<p class="empty members-empty">No hay máquinas configuradas.</p>';
}

async function loadGym() {
  gymMachineStatus.textContent = 'Cargando...';
  gymData = await nui('gymData');
  renderGym();
}

async function loadDashboard() {
  const data = await nui('dashboard');
  if (!data.ok) return;
  statMembers.textContent = data.members;
  statBalance.textContent = `$ ${Number(data.balance).toLocaleString('es-CO')}`;
  statService.textContent = `${data.vehicles} vehículos`;
}

window.addEventListener('message', ({ data }) => {
  if (data.action === 'hidePanel') {
    modal.hidden = true;
    panel.hidden = true;
    return;
  }
  if (data.action !== 'openLogin') return;
  features = data.features || {};
  document.querySelectorAll('[data-view]').forEach(item => {
    const feature = item.dataset.view;
    const gymFeature = ['gymMachines', 'gymMemberships', 'gymPlans'].includes(feature);
    item.hidden = feature !== 'dashboard' && features[feature] !== true && !(gymFeature && features.gymManagement === true);
  });
  gymManagementButton.hidden = features.gymManagement !== true;
  gymMembershipsButton.hidden = features.gymManagement !== true;
  gymPlansButton.hidden = features.gymManagement !== true;
  if (features.gymManagement) loadGym();
  document.querySelectorAll('.action').forEach((item, index) => {
    item.hidden = ![features.members, features.finance, features.vehicles][index];
  });
  document.querySelectorAll('.police-dashboard .stats article').forEach((item, index) => {
    item.hidden = ![features.members, features.finance, true][index];
  });
  document.querySelectorAll('.lower .card').forEach(item => { item.hidden = false; });
  const login = data.login || {};
  title.textContent = data.label || 'Panel administrativo';
  username.value = '';
  password.value = '';
  if (login.logo) logo.innerHTML = `<img src="${login.logo}" alt="Logo">`;
  panel.hidden = false;
  loginScreen.hidden = false;
  adminScreen.hidden = true;
  dashboard.hidden = false;
  membersScreen.hidden = true;
  vehiclesScreen.hidden = true;
  financeScreen.hidden = true;
  settingsScreen.hidden = true;
  gymScreen.hidden = true;
  gymMembershipsScreen.hidden = true;
  gymPlansScreen.hidden = true;
  adminScreen.classList.remove('internal-view');
  document.querySelectorAll('[data-view]').forEach(item => item.classList.toggle('active', item.dataset.view === 'dashboard'));
  let index = 0;
  const user = String(login.username || '');
  const pass = String(login.password || '');
  typing = setInterval(() => {
    if (index <= user.length) username.value = user.slice(0, index);
    else password.value = pass.slice(0, index - user.length);
    if (index++ > user.length + pass.length) clearInterval(typing);
  }, 70);
});

function renderMembers() {
  const query = memberSearch.value.toLowerCase();
  const members = memberData.members.filter(member => member.name.toLowerCase().includes(query));
  memberCount.textContent = `${members.length} miembro${members.length === 1 ? '' : 's'} registrado${members.length === 1 ? '' : 's'}`;
  memberList.innerHTML = members.map(member => `<article class="member-row" data-id="${member.id}">
    <span class="member-avatar">${member.name.charAt(0)}</span><div class="member-info"><strong>${member.name}</strong><small>${member.gradeName} · ${member.online ? 'En servicio' : 'Fuera de servicio'}</small></div>
    <span class="online-dot ${member.online ? 'on' : ''}"></span><button class="member-action" data-action="memberVehicles">Vehículos</button><button class="member-action" data-action="grade">Rango</button><button class="member-action" data-action="bonus">Bono</button><button class="member-action danger" data-action="fire">Despedir</button>
  </article>`).join('') || '<p class="empty members-empty">No hay miembros para mostrar.</p>';
}

async function loadFinance() {
  const data = await nui('finance');
  financeBalance.textContent = data.ok ? `$ ${Number(data.balance).toLocaleString('es-CO')}` : '$ —';
  financeProvider.textContent = data.provider;
  financeStatus.textContent = data.ok ? 'Conectada' : 'No disponible';
  financeStatus.className = data.ok ? 'connected' : 'disconnected';
  financeTransactions.innerHTML = data.transactions?.map(transaction => `<div class="transaction"><span class="transaction-icon ${transaction.type === 'deposit' ? 'positive' : 'negative'}">${transaction.type === 'deposit' ? '+' : '−'}</span><div><strong>${transaction.description || 'Movimiento'}</strong><small>${transaction.date || ''}</small></div><b class="${transaction.type === 'deposit' ? 'positive' : 'negative'}">${transaction.type === 'deposit' ? '+' : '-'} $ ${Number(transaction.amount).toLocaleString('es-CO')}</b></div>`).join('') || '<p class="empty">No hay movimientos registrados todavía.</p>';
}

function renderVehicles() {
  const query = vehicleSearch.value.toLowerCase();
  const filtered = vehicles.filter(vehicle => `${vehicle.plate} ${vehicle.owner} ${vehicle.model}`.toLowerCase().includes(query));
  fleetCount.textContent = `${filtered.length} vehículo${filtered.length === 1 ? '' : 's'}`;
  vehicleList.innerHTML = filtered.map(vehicle => `<article class="vehicle-row" data-plate="${vehicle.plate}"><span class="vehicle-icon"><i class="fa-solid fa-car-side"></i></span><div class="member-info"><strong>${vehicle.plate}</strong><small>Modelo: ${vehicle.model} · ${vehicle.type}</small></div><div class="vehicle-owner"><small>PROPIETARIO</small><strong>${vehicle.owner}</strong><em class="vehicle-status">${vehicle.status}</em></div><button class="member-action" data-action="vehicleModel">Modelo</button><button class="member-action" data-action="vehicleState">Estado</button><button class="member-action" data-action="vehicleOwner">Dueño</button></article>`).join('') || '<p class="empty members-empty">No hay vehículos asignados a este trabajo.</p>';
}

async function loadVehicles() {
  fleetCount.textContent = 'Cargando flota...';
  vehicles = await nui('vehicles');
  renderVehicles();
}

async function loadMembers() {
  memberCount.textContent = 'Cargando personal...';
  memberData = await nui('members');
  renderMembers();
}

async function showMemberVehicles(member) {
  if (!member) return;
  document.querySelectorAll('[data-view]').forEach(item => item.classList.toggle('active', item.dataset.view === 'vehicles'));
  dashboard.hidden = true;
  membersScreen.hidden = true;
  vehiclesScreen.hidden = false;
  financeScreen.hidden = true;
  adminScreen.classList.add('internal-view');
  await loadVehicles();
  vehicleSearch.value = member.name;
  renderVehicles();
}

document.querySelectorAll('[data-view]').forEach(button => button.addEventListener('click', () => {
  document.querySelectorAll('[data-view]').forEach(item => item.classList.remove('active'));
  button.classList.add('active');
  const members = button.dataset.view === 'members';
  const vehicleView = button.dataset.view === 'vehicles';
  const financeView = button.dataset.view === 'finance';
  const settingsView = button.dataset.view === 'settings';
  const gymView = button.dataset.view === 'gymMachines';
  const membershipsView = button.dataset.view === 'gymMemberships';
  const plansView = button.dataset.view === 'gymPlans';
  adminScreen.classList.toggle('internal-view', members || vehicleView || financeView || settingsView || gymView || membershipsView || plansView);
  dashboard.hidden = members || vehicleView || financeView || settingsView || gymView || membershipsView || plansView;
  membersScreen.hidden = !members || vehicleView;
  vehiclesScreen.hidden = !vehicleView;
  financeScreen.hidden = !financeView;
  settingsScreen.hidden = !settingsView;
  gymScreen.hidden = !gymView;
  gymMembershipsScreen.hidden = !membershipsView;
  gymPlansScreen.hidden = !plansView;
  if (members) loadMembers();
  if (vehicleView) loadVehicles();
  if (financeView) loadFinance();
  if (settingsView) document.querySelector('#settings-status').textContent = '';
  if (gymView) loadGym();
  if (membershipsView) loadGym();
  if (plansView) loadGym();
  if (button.dataset.view === 'dashboard') loadDashboard();
}));

memberSearch.addEventListener('input', renderMembers);
vehicleSearch.addEventListener('input', renderVehicles);
vehicleList.addEventListener('click', async event => {
  const button = event.target.closest('[data-action]');
  if (!button) return;
  if (button.dataset.action === 'vehicleOwner' && !memberData.members.length) await loadMembers();
  openModal(button.dataset.action, button.closest('.vehicle-row').dataset.plate);
});
document.querySelector('#hire').addEventListener('click', async () => {
  openModal('hire');
});

document.querySelector('#finance-deposit').addEventListener('click', () => openModal('financeDeposit'));
gymMembershipList.addEventListener('click', event => {
  const button = event.target.closest('[data-membership-action]');
  if (button) openModal(button.dataset.membershipAction === 'revoke' ? 'gymMembershipRevoke' : 'gymMembershipExpiry', button.dataset.identifier);
});
gymMembershipPlanList.addEventListener('click', event => {
  const button = event.target.closest('[data-action="gymPlanPrice"]');
  if (button) openModal('gymPlanPrice', button.dataset.planHours);
});
gymAddMachine.addEventListener('click', async () => {
  openModal('gymMachine');
});
document.querySelector('#save-management-point').addEventListener('click', async () => {
  const result = await nui('saveManagementPoint', { type: managementPointType.value });
  document.querySelector('#settings-status').textContent = result.ok ? 'Punto guardado correctamente.' : 'Colocación cancelada o no autorizada.';
});

memberList.addEventListener('click', async event => {
  const button = event.target.closest('[data-action]');
  if (!button) return;
  const target = button.closest('.member-row').dataset.id;
  if (button.dataset.action === 'memberVehicles') {
    showMemberVehicles(memberData.members.find(member => member.id === target));
    return;
  }
  openModal(button.dataset.action, target);
});

modalForm.addEventListener('submit', async event => {
  event.preventDefault();
  const value = document.querySelector('#modal-input').value;
  const result = modalAction === 'gymPlanPrice'
    ? await nui('updateGymPlan', { durationHours: modalTarget, price: value })
    : modalAction === 'gymMembershipExpiry' || modalAction === 'gymMembershipRevoke'
    ? await nui('gymMembershipAction', { action: modalAction === 'gymMembershipRevoke' ? 'revoke' : 'expiry', identifier: modalTarget, expires: value })
    : modalAction === 'gymMachine'
    ? await nui('addGymMachine', { type: value })
    : modalAction === 'financeDeposit'
    ? await nui('financeDeposit', { amount: value })
    : modalAction === 'vehicleOwner'
      ? await nui('vehicleOwner', { plate: modalTarget, citizenid: value })
    : modalAction === 'vehicleModel'
      ? await nui('vehicleModel', { plate: modalTarget, model: value })
    : modalAction === 'vehicleState'
      ? await nui('vehicleState', { plate: modalTarget, state: value })
    : await nui('memberAction', { action: modalAction, target: modalTarget, value });
  if (result.ok) { closeModal(); modalAction === 'gymMachine' || modalAction === 'gymPlanPrice' || modalAction === 'gymMembershipExpiry' || modalAction === 'gymMembershipRevoke' ? loadGym() : ['vehicleOwner', 'vehicleModel', 'vehicleState'].includes(modalAction) ? loadVehicles() : modalAction === 'financeDeposit' ? loadFinance() : loadMembers(); }
});
document.querySelector('#modal-close').addEventListener('click', closeModal);
document.querySelector('#modal-cancel').addEventListener('click', closeModal);

document.querySelector('#close').addEventListener('click', close);
document.querySelector('#login-form').addEventListener('submit', event => {
  event.preventDefault();
  clearInterval(typing);
  loginScreen.hidden = true;
  adminScreen.hidden = false;
  loadDashboard();
});
document.addEventListener('keyup', ({ key }) => { if (key === 'Escape') modal.hidden ? close() : closeModal(); });

const openView = view => document.querySelector(`#admin-screen nav [data-view="${view}"]`)?.click();
document.querySelectorAll('.action')[0]?.addEventListener('click', () => features.members && openView('members'));
document.querySelectorAll('.action')[1]?.addEventListener('click', () => features.finance && openView('finance'));
const vehicleAction = document.createElement('button');
vehicleAction.className = 'action';
vehicleAction.innerHTML = '<b><i class="fa-solid fa-car"></i></b><div><strong>Gestionar vehículos</strong><small>Flota asignada al trabajo</small></div><i class="fa-solid fa-chevron-right"></i>';
vehicleAction.addEventListener('click', () => features.vehicles && openView('vehicles'));
document.querySelector('.lower .card')?.append(vehicleAction);

const quickViews = [
  ['<i class="fa-solid fa-users"></i>', 'Gestionar miembros', 'Rangos, permisos y plantilla', 'members'],
  ['<i class="fa-solid fa-dollar-sign"></i>', 'Consultar finanzas', 'Movimientos y presupuesto', 'finance'],
  ['<i class="fa-solid fa-car"></i>', 'Gestionar vehículos', 'Flota asignada al trabajo', 'vehicles']
];
document.querySelectorAll('.police-dashboard .stats article').forEach((card, index) => {
  const [icon, titleText, description, view] = quickViews[index];
  card.innerHTML = `<span class="quick-icon">${icon}</span><div><strong>${titleText}</strong><small>${description}</small></div><i class="fa-solid fa-chevron-right"></i>`;
  card.addEventListener('click', () => openView(view));
  card.setAttribute('role', 'button');
  card.tabIndex = 0;
});
document.querySelector('.lower .card:first-child')?.setAttribute('hidden', '');

document.querySelectorAll('#members-screen, #vehicles-screen, #finance-screen, #gym-screen, #gym-memberships-screen').forEach(screen => {
  const back = document.createElement('button');
  back.className = 'back-button';
  back.type = 'button';
  back.textContent = '← Volver';
  back.addEventListener('click', () => openView('dashboard'));
  screen.querySelector('header')?.prepend(back);
});
