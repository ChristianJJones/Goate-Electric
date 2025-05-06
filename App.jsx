import React, { useState, useEffect } from 'react';
import './App.css';
import Header from './components/Header';
import Services from './components/Services';
import LoginModal from './components/LoginModal';
import FeatureModal from './components/FeatureModal';
import { initWeb3WithInteroperability, setActiveChain } from './web3/instilledInteroperability';
import { usdMediator } from './web3/usdMediator';

const supportedAssets = ['USD', 'PI', 'ZPE', 'ZPP', 'ZPW', 'ZHV', 'GOATE', 'GySt', 'SD', 'ZGI', 'GP', 'zS'];

function App() {
  const [currentUser, setCurrentUser] = useState(null);
  const [userPin, setUserPin] = useState(null);
  const [userPassword, setUserPassword] = useState(null);
  const [userData, setUserData] = useState({
    piAddress: null,
    email: null,
    appleId: null,
    bank: { accountNumber: null, routingNumber: null },
    card: { number: null, expiration: null, cvc: null },
    phoneNumber: null,
    ssn: null,
    username: null,
    address: null,
  });
  const [devices, setDevices] = useState([]);
  const [isNewDevice, setIsNewDevice] = useState(false);
  const [activeChain, setActiveChainState] = useState('Stellar');
  const [balances, setBalances] = useState({});
  const [showLoginModal, setShowLoginModal] = useState(false);
  const [featureModal, setFeatureModal] = useState({ show: false, title: '', content: null });

  useEffect(() => {
    const initialize = async () => {
      await initWeb3WithInteroperability(setActiveChainState);
      await updateBalances();
    };
    initialize();
  }, []);

  const updateBalances = async () => {
    if (!currentUser) return;
    const newBalances = {};
    for (const asset of supportedAssets) {
      try {
        let balance;
        if (activeChain === 'Pi Network' || activeChain === 'Stellar') {
          balance = Math.random() * 100; // Mock for non-EVM chains
        } else {
          balance = await window.tokenManager.getBalance(asset);
          balance = ethers.utils.formatUnits(balance, 18);
        }
        newBalances[asset.toLowerCase()] = balance.toFixed(2);
      } catch (error) {
        console.error(`Error fetching balance for ${asset}:`, error);
      }
    }
    setBalances(newBalances);
  };

  const handleLogin = async (method, identifier) => {
    if (isNewDevice || !localStorage.getItem('deviceId')) {
      const password = prompt('Enter password for new device/IP:');
      if (password !== userPassword) {
        alert('Invalid password.');
        return;
      }
    }

    setCurrentUser(identifier);
    setUserData(prev => ({ ...prev, username: identifier.split('@')[0] || identifier }));

    if (!userPin) {
      let pin = prompt('Create a 4-digit PIN:');
      while (!/^\d{4}$/.test(pin)) {
        pin = prompt('Invalid PIN. Create a 4-digit PIN:');
      }
      setUserPin(pin);
      let password = prompt('Create a password:');
      let confirmPassword = prompt('Confirm your password:');
      while (password !== confirmPassword) {
        password = prompt('Passwords do not match. Create a password:');
        confirmPassword = prompt('Confirm your password:');
      }
      setUserPassword(password);
    }

    if (!userData.bank.accountNumber) {
      setUserData(prev => ({
        ...prev,
        bank: {
          accountNumber: 'XXXX' + Math.floor(Math.random() * 100000000).toString().padStart(8, '0'),
          routingNumber: '0' + Math.floor(Math.random() * 100000000).toString().padStart(8, '0'),
        },
      }));
    }
    if (!userData.card.number) {
      const number = '4' + Math.floor(Math.random() * 10**15).toString().padStart(15, '0');
      const expiration = new Date();
      expiration.setFullYear(expiration.getFullYear() + 20);
      const expStr = `${expiration.getMonth() + 1}/${expiration.getFullYear() % 100}`;
      const cvc = Math.floor(Math.random() * 1000).toString().padStart(3, '0');
      setUserData(prev => ({ ...prev, card: { number, expiration: expStr, cvc } }));
    }

    if (!userData.phoneNumber) {
      setUserData(prev => ({ ...prev, phoneNumber: prompt('Enter phone number:') }));
    }
    if (!userData.ssn) {
      setUserData(prev => ({ ...prev, ssn: prompt('Enter SSN (optional):') }));
    }

    await updateBalances();
    setShowLoginModal(false);
  };

  const handleNavigateTo = (service) => {
    if (!currentUser) {
      alert('Please login first.');
      return;
    }
    setFeatureModal({ show: true, title: service === 'goate-electric' ? 'Goate Electric' : service === 'gerastyx' ? 'Gerastyx Playground' : 'GoatePig', content: service });
  };

  return (
    <div className="App">
      <Header user={currentUser} setShowLoginModal={setShowLoginModal} devices={devices} setDevices={setDevices} />
      <main>
        <Services navigateTo={handleNavigateTo} />
      </main>
      <footer>
        <p>THE LAMBDUCK, INC.</p>
        <p>@thelambduckinc</p>
      </footer>
      {showLoginModal && <LoginModal onClose={() => setShowLoginModal(false)} onLogin={handleLogin} />}
      {featureModal.show && (
        <FeatureModal
          title={featureModal.title}
          content={featureModal.content}
          onClose={() => setFeatureModal({ show: false, title: '', content: null })}
          balances={balances}
          updateBalances={updateBalances}
          devices={devices}
          setDevices={setDevices}
          userPin={userPin}
          activeChain={activeChain}
          setActiveChain={setActiveChain}
        />
      )}
    </div>
  );
}

export default App;
