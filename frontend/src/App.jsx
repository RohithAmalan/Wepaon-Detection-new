import React, { useState, useEffect } from 'react';
import { LayoutDashboard, Bell, Settings, Shield, AlertTriangle, Download, Volume2, DoorClosed, X } from 'lucide-react';
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
  const [activeTab, setActiveTab] = useState('dashboard');
  const [actionMsg, setActionMsg] = useState('');

  useEffect(() => {
    if (status.level === 'HIGH') setShowEmergency(true);
    else if (status.level === 'SAFE') setShowEmergency(false);
  }, [status.level]);

  useEffect(() => {
    // 1. Poll live status for the threat meter & emergency popup
    const fetchStatus = () => {
      fetch('/api/status')
        .then(res => res.json())
        .then(data => setStatus(data))
        .catch(err => console.error(err));
    };

    // 2. Poll the database for permanent logs
    const fetchLogs = () => {
      fetch('/api/logs')
        .then(res => res.json())
        .then(data => {
          if (data.status === 'success') {
            setAlerts(data.logs);
          }
        })
        .catch(err => console.error(err));
    };

    const interval = setInterval(() => {
      fetchStatus();
      fetchLogs();
    }, 1500); // 1.5 seconds

    // Initial fetch
    fetchStatus();
    fetchLogs();

    return () => clearInterval(interval);
  }, []);

  const triggerAction = async (endpoint, label) => {
    try {
      const res = await fetch(endpoint, { method: 'POST' });
      const data = await res.json();
      setActionMsg(data.status === 'success' ? `✅ ${label} sent!` : `❌ ${label} failed.`);
    } catch {
      setActionMsg(`❌ Server unreachable`);
    }
    setTimeout(() => setActionMsg(''), 3000);
  };

  const threatColors = {
    HIGH:   { bg: 'bg-red-500/10',    border: 'border-red-400',    text: 'text-red-600',    badge: 'bg-red-100 text-red-700' },
    MEDIUM: { bg: 'bg-amber-500/10',  border: 'border-amber-400',  text: 'text-amber-600',  badge: 'bg-amber-100 text-amber-700' },
    SAFE:   { bg: 'bg-emerald-500/10',border: 'border-emerald-400',text: 'text-emerald-600',badge: 'bg-emerald-100 text-emerald-700' },
  };
  const tc = threatColors[status.level] || threatColors.SAFE;

  return (
    <div className="min-h-screen flex relative overflow-hidden">

      {/* ── Emergency Overlay ── */}
      {showEmergency && (
        <div className="fixed inset-0 z-50 flex items-center justify-center"
          style={{ background: 'rgba(239,68,68,0.92)', backdropFilter: 'blur(6px)' }}>
          <div className="bg-white rounded-3xl shadow-2xl p-10 max-w-md w-full mx-4 flex flex-col items-center gap-5">
            <AlertTriangle size={72} className="text-red-600 animate-bounce" />
            <h1 className="text-4xl font-black text-red-600 text-center tracking-tight">WEAPON DETECTED!</h1>
            <p className="text-slate-600 text-center">Immediate action required. Use the controls below.</p>
            {actionMsg && (
              <div className="w-full text-center py-2 px-4 rounded-xl bg-slate-100 text-slate-700 text-sm font-semibold">
                {actionMsg}
              </div>
            )}
            <div className="grid grid-cols-2 gap-4 w-full">
              <button
                onClick={() => triggerAction('/api/trigger_alarm', 'Alarm')}
                className="action-btn bg-red-600 hover:bg-red-700 text-white font-bold py-4 rounded-2xl shadow-lg flex flex-col items-center gap-1"
              >
                <Volume2 size={22} />
                <span className="text-sm">ALARM ON</span>
              </button>
              <button
                onClick={() => triggerAction('/api/close_gate', 'Gate Close')}
                className="action-btn bg-slate-800 hover:bg-black text-white font-bold py-4 rounded-2xl shadow-lg flex flex-col items-center gap-1"
              >
                <DoorClosed size={22} />
                <span className="text-sm">CLOSE GATE</span>
              </button>
            </div>
            <button
              onClick={() => setShowEmergency(false)}
              className="flex items-center gap-2 text-slate-400 hover:text-slate-700 text-sm mt-2 transition-colors"
            >
              <X size={16} /> Dismiss / Back to Normal
            </button>
          </div>
        </div>
      )}

      {/* ── Sidebar ── */}
      <aside className="glass-sidebar w-20 md:w-64 flex flex-col p-4 gap-6 shrink-0">
        {/* Logo */}
        <div className="flex items-center gap-3 px-2 pt-2">
          <div className="w-10 h-10 rounded-xl bg-primary-600 flex items-center justify-center shrink-0 shadow-lg shadow-primary-600/30">
            <Shield size={22} className="text-white" />
          </div>
          <div className="hidden md:block">
            <p className="font-bold text-slate-800 leading-tight">Sentinel</p>
            <p className="text-primary-600 text-xs font-medium">Guard AI</p>
          </div>
        </div>

        {/* Nav */}
        <nav className="space-y-1 flex-1">
          <NavItem icon={LayoutDashboard} label="Dashboard" active={activeTab === 'dashboard'} onClick={() => setActiveTab('dashboard')} />
          <NavItem icon={Bell}            label={`Alerts (${alerts.length})`} active={activeTab === 'alerts'} onClick={() => setActiveTab('alerts')} />
          <NavItem icon={Settings}        label="Settings" active={activeTab === 'settings'} onClick={() => setActiveTab('settings')} />
        </nav>

        {/* Download APK */}
        <div className="hidden md:block">
          <a href="/Weapon.apk" download
            className="action-btn flex items-center justify-center gap-2 w-full bg-primary-600 hover:bg-primary-500 text-white py-2.5 rounded-xl text-sm font-bold shadow-lg shadow-primary-600/20 transition-colors">
            <Download size={16} /> Download APK
          </a>
        </div>

        {/* Status dot */}
        <div className="hidden md:flex items-center gap-2 px-2 pb-2">
          <span className="w-2.5 h-2.5 rounded-full bg-emerald-500 animate-pulse" />
          <span className="text-xs font-semibold text-emerald-600">System Online</span>
        </div>
      </aside>

      {/* ── Main ── */}
      <main className="flex-1 flex flex-col overflow-hidden">
        {/* Header */}
        <header className={`glass border-b border-white/60 px-8 py-4 flex items-center justify-between transition-colors ${tc.border}`}>
          <div>
            <h2 className="text-2xl font-bold text-slate-800">Live Surveillance</h2>
            <p className="text-slate-500 text-sm">Real-time crowd analysis and threat detection</p>
          </div>
          <div className="flex items-center gap-3">
            {/* Threat badge */}
            <span className={`px-3 py-1 rounded-full text-xs font-bold ${tc.badge}`}>
              {status.level}
            </span>
            <img src="https://ui-avatars.com/api/?name=Admin&background=random" className="w-9 h-9 rounded-full border-2 border-white shadow" alt="User" />
          </div>
        </header>

        {/* Content */}
        <div className="flex-1 overflow-auto p-6 lg:p-8">
          {activeTab === 'dashboard' && (
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
              {/* Left: Video feed */}
              <div className="lg:col-span-2 space-y-5">
                <div className={`glass rounded-2xl overflow-hidden border-2 transition-colors ${tc.border}`}>
                  <VideoFeed
                    src={`http://${window.location.hostname}:8000/video_feed`}
                    label="Main Camera Feed (Fused)"
                    isActive
                  />
                </div>

                {/* Action buttons — always visible below feed */}
                <div className="glass rounded-2xl p-5">
                  <h3 className="text-slate-700 font-semibold mb-3 text-sm uppercase tracking-wider">Quick Controls</h3>
                  {actionMsg && (
                    <div className="mb-3 text-center py-2 px-4 rounded-xl bg-slate-100 text-slate-700 text-sm font-semibold">
                      {actionMsg}
                    </div>
                  )}
                  <div className="grid grid-cols-2 gap-4">
                    <button
                      onClick={() => triggerAction('/api/trigger_alarm', 'Alarm')}
                      className="action-btn flex items-center justify-center gap-2 bg-red-600 hover:bg-red-700 text-white font-bold py-3 rounded-xl shadow-md shadow-red-500/20"
                    >
                      <Volume2 size={18} /> ALARM ON
                    </button>
                    <button
                      onClick={() => triggerAction('/api/close_gate', 'Gate Close')}
                      className="action-btn flex items-center justify-center gap-2 bg-slate-700 hover:bg-slate-900 text-white font-bold py-3 rounded-xl shadow-md"
                    >
                      <DoorClosed size={18} /> CLOSE GATE
                    </button>
                  </div>
                </div>
              </div>

              {/* Right: Analytics */}
              <div className="space-y-5">
                <ThreatMeter status={status} />

                {/* Recent alerts */}
                <div className="glass rounded-2xl p-5">
                  <div className="flex items-center justify-between mb-3">
                    <h3 className="text-slate-700 font-semibold flex items-center gap-2 text-sm"><Bell size={16} /> Recent Alerts</h3>
                    <span className="text-xs bg-slate-100 text-slate-600 px-2 py-0.5 rounded-full font-medium">{alerts.length}</span>
                  </div>
                  <div className="space-y-2 max-h-64 overflow-y-auto">
                    {alerts.length === 0 ? (
                      <p className="text-center text-slate-400 text-sm py-8 italic">No threats detected recently.</p>
                    ) : alerts.map((alert, i) => (
                      <div key={i} className={`p-3 rounded-xl border-l-4 ${alert.level === 'HIGH' ? 'border-red-500 bg-red-50' : 'border-amber-400 bg-amber-50'}`}>
                        <div className="flex justify-between mb-0.5">
                          <span className={`text-xs font-bold ${alert.level === 'HIGH' ? 'text-red-600' : 'text-amber-600'}`}>{alert.level} THREAT</span>
                          <span className="text-[10px] text-slate-400">{alert.timestamp}</span>
                        </div>
                        <p className="text-sm text-slate-700">{alert.description}</p>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            </div>
          )}

          {activeTab === 'alerts' && (
            <div className="glass rounded-2xl p-6">
              <h3 className="text-slate-800 font-bold text-lg mb-4 flex items-center gap-2"><Bell size={20} /> All Alerts</h3>
              <div className="space-y-3">
                {alerts.length === 0
                  ? <p className="text-slate-400 text-center py-12 italic">No threats recorded in this session.</p>
                  : alerts.map((alert, i) => (
                    <div key={i} className={`p-4 rounded-xl border-l-4 ${alert.level === 'HIGH' ? 'border-red-500 bg-red-50' : 'border-amber-400 bg-amber-50'}`}>
                      <div className="flex justify-between mb-1">
                        <span className={`text-sm font-bold ${alert.level === 'HIGH' ? 'text-red-700' : 'text-amber-700'}`}>{alert.level} THREAT</span>
                        <span className="text-xs text-slate-400">{alert.timestamp}</span>
                      </div>
                      <p className="text-sm text-slate-700">{alert.description}</p>
                      {alert.weapons?.length > 0 && <p className="text-xs text-slate-500 mt-1">Weapons: {alert.weapons.join(', ')}</p>}
                    </div>
                  ))
                }
              </div>
            </div>
          )}

          {activeTab === 'settings' && (
            <div className="glass rounded-2xl p-6 max-w-lg">
              <h3 className="text-slate-800 font-bold text-lg mb-4">System Settings</h3>
              <div className="space-y-3 text-sm text-slate-600">
                <div className="flex justify-between py-3 border-b border-slate-100">
                  <span>Backend Endpoint</span>
                  <code className="bg-slate-100 px-2 py-0.5 rounded text-slate-700">{window.location.hostname}:8000</code>
                </div>
                <div className="flex justify-between py-3 border-b border-slate-100">
                  <span>MQTT Broker</span>
                  <code className="bg-slate-100 px-2 py-0.5 rounded text-slate-700">broker.hivemq.com:1883</code>
                </div>
                <div className="flex justify-between py-3">
                  <span>Polling Interval</span>
                  <code className="bg-slate-100 px-2 py-0.5 rounded text-slate-700">1 second</code>
                </div>
              </div>
            </div>
          )}
        </div>
      </main>
    </div>
  );
}

const NavItem = ({ icon: Icon, label, active, onClick }) => (
  <button
    onClick={onClick}
    className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl transition-all text-left ${
      active
        ? 'bg-primary-600 text-white shadow-lg shadow-primary-600/20'
        : 'text-slate-500 hover:bg-white/60 hover:text-slate-800'
    }`}
  >
    <Icon size={20} className="shrink-0" />
    <span className="hidden md:block text-sm font-medium">{label}</span>
  </button>
);

export default App;
