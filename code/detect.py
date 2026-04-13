import argparse
import time
from pathlib import Path

import cv2
import torch
import pandas as pd
import torch.backends.cudnn as cudnn
from numpy import random

from models.experimental import attempt_load
from utils.datasets import LoadStreams, LoadImages
from utils.general import check_img_size, check_requirements, check_imshow, non_max_suppression, apply_classifier, \
    scale_coords, xyxy2xywh, strip_optimizer, set_logging, increment_path
from utils.plots import plot_one_box
from utils.torch_utils import select_device, load_classifier, time_synchronized, TracedModel


from flask import Flask, Response, render_template, jsonify, request
from flask_cors import CORS
import logging
log = logging.getLogger('werkzeug')
log.setLevel(logging.ERROR) # Disable request logging
import threading

import socket
import sqlite3
import datetime

# --- Database Setup ---
DB_NAME = "threat_logs.db"
def init_db():
    conn = sqlite3.connect(DB_NAME)
    c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS logs
                 (id INTEGER PRIMARY KEY AUTOINCREMENT,
                  timestamp TEXT,
                  level TEXT,
                  crowd_count INTEGER,
                  weapons TEXT,
                  description TEXT)''')
    conn.commit()
    conn.close()

def log_threat_to_db(level, crowd_count, weapons, description):
    # Only log HIGH or MEDIUM threats
    if level not in ["HIGH", "MEDIUM"]:
        return
    conn = sqlite3.connect(DB_NAME)
    c = conn.cursor()
    now_str = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    weapons_str = ", ".join(weapons) if isinstance(weapons, list) else str(weapons)
    c.execute("INSERT INTO logs (timestamp, level, crowd_count, weapons, description) VALUES (?, ?, ?, ?, ?)",
              (now_str, level, crowd_count, weapons_str, description))
    conn.commit()
    conn.close()

init_db()
# ----------------------

s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
s.connect(("8.8.8.8", 80))
ip_address = s.getsockname()[0]
print(ip_address)

import paho.mqtt.client as mqtt
import requests
import json
from threat_analyzer import ThreatAnalyzer

# Global storage for frames and status
lock = threading.Lock()
camera_frames = {}  # { source_index_or_id: frame }
latest_threat_status = {
    "level": "SAFE",
    "crowd_count": 0,
    "weapons": [],
    "description": "System Initializing",
    "sources": []
}
system_status = "INITIALIZING" # INITIALIZING, RUNNING, ERROR

analyzer = ThreatAnalyzer()

def on_message(client, userdata, message):
    print("li")
    data1 =[]
    receivedstring = str(message.payload.decode("utf-8"))
    data1=receivedstring.split(",")
    # print(data1)
    if data1[0] == '*':
        print('WEAPON detected and the Alarm is ON')
    if data1[0] == '$':
        print('WEAPON detected and the GATE is Closed')
    with open('config.json', 'w') as json_file:
        json.dump(data1, json_file)

mqtt_enabled = False
try:
    broker_address="broker.hivemq.com"
    client = mqtt.Client("WEAPON") 
    client.connect(broker_address) 
    client.on_message=on_message 
    client.subscribe("WEAPON-NT")
    mqtt_enabled = True
except Exception as e:
    print(f"MQTT Connection failed: {e}. Running without MQTT.")
response = 0 

with open('config.json') as f:
    data = json.load(f)


serverToken = 'AAAA9myXIrY:APA91bHsrnPMm8TUAk7lfPCdXzdTZdz0riWCQlaoTpWVTCGMiWakwWWEoAFdERvk6LQ8esGb-rRJvFTTY9NRTcVc-O9WrNS_MaE3GNmoJ7tbRrqt46RRXlzIPVO4NBo21LFEA8lRMtSD'
deviceToken = data[0]
headers = {
        'Content-Type': 'application/json',
        'Authorization': 'key=' + serverToken,
      }

body = {
          'notification': {'title': 'Sending push form python script',
                            'body': 'New Message'
                            },
          'to':
              deviceToken,
          'priority': 'high',
        }

outputFrame = None
lock = threading.Lock()

# initialize a flask object
app = Flask(__name__)

@app.route("/")
def index():
    # return the rendered template
    # APK Compatibility: Serve video stream at root "/"
    return Response(generate(),
        mimetype = "multipart/x-mixed-replace; boundary=frame")

def web_stream(frameCount):
    # grab global references to the video stream, output frame, and
    # lock variables
    global outputFrame, lock, latest_threat_status

    # Parse args from global scope if possible or define defaults
    parser = argparse.ArgumentParser()
    parser.add_argument('--weights', nargs='+', type=str, default='best.pt', help='model.pt path(s)')
    parser.add_argument('--source', type=str, default='0', help='source')  # file/folder, 0 for webcam
    parser.add_argument('--img-size', type=int, default=640, help='inference size (pixels)')
    parser.add_argument('--conf-thres', type=float, default=0.25, help='object confidence threshold')
    parser.add_argument('--iou-thres', type=float, default=0.45, help='IOU threshold for NMS')
    parser.add_argument('--device', default='', help='cuda device, i.e. 0 or 0,1,2,3 or cpu')
    parser.add_argument('--view-img', action='store_true', help='display results')
    parser.add_argument('--save-txt', action='store_true', help='save results to *.txt')
    parser.add_argument('--save-conf', action='store_true', help='save confidences in --save-txt labels')
    parser.add_argument('--nosave', action='store_true', help='do not save images/videos')
    parser.add_argument('--classes', nargs='+', type=int, help='filter by class: --class 0, or --class 0 2 3')
    parser.add_argument('--agnostic-nms', action='store_true', help='class-agnostic NMS')
    parser.add_argument('--augment', action='store_true', help='augmented inference')
    parser.add_argument('--update', action='store_true', help='update all models')
    parser.add_argument('--project', default='runs/detect', help='save results to project/name')
    parser.add_argument('--name', default='exp', help='save results to project/name')
    parser.add_argument('--exist-ok', action='store_true', help='existing project/name ok, do not increment')
    parser.add_argument('--no-trace', action='store_true', help='don`t trace model')
    args, unknown = parser.parse_known_args()

    opt = pd.Series()
    opt.weights = args.weights
    opt.source = args.source
    opt.img_size = args.img_size
    opt.conf_thres = args.conf_thres
    opt.iou_thres = 0.25
    opt.device = args.device
    opt.view_img = args.view_img
    opt.save_txt = args.save_txt
    opt.save_conf = args.save_conf
    opt.nosave = args.nosave
    opt.classes = args.classes
    opt.agnostic_nms = False
    opt.augment = args.augment
    opt.project = args.project
    opt.name = args.name
    opt.exist_ok = args.exist_ok
    opt.no_trace = args.no_trace
    
    # If source is numeric (webcam), ensure view_img is True unless specified otherwise
    if opt.source.isnumeric():
        opt.view_img = True
        
    print(f"\n[INFO] --------------------------------------------------------")
    print(f"[INFO] ATTEMPTING TO OPEN CAMERA SOURCE: {opt.source}")
    print(f"[INFO] If this is incorrect, try running with --source 0 or --source 1")
    print(f"[INFO] --------------------------------------------------------\n")
    print(opt)

    # with torch.no_grad():
    #         detect()

    # global notification_flag
    notification_flag = 0
    notification_flag = 0
    normalflag = 0
    
    # Console Output Optimization
    last_printed_status = ""
    last_print_time = time.time()

    source, weights, view_img, save_txt, imgsz, trace = opt.source, opt.weights, opt.view_img, opt.save_txt, opt.img_size, not opt.no_trace
    save_img = not opt.nosave and not source.endswith('.txt')  # save inference images
    webcam = True
    
    global system_status
    system_status = "INITIALIZING"

    # Directories
    save_dir = Path(increment_path(Path(opt.project) / opt.name, exist_ok=opt.exist_ok))  # increment run
    (save_dir / 'labels' if save_txt else save_dir).mkdir(parents=True, exist_ok=True)  # make dir

    # Initialize
    set_logging()
    device = select_device(opt.device)
    half = device.type != 'cpu'  # half precision only supported on CUDA

    # Load model
    model = attempt_load(weights, map_location=device)  # load FP32 model
    stride = int(model.stride.max())  # model stride
    imgsz = check_img_size(imgsz, s=stride)  # check img_size

    if trace:
        model = TracedModel(model, device, opt.img_size)

    # Set Dataloader
    vid_path, vid_writer = None, None
    if webcam:
        view_img = check_imshow()
        cudnn.benchmark = True  # set True to speed up constant image size inference
        try:
            dataset = LoadStreams(source, img_size=imgsz, stride=stride)
        except AssertionError as e:
            print(f"\n\n[ERROR] Could not open camera (Source: {source}).")
            print("Please ensure you have granted 'Camera' permission to your Terminal/VS Code.")
            print("Mac: System Settings > Privacy & Security > Camera\n")
            system_status = "ERROR"
            # Keep the main thread alive to serve the error image
            while True:
                time.sleep(1)
    else:
        dataset = LoadImages(source, img_size=imgsz, stride=stride)

    # Get names and colors
    names = model.module.names if hasattr(model, 'module') else model.names
    colors = [[random.randint(0, 255) for _ in range(3)] for _ in names]
    
    print(f"\n[INFO] Model loaded successfully.")
    print(f"[INFO] Classes detected by this model: {names}\n")
    
    system_status = "RUNNING"

    # Run inference
    if device.type != 'cpu':
        model(torch.zeros(1, 3, imgsz, imgsz).to(device).type_as(next(model.parameters())))  # run once
    old_img_w = old_img_h = imgsz
    old_img_b = 1

    t0 = time.time()
    for path, img, im0s, vid_cap in dataset:
        if mqtt_enabled:
            client.loop_start()
        img = torch.from_numpy(img).to(device)
        img = img.half() if half else img.float()  # uint8 to fp16/32
        img /= 255.0  # 0 - 255 to 0.0 - 1.0
        if img.ndimension() == 3:
            img = img.unsqueeze(0)

        # Warmup
        if device.type != 'cpu' and (old_img_b != img.shape[0] or old_img_h != img.shape[2] or old_img_w != img.shape[3]):
            old_img_b = img.shape[0]
            old_img_h = img.shape[2]
            old_img_w = img.shape[3]
            for i in range(3):
                model(img, augment=opt.augment)[0]

        # Inference
        t1 = time_synchronized()
        with torch.no_grad():   # Calculating gradients would cause a GPU memory leak
            pred = model(img, augment=opt.augment)[0]
        t2 = time_synchronized()

        # Apply NMS
        # Apply NMS - Lower IOU threshold to 0.25 and disable agnostic to stop people eclipsing weapons
        pred = non_max_suppression(pred, opt.conf_thres, 0.25, classes=opt.classes, agnostic=False)
        t3 = time_synchronized()

        # Process detections
        for i, det in enumerate(pred):  # detections per image
            if webcam:  # batch_size >= 1
                p, s, im0, frame = path[i], '%g: ' % i, im0s[i].copy(), dataset.count
            else:
                p, s, im0, frame = path, '', im0s, getattr(dataset, 'frame', 0)

            p = Path(p)  # to Path
            save_path = str(save_dir / p.name)  # img.jpg
            txt_path = str(save_dir / 'labels' / p.stem) + ('' if dataset.mode == 'image' else f'_{frame}')  # img.txt
            gn = torch.tensor(im0.shape)[[1, 0, 1, 0]]  # normalization gain whwh
            # ── FILTER 1: Confidence Thresholds (Raised weapon thresholds to cut false positives) ──
            custom_thresholds = {
                'person':     0.65,  # Keep person threshold high to reduce clutter
                'knife':      0.50,  # Raised from 0.15 → eliminates ghost knife detections
                'pistol':     0.50,  # Raised from 0.25 → needs clear gun shape
                'rifle':      0.50,  # Raised from 0.25
                'gun':        0.50,  # Raised from 0.25
                'smartphone': 0.80,  # Heavy penalty – phones look like guns
            }

            # Apply confidence filter
            filtered_det = []
            person_boxes = []   # track all person bboxes for proximity check
            weapon_boxes = []   # track weapon bboxes for proximity check
            WEAPON_CLASSES = {'knife', 'pistol', 'rifle', 'gun'}

            for *xyxy, conf, cls in det:
                c_name = names[int(cls)]
                req_conf = custom_thresholds.get(c_name, 0.45)
                if float(conf) >= req_conf:
                    filtered_det.append([*xyxy, conf, cls])
                    if c_name == 'person':
                        person_boxes.append([float(v) for v in xyxy])
                    elif c_name in WEAPON_CLASSES:
                        weapon_boxes.append([float(v) for v in xyxy])

            # ── FILTER 2: Person-Weapon Proximity Check ──
            # A weapon that is NOT near any person is almost certainly a false positive
            # (guns don't float in the air). Expand person box by 30% before checking.
            def boxes_are_near(wbox, pbox, margin=0.30):
                """Returns True if weapon bbox overlaps with margin-expanded person bbox."""
                wx1, wy1, wx2, wy2 = wbox
                px1, py1, px2, py2 = pbox
                pw = px2 - px1
                ph = py2 - py1
                px1e = px1 - margin * pw
                py1e = py1 - margin * ph
                px2e = px2 + margin * pw
                py2e = py2 + margin * ph
                # Check for overlap
                return not (wx2 < px1e or wx1 > px2e or wy2 < py1e or wy1 > py2e)

            if person_boxes and weapon_boxes:
                # Keep only weapons that are near at least one person
                valid_weapon_indices = set()
                for wi, wbox in enumerate(weapon_boxes):
                    for pbox in person_boxes:
                        if boxes_are_near(wbox, pbox):
                            valid_weapon_indices.add(wi)
                            break
                # Rebuild filtered_det: keep all persons + only validated weapons
                new_filtered = []
                w_idx = 0
                for item in filtered_det:
                    c_name = names[int(item[-1])]
                    if c_name in WEAPON_CLASSES:
                        if w_idx in valid_weapon_indices:
                            new_filtered.append(item)
                        w_idx += 1
                    else:
                        new_filtered.append(item)
                filtered_det = new_filtered

            det = torch.tensor(filtered_det) if len(filtered_det) > 0 else torch.tensor([])

            # Re-parse classes after filtering
            if len(det):
                # Rescale boxes from img_size to im0 size
                det[:, :4] = scale_coords(img.shape[2:], det[:, :4], im0.shape).round()

                # Parse detections for Threat Logic
                current_detections_classes = []
                for cls_idx in det[:, -1]:
                        current_detections_classes.append(names[int(cls_idx)])
                
                # Analyze Threat
                analysis = analyzer.analyze_threat(det[:, -1], names)
            else:
                analysis = {
                    'threat_level': 'SAFE',
                    'crowd_count': 0,
                    'weapons_detected': [],
                    'description': 'Safe'
                }

            # ── FILTER 3: Three-Consecutive-Frame Confirmation Rule ──
            # Only trigger an alarm once a weapon is seen in 3 frames IN A ROW.
            # This eliminates single-frame ghost detections (the biggest source of false alarms).
            if not hasattr(web_stream, "confirm_counter"):
                web_stream.confirm_counter = 0   # counts consecutive weapon frames
            if not hasattr(web_stream, "persistence_counter"):
                web_stream.persistence_counter = 0

            raw_has_weapon = 1 if len(analysis['weapons_detected']) > 0 else 0

            if raw_has_weapon:
                web_stream.confirm_counter = min(web_stream.confirm_counter + 1, 3)
            else:
                web_stream.confirm_counter = 0   # reset immediately if no weapon seen

            # Only accept as CONFIRMED if seen 3 or more frames in a row
            confirmed_weapon = 1 if web_stream.confirm_counter >= 3 else 0

            if confirmed_weapon:
                web_stream.persistence_counter = 8  # hold alert for ~8 more frames after loss
            elif web_stream.persistence_counter > 0:
                web_stream.persistence_counter -= 1

            smoothed_has_weapon = 1 if web_stream.persistence_counter > 0 else 0
            
            # Update Global Status
            current_status_dict = {
                "level": analysis['threat_level'] if raw_has_weapon else ("MEDIUM" if smoothed_has_weapon else "SAFE"),
                "crowd_count": analysis['crowd_count'],
                "weapons": analysis['weapons_detected'],
                "description": analysis['description'] if raw_has_weapon else ("Potential Threat (Persistent)" if smoothed_has_weapon else "Safe"),
                "timestamp": time.time(),
                "source_index": i
            }

            # Avoid logging exactly duplicate threats within a small time window (e.g. 5 seconds)
            if current_status_dict['level'] in ['HIGH', 'MEDIUM']:
                if not hasattr(web_stream, "last_db_log_time") or (time.time() - getattr(web_stream, "last_db_log_time", 0) > 10):
                    log_threat_to_db(
                        current_status_dict["level"], 
                        current_status_dict["crowd_count"], 
                        current_status_dict["weapons"], 
                        current_status_dict["description"]
                    )
                    web_stream.last_db_log_time = time.time()

            latest_threat_status = current_status_dict

            # Print results & Existing logic upgrade
            if len(det):
                for c in det[:, -1].unique():
                    n = (det[:, -1] == c).sum()  # detections per class
                    s += f"{n} {names[int(c)]}{'s' * (n > 1)}, "  # add to string
                
                # print(f"[ANALYSIS] {analysis['description']}")

                # Trigger Alerts if High/Medium Threat
                if analysis['threat_level'] in ['HIGH', 'MEDIUM']:
                     # ... (keep existing high threat logic if it was there, but for now just fix the indentation/structure)
                     pass 
                
                # Reset flags if safe
                if analysis['threat_level'] not in ['HIGH', 'MEDIUM']:
                    if mqtt_enabled:
                         pass
                    notification_flag=0
                    normalflag=1

                # Write results
                for *xyxy, conf, cls in reversed(det):
                    if save_txt:  # Write to file
                        xywh = (xyxy2xywh(torch.tensor(xyxy).view(1, 4)) / gn).view(-1).tolist()  # normalized xywh
                        line = (cls, *xywh, conf) if opt.save_conf else (cls, *xywh)  # label format
                        with open(txt_path + '.txt', 'a') as f:
                            f.write(('%g ' * len(line)).rstrip() % line + '\n')

                    if save_img or view_img:  # Add bbox to image
                        label = f'{names[int(cls)]} {conf:.2f}'
                        plot_one_box(xyxy, im0, label=label, color=colors[int(cls)], line_thickness=3)

                # Update Global Status & Print Simplified Output
                # User Format: "0 for no detect, 1 for weapon detected also the crowd"
                # Uses smoothed value for stability
                # Update Global Status & Print Simplified Output
                # User Format: "0 for no detect, 1 for weapon detected also the crowd"
                # Uses smoothed value for stability
                current_status_summary = f"{smoothed_has_weapon}-{analysis['crowd_count']}-{latest_threat_status['level']}"
                
                # Print only on change or heartbeat (every 5 seconds)
                if current_status_summary != last_printed_status or (time.time() - last_print_time > 5):
                    print(f"[STATUS] Weapon: {smoothed_has_weapon} | Crowd: {analysis['crowd_count']} | Threat: {latest_threat_status['level']}")
                    last_printed_status = current_status_summary
                    last_print_time = time.time()


                # Update Frames for Web Streaming (AFTER drawing boxes)
                with lock:
                    # Store frame by source index
                    camera_frames[i] = im0.copy()
                    
                    # Keep original outputFrame behavior for backward compatibility
                    if i == 0:
                        outputFrame = im0.copy()

            else:
                 # No detections in this frame (from NMS) OR filtered out by custom thresholds
                 # We need to decay persistence here too!
                 if hasattr(web_stream, "persistence_counter") and web_stream.persistence_counter > 0:
                     web_stream.persistence_counter -= 1
                 
                 # Reset status for this frame
                 smoothed_has_weapon = 1 if (hasattr(web_stream, "persistence_counter") and web_stream.persistence_counter > 0) else 0
                 threat_level = "MEDIUM" if smoothed_has_weapon else "SAFE"
                 
                 latest_threat_status['level'] = threat_level
                 if not smoothed_has_weapon:
                     latest_threat_status['description'] = "Safe"
                 
                 if not smoothed_has_weapon:
                     latest_threat_status['description'] = "Safe"
                 
                 current_status_summary = f"{smoothed_has_weapon}-0-SAFE"
                 
                 # Print only on change or heartbeat (every 5 seconds)
                 if current_status_summary != last_printed_status or (time.time() - last_print_time > 5):
                     print(f"[STATUS] No objects detected (Scanning...) | Persistence: {smoothed_has_weapon}")
                     last_printed_status = current_status_summary
                     last_print_time = time.time()
                 
                 with lock:
                    if i == 0:
                         outputFrame = im0.copy()

            # Print time (inference + NMS)
            # print(f'{s}Done. ({(1E3 * (t2 - t1)):.1f}ms) Inference, ({(1E3 * (t3 - t2)):.1f}ms) NMS')
            
            # with lock:
            #     outputFrame = im0.copy()
            # if cv2.waitKey(1) & 0xFF == ord("q"):
            #     break

            # Stream results
            if view_img:
                cv2.imshow(str(p), im0)
                if cv2.waitKey(1) == ord('q'):  # q to quit
                    break


    if save_txt or save_img:
        s = f"\n{len(list(save_dir.glob('labels/*.txt')))} labels saved to {save_dir / 'labels'}" if save_txt else ''
        #print(f"Results saved to {save_dir}{s}")

    print(f'Done. ({time.time() - t0:.3f}s)')

       
def generate():
    # grab global references to the output frame and lock variables
    global outputFrame, lock

    # loop over frames from the output stream
    while True:
        # wait until the lock is acquired
        with lock:
            # check if the output frame is available, otherwise skip
            # check if the output frame is available, otherwise skip
            if outputFrame is None:
                # Create a placeholder image based on status
                if 'np' not in globals(): import numpy as np
                
                blank_image = np.zeros((480, 640, 3), np.uint8)
                msg = "System Initializing..."
                color = (255, 255, 255)
                
                if system_status == "ERROR":
                    msg = "CAMERA ERROR: Check Terminal"
                    color = (0, 0, 255)
                
                cv2.putText(blank_image, msg, (50, 240), cv2.FONT_HERSHEY_SIMPLEX, 1, color, 2, cv2.LINE_AA)
                
                (flag, encodedImage) = cv2.imencode(".jpg", blank_image)
                if not flag: continue
                
            else:
                # encode the frame in JPEG format
                # Optimize: Reduce quality to 70 for speed
                (flag, encodedImage) = cv2.imencode(".jpg", outputFrame, [int(cv2.IMWRITE_JPEG_QUALITY), 70])

                # ensure the frame was successfully encoded
                if not flag:
                    continue

        # yield the output frame in the byte format
        yield(b'--frame\r\n' b'Content-Type: image/jpeg\r\n\r\n' + 
            bytearray(encodedImage) + b'\r\n')
        
        # Optimize: Prevent CPU 100% usage
        time.sleep(0.05)
        
@app.route("/video_feed")
def video_feed():
    # return the response generated along with the specific media
    # type (mime type)
    return Response(generate(),
        mimetype = "multipart/x-mixed-replace; boundary=frame")

@app.route("/api/status")
def api_status():
    global latest_threat_status
    return jsonify(latest_threat_status)

@app.route("/api/login", methods=['POST'])
def api_login():
    try:
        data = request.json
        username = data.get('username')
        password = data.get('password')
        
        # Simple Hardcoded Secure Logic (Replace with DB later)
        if username == "admin" and password == "password":
            return jsonify({
                "status": "success", 
                "message": "Login Successful",
                "topics": {
                    "notification": "WEAPON-NT",
                    "shop": "SHOP-TOPIC"
                }
            })
        else:
            return jsonify({"status": "error", "message": "Invalid Credentials"}), 401
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

def _mqtt_publish_action(payload: str):
    """Helper: publish a one-shot MQTT action message."""
    import paho.mqtt.client as _mqtt_client
    try:
        c = _mqtt_client.Client(mqtt.CallbackAPIVersion.VERSION1, f"dashboard_action_{int(time.time())}")
        c.connect("broker.hivemq.com", 1883, 10)
        c.publish("WEAPON-NT", payload, qos=1)
        c.disconnect()
        return True
    except Exception as e:
        print(f"[MQTT Action] Failed: {e}")
        return False

@app.route("/api/trigger_alarm", methods=['POST'])
def api_trigger_alarm():
    """Trigger the alarm via MQTT (publishes '*' to WEAPON-NT)."""
    success = _mqtt_publish_action("*")
    if success:
        return jsonify({"status": "success", "message": "Alarm triggered"})
    return jsonify({"status": "error", "message": "MQTT publish failed"}), 500

@app.route("/api/close_gate", methods=['POST'])
def api_close_gate():
    """Close the gate via MQTT (publishes '$' to WEAPON-NT)."""
    success = _mqtt_publish_action("$")
    if success:
        return jsonify({"status": "success", "message": "Gate closed"})
    return jsonify({"status": "error", "message": "MQTT publish failed"}), 500


@app.route("/api/logs", methods=['GET'])
def api_logs():
    """Fetch the latest 50 threat logs from SQLite."""
    try:
        conn = sqlite3.connect(DB_NAME)
        conn.row_factory = sqlite3.Row
        c = conn.cursor()
        c.execute("SELECT * FROM logs ORDER BY id DESC LIMIT 50")
        rows = c.fetchall()
        
        logs = []
        for r in rows:
            logs.append({
                "id": r["id"],
                "timestamp": r["timestamp"],
                "level": r["level"],
                "crowd_count": r["crowd_count"],
                "weapons": r["weapons"].split(", ") if r["weapons"] else [],
                "description": r["description"]
            })
        conn.close()
        return jsonify({"status": "success", "logs": logs})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500


@app.route("/video_feed/<int:source_id>")
def video_feed_source(source_id):
    return Response(generate_source(source_id),
        mimetype = "multipart/x-mixed-replace; boundary=frame")

def generate_source(source_id):
    global camera_frames, lock
    while True:
        with lock:
            if source_id not in camera_frames:
                # Optimize: Sleep if no source
                time.sleep(0.1)
                continue
            frame = camera_frames[source_id]
            # Optimize: Reduce quality to 70
            (flag, encodedImage) = cv2.imencode(".jpg", frame, [int(cv2.IMWRITE_JPEG_QUALITY), 70])
            if not flag:
                continue
        yield(b'--frame\r\n' b'Content-Type: image/jpeg\r\n\r\n' + bytearray(encodedImage) + b'\r\n')
        
        # Optimize: Cap framerate to ~20FPS to save CPU/Bandwidth
        time.sleep(0.05)

# check to see if this is the main thread of execution
if __name__ == '__main__':

    # start the flask app in a background thread
    t = threading.Thread(target=app.run, kwargs={'host': "0.0.0.0", 'port': "8000", 'threaded': True, 'use_reloader': False})
    t.daemon = True
    t.start()
    
    # Run detection in main thread (required for macOS GUI)
    web_stream(32)
