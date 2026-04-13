import React from 'react';
import { ShieldAlert, ShieldCheck, Shield, Users, Swords } from 'lucide-react';

const ThreatMeter = ({ status }) => {
    const { level, crowd_count, weapons, description } = status;

    const cfg = {
        HIGH:   { label: 'CRITICAL THREAT', icon: ShieldAlert, ring: 'ring-red-400',    text: 'text-red-600',    bg: 'bg-red-50',    badge: 'bg-red-100 text-red-700' },
        MEDIUM: { label: 'ELEVATED RISK',   icon: ShieldAlert, ring: 'ring-amber-400',  text: 'text-amber-600',  bg: 'bg-amber-50',  badge: 'bg-amber-100 text-amber-700' },
        LOW:    { label: 'POTENTIAL RISK',  icon: Shield,      ring: 'ring-blue-400',   text: 'text-blue-600',   bg: 'bg-blue-50',   badge: 'bg-blue-100 text-blue-700' },
        SAFE:   { label: 'SYSTEM SAFE',     icon: ShieldCheck, ring: 'ring-emerald-400',text: 'text-emerald-600',bg: 'bg-emerald-50',badge: 'bg-emerald-100 text-emerald-700' },
    };
    const s = cfg[level] || cfg.SAFE;
    const Icon = s.icon;

    return (
        <div className="glass rounded-2xl p-6">
            {/* Status Icon */}
            <div className="flex flex-col items-center mb-5">
                <div className={`p-4 rounded-full ring-4 ${s.ring} ${s.bg} mb-3 transition-all`}>
                    <Icon size={44} className={s.text} />
                </div>
                <h2 className={`text-xl font-black tracking-widest ${s.text}`}>{s.label}</h2>
                <p className="text-slate-500 text-xs mt-1 text-center max-w-[85%]">{description}</p>
            </div>

            {/* Stat chips */}
            <div className="grid grid-cols-2 gap-3">
                <div className="stat-chip">
                    <div className="flex items-center justify-center gap-1.5 text-slate-400 mb-1.5">
                        <Users size={14} />
                        <span className="text-[11px] uppercase tracking-wider font-medium">Crowd</span>
                    </div>
                    <span className="text-2xl font-black text-slate-800">{crowd_count}</span>
                </div>
                <div className="stat-chip">
                    <div className="flex items-center justify-center gap-1.5 text-slate-400 mb-1.5">
                        <Swords size={14} />
                        <span className="text-[11px] uppercase tracking-wider font-medium">Threats</span>
                    </div>
                    <span className={`text-sm font-bold ${weapons?.length > 0 ? 'text-red-600' : 'text-emerald-600'}`}>
                        {weapons?.length > 0 ? weapons.join(', ') : 'None'}
                    </span>
                </div>
            </div>
        </div>
    );
};

export default ThreatMeter;
