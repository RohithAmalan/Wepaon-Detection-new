
class ThreatAnalyzer:
    def __init__(self):
        # Configuration
        self.CROWD_THRESHOLD_LOW = 3
        self.CROWD_THRESHOLD_HIGH = 5
        
        # Class IDs (assuming COCO dataset for 'person' which is 0)
        # You might need to adjust these based on your specific custom model's classes
        # If your model is trained ONLY on weapons, you won't detect people.
        # But YOLOv7 standard weights/COCO include person.
        # If using a custom model trained only on weapons, we need to know if it has a 'person' class.
        # For now, I'll assume we pass class names string to be safe.
        
        self.GUN_KEYWORDS = ['pistol', 'rifle', 'gun', 'firearm']
        self.WEAPON_KEYWORDS = ['knife', 'bat', 'pistol', 'rifle', 'gun', 'firearm']

    def analyze_threat(self, detections, class_names):
        """
        Analyze detections to determine threat level.
        
        Args:
            detections (list): List of detection tuples (class_id, confidence, bbox). 
                               Or just class_ids if that's all we have.
            class_names (list): List of class names corresponding to class_ids.
            
        Returns:
            dict: {
                'threat_level': 'SAFE' | 'LOW' | 'MEDIUM' | 'HIGH',
                'crowd_count': int,
                'weapon_detected': list of strings,
                'description': str
            }
        """
        crowd_count = 0
        weapons_found = []
        guns_found = []
        
        for cls_id in detections:
            name = class_names[int(cls_id)]
            
            if name == 'person':
                crowd_count += 1
            elif any(k in name.lower() for k in self.WEAPON_KEYWORDS):
                weapons_found.append(name)
                if any(gk in name.lower() for gk in self.GUN_KEYWORDS):
                    guns_found.append(name)
        
        threat_level = 'SAFE'
        description = "No detections"
        
        has_weapon = len(weapons_found) > 0
        has_gun = len(guns_found) > 0
        
        if not has_weapon:
            threat_level = 'SAFE'
            description = f"Safe. Crowd count: {crowd_count}"
            
        else:
            # We have a weapon
            if has_gun:
                if crowd_count >= self.CROWD_THRESHOLD_LOW or len(guns_found) > 1:
                    threat_level = 'HIGH'
                    description = f"HIGH THREAT! Gun detected in crowd ({crowd_count}) or multi-gun."
                else:
                    threat_level = 'MEDIUM'
                    description = f"MEDIUM THREAT. Gun detected. Low crowd ({crowd_count})."
            else:
                # Weapon but not a gun (e.g. Knife)
                if crowd_count >= self.CROWD_THRESHOLD_LOW:
                    threat_level = 'HIGH'
                    description = f"HIGH THREAT! Dangerous weapon ({weapons_found[0]}) detected in crowd."
                else:
                    threat_level = 'MEDIUM'
                    description = f"MEDIUM THREAT. Dangerous weapon ({weapons_found[0]}) detected."

        return {
            'threat_level': threat_level,
            'crowd_count': crowd_count,
            'weapons_detected': weapons_found,
            'description': description
        }
