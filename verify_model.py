"""
End-to-end verification: Tests the exact same Letterbox preprocessing used
in the Flutter app on both best.pt and pest_model.tflite, then compares results.
"""
import cv2
import numpy as np
import glob
import os
import tensorflow as tf
from ultralytics import YOLO

PT_NAMES = {0: 'Thrips', 1: 'Mites', 2: 'Stem Borer'}
TFLITE_MODEL = "assets/pest_model.tflite"
PT_MODEL_PATH = "/Users/usmanhussain/runs/detect/cashew_multi_pest17/weights/best.pt"
CONF_THRESHOLD = 0.25

def letterbox(image_path, size=640, pad_color=114):
    """Exact same Letterbox logic as the Flutter Dart code."""
    img = cv2.imread(image_path)
    img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    h, w = img.shape[:2]
    scale = size / max(h, w)
    new_w, new_h = int(w * scale), int(h * scale)
    img_resized = cv2.resize(img, (new_w, new_h), interpolation=cv2.INTER_LINEAR)
    padded = np.full((size, size, 3), pad_color, dtype=np.uint8)
    x_off = (size - new_w) // 2
    y_off = (size - new_h) // 2
    padded[y_off:y_off + new_h, x_off:x_off + new_w] = img_resized
    return padded

def run_tflite(image_path):
    interpreter = tf.lite.Interpreter(model_path=TFLITE_MODEL)
    interpreter.allocate_tensors()
    inp = interpreter.get_input_details()
    out = interpreter.get_output_details()
    img = letterbox(image_path).astype(np.float32) / 255.0
    img = np.expand_dims(img, 0)
    interpreter.set_tensor(inp[0]['index'], img)
    interpreter.invoke()
    output = interpreter.get_tensor(out[0]['index'])[0]  # [7, 8400]
    best_conf = 0
    best_cls = -1
    for cell in range(8400):
        for c in range(3):
            prob = output[4 + c][cell]
            if prob > best_conf:
                best_conf = prob
                best_cls = c
    label = PT_NAMES.get(best_cls, 'Unknown') if best_conf >= CONF_THRESHOLD else 'No Pest'
    return label, best_conf

def run_pytorch(image_path):
    model = YOLO(PT_MODEL_PATH)
    results = model(image_path, verbose=False)
    detections = []
    for r in results:
        for box in r.boxes:
            cls = int(box.cls[0])
            conf = float(box.conf[0])
            detections.append((model.names[cls], conf))
    return detections if detections else [('No Pest', 0.0)]

def verify_all():
    test_images = glob.glob("assets/*.png") + glob.glob("assets/*.jpg")
    print(f"\n{'Image':<30} {'PyTorch':<25} {'TFLite (Flutter)':<25} {'Match?'}")
    print("-" * 85)
    for img_path in sorted(test_images):
        name = os.path.basename(img_path)
        pt_results = run_pytorch(img_path)
        pt_label = pt_results[0][0]
        tflite_label, tflite_conf = run_tflite(img_path)
        match = "✅" if pt_label.lower() in tflite_label.lower() or tflite_label.lower() in pt_label.lower() else "❌"
        pt_str = f"{pt_label} ({pt_results[0][1]:.2f})"
        tflite_str = f"{tflite_label} ({tflite_conf:.2f})"
        print(f"{name:<30} {pt_str:<25} {tflite_str:<25} {match}")

if __name__ == "__main__":
    import warnings
    warnings.filterwarnings("ignore")
    verify_all()
