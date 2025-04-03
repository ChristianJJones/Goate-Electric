// State variables
let isLoggedIn = false;
let isDeviceConnected = false;
let username = '';
let zeropointBalance = 0;
let usdBalance = 0;
let wirelessBalance = 0;
let balanceInterval = null;

// Simulated transaction history
const transactions = [
    { date: '2023-01-01', type: 'Buy Zeropoint', amount: 100 },
    { date: '2023-01-02', type: 'Sell Wireless Connect', amount: 50 }
];

// Update user section based on login and device state
function updateUserSection() {
    const userSection = document.getElementById('user-section');
    if (!isLoggedIn) {
        userSection.innerHTML = '<button id="signup-login">Signup/Login</button>';
    } else {
        let html = `<div class="user-info">
                        <span>${username}</span>
                        <button id="logout">Logout</button>`;
        if (!isDeviceConnected) {
            html += '<button id="connect-device">Connect Device</button>';
        } else {
            html += '<div>Device Connected <span style="color: green;">•</span></div>';
            html += '<button id="manage-devices">Manage Devices</button>';
        }
        html += '</div>';
        userSection.innerHTML = html;
    }
}

// Update home section based on login state
function updateHomeSection() {
    const notLoggedInDiv = document.getElementById('not-logged-in');
    const loggedInDiv = document.getElementById('logged-in');
    if (isLoggedIn) {
        notLoggedInDiv.style.display = 'none';
        loggedInDiv.style.display = 'block';
        startBalanceUpdates();
        updateTransactionHistory();
    } else {
        notLoggedInDiv.style.display = 'block';
        loggedInDiv.style.display = 'none';
        stopBalanceUpdates();
    }
}

// Simulate real-time balance updates
function updateBalances() {
    zeropointBalance += Math.random() * 10 - 5;
    usdBalance += Math.random() * 10 - 5;
    wirelessBalance += Math.random() * 10 - 5;
    document.getElementById('zeropoint-balance').textContent = zeropointBalance.toFixed(2);
    document.getElementById('usd-balance').textContent = usdBalance.toFixed(2);
    document.getElementById('wireless-balance').textContent = wirelessBalance.toFixed(2);
}

function startBalanceUpdates() {
    if (!balanceInterval) {
        balanceInterval = setInterval(updateBalances, 500); // Update every 500ms (twice per second)
    }
}

function stopBalanceUpdates() {
    if (balanceInterval) {
        clearInterval(balanceInterval);
        balanceInterval = null;
    }
}

// Update transaction history
function updateTransactionHistory() {
    const transactionList = document.getElementById('transaction-list');
    transactionList.innerHTML = '';
    transactions.forEach(tx => {
        const li = document.createElement('li');
        li.textContent = `${tx.date}: ${tx.type} - ${tx.amount}`;
        transactionList.appendChild(li);
    });
}

// Handle page navigation
const pages = document.querySelectorAll('.page');
const navLinks = document.querySelectorAll('.nav-link');

function showPage(pageId) {
    pages.forEach(page => {
        if (page.id === pageId) {
            page.style.display = 'block';
            setTimeout(() => page.classList.remove('hidden'), 10);
            if (pageId === 'home') updateHomeSection();
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

// Handle user section interactions
document.getElementById('user-section').addEventListener('click', (event) => {
    if (event.target.id === 'signup-login') {
        isLoggedIn = true;
        username = 'User123';
        updateUserSection();
        updateHomeSection();
    } else if (event.target.id === 'connect-device') {
        isDeviceConnected = true;
        updateUserSection();
    } else if (event.target.id === 'manage-devices') {
        alert('Manage Devices clicked');
    } else if (event.target.id === 'logout') {
        isLoggedIn = false;
        isDeviceConnected = false;
        username = '';
        updateUserSection();
        updateHomeSection();
    }
});

// Initialize the page
document.addEventListener('DOMContentLoaded', () => {
    const initialPageId = window.location.hash.substring(1) || 'home';
    showPage(initialPageId);
    updateUserSection();
});
