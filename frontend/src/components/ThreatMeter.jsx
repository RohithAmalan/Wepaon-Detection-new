import React from 'react';
import { ShieldAlert, ShieldCheck, Shield } from 'lucide-react';

const ThreatMeter = ({ status }) => {
    const { level, crowd_count, weapons, description } = status;

    const getStyle = () => {
        switch (level) {
            case 'HIGH': return { color: 'text-danger', bg: 'bg-danger', icon: ShieldAlert, label: 'CRITICAL THREAT' };
            case 'MEDIUM': return { color: 'text-warning', bg: 'bg-warning', icon: ShieldAlert, label: 'ELEVATED RISK' };
            case 'LOW': return { color: 'text-blue-400', bg: 'bg-blue-500', icon: Shield, label: 'POTENTIAL THREAT' };
            default: return { color: 'text-success', bg: 'bg-success', icon: ShieldCheck, label: 'SYSTEM SAFE' };
        }
    };

    const style = getStyle();
    const Icon = style.icon;

    return (
        <div className="glass rounded-xl p-6 flex flex-col items-center justify-center relative overflow-hidden">
            {/* Background Glow */}
            <div className={`absolute -top-10 -right-10 w-32 h-32 rounded-full ${style.bg} blur-[80px] opacity-20`}></div>

            <div className={`p-4 rounded-full bg-dark-800 border-2 ${style.color.replace('text', 'border')} mb-4 relative z-10`}>
                <Icon size={48} className={style.color} />
            </div>

            <h2 className={`text-2xl font-bold tracking-widest ${style.color} mb-1`}>{style.label}</h2>
            <p className="text-white/60 text-sm mb-6 text-center max-w-[80%]">{description}</p>

            <div className="grid grid-cols-2 gap-4 w-full">
                <div className="bg-dark-800/50 rounded-lg p-3 text-center border border-white/5">
                    <span className="block text-xs text-white/40 uppercase mb-1">Crowd Density</span>
                    <span className="text-xl font-mono font-bold text-white">{crowd_count}</span>
                </div>
                <div className="bg-dark-800/50 rounded-lg p-3 text-center border border-white/5">
                    <span className="block text-xs text-white/40 uppercase mb-1">Items Detected</span>
                    <span className="text-xl font-mono font-bold text-white">
                        {weapons.length > 0 ? weapons.join(', ') : 'None'}
                    </span>
                </div>
            </div>
        </div>
    );
};

export default ThreatMeter;
