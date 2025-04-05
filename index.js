const provider = new ethers.providers.Web3Provider(window.ethereum);
const signer = provider.getSigner();
const zpeContract = new ethers.Contract("0xYourZPEAddress", zpeABI, signer);
const zpwContract = new ethers.Contract("0xYourZPWAddress", zpwABI, signer);
const zppContract = new ethers.Contract("0xYourZPPAddress", zppABI, signer);
const deviceContract = new ethers.Contract("0xYourDeviceConnectAddress", deviceABI, signer);
const usdcContract = new ethers.Contract("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", usdcABI, signer);
const mediator = new USDMediator();
let currentUser, isLoggedIn = false;
const db = { users: {}, devices: {} };

async function updateBalances() {
    const userAddress = await signer.getAddress();
    document.getElementById('zeropoint-balance').textContent = ethers.utils.formatUnits(await zpeContract.balanceOf(userAddress), 3);
    document.getElementById('zeropointwifi-balance').textContent = ethers.utils.formatUnits(await zpwContract.balanceOf(userAddress), 2);
    document.getElementById('zeropointphone-balance').textContent = ethers.utils.formatUnits(await zppContract.balanceOf(userAddress), 2);
    document.getElementById('usd-balance').textContent = ethers.utils.formatUnits(await usdcContract.balanceOf(userAddress), 6);
}

async function loadDevices() {
    const userAddress = await signer.getAddress();
    const devices = await deviceContract.getUserDevices(userAddress);
    const container = document.getElementById('devices-container');
    container.innerHTML = devices.map(device => `
        <div class="device-card">
            <span>${device.deviceId} (Modals: ${device.modalCount})</span>
            <span>${device.isActive ? 'Active' : 'Inactive'}</span>
            <button onclick="disconnectDevice('${device.deviceId}')">${device.isActive ? 'Disconnect' : 'Disconnected'}</button>
        </div>
    `).join('');
}

async function disconnectDevice(deviceId) {
    const tx = await deviceContract.disconnectDevice(deviceId);
    await tx.wait();
    loadDevices();
}

function updateUI() {
    document.getElementById('logged-in').style.display = isLoggedIn ? 'block' : 'none';
    document.getElementById('not-logged-in').style.display = isLoggedIn ? 'none' : 'block';
    document.getElementById('navigation').style.display = isLoggedIn ? 'flex' : 'none';
    document.getElementById('signup-login').style.display = isLoggedIn ? 'none' : 'inline';
    document.getElementById('user-email').style.display = isLoggedIn ? 'inline' : 'none';
    document.getElementById('logout').style.display = isLoggedIn ? 'inline' : 'none';
    if (isLoggedIn) {
        document.getElementById('user-email').textContent = currentUser;
        updateBalances();
        loadDevices();
    }
}

document.addEventListener('DOMContentLoaded', async () => {
    await provider.send("eth_requestAccounts", []);

    document.getElementById('signup-login').addEventListener('click', () => {
        document.getElementById('auth-modal').style.display = 'flex';
    });

    document.getElementById('login-form').addEventListener('submit', async (e) => {
        e.preventDefault();
        const id = document.getElementById('login-id').value;
        const password = document.getElementById('login-password').value;
        if (db.users[id]?.password === password) {
            currentUser = id;
            isLoggedIn = true;
            updateUI();
            document.getElementById('auth-modal').style.display = 'none';
        }
    });

    document.getElementById('signup-form').addEventListener('submit', async (e) => {
        e.preventDefault();
        const email = document.getElementById('signup-email-phone').value;
        db.users[email] = { password: document.getElementById('signup-password').value, assets: {} };
        currentUser = email;
        isLoggedIn = true;
        updateUI();
        document.getElementById('auth-modal').style.display = 'none';
    });

    document.getElementById('logout').addEventListener('click', () => {
        isLoggedIn = false;
        currentUser = null;
        updateUI();
    });

    document.getElementById('consume-zpe').addEventListener('click', async () => {
        const tx = await zpeContract.consumeForService(1000); // Example amount
        await tx.wait();
        await mediator.handleConsumption(1, "ZPE", 1000);
        updateBalances();
    });

    document.getElementById('consume-zpw').addEventListener('click', async () => {
        const tx = await zpwContract.consumeForService(100); // Example amount
        await tx.wait();
        await mediator.handleConsumption(1, "ZPW", 100);
        updateBalances();
    });

    document.getElementById('subscribe-zpp').addEventListener('click', async () => {
        const tx = await zppContract.subscribe();
        await tx.wait();
        await mediator.handleConsumption(1, "ZPP", 100);
        updateBalances();
    });

    document.getElementById('add-device').addEventListener('click', async () => {
        const deviceId = document.getElementById('device-id').value;
        const tx = await deviceContract.addDevice(deviceId);
        await tx.wait();
        loadDevices();
    });

    document.getElementById('use-modal').addEventListener('click', async () => {
        const deviceId = document.getElementById('device-id').value;
        const tx = await deviceContract.useModal(deviceId);
        await tx.wait();
        await mediator.handleModalPurchase(1 * 10**6);
        loadDevices();
        updateBalances();
    });

    document.getElementById('bank-to-goate').addEventListener('click', async () => {
        // Placeholder for bank deposit logic (e.g., via MoonPay/Banxa)
        alert("Bank to Goate Electric deposit initiated");
    });

    document.getElementById('goate-to-bank').addEventListener('click', async () => {
        // Placeholder for bank withdrawal logic
        alert("Goate Electric to Bank withdrawal initiated");
    });

    document.querySelectorAll('.nav-link').forEach(link => {
        link.addEventListener('click', (e) => {
            e.preventDefault();
            document.querySelectorAll('.page').forEach(page => page.classList.remove('active'));
            document.querySelector(link.getAttribute('href')).classList.add('active');
        });
    });

    // Populate swap dropdowns
    const tokens = ["USDC", "ZPE", "ZPW", "ZPP"];
    ["from-asset", "to-asset"].forEach(id => {
        const select = document.getElementById(id);
        tokens.forEach(token => select.innerHTML += `<option value="${token}">${token}</option>`);
    });
});
