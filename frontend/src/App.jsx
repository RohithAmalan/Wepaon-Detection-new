import React, { useState, useEffect } from 'react';
import { LayoutDashboard, Bell, Settings, Menu, Shield, AlertTriangle, Download } from 'lucide-react';
import VideoFeed from './components/VideoFeed';
import ThreatMeter from './components/ThreatMeter';

function App() {
  const [status, setStatus] = useState({
    level: 'SAFE',
    crowd_count: 0,
    weapons: [],
    description: 'Connecting...',
    timestamp: 0
  });
  const [alerts, setAlerts] = useState([]);
  const [showEmergency, setShowEmergency] = useState(false);

  useEffect(() => {
    if (status.level === 'HIGH') {
      setShowEmergency(true);
    } else if (status.level === 'SAFE') {
      setShowEmergency(false);
    }
  }, [status.level]);

  useEffect(() => {
    const interval = setInterval(() => {
      fetch('/api/status')
        .then(res => res.json())
        .then(data => {
          setStatus(data);
          if (data.level !== 'SAFE') {
            setAlerts(prev => {
              // Prevent duplicates logic could go here
              const newAlert = { ...data, id: Date.now() };
              return [newAlert, ...prev].slice(0, 10);
            });
          }
        })
        .catch(err => console.error(err));
    }, 1000); // 1-second polling
    return () => clearInterval(interval);
  }, []);

  return (
    <div className="min-h-screen bg-dark-900 text-white flex relative overflow-hidden">
      {/* Emergency Overlay */}
      {showEmergency && (
        <div className="fixed inset-0 z-50 bg-red-600 flex flex-col items-center justify-center animate-pulse">
          <div className="bg-white p-10 rounded-3xl shadow-2xl flex flex-col items-center gap-6 max-w-md w-full mx-4">
            <AlertTriangle size={80} className="text-red-600" />
            <h1 className="text-4xl font-black text-red-600 text-center tracking-tighter">
              WEAPON DETECTED!
            </h1>
            <p className="text-gray-800 font-bold text-center text-lg">
              Immediate Action Required
            </p>

            <div className="w-full h-1 bg-gray-200 rounded-full" />

            <div className="grid grid-cols-2 gap-4 w-full">
              <button className="bg-red-600 hover:bg-red-700 text-white font-bold py-4 rounded-xl shadow-lg transition-transform active:scale-95">
                ALARM ON
              </button>
              <button className="bg-gray-800 hover:bg-black text-white font-bold py-4 rounded-xl shadow-lg transition-transform active:scale-95">
                CLOSE GATE
              </button>
            </div>

            <button
              onClick={() => setShowEmergency(false)}
              className="mt-4 text-gray-500 underline text-sm hover:text-gray-800"
            >
              Dismiss / Back to Normal
            </button>
          </div>
        </div>
      )}

      {/* Sidebar */}
      <aside className="w-20 md:w-64 border-r border-white/5 bg-dark-800/50 flex flex-col p-4">
        <div className="flex items-center gap-3 mb-10 px-2">
          <div className="w-10 h-10 rounded-lg bg-primary-600 flex items-center justify-center shrink-0">
            <Shield size={24} />
          </div>
          <h1 className="hidden md:block font-bold text-lg tracking-tight leading-tight">
            Sentinel<br /><span className="text-primary-500 font-normal">Guard AI</span>
          </h1>
        </div>

        <nav className="space-y-2 flex-1">
          <NavItem icon={LayoutDashboard} label="Dashboard" active />
          <NavItem icon={Bell} label="Alerts" />
          <NavItem icon={Settings} label="Settings" />
        </nav>

        <div className="hidden md:block p-4 rounded-xl bg-gradient-to-br from-primary-600/20 to-primary-900/10 border border-primary-500/20">
          <p className="text-xs text-primary-300 mb-2">Get Mobile App</p>
          <a
            href="/Weapon.apk"
            download
            className="flex items-center gap-2 w-full justify-center bg-primary-600 hover:bg-primary-500 text-white py-2 rounded-lg text-sm font-bold transition-all shadow-lg shadow-primary-600/20"
          >
            <Download size={16} /> Download APK
          </a>
        </div>

        <div className="hidden md:block p-4 rounded-xl bg-gradient-to-br from-primary-600/20 to-primary-900/10 border border-primary-500/20 mt-4">
          <p className="text-xs text-primary-300 mb-1">System Status</p>
          <div className="flex items-center gap-2">
            <span className="w-2 h-2 rounded-full bg-green-500 animate-pulse"></span>
            <span className="text-sm font-medium text-green-400">Online</span>
          </div>
        </div>
      </aside>

      {/* Main Content */}
      <main className="flex-1 p-6 lg:p-10 overflow-auto">
        <header className="flex justify-between items-center mb-8">
          <div>
            <h2 className="text-3xl font-bold mb-1">Live Surveillance</h2>
            <p className="text-white/40 text-sm">Real-time crowd analysis and threat detection.</p>
          </div>
          <div className="flex items-center gap-4">
            <a
              href="/Weapon.apk"
              download
              className="flex items-center gap-2 bg-primary-600 hover:bg-primary-500 text-white px-4 py-2 rounded-lg text-sm font-bold transition-all shadow-lg shadow-primary-600/20"
            >
              <Download size={18} />
              <span className="hidden sm:inline">Get App</span>
            </a>
            <div className="bg-dark-700/50 p-2 rounded-full border border-white/10">
              <img src="https://ui-avatars.com/api/?name=Admin&background=random" className="w-8 h-8 rounded-full" alt="User" />
            </div>
          </div>
        </header>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Left Column: Video Feeds */}
          <div className="lg:col-span-2 space-y-6">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {/* Primary Feed (Local) */}
              <div className="md:col-span-2">
                <VideoFeed
                  src={`http://${window.location.hostname}:8000/video_feed`}
                  label="Main Camera Feed (Fused)"
                  isActive
                />
              </div>
              {/* Secondary Feeds (Placeholders/Active) */}
              {/* <VideoFeed src="/video_feed/1" label="Gate Input 1" /> */}
              {/* <VideoFeed src="/video_feed/2" label="Street View" /> */}
            </div>
          </div>

          {/* Right Column: Analytics & Alerts */}
          <div className="space-y-6">
            <ThreatMeter status={status} />

            <div className="glass rounded-xl p-5 min-h-[400px]">
              <div className="flex justify-between items-center mb-4">
                <h3 className="font-bold flex items-center gap-2">
                  <Bell size={18} /> Recent Alerts
                </h3>
                <span className="text-xs bg-white/10 px-2 py-1 rounded-full">{alerts.length}</span>
              </div>

              <div className="space-y-3">
                {alerts.length === 0 ? (
                  <div className="text-center py-10 text-white/20 text-sm italic">
                    No threats detected recently.
                  </div>
                ) : (
                  alerts.map((alert, i) => (
                    <div key={i} className={`p-3 rounded-lg border-l-4 ${alert.level === 'HIGH' ? 'border-danger bg-danger/10' : 'border-warning bg-warning/10'}`}>
                      <div className="flex justify-between mb-1">
                        <span className={`text-xs font-bold ${alert.level === 'HIGH' ? 'text-red-400' : 'text-orange-400'}`}>{alert.level} THREAT</span>
                        <span className="text-[10px] text-white/40">{new Date(alert.timestamp * 1000).toLocaleTimeString()}</span>
                      </div>
                      <p className="text-sm font-medium text-white/90">{alert.description}</p>
                    </div>
                  ))
                )}
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}

const NavItem = ({ icon: Icon, label, active }) => (
  <button className={`w-full flex items-center gap-3 px-4 py-3 rounded-lg transition-all ${active ? 'bg-primary-600 text-white shadow-lg shadow-primary-600/20' : 'text-white/50 hover:bg-white/5 hover:text-white'}`}>
    <Icon size={20} />
    <span className="hidden md:block text-sm font-medium">{label}</span>
  </button>
);

export default App;
