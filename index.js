const ethers = require('ethers');
const { StellarSdk } = require('stellar-sdk');

// Simulated database
const db = { users: {}, devices: {}, pins: {}, trustedDevices: {} };
let currentUser, isLoggedIn = false;

let provider, signer, contract, stellarAccount;
const contractAddress = "0xYourDeployedContractAddress";
const contractABI = [/* Full ABI from InstilledInteroperability.sol */];
const mediatorAccount = "0xMediatorAddress";

async function initWeb3() {
    if (window.ethereum) {
        provider = new ethers.providers.Web3Provider(window.ethereum);
        await provider.send("eth_requestAccounts", []);
        signer = provider.getSigner();
        contract = new ethers.Contract(contractAddress, contractABI, signer);
        const keypair = StellarSdk.Keypair.fromSecret("YourStellarSecret");
        stellarAccount = await new StellarSdk.Server('https://horizon.stellar.org').loadAccount(keypair.publicKey());
    }
}

async function login(email, password) {
    if (!db.users[email]) db.users[email] = { password, assets: {}, chain: "4", kyc: {} };
    if (db.users[email].password === password) {
        currentUser = email;
        isLoggedIn = true;
        updateUI();
    } else {
        alert("Invalid credentials");
    }
}

function logout() {
    isLoggedIn = false;
    currentUser = null;
    updateUI();
}

async function updatePortfolio() {
    const user = db.users[currentUser];
    const list = document.getElementById('portfolio-list');
    list.innerHTML = '';
    const tokens = ["USDC", "ZPE", "ZPW", "XLM", "ETH", "BNB", "LINK", "ARB", "BTC", "BTC-LN", "SOL", "CRO"];
    for (const token of tokens) {
        const balance = user.assets[token] || 0;
        const li = document.createElement('li');
        li.textContent = `${token}: ${balance}`;
        list.appendChild(li);
    }
    const mediatorData = await contract.mediatorBalance();
    list.innerHTML += `
        <li>Mediator Total USD: ${ethers.utils.formatUnits(mediatorData.totalUSD, 6)}</li>
        <li>Mediator Public USD: ${ethers.utils.formatUnits(mediatorData.publicUSD, 6)}</li>
        <li>Mediator Capital/Debt: ${ethers.utils.formatUnits(mediatorData.capitalOrDebt, 6)}</li>
    `;
}

async function confirmTransaction(details, callback) {
    const modal = document.getElementById('tx-confirm-modal');
    document.getElementById('tx-details').textContent = details;
    modal.style.display = 'flex';
    document.getElementById('tx-confirm').onclick = async () => {
        modal.style.display = 'none';
        await callback();
    };
}

function updateUI() {
    const loggedIn = document.getElementById('logged-in');
    const notLoggedIn = document.getElementById('not-logged-in');
    const navigation = document.getElementById('navigation');
    const userSection = document.getElementById('user-section');
    const signupLogin = document.getElementById('signup-login');
    const userEmail = document.getElementById('user-email');
    const logoutBtn = document.getElementById('logout');

    if (isLoggedIn) {
        loggedIn.style.display = 'block';
        notLoggedIn.style.display = 'none';
        navigation.style.display = 'flex';
        signupLogin.style.display = 'none';
        userEmail.textContent = currentUser;
        userEmail.style.display = 'inline';
        logoutBtn.style.display = 'inline';
        updatePortfolio();
    } else {
        loggedIn.style.display = 'none';
        notLoggedIn.style.display = 'block';
        navigation.style.display = 'none';
        signupLogin.style.display = 'inline';
        userEmail.style.display = 'none';
        logoutBtn.style.display = 'none';
    }
}

document.addEventListener('DOMContentLoaded', async () => {
    await initWeb3();

    // Navigation
    document.querySelectorAll('.nav-link').forEach(link => {
        link.addEventListener('click', (e) => {
            e.preventDefault();
            document.querySelectorAll('.page').forEach(page => page.classList.remove('active'));
            document.querySelector(link.getAttribute('href')).classList.add('active');
        });
    });

    // Auth Modal
    document.getElementById('signup-login').addEventListener('click', () => {
        document.getElementById('auth-modal').style.display = 'flex';
    });

    document.getElementById('signup-tab').addEventListener('click', () => {
        document.getElementById('signup-tab').classList.add('active');
        document.getElementById('login-tab').classList.remove('active');
        document.getElementById('signup-form').style.display = 'block';
        document.getElementById('login-form').style.display = 'none';
    });

    document.getElementById('login-tab').addEventListener('click', () => {
        document.getElementById('login-tab').classList.add('active');
        document.getElementById('signup-tab').classList.remove('active');
        document.getElementById('login-form').style.display = 'block';
        document.getElementById('signup-form').style.display = 'none';
    });

    document.getElementById('login-form').addEventListener('submit', (e) => {
        e.preventDefault();
        const id = document.getElementById('login-id').value;
        const password = document.getElementById('login-password').value;
        login(id, password);
        document.getElementById('auth-modal').style.display = 'none';
    });

    document.getElementById('signup-form').addEventListener('submit', (e) => {
        e.preventDefault();
        const email = document.getElementById('signup-email-phone').value;
        db.users[email] = {
            password: document.getElementById('signup-password').value,
            assets: {},
            chain: "4",
            kyc: {
                firstName: document.getElementById('signup-first-name').value,
                lastName: document.getElementById('signup-last-name').value,
                address: document.getElementById('signup-address').value,
                dob: document.getElementById('signup-dob').value,
                ssn: document.getElementById('signup-ssn').value
            }
        };
        login(email, db.users[email].password);
        document.getElementById('auth-modal').style.display = 'none';
    });

    document.getElementById('logout').addEventListener('click', logout);

    // Swap and Chain Dropdowns
    const tokens = ["USDC", "ZPE", "ZPW", "XLM", "ETH", "BNB", "LINK", "ARB", "BTC", "BTC-LN", "SOL", "CRO"];
    const chains = ["1", "2", "3", "4", "5", "6", "7"];
    ["from-asset", "to-asset"].forEach(id => {
        const select = document.getElementById(id);
        tokens.forEach(token => {
            const option = document.createElement('option');
            option.value = token;
            option.textContent = token;
            select.appendChild(option);
        });
    });
    const toChain = document.getElementById('to-chain');
    chains.forEach(chain => {
        const option = document.createElement('option');
        option.value = chain;
        option.textContent = chain === "4" ? "Stellar" : chain === "5" ? "Solana" : chain === "6" ? "Cronos" : chain === "7" ? "Bitcoin" : `Chain ${chain}`;
        toChain.appendChild(option);
    });

    document.getElementById('swap-button').addEventListener('click', async () => {
        const fromAsset = document.getElementById('from-asset').value;
        const toAsset = document.getElementById('to-asset').value;
        const toChain = document.getElementById('to-chain').value;
        const amount = ethers.utils.parseUnits(document.getElementById('swap-amount').value || "0", 6);
        confirmTransaction(`Swap ${amount} ${fromAsset} to ${toAsset} on chain ${toChain}`, async () => {
            if (toChain === "7" && toAsset === "BTC-LN") {
                console.log(`Lightning swap: ${amount} ${fromAsset} to BTC-LN`);
            } else {
                await contract.crossChainTransfer("4", toChain, fromAsset, amount, await signer.getAddress(), { value: ethers.utils.parseEther("0.01") });
            }
            document.getElementById('swap-status').textContent = "Status: Swap Complete";
        });
    });

    // Device Management
    const deviceList = document.getElementById('devices-container');
    deviceList.innerHTML = `
        <div class="device-card"><div class="device-info"><p>Ethereum</p></div><div class="slider-group"><button class="slider-btn on" data-chain="1">On</button><button class="slider-btn off active" data-chain="1">Off</button></div></div>
        <div class="device-card"><div class="device-info"><p>BNB Chain</p></div><div class="slider-group"><button class="slider-btn on" data-chain="2">On</button><button class="slider-btn off active" data-chain="2">Off</button></div></div>
        <div class="device-card"><div class="device-info"><p>Polygon</p></div><div class="slider-group"><button class="slider-btn on" data-chain="3">On</button><button class="slider-btn off active" data-chain="3">Off</button></div></div>
        <div class="device-card"><div class="device-info"><p>Stellar</p></div><div class="slider-group"><button class="slider-btn on active" data-chain="4">On</button><button class="slider-btn off" data-chain="4">Off</button></div></div>
        <div class="device-card"><div class="device-info"><p>Solana</p></div><div class="slider-group"><button class="slider-btn on" data-chain="5">On</button><button class="slider-btn off active" data-chain="5">Off</button></div></div>
        <div class="device-card"><div class="device-info"><p>Cronos</p></div><div class="slider-group"><button class="slider-btn on" data-chain="6">On</button><button class="slider-btn off active" data-chain="6">Off</button></div></div>
        <div class="device-card"><div class="device-info"><p>Bitcoin</p></div><div class="slider-group"><button class="slider-btn on" data-chain="7">On</button><button class="slider-btn off active" data-chain="7">Off</button></div></div>
        <div class="device-card"><div class="device-info"><p>Zeropoint Modem</p></div><div class="slider-group"><button class="slider-btn on" data-device="zeropoint">On</button><button class="slider-btn off active" data-device="zeropoint">Off</button></div></div>
        <div class="device-card"><div class="device-info"><p>ZeropointWifi Modem</p></div><div class="slider-group"><button class="slider-btn on" data-device="zeropointwifi">On</button><button class="slider-btn off active" data-device="zeropointwifi">Off</button></div></div>
    `;

    document.querySelectorAll('.slider-btn').forEach(btn => {
        btn.addEventListener('click', async () => {
            const chain = btn.dataset.chain;
            const device = btn.dataset.device;
            const isOn = btn.classList.contains('on');
            const sibling = btn.parentElement.querySelector(isOn ? '.off' : '.on');
            btn.classList.add('active');
            sibling.classList.remove('active');
            if (chain) {
                db.users[currentUser].chain = isOn ? chain : "4";
                if (isOn) await contract.crossChainTransfer("4", chain, "USD", db.users[currentUser].assets["USD"] || 0, currentUser);
            } else if (device) {
                db.devices[currentUser] = db.devices[currentUser] || {};
                db.devices[currentUser][device] = isOn;
            }
        });
    });

    // Mock login for testing
    login("cj03nes@gmail.com", "password");
});
