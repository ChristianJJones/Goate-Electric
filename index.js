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
            document.getElementById('manage-devices')?.addEventListener('click', showManageDevicesModal);
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

// Settings page
function updateSettingsPage() {
    const user = users.find(u => u.username === username);
    if (!user) return;

    document.getElementById('kyc-name').textContent = `${user.firstName} ${user.lastName}`;
    document.getElementById('kyc-dob').textContent = user.dob;
    document.getElementById('kyc-address').textContent = `${user.address}, ${user.city}, ${user.state} ${user.zip}`;
    const ssnSpan = document.getElementById('kyc-ss
