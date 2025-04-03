// State variables
let isLoggedIn = false;
let isDeviceConnected = false;
let username = '';
let zeropointBalance = 0;
let usdBalance = 0;
let wirelessBalance = 0;
let balanceInterval = null;
let cardOrdered = false;
let cardDetails = null;
let devices = [];
const users = JSON.parse(localStorage.getItem('users')) || [];
const securityQuestions = [
    "Mother's middle name", "Father's middle name", "Mother's maiden name",
    "Childhood nickname", "Favorite sport", "Favorite book",
    "Favorite vacation spot", "Dream job", "Favorite color", "Favorite animal"
];
const MAX_FREE_DEVICES = 5;

// Simulated transaction history
const transactions = [
    { date: '2023-01-01', type: 'Buy Zeropoint', amount: 100 },
    { date: '2023-01-02', type: 'Sell Wireless Connect', amount: 50 }
];

// Populate security questions
function populateSecurityQuestions() {
    const container = document.getElementById('security-questions');
    container.innerHTML = '';
    securityQuestions.forEach((question, index) => {
        const div = document.createElement('div');
        div.innerHTML = `
            <input type="checkbox" id="sq-${index}" name="security-question" value="${question}">
            <label for="sq-${index}">${question}</label>
            <input type="text" id="sa-${index}" class="security-answer" style="display: none;" placeholder="Answer">
        `;
        container.appendChild(div);
        document.getElementById(`sq-${index}`).addEventListener('change', (e) => {
            document.getElementById(`sa-${index}`).style.display = e.target.checked ? 'block' : 'none';
        });
    });
}

// Update user section
function updateUserSection() {
    const userSection = document.getElementById('user-section');
    if (!isLoggedIn) {
        userSection.innerHTML = '<button id="signup-login">Signup/Login</button>';
    } else {
        let html = `<div class="user-info"><span>${username}</span><button id="logout">Logout</button>`;
        if (!isDeviceConnected) html += '<button id="connect-device">Connect Device</button>';
        else html += '<div>Device Connected <span style="color: green;">•</span></div><button id="manage-devices">Manage Devices</button>';
        html += '</div>';
        userSection.innerHTML = html;

        if (isDeviceConnected) {
            document.getElementById('manage-devices')?.addEventListener('click', () => showPage('manage-devices'));
            document.getElementById('connect-device')?.addEventListener('click', connectDevice);
        }
    }
}

// Update home section
function updateHomeSection() {
    const notLoggedInDiv = document.getElementById('not-logged-in');
    const loggedInDiv = document.getElementById('logged-in');
    const navigation = document.getElementById('navigation');
    if (isLoggedIn) {
        notLoggedInDiv.style.display = 'none';
        loggedInDiv.style.display = 'block';
        navigation.style.display = 'block';
        startBalanceUpdates();
        updateTransactionHistory();
    } else {
        notLoggedInDiv.style.display = 'block';
        loggedInDiv.style.display = 'none';
        navigation.style.display = 'none';
        stopBalanceUpdates();
    }
}

// Balance and transaction updates
function updateBalances() {
    zeropointBalance += Math.random() * 10 - 5;
    usdBalance += Math.random() * 10 - 5;
    wirelessBalance += Math.random() * 10 - 5;
    document.getElementById('zeropoint-balance').textContent = zeropointBalance.toFixed(2);
    document.getElementById('usd-balance').textContent = usdBalance.toFixed(2);
    document.getElementById('wireless-balance').textContent = wirelessBalance.toFixed(2);
}
function startBalanceUpdates() { if (!balanceInterval) balanceInterval = setInterval(updateBalances, 500); }
function stopBalanceUpdates() { if (balanceInterval) { clearInterval(balanceInterval); balanceInterval = null; } }
function updateTransactionHistory() {
    const transactionList = document.getElementById('transaction-list');
    transactionList.innerHTML = '';
    transactions.forEach(tx => {
        const li = document.createElement('li');
        li.textContent = `${tx.date}: ${tx.type} - ${tx.amount}`;
        transactionList.appendChild(li);
    });
}

// Auth modal and tabs
document.getElementById('user-section').addEventListener('click', (event) => {
    if (event.target.id === 'signup-login') {
        document.getElementById('auth-modal').style.display = 'flex';
        document.getElementById('signup-form').style.display = 'block';
        document.getElementById('login-form').style.display = 'none';
        document.getElementById('signup-tab').classList.add('active');
        document.getElementById('login-tab').classList.remove('active');
        populateSecurityQuestions();
    } else if (event.target.id === 'logout') {
        isLoggedIn = false;
        isDeviceConnected = false;
        username = '';
        devices = [];
        updateUserSection();
        updateHomeSection();
    } else if (event.target.id === 'connect-device') {
        connectDevice();
    }
});

document.getElementById('signup-tab').addEventListener('click', () => {
    document.getElementById('signup-form').style.display = 'block';
    document.getElementById('login-form').style.display = 'none';
    document.getElementById('signup-tab').classList.add('active');
    document.getElementById('login-tab').classList.remove('active');
});

document.getElementById('login-tab').addEventListener('click', () => {
    document.getElementById('signup-form').style.display = 'none';
    document.getElementById('login-form').style.display = 'block';
    document.getElementById('signup-tab').classList.remove('active');
    document.getElementById('login-tab').classList.add('active');
});

// Signup form submission
document.getElementById('signup-form').addEventListener('submit', (e) => {
    e.preventDefault();
    const emailPhone = document.getElementById('signup-email-phone').value;
    const usernameInput = document.getElementById('signup-username').value;
    const password = document.getElementById('signup-password').value;
    const passwordConfirm = document.getElementById('signup-password-confirm').value;
    const firstName = document.getElementById('signup-first-name').value;
    const lastName = document.getElementById('signup-last-name').value;
    const address = document.getElementById('signup-address').value;
    const state = document.getElementById('signup-state').value;
    const city = document.getElementById('signup-city').value;
    const zip = document.getElementById('signup-zip').value;
    const dob = document.getElementById('signup-dob').value;
    const age = document.getElementById('signup-age').value;
    const ssn = document.getElementById('signup-ssn').value;
    const dependents = document.getElementById('signup-dependents').value;
    const securityAnswers = Array.from(document.querySelectorAll('.security-answer'))
        .filter(input => input.style.display === 'block' && input.value)
        .map(input => ({ question: input.previousElementSibling.previousElementSibling.value, answer: input.value }));

    let errorField = null;
    if (/^[a-zA-Z]/.test(emailPhone)) {
        if (!/@[a-zA-Z]+\.[a-zA-Z]+$/.test(emailPhone)) errorField = 'signup-email-phone';
        else if (users.some(u => u.emailPhone === emailPhone)) errorField = 'signup-email-phone';
    } else {
        if (!/^\d+$/.test(emailPhone) || emailPhone.length > 18) errorField = 'signup-email-phone';
        else if (users.some(u => u.emailPhone === emailPhone)) errorField = 'signup-email-phone';
    }
    if (!/^[a-zA-Z0-9]{3,}$/.test(usernameInput) || users.some(u => u.username === usernameInput)) errorField = errorField || 'signup-username';
    if (password.length < 8) errorField = errorField || 'signup-password';
    if (password !== passwordConfirm) errorField = errorField || 'signup-password-confirm';
    if (!/^[a-zA-Z]+$/.test(firstName)) errorField = errorField || 'signup-first-name';
    if (!/^[a-zA-Z]+$/.test(lastName)) errorField = errorField || 'signup-last-name';
    if (!/^\d+/.test(address)) errorField = errorField || 'signup-address';
    if (!/^[a-zA-Z]+$/.test(state)) errorField = errorField || 'signup-state';
    if (!/^[a-zA-Z]+$/.test(city)) errorField = errorField || 'signup-city';
    if (!/^\d{5}$/.test(zip)) errorField = errorField || 'signup-zip';
    if (!/^\d{2}\/\d{2}\/\d{4}$/.test(dob)) errorField = errorField || 'signup-dob';
    if (!/^\d{1,3}$/.test(age)) errorField = errorField || 'signup-age';
    if (!/^\d{4}$/.test(ssn)) errorField = errorField || 'signup-ssn';
    if (!/^\d+$/.test(dependents)) errorField = errorField || 'signup-dependents';
    if (securityAnswers.length < 3) errorField = errorField || 'security-questions';

    if (errorField) {
        document.getElementById(errorField).parentElement.classList.add('error');
        document.getElementById(errorField).scrollIntoView({ behavior: 'smooth', block: 'center' });
        return;
    }

    users.push({ emailPhone, username: usernameInput, password, firstName, lastName, address, state, city, zip, dob, age, ssn, dependents, securityAnswers, devices: [] });
    localStorage.setItem('users', JSON.stringify(users));
    isLoggedIn = true;
    username = usernameInput;
    document.getElementById('auth-modal').style.display = 'none';
    updateUserSection();
    updateHomeSection();
});

// Login form submission
document.getElementById('login-form').addEventListener('submit', (e) => {
    e.preventDefault();
    const loginId = document.getElementById('login-id').value;
    const password = document.getElementById('login-password').value;
    const user = users.find(u => (u.emailPhone === loginId || u.username === loginId));
    if (!user) {
        alert('User not signed up');
        return;
    }
    if (user.password !== password) {
        alert('Incorrect password');
        return;
    }
    isLoggedIn = true;
    username = user.username;
    document.getElementById('auth-modal').style.display = 'none';
    updateUserSection();
    updateHomeSection();
});

// Password confirmation real-time check
document.getElementById('signup-password-confirm').addEventListener('input', (e) => {
    const password = document.getElementById('signup-password').value;
    if (e.target.value !== password) e.target.parentElement.classList.add('error');
    else e.target.parentElement.classList.remove('error');
});

// Settings page (unchanged)
function updateSettingsPage() {
    const user = users.find(u => u.username === username);
    if (!user) return;

    document.getElementById('kyc-name').textContent = `${user.firstName} ${user.lastName}`;
    document.getElementById('kyc-dob').textContent = user.dob;
    document.getElementById('kyc-address').textContent = `${user.address}, ${user.city}, ${user.state} ${user.zip}`;
    const ssnSpan = document.getElementById('kyc-ssn');
    const toggleSsn = document.getElementById('toggle-ssn');
    ssnSpan.textContent = '****';
    toggleSsn.textContent = 'Show';
    toggleSsn.onclick = () => {
        ssnSpan.textContent = ssnSpan.textContent === '****' ? user.ssn : '****';
        toggleSsn.textContent = ssnSpan.textContent === '****' ? 'Show' : 'Hide';
    };

    document.getElementById('account-settings-form').onsubmit = (e) => {
        e.preventDefault();
        const newPassword = document.getElementById('change-password').value;
        const newAddress = document.getElementById('change-address').value;
        const newUsername = document.getElementById('change-username').value;
        const newEmailPhone = document.getElementById('change-email-phone').value;
        const addEmailPhone = document.getElementById('add-email-phone').value;

        if (newPassword) user.password = newPassword;
        if (newAddress) {
            user.address = newAddress;
            user.state = 'State';
            user.city = 'City';
            user.zip = '12345';
        }
        if (newUsername && /^[a-zA-Z0-9]{3,}$/.test(newUsername) && !users.some(u => u.username === newUsername && u.username !== username)) {
            user.username = newUsername;
            username = newUsername;
        }
        if (newEmailPhone) user.emailPhone = newEmailPhone;
        if (addEmailPhone) user.emailPhone = addEmailPhone;
        localStorage.setItem('users', JSON.stringify(users));
        updateUserSection();
        updateSettingsPage();
        alert('Account updated');
    };

    document.getElementById('connect-plaid').onclick = () => {
        alert('Plaid integration placeholder.');
    };
    document.getElementById('manual-debit-form').onsubmit = (e) => {
        e.preventDefault();
        const number = document.getElementById('debit-number').value;
        const expiry = document.getElementById('debit-expiry').value;
        const cvc = document.getElementById('debit-cvc').value;
        if (/^\d{16}$/.test(number) && /^\d{2}\/\d{2}$/.test(expiry) && /^\d{3}$/.test(cvc)) {
            user.debitCard = { number, expiry, cvc };
            localStorage.setItem('users', JSON.stringify(users));
            alert('Debit card added');
        } else {
            alert('Invalid debit card details');
        }
    };

    const orderCardBtn = document.getElementById('order-card');
    const cardInfo = document.getElementById('card-info');
    if (!cardOrdered) {
        orderCardBtn.style.display = 'block';
        cardInfo.style.display = 'none';
        orderCardBtn.onclick = () => {
            cardOrdered = true;
            cardDetails = { number: '1234567890123456', cvc: '123', expiry: '12/25' };
            user.card = cardDetails;
            localStorage.setItem('users', JSON.stringify(users));
            updateCardSettings();
        };
    } else {
        updateCardSettings();
    }
}

function updateCardSettings() {
    const orderCardBtn = document.getElementById('order-card');
    const cardInfo = document.getElementById('card-info');
    orderCardBtn.style.display = 'none';
    cardInfo.style.display = 'block';

    const cardNumber = document.getElementById('card-number');
    const cardCvc = document.getElementById('card-cvc');
    const cardExpiry = document.getElementById('card-expiry');
    const toggleCard = document.getElementById('toggle-card');
    cardNumber.textContent = '**** **** **** ****';
    cardCvc.textContent = '***';
    cardExpiry.textContent = '**/**';
    toggleCard.textContent = 'Show';
    toggleCard.onclick = () => {
        if (cardNumber.textContent === '**** **** **** ****') {
            cardNumber.textContent = cardDetails.number;
            cardCvc.textContent = cardDetails.cvc;
            cardExpiry.textContent = cardDetails.expiry;
            toggleCard.textContent = 'Hide';
        } else {
            cardNumber.textContent = '**** **** **** ****';
            cardCvc.textContent = '***';
            cardExpiry.textContent = '**/**';
            toggleCard.textContent = 'Show';
        }
    };

    const zpeYes = document.getElementById('zpe-yes');
    const zpeNo = document.getElementById('zpe-no');
    const wcYes = document.getElementById('wc-yes');
    const wcNo = document.getElementById('wc-no');
    zpeYes.onclick = () => toggleSpending('zpe', true);
    zpeNo.onclick = () => toggleSpending('zpe', false);
    wcYes.onclick = () => toggleSpending('wc', true);
    wcNo.onclick = () => toggleSpending('wc', false);
}

function toggleSpending(type, enabled) {
    const yesBtn = document.getElementById(`${type}-yes`);
    const noBtn = document.getElementById(`${type}-no`);
    if (enabled) {
        yesBtn.classList.add('active');
        noBtn.classList.remove('active');
    } else {
        yesBtn.classList.remove('active');
        noBtn.classList.add('active');
    }
    const user = users.find(u => u.username === username);
    user[`${type}Spending`] = enabled;
    localStorage.setItem('users', JSON.stringify(users));
}

// Manage Devices
function connectDevice(deviceData = null) {
    const user = users.find(u => u.username === username);
    if (!user) return;
    const activeDevices = devices.filter(d => d.active).length;
    if (activeDevices >= MAX_FREE_DEVICES && usdBalance < 1) {
        alert('You need $1 USD to add more than 5 devices.');
        return;
    }
    if (activeDevices >= MAX_FREE_DEVICES) usdBalance -= 1;

    const newDevice = deviceData || {
        id: Date.now(),
        name: `Device-${devices.length + 1}`,
        battery: Math.floor(Math.random() * 100),
        wifi: Math.random() > 0.5 ? 'Connected' : 'Disconnected',
        autoChargeZPE: false,
        chargeOnReceiveZPE: false,
        autoConnectWC: false,
        connectOnReceiveWC: false,
        totalZPEConsumed: 0,
        totalWCConsumed: 0,
        active: true
    };

    if (devices.some(d => d.id === newDevice.id && d.active)) {
        alert('Your device is already connected.');
        return;
    }
    devices.push(newDevice);
    user.devices = devices;
    localStorage.setItem('users', JSON.stringify(users));
    isDeviceConnected = true;
    updateUserSection();
    updateManageDevicesPage();
    startDeviceMonitoring();
}

function updateManageDevicesPage() {
    const container = document.getElementById('devices-container');
    container.innerHTML = '';
    const user = users.find(u => u.username === username);
    devices = user?.devices || devices;
    devices.filter(d => d.active).forEach(device => {
        const modal = document.createElement('div');
        modal.className = 'device-modal';
        modal.innerHTML = `
            <h3>${device.name}</h3>
            <div class="device-info">
                <p>Battery: <span id="battery-${device.id}">${device.battery}%</span></p>
                <p>WiFi: <span id="wifi-${device.id}">${device.wifi}</span></p>
            </div>
            <div class="slider-group">
                <label>Auto-Charge w/ $ZPE:</label>
                <button class="slider-btn on" id="auto-charge-${device.id}-on">${device.autoChargeZPE ? 'On' : 'On'}</button>
                <button class="slider-btn off" id="auto-charge-${device.id}-off">${device.autoChargeZPE ? 'Off' : 'Off'}</button>
            </div>
            <div class="slider-group">
                <label>Charge On-Receive $ZPE:</label>
                <button class="slider-btn on" id="charge-receive-${device.id}-on">${device.chargeOnReceiveZPE ? 'On' : 'On'}</button>
                <button class="slider-btn off" id="charge-receive-${device.id}-off">${device.chargeOnReceiveZPE ? 'Off' : 'Off'}</button>
            </div>
            <div class="slider-group">
                <label>Auto-Connect w/ $WC:</label>
                <button class="slider-btn on" id="auto-connect-${device.id}-on">${device.autoConnectWC ? 'On' : 'On'}</button>
                <button class="slider-btn off" id="auto-connect-${device.id}-off">${device.autoConnectWC ? 'Off' : 'Off'}</button>
            </div>
            <div class="slider-group">
                <label>Connect On-Receive $WC:</label>
                <button class="slider-btn on" id="connect-receive-${device.id}-on">${device.connectOnReceiveWC ? 'On' : 'On'}</button>
                <button class="slider-btn off" id="connect-receive-${device.id}-off">${device.connectOnReceiveWC ? 'Off' : 'Off'}</button>
            </div>
            <div class="device-stats">
                <p>Total $ZPE Consumed: <span id="zpe-consumed-${device.id}">${device.totalZPEConsumed}</span></p>
                <p>Total $WC Consumed: <span id="wc-consumed-${device.id}">${device.totalWCConsumed}</span></p>
            </div>
            <button id="disconnect-${device.id}" class="disconnect-device">Disconnect</button>
        `;
        container.appendChild(modal);

        // Slider logic
        toggleSlider(device, 'auto-charge', 'autoChargeZPE');
        toggleSlider(device, 'charge-receive', 'chargeOnReceiveZPE');
        toggleSlider(device, 'auto-connect', 'autoConnectWC');
        toggleSlider(device, 'connect-receive', 'connectOnReceiveWC');

        // Disconnect button
        document.getElementById(`disconnect-${device.id}`).onclick = () => showConfirmDisconnect(device.id);
    });

    document.getElementById('add-device-btn').onclick = () => {
        document.getElementById('add-device-modal').style.display = 'flex';
    };
    document.getElementById('manual-add-device').onclick = () => {
        document.getElementById('add-device-modal').style.display = 'none';
        document.getElementById('manual-device-modal').style.display = 'flex';
    };
    document.getElementById('scan-device').onclick = () => {
        document.getElementById('add-device-modal').style.display = 'none';
        alert('Scanning device (camera/NFC placeholder)');
        connectDevice({ id: Date.now(), name: `Scanned-Device`, battery: 50, wifi: 'Connected', autoChargeZPE: false, chargeOnReceiveZPE: false, autoConnectWC: false, connectOnReceiveWC: false, totalZPEConsumed: 0, totalWCConsumed: 0, active: true });
    };
    document.getElementById('get-device').onclick = () => {
        document.getElementById('add-device-modal').style.display = 'none';
        connectDevice();
    };
    document.getElementById('manual-device-form').onsubmit = (e) => {
        e.preventDefault();
        const modelName = document.getElementById('model-name').value;
        const serialNumber = document.getElementById('serial-number').value;
        const imei = document.getElementById('imei').value;
        document.getElementById('manual-device-modal').style.display = 'none';
        connectDevice({ id: parseInt(imei), name: modelName, battery: 75, wifi: 'Connected', autoChargeZPE: false, chargeOnReceiveZPE: false, autoConnectWC: false, connectOnReceiveWC: false, totalZPEConsumed: 0, totalWCConsumed: 0, active: true, serialNumber });
    };
}

function toggleSlider(device, prefix, prop) {
    const onBtn = document.getElementById(`${prefix}-${device.id}-on`);
    const offBtn = document.getElementById(`${prefix}-${device.id}-off`);
    if (device[prop]) {
        onBtn.classList.add('active');
        offBtn.classList.remove('active');
    } else {
        onBtn.classList.remove('active');
        offBtn.classList.add('active');
    }
    onBtn.onclick = () => {
        device[prop] = true;
        onBtn.classList.add('active');
        offBtn.classList.remove('active');
        updateDeviceInStorage(device);
    };
    offBtn.onclick = () => {
        device[prop] = false;
        onBtn.classList.remove('active');
        offBtn.classList.add('active');
        updateDeviceInStorage(device);
    };
}

function updateDeviceInStorage(device) {
    const user = users.find(u => u.username === username);
    const index = devices.findIndex(d => d.id === device.id);
    devices[index] = device;
    user.devices = devices;
    localStorage.setItem('users', JSON.stringify(users));
}

function showConfirmDisconnect(deviceId) {
    const modal = document.getElementById('confirm-disconnect-modal');
    modal.style.display = 'flex';
    document.getElementById('confirm-yes').onclick = () => {
        const device = devices.find(d => d.id === deviceId);
        device.active = false;
        isDeviceConnected = devices.some(d => d.active);
        updateDeviceInStorage(device);
        modal.style.display = 'none';
        updateManageDevicesPage();
        updateUserSection();
    };
    document.getElementById('confirm-no').onclick = () => {
        modal.style.display = 'none';
    };
}

let deviceMonitorInterval = null;
function startDeviceMonitoring() {
    if (!deviceMonitorInterval) {
        deviceMonitorInterval = setInterval(() => {
            devices.forEach(device => {
                if (!device.active) return;
                device.battery = Math.max(0, Math.min(100, device.battery - Math.random() * 5));
                device.wifi = Math.random() > 0.2 ? 'Connected' : 'Disconnected';

                if (device.autoChargeZPE && device.battery <= 20 && zeropointBalance >= (100 - device.battery)) {
                    const amount = 100 - device.battery;
                    zeropointBalance -= amount;
                    device.battery = 100;
                    device.totalZPEConsumed += amount;
                }
                if (device.chargeOnReceiveZPE && device.battery === 0 && zeropointBalance >= 100) {
                    zeropointBalance -= 100;
                    device.battery = 100;
                    device.totalZPEConsumed += 100;
                }
                if (device.autoConnectWC && device.wifi === 'Disconnected' && wirelessBalance >= 1) {
                    wirelessBalance -= 1;
                    device.wifi = 'Connected';
                    device.totalWCConsumed += 1;
                }
                if (device.connectOnReceiveWC && device.wifi === 'Disconnected' && wirelessBalance >= 1) {
                    wirelessBalance -= 1;
                    device.wifi = 'Connected';
                    device.totalWCConsumed += 1;
                }

                if (document.getElementById(`battery-${device.id}`)) {
                    document.getElementById(`battery-${device.id}`).textContent = `${device.battery}%`;
                    document.getElementById(`wifi-${device.id}`).textContent = device.wifi;
                    document.getElementById(`zpe-consumed-${device.id}`).textContent = device.totalZPEConsumed;
                    document.getElementById(`wc-consumed-${device.id}`).textContent = device.totalWCConsumed;
                }
            });
            const user = users.find(u => u.username === username);
            user.devices = devices;
            localStorage.setItem('users', JSON.stringify(users));
            document.getElementById('zeropoint-balance').textContent = zeropointBalance.toFixed(2);
            document.getElementById('wireless-balance').textContent = wirelessBalance.toFixed(2);
            document.getElementById('usd-balance').textContent = usdBalance.toFixed(2);
        }, 5000);
    }
}

function stopDeviceMonitoring() {
    if (deviceMonitorInterval) {
        clearInterval(deviceMonitorInterval);
        deviceMonitorInterval = null;
    }
}

// Page navigation
const pages = document.querySelectorAll('.page');
const navLinks = document.querySelectorAll('.nav-link');

function showPage(pageId) {
    pages.forEach(page => {
        if (page.id === pageId) {
            page.style.display = 'block';
            setTimeout(() => page.classList.remove('hidden'), 10);
            if (pageId === 'home') updateHomeSection();
            if (pageId === 'settings') updateSettingsPage();
            if (pageId === 'manage-devices' && isDeviceConnected) updateManageDevicesPage();
        } else {
            page.classList.add('hidden');
            page.addEventListener('transitionend', () => {
                page.style.display = 'none';
            }, { once: true });
        }
    });
}

navLinks.forEach(link => {
    link.addEventListener('click', (e) => {
        e.preventDefault();
        const pageId = link.getAttribute('href').substring(1);
        showPage(pageId);
        window.history.pushState(null, '', `#${pageId}`);
    });
});

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    const initialPageId = window.location.hash.substring(1) || 'home';
    showPage(initialPageId);
    updateUserSection();
    const user = users.find(u => u.username === username);
    if (user && user.devices && user.devices.length > 0) {
        devices = user.devices;
        isDeviceConnected = devices.some(d => d.active);
        if (isDeviceConnected) startDeviceMonitoring();
    }
});
