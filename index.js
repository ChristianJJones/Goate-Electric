// State variables
let isLoggedIn = false;
let isDeviceConnected = false;
let username = '';
let zeropointBalance = 0;
let usdBalance = 0;
let wirelessBalance = 0;
let balanceInterval = null;
const users = JSON.parse(localStorage.getItem('users')) || [];

// Security questions
const securityQuestions = [
    "Mother's middle name", "Father's middle name", "Mother's maiden name",
    "Childhood nickname", "Favorite sport", "Favorite book",
    "Favorite vacation spot", "Dream job", "Favorite color", "Favorite animal"
];

// Populate security questions
function populateSecurityQuestions() {
    const container = document.getElementById('security-questions');
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
        logged...

Something went wrong, please try again.
