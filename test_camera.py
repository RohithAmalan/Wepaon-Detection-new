import cv2

def test_camera(index):
    cap = cv2.VideoCapture(index)
    if not cap.isOpened():
        print(f"[-] Camera source {index} is NOT available.")
        return False
    else:
        ret, frame = cap.read()
        if ret:
            print(f"[+] Camera source {index} is working! Resolution: {frame.shape[1]}x{frame.shape[0]}")
            cap.release()
            return True
        else:
            print(f"[?] Camera source {index} opened but returned no frame.")
            cap.release()
            return False

print("Testing camera indices 0, 1, 2...")
for i in range(3):
    test_camera(i)
